import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const JSON_HEADERS = { "Content-Type": "application/json" };

const BUS_POSITIONS_RETENTION_DAYS = 30;
const NOTIFICATIONS_RETENTION_DAYS = 90;

serve(async (_req: Request) => {
  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const busCutoff = new Date();
    busCutoff.setDate(busCutoff.getDate() - BUS_POSITIONS_RETENTION_DAYS);

    const notifCutoff = new Date();
    notifCutoff.setDate(notifCutoff.getDate() - NOTIFICATIONS_RETENTION_DAYS);

    const { error: busError, count: busDeleted } = await supabase
      .from("bus_positions")
      .delete({ count: "exact" })
      .lt("recorded_at", busCutoff.toISOString());

    if (busError) {
      console.error("[purge_old_data] bus_positions delete error:", busError);
    }

    const { error: notifError, count: notifDeleted } = await supabase
      .from("app_notifications")
      .delete({ count: "exact" })
      .lt("created_at", notifCutoff.toISOString());

    if (notifError) {
      console.error("[purge_old_data] app_notifications delete error:", notifError);
    }

    console.log(
      `[purge_old_data] purged bus_positions=${busDeleted ?? 0} app_notifications=${notifDeleted ?? 0}`,
    );

    return new Response(
      JSON.stringify({
        success: true,
        bus_positions_deleted: busDeleted ?? 0,
        app_notifications_deleted: notifDeleted ?? 0,
      }),
      { headers: JSON_HEADERS },
    );
  } catch (err) {
    console.error("[purge_old_data] unhandled error:", err);
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: JSON_HEADERS },
    );
  }
});
