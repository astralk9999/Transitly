import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const JSON_HEADERS = { "Content-Type": "application/json" };

function isServiceRoleCaller(req: Request): boolean {
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!serviceKey) return false;
  const auth = req.headers.get("Authorization") ?? "";
  const bearer = auth.startsWith("Bearer ") ? auth.slice(7) : "";
  if (bearer.length !== serviceKey.length) return false;
  let diff = 0;
  for (let i = 0; i < bearer.length; i++) {
    diff |= bearer.charCodeAt(i) ^ serviceKey.charCodeAt(i);
  }
  return diff === 0;
}

serve(async (req: Request) => {
  try {
    if (req.method !== "POST") {
      return new Response(
        JSON.stringify({ error: "Method not allowed" }),
        { status: 405, headers: JSON_HEADERS },
      );
    }

    if (!isServiceRoleCaller(req)) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: JSON_HEADERS },
      );
    }

    const { user_id } = await req.json();

    if (!user_id || typeof user_id !== "string") {
      return new Response(
        JSON.stringify({ error: "user_id is required" }),
        { status: 400, headers: JSON_HEADERS },
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    await supabase.from("incidents").update({ user_id: null }).eq("user_id", user_id);
    await supabase.from("route_feedback").update({ author_id: null }).eq("author_id", user_id);

    await supabase.from("user_preferences").delete().eq("user_id", user_id);
    await supabase.from("profiles").delete().eq("id", user_id);

    await supabase.from("audit_log").insert({
      action: "right_to_be_forgotten",
      target_id: user_id,
      details: { timestamp: new Date().toISOString() },
    });

    return new Response(
      JSON.stringify({ success: true }),
      { headers: JSON_HEADERS },
    );
  } catch (err) {
    console.error("[delete_user] unhandled error:", err);
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: JSON_HEADERS },
    );
  }
});
