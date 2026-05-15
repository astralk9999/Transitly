// Edge Function: send_notification
// =============================================================
// F21 — Recibe { user_id, title, body, deeplink, data, type }
// 1. Inserta en `notifications` (in-app)
// 2. Busca `device_tokens` del usuario
// 3. Envía push via FCM HTTP v1
// 4. Responde { success: true, tokens_sent: N }
//
// Invocada desde triggers SQL via pg_net (015_push_triggers.sql)
// con el header Authorization: Bearer <service_role_key>.
//
// ENV vars requeridas:
//   SUPABASE_URL                — auto-populated by Supabase
//   SUPABASE_SERVICE_ROLE_KEY   — auto-populated by Supabase
//   FCM_SERVICE_ACCOUNT_JSON    — Firebase service account JSON (one line)
//   FCM_PROJECT_ID              — Firebase project ID

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req: Request) => {
  try {
    const { user_id, title, body, deeplink, data, type } = await req.json();

    if (!user_id || !title || !body) {
      return new Response(
        JSON.stringify({ error: "user_id, title, and body are required" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    // 1 ── Insertar notificación in-app ────────────────────────────
    const { error: notifError } = await supabase
      .from("notifications")
      .insert({
        user_id,
        type: type || "custom",
        payload: {
          title,
          body,
          deeplink: deeplink || null,
          data: data || {},
        },
      });

    if (notifError) {
      console.error("[send_notification] insert error:", notifError);
    }

    // 2 ── Buscar device_tokens del usuario ─────────────────────────
    const { data: tokens, error: tokenError } = await supabase
      .from("device_tokens")
      .select("token, platform")
      .eq("user_id", user_id);

    if (tokenError) {
      console.error("[send_notification] token lookup error:", tokenError);
      return new Response(
        JSON.stringify({ success: true, tokens_sent: 0, error: tokenError.message }),
        { headers: { "Content-Type": "application/json" } },
      );
    }

    if (!tokens || tokens.length === 0) {
      return new Response(
        JSON.stringify({ success: true, tokens_sent: 0 }),
        { headers: { "Content-Type": "application/json" } },
      );
    }

    // 3 ── Enviar push via FCM ─────────────────────────────────────
    const fcmSa = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");
    const fcmProjectId = Deno.env.get("FCM_PROJECT_ID");

    if (!fcmSa || !fcmProjectId) {
      console.warn(
        "[send_notification] FCM not configured (missing FCM_SERVICE_ACCOUNT_JSON or FCM_PROJECT_ID)",
      );
      return new Response(
        JSON.stringify({
          success: true,
          tokens_sent: 0,
          warning: "FCM not configured",
        }),
        { headers: { "Content-Type": "application/json" } },
      );
    }

    let sa: { client_email: string; private_key: string; token_uri?: string };
    try {
      sa = JSON.parse(fcmSa);
    } catch {
      return new Response(
        JSON.stringify({ error: "Invalid FCM_SERVICE_ACCOUNT_JSON" }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }

    const accessToken = await getAccessToken(sa);
    let tokensSent = 0;
    const invalidTokens: string[] = [];

    for (const tk of tokens) {
      try {
        const result = await sendFcmMessage(
          accessToken,
          fcmProjectId,
          tk.token,
          { title, body, deeplink, data },
        );
        if (result === "sent") tokensSent++;
        else if (result === "invalid") invalidTokens.push(tk.token);
      } catch (e) {
        console.error(
          `[send_notification] FCM send failed token=${tk.token.substring(0, 10)}...`,
          e,
        );
      }
    }

    // Limpiar tokens inválidos
    if (invalidTokens.length > 0) {
      const { error: cleanError } = await supabase
        .from("device_tokens")
        .delete()
        .in("token", invalidTokens);
      if (cleanError) {
        console.error("[send_notification] token cleanup error:", cleanError);
      }
    }

    return new Response(
      JSON.stringify({ success: true, tokens_sent: tokensSent }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (err) {
    console.error("[send_notification] unhandled error:", err);
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});

// ── OAuth 2.0 access token para FCM HTTP v1 ────────────────────────

async function getAccessToken(
  sa: { client_email: string; private_key: string; token_uri?: string },
): Promise<string> {
  const jwt = await signJwt(sa);

  const res = await fetch(
    sa.token_uri || "https://oauth2.googleapis.com/token",
    {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion: jwt,
      }),
    },
  );

  if (!res.ok) {
    const errBody = await res.text();
    throw new Error(`OAuth token request failed: ${res.status} ${errBody}`);
  }

  const data = await res.json();
  return data.access_token;
}

// ── JWT RS256 (Web Crypto) ─────────────────────────────────────────

async function signJwt(
  sa: { client_email: string; private_key: string; token_uri?: string },
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);

  const header = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: sa.token_uri || "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  };

  const enc = new TextEncoder();
  const h = base64url(enc.encode(JSON.stringify(header)));
  const p = base64url(enc.encode(JSON.stringify(payload)));
  const signingInput = `${h}.${p}`;

  const key = await importRsaKey(sa.private_key);
  const sig = await crypto.subtle.sign(
    { name: "RSASSA-PKCS1-v1_5" },
    key,
    enc.encode(signingInput),
  );

  return `${signingInput}.${base64url(new Uint8Array(sig))}`;
}

async function importRsaKey(pem: string): Promise<CryptoKey> {
  const der = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");

  const binary = Uint8Array.from(atob(der), (c) => c.charCodeAt(0));

  return await crypto.subtle.importKey(
    "pkcs8",
    binary,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
}

function base64url(data: Uint8Array): string {
  let s = "";
  for (let i = 0; i < data.length; i++) s += String.fromCharCode(data[i]);
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

// ── FCM HTTP v1 send ───────────────────────────────────────────────

type FcmResult = "sent" | "invalid" | "error";

async function sendFcmMessage(
  accessToken: string,
  projectId: string,
  token: string,
  notif: {
    title: string;
    body: string;
    deeplink?: string;
    data?: Record<string, unknown>;
  },
): Promise<FcmResult> {
  const message: Record<string, unknown> = {
    token,
    notification: { title: notif.title, body: notif.body },
  };

  if (notif.data && typeof notif.data === "object") {
    const sd: Record<string, string> = {};
    for (const [k, v] of Object.entries(notif.data)) sd[k] = String(v);
    message.data = sd;
  }

  const android: Record<string, unknown> = {};
  if (notif.deeplink) {
    android.notification = { click_action: notif.deeplink };
  }
  if (Object.keys(android).length > 0) message.android = android;

  if (notif.deeplink) {
    message.webpush = { fcm_options: { link: notif.deeplink } };
  }

  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify({ message }),
    },
  );

  if (res.ok) return "sent";

  const err = await res.json();
  const status = err?.error?.status;
  const details: Array<{ errorCode?: string }> = err?.error?.details ?? [];

  if (
    status === "NOT_FOUND" ||
    status === "INVALID_ARGUMENT" ||
    details.some((d) => d.errorCode === "UNREGISTERED")
  ) {
    console.warn(
      `[send_notification] invalid token ${token.substring(0, 10)}... status=${status}`,
    );
    return "invalid";
  }

  console.error(
    `[send_notification] FCM error token=${token.substring(0, 10)}...`,
    err,
  );
  return "error";
}
