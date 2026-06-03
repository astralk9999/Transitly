// Edge Function: validate_share_code
// =============================================================
// V14 A1-T3 — Valida un share_code de user_routes y devuelve
// los datos de la ruta si existe y está publicada.
// Registra la visita en user_route_views automáticamente.
//
// Llamada desde el cliente (anon key permitida):
//   POST /functions/v1/validate-share-code
//   Body: { "code": "A3F9K2" }

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

    const { code } = await req.json();

    if (!code || typeof code !== "string" || code.length < 3) {
      return new Response(
        JSON.stringify({ error: "code is required (min 3 chars)" }),
        { status: 400, headers: JSON_HEADERS },
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const { data, error } = await supabase
      .from("user_routes")
      .select("id, name, description, route_color, public_slug, author_id, vote_count, view_count")
      .eq("share_code", code.toUpperCase())
      .eq("status", "published")
      .maybeSingle();

    if (error) {
      console.error("[validate_share_code] query error:", error);
      return new Response(
        JSON.stringify({ error: "Database error" }),
        { status: 500, headers: JSON_HEADERS },
      );
    }

    if (!data) {
      return new Response(
        JSON.stringify({ error: "Route not found" }),
        { status: 404, headers: JSON_HEADERS },
      );
    }

    // Registrar visita (service role para evitar problemas RLS)
    const authHeader = req.headers.get("Authorization") ?? "";
    const token = authHeader.startsWith("Bearer ") ? authHeader.slice(7) : "";
    let viewerId: string | null = null;

    if (token) {
      try {
        const { data: userData } = await supabase.auth.getUser(token);
        viewerId = userData?.user?.id ?? null;
      } catch {
        // Token inválido/anon, ignorar
      }
    }

    await supabase.from("user_route_views").insert({
      route_id: data.id,
      viewer_id: viewerId,
      via_share_code: true,
    });

    // Incrementar view_count
    await supabase
      .from("user_routes")
      .update({ view_count: data.view_count + 1 })
      .eq("id", data.id);

    return new Response(
      JSON.stringify({
        id: data.id,
        name: data.name,
        description: data.description,
        route_color: data.route_color,
        public_slug: data.public_slug,
        vote_count: data.vote_count,
      }),
      { headers: JSON_HEADERS },
    );
  } catch (err) {
    console.error("[validate_share_code] unhandled error:", err);
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: JSON_HEADERS },
    );
  }
});
