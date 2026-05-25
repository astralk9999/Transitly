import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req) => {
  const { user_id } = await req.json();
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const [profile, favorites, contributions, feedback, incidents] =
    await Promise.all([
      supabase.from("profiles").select("*").eq("id", user_id).single(),
      supabase.from("user_favorites").select("*").eq("user_id", user_id),
      supabase.from("route_suggestions").select("*").eq("user_id", user_id),
      supabase.from("route_feedback").select("*").eq("user_id", user_id),
      supabase.from("incidents").select("*").eq("reporter_id", user_id),
    ]);

  const exportData = {
    exported_at: new Date().toISOString(),
    user_id,
    profile: profile.data,
    favorites: favorites.data,
    contributions: contributions.data,
    feedback: feedback.data,
    incidents: incidents.data,
  };

  const fileName = `exports/${user_id}/${Date.now()}.json`;
  await supabase.storage
    .from("exports")
    .upload(fileName, JSON.stringify(exportData, null, 2));

  const { data: signedUrl } = await supabase.storage
    .from("exports")
    .createSignedUrl(fileName, 60 * 60 * 24 * 7);

  await supabase
    .from("data_exports")
    .update({ executed_at: new Date().toISOString(), download_url: signedUrl?.signedUrl })
    .eq("user_id", user_id);

  return new Response(JSON.stringify({ ok: true, url: signedUrl?.signedUrl }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
