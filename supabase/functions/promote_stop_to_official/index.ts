// Edge Function: promote_stop_to_official
// =============================================================
// V14 A1-T4 — Admin-only: promueve una user_stop a la tabla
// oficial de stops y asigna XP (+20) al autor.
//
//   POST /functions/v1/promote-stop-to-official
//   Body: { "user_stop_id": "<uuid>" }

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const JSON_HEADERS = { "Content-Type": "application/json" };

serve(async (req: Request) => {
  try {
    if (req.method !== "POST") {
      return new Response(
        JSON.stringify({ error: "Method not allowed" }),
        { status: 405, headers: JSON_HEADERS },
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const { user_stop_id } = await req.json();

    if (!user_stop_id || typeof user_stop_id !== "string") {
      return new Response(
        JSON.stringify({ error: "user_stop_id is required" }),
        { status: 400, headers: JSON_HEADERS },
      );
    }

    // Verificar que el caller es admin
    const authHeader = req.headers.get("Authorization") ?? "";
    const token = authHeader.startsWith("Bearer ") ? authHeader.slice(7) : "";

    if (!token) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: JSON_HEADERS },
      );
    }

    const { data: userData, error: userError } = await supabase.auth.getUser(token);
    if (userError || !userData?.user) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: JSON_HEADERS },
      );
    }

    const { data: profile } = await supabase
      .from("profiles")
      .select("role")
      .eq("id", userData.user.id)
      .maybeSingle();

    const isAdmin = profile?.role === "admin" || profile?.role === "moderator";
    if (!isAdmin) {
      return new Response(
        JSON.stringify({ error: "Admin only" }),
        { status: 403, headers: JSON_HEADERS },
      );
    }

    // Obtener la user_stop
    const { data: userStop, error: stopError } = await supabase
      .from("user_stops")
      .select("*")
      .eq("id", user_stop_id)
      .maybeSingle();

    if (stopError || !userStop) {
      return new Response(
        JSON.stringify({ error: "Stop not found" }),
        { status: 404, headers: JSON_HEADERS },
      );
    }

    if (userStop.promotion_status !== "requested") {
      return new Response(
        JSON.stringify({ error: "Stop is not in requested status" }),
        { status: 400, headers: JSON_HEADERS },
      );
    }

    // Insertar en stops oficial
    const { data: officialStop, error: insertError } = await supabase
      .from("stops")
      .insert({
        name: userStop.name,
        geom: `SRID=4326;POINT(${userStop.lng} ${userStop.lat})`,
      })
      .select("id")
      .single();

    if (insertError) {
      console.error("[promote_stop_to_official] insert error:", insertError);
      return new Response(
        JSON.stringify({ error: "Failed to create official stop" }),
        { status: 500, headers: JSON_HEADERS },
      );
    }

    // Actualizar user_stop
    await supabase
      .from("user_stops")
      .update({
        promotion_status: "approved",
        promoted_to_official_at: new Date().toISOString(),
        official_stop_id: officialStop.id,
        reviewed_by: userData.user.id,
      })
      .eq("id", user_stop_id);

    // XP al autor
    await supabase.rpc("add_xp", {
      p_user_id: userStop.author_id,
      p_xp: 20,
    });

    // Audit log
    await supabase.from("audit_log").insert({
      actor_id: userData.user.id,
      action: "promote_stop_to_official",
      target_kind: "user_stop",
      target_id: user_stop_id,
      payload: { official_stop_id: officialStop.id },
    });

    return new Response(
      JSON.stringify({
        success: true,
        official_stop_id: officialStop.id,
      }),
      { headers: JSON_HEADERS },
    );
  } catch (err) {
    console.error("[promote_stop_to_official] unhandled error:", err);
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: JSON_HEADERS },
    );
  }
});
