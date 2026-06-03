// Edge Function: approve_user_route
// =============================================================
// V14 A1-T5 — Admin-only: aprueba una user_route como
// "community_approved" y asigna XP (+50) al autor.
// Opcional: copia a la tabla routes oficial si se pasa
// operator_id.
//
//   POST /functions/v1/approve-user-route
//   Body: { "route_id": "<uuid>", "operator_id?": "<uuid>" }

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

    const { route_id, operator_id } = await req.json();

    if (!route_id || typeof route_id !== "string") {
      return new Response(
        JSON.stringify({ error: "route_id is required" }),
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

    // Obtener la user_route
    const { data: userRoute, error: routeError } = await supabase
      .from("user_routes")
      .select("*")
      .eq("id", route_id)
      .maybeSingle();

    if (routeError || !userRoute) {
      return new Response(
        JSON.stringify({ error: "Route not found" }),
        { status: 404, headers: JSON_HEADERS },
      );
    }

    if (userRoute.status !== "review_pending") {
      return new Response(
        JSON.stringify({ error: "Route is not in review_pending status" }),
        { status: 400, headers: JSON_HEADERS },
      );
    }

    // Actualizar user_route a community_approved
    await supabase
      .from("user_routes")
      .update({
        status: "community_approved",
        reviewed_by: userData.user.id,
        reviewed_at: new Date().toISOString(),
        visibility: "public",
      })
      .eq("id", route_id);

    // Opcional: copiar a la tabla routes oficial si hay operator_id
    if (operator_id) {
      try {
        const { data: routeStops } = await supabase
          .from("user_route_stops")
          .select("user_stop_id, order_index")
          .eq("route_id", route_id)
          .order("order_index");

        const { data: officialRoute } = await supabase
          .from("routes")
          .insert({
            operator_id,
            source: "community",
            status: "official",
            code: userRoute.share_code || undefined,
            name: userRoute.name,
            description: userRoute.description || undefined,
            color: userRoute.route_color,
            owner_id: userRoute.author_id,
          })
          .select("id")
          .single();

        if (officialRoute && routeStops && routeStops.length > 0) {
          for (const rs of routeStops) {
            const { data: userStop } = await supabase
              .from("user_stops")
              .select("official_stop_id")
              .eq("id", rs.user_stop_id)
              .maybeSingle();

            const stopId = userStop?.official_stop_id || null;
            if (stopId) {
              await supabase.from("route_stops").insert({
                route_id: officialRoute.id,
                stop_id: stopId,
                sequence: rs.order_index,
              });
            }
          }
        }
      } catch (copyErr) {
        console.error("[approve_user_route] copy to routes failed:", copyErr);
        // No fail — seguimos con el flujo principal
      }
    }

    // XP al autor
    await supabase.rpc("add_xp", {
      p_user_id: userRoute.author_id,
      p_xp: 50,
    });

    // Audit log
    await supabase.from("audit_log").insert({
      actor_id: userData.user.id,
      action: "approve_user_route_to_community",
      target_kind: "user_route",
      target_id: route_id,
      payload: { operator_id: operator_id || null },
    });

    return new Response(
      JSON.stringify({ success: true }),
      { headers: JSON_HEADERS },
    );
  } catch (err) {
    console.error("[approve_user_route] unhandled error:", err);
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: JSON_HEADERS },
    );
  }
});
