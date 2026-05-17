// Edge Function: import_gtfs
// Importa un feed GTFS estándar y lo mapea a las tablas de Transitly.
// Solo callable por roles admin u operator_admin.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// CORS restringido por allowlist (env ALLOWED_ORIGINS, separada por comas).
// Sin wildcard: solo se refleja el Origin si está en la lista.
const ALLOWED_ORIGINS = (Deno.env.get("ALLOWED_ORIGINS") ?? "")
  .split(",")
  .map((o) => o.trim())
  .filter((o) => o.length > 0);

function corsFor(req: Request): Record<string, string> {
  const origin = req.headers.get("Origin") ?? "";
  const allowed = ALLOWED_ORIGINS.includes(origin) ? origin : "";
  return {
    "Access-Control-Allow-Origin": allowed,
    "Vary": "Origin",
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
  };
}

// Protección SSRF: solo https, host público, y allowlist opcional de
// hosts (env GTFS_ALLOWED_HOSTS, separada por comas). Bloquea loopback
// y rangos privados/link-local para impedir pivotar a la red interna.
function assertSafeGtfsUrl(raw: string): URL {
  let url: URL;
  try {
    url = new URL(raw);
  } catch {
    throw new Error("gtfsUrl is not a valid URL");
  }
  if (url.protocol !== "https:") {
    throw new Error("gtfsUrl must use https");
  }
  const host = url.hostname.toLowerCase();
  const isPrivate =
    host === "localhost" ||
    host === "0.0.0.0" ||
    host === "::1" ||
    host.endsWith(".localhost") ||
    host.endsWith(".internal") ||
    /^127\./.test(host) ||
    /^10\./.test(host) ||
    /^192\.168\./.test(host) ||
    /^169\.254\./.test(host) ||
    /^172\.(1[6-9]|2\d|3[0-1])\./.test(host);
  if (isPrivate) {
    throw new Error("gtfsUrl host is not allowed (private/loopback)");
  }
  const allowHosts = (Deno.env.get("GTFS_ALLOWED_HOSTS") ?? "")
    .split(",")
    .map((h) => h.trim().toLowerCase())
    .filter((h) => h.length > 0);
  if (allowHosts.length > 0 && !allowHosts.includes(host)) {
    throw new Error("gtfsUrl host is not in GTFS_ALLOWED_HOSTS allowlist");
  }
  return url;
}

serve(async (req: Request) => {
  const corsHeaders = corsFor(req);

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Method not allowed" }),
      { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  try {
    const { operatorSlug, gtfsUrl, dryRun } = await req.json();

    if (!operatorSlug || !gtfsUrl) {
      return new Response(
        JSON.stringify({ error: "operatorSlug and gtfsUrl are required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (typeof operatorSlug !== "string" || !/^[a-z0-9_-]{2,40}$/.test(operatorSlug)) {
      return new Response(
        JSON.stringify({ error: "operatorSlug must match ^[a-z0-9_-]{2,40}$" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    let safeGtfsUrl: URL;
    try {
      safeGtfsUrl = assertSafeGtfsUrl(String(gtfsUrl));
    } catch (e) {
      return new Response(
        JSON.stringify({ error: (e as Error).message }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Authorization required" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const token = authHeader.replace("Bearer ", "");
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Invalid token" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Verificar rol
    const { data: profile } = await supabase
      .from("profiles")
      .select("role")
      .eq("id", user.id)
      .single();

    if (!profile || (profile.role !== "admin" && profile.role !== "operator_admin")) {
      return new Response(
        JSON.stringify({ error: "Unauthorized role" }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Crear registro de importación
    const { data: importRecord } = await supabase
      .from("gtfs_imports")
      .insert({
        operator_id: null,
        gtfs_url: safeGtfsUrl.toString(),
        status: "running",
        triggered_by: user.id,
      })
      .select()
      .single();

    const importId = importRecord?.id;

    try {
      // Descargar y parsear GTFS
      const stats = await importGtfsFeed(supabase, operatorSlug, safeGtfsUrl.toString(), dryRun === true);

      await supabase
        .from("gtfs_imports")
        .update({
          status: "success",
          stats,
          finished_at: new Date().toISOString(),
          feed_version: stats.feed_version,
        })
        .eq("id", importId);

      return new Response(
        JSON.stringify({ success: true, stats, dryRun: dryRun === true }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    } catch (err) {
      await supabase
        .from("gtfs_imports")
        .update({
          status: "failed",
          errors: [{ message: err.message, stack: err.stack }],
          finished_at: new Date().toISOString(),
        })
        .eq("id", importId);

      throw err;
    }
  } catch (err) {
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

// ── GTFS Parser ────────────────────────────────────────────────────

interface GtfsStats {
  feed_version?: string;
  operators_upserted: number;
  stops_upserted: number;
  routes_upserted: number;
  route_stops_upserted: number;
  schedules_upserted: number;
  errors: string[];
}

async function importGtfsFeed(
  supabase: any,
  slug: string,
  url: string,
  dryRun: boolean
): Promise<GtfsStats> {
  const stats: GtfsStats = {
    operators_upserted: 0,
    stops_upserted: 0,
    routes_upserted: 0,
    route_stops_upserted: 0,
    schedules_upserted: 0,
    errors: [],
  };

  // Descargar ZIP con timeout (30s) y límite de tamaño (50 MB) para
  // acotar el impacto de un endpoint malicioso o lento.
  const MAX_BYTES = 50 * 1024 * 1024;
  const ac = new AbortController();
  const timer = setTimeout(() => ac.abort(), 30_000);
  let response: Response;
  try {
    response = await fetch(url, { signal: ac.signal, redirect: "follow" });
  } finally {
    clearTimeout(timer);
  }
  if (!response.ok) {
    throw new Error(`Failed to download GTFS feed: ${response.status} ${response.statusText}`);
  }
  const declaredLen = Number(response.headers.get("content-length") ?? "0");
  if (declaredLen > MAX_BYTES) {
    throw new Error(`GTFS feed too large: ${declaredLen} bytes (max ${MAX_BYTES})`);
  }

  const zipData = await response.arrayBuffer();
  if (zipData.byteLength > MAX_BYTES) {
    throw new Error(`GTFS feed too large: ${zipData.byteLength} bytes (max ${MAX_BYTES})`);
  }
  const zip = await parseZip(zipData);

  // Leer CSVs
  const agency = parseCsv(readFile(zip, "agency.txt"));
  const stops = parseCsv(readFile(zip, "stops.txt"));
  const routes = parseCsv(readFile(zip, "routes.txt"));
  const trips = parseCsv(readFile(zip, "trips.txt"));
  const stopTimes = parseCsv(readFile(zip, "stop_times.txt"));
  const calendar = parseCsv(readFile(zip, "calendar.txt"));
  const calendarDates = parseCsv(readFile(zip, "calendar_dates.txt"));
  const shapes = parseCsv(readFile(zip, "shapes.txt"));

  if (agency.length === 0) throw new Error("agency.txt is empty or missing");
  if (stops.length === 0) throw new Error("stops.txt is empty or missing");

  stats.feed_version = agency[0].agency_version || undefined;

  // ── Operators ──
  const agencyRow = agency[0];
  const { data: existingOp } = await supabase
    .from("operators")
    .select("id")
    .eq("slug", slug)
    .maybeSingle();

  let operatorId = existingOp?.id;

  if (!existingOp) {
    const { data: newOp, error: opError } = await supabase
      .from("operators")
      .insert({
        slug,
        name: agencyRow.agency_name || slug,
        contact_email: agencyRow.agency_email || null,
        website: agencyRow.agency_url || null,
        region: "ES",
      })
      .select()
      .single();

    if (opError) {
      stats.errors.push(`Failed to create operator: ${opError.message}`);
      throw new Error(opError.message);
    }
    operatorId = newOp.id;
  } else {
    await supabase
      .from("operators")
      .update({
        name: agencyRow.agency_name || slug,
        contact_email: agencyRow.agency_email || null,
        website: agencyRow.agency_url || null,
      })
      .eq("id", operatorId);
  }
  stats.operators_upserted = 1;

  // ── Stops ──
  for (const stop of stops) {
    const geom = `SRID=4326;POINT(${stop.stop_lon || "0"} ${stop.stop_lat || "0"})`;
    try {
      await supabase.from("stops").upsert({
        operator_id: operatorId,
        code: stop.stop_code || stop.stop_id,
        name: stop.stop_name || "Unknown",
        geom,
        gtfs_stop_id: stop.stop_id,
        metadata: {
          stop_desc: stop.stop_desc,
          location_type: stop.location_type,
          wheelchair_boarding: stop.wheelchair_boarding,
        },
      }, { onConflict: "operator_id, gtfs_stop_id" });
      stats.stops_upserted++;
    } catch (e) {
      stats.errors.push(`Stop ${stop.stop_id}: ${e.message}`);
    }
  }

  // ── Routes ──
  for (const route of routes) {
    const color = route.route_color ? `#${route.route_color}` : null;
    try {
      await supabase.from("routes").upsert({
        operator_id: operatorId,
        source: "official",
        status: "official",
        code: route.route_short_name,
        name: route.route_long_name || route.route_short_name || "Unknown",
        color,
        gtfs_route_id: route.route_id,
        metadata: {
          route_type: route.route_type,
          route_desc: route.route_desc,
        },
      }, { onConflict: "operator_id, gtfs_route_id" });
      stats.routes_upserted++;
    } catch (e) {
      stats.errors.push(`Route ${route.route_id}: ${e.message}`);
    }
  }

  // ── Route Stops + Schedules ──
  const tripMap = new Map<string, any>();
  for (const trip of trips) {
    tripMap.set(trip.trip_id, trip);
  }

  const routeIdByGtfs: Record<string, string> = {};
  const { data: dbRoutes } = await supabase
    .from("routes")
    .select("id, gtfs_route_id")
    .eq("operator_id", operatorId);

  if (dbRoutes) {
    for (const r of dbRoutes) {
      if (r.gtfs_route_id) routeIdByGtfs[r.gtfs_route_id] = r.id;
    }
  }

  const stopIdByGtfs: Record<string, string> = {};
  const { data: dbStops } = await supabase
    .from("stops")
    .select("id, gtfs_stop_id")
    .eq("operator_id", operatorId);

  if (dbStops) {
    for (const s of dbStops) {
      if (s.gtfs_stop_id) stopIdByGtfs[s.gtfs_stop_id] = s.id;
    }
  }

  // Ruta → Set de stop_ids con dirección
  const routeStopSet = new Map<string, Set<string>>();

  for (const st of stopTimes) {
    const trip = tripMap.get(st.trip_id);
    if (!trip) continue;

    const routeId = routeIdByGtfs[trip.route_id];
    const stopId = stopIdByGtfs[st.stop_id];
    if (!routeId || !stopId) continue;

    const key = `${routeId}:${trip.direction_id || "0"}:${st.stop_sequence}`;
    if (!routeStopSet.has(key)) routeStopSet.set(key, new Set());
    routeStopSet.get(key)!.add(stopId);
  }

  for (const [key, stopIds] of routeStopSet) {
    const [routeId, direction, sequence] = key.split(":");
    try {
      await supabase.from("route_stops").upsert({
        route_id: routeId,
        stop_id: Array.from(stopIds)[0],
        sequence: parseInt(sequence),
        direction: parseInt(direction),
      }, { onConflict: "route_id, stop_id, direction, sequence" });
      stats.route_stops_upserted++;
    } catch (e) {
      stats.errors.push(`RouteStop ${key}: ${e.message}`);
    }
  }

  // ── Schedules ──
  const scheduleSet = new Set<string>();
  for (const st of stopTimes) {
    const trip = tripMap.get(st.trip_id);
    if (!trip) continue;
    const routeId = routeIdByGtfs[trip.route_id];
    if (!routeId) continue;

    // Solo primera parada de cada trip genera un schedule
    const seq = parseInt(st.stop_sequence);
    if (seq !== 1) continue;

    const calEntry = calendar.find((c: any) => c.service_id === trip.service_id);
    let dayType = "weekday";
    if (calEntry) {
      if (calEntry.monday === "1") dayType = "weekday";
      if (calEntry.saturday === "1") dayType = "saturday";
      if (calEntry.sunday === "1") dayType = "sunday_holiday";
    }

    const scheduleKey = `${routeId}:${dayType}:${trip.direction_id || "0"}:${st.departure_time}`;
    if (scheduleSet.has(scheduleKey)) continue;
    scheduleSet.add(scheduleKey);

    try {
      await supabase.from("schedules").upsert({
        route_id: routeId,
        day_type: dayType,
        direction: parseInt(trip.direction_id || "0"),
        departure_time: st.departure_time,
      });
      stats.schedules_upserted++;
    } catch (e) {
      stats.errors.push(`Schedule ${scheduleKey}: ${e.message}`);
    }
  }

  return stats;
}

// ── CSV Parser ──────────────────────────────────────────────────────

function parseCsv(text: string): Record<string, string>[] {
  if (!text) return [];
  const lines = text.trim().split("\n");
  if (lines.length < 2) return [];

  const headers = lines[0].split(",").map((h) => h.trim().replace(/^"|"$/g, ""));
  const rows: Record<string, string>[] = [];

  for (let i = 1; i < lines.length; i++) {
    const values = parseCsvLine(lines[i]);
    if (values.length === 0) continue;
    const row: Record<string, string> = {};
    headers.forEach((h, idx) => {
      row[h] = values[idx]?.trim().replace(/^"|"$/g, "") || "";
    });
    rows.push(row);
  }

  return rows;
}

function parseCsvLine(line: string): string[] {
  const result: string[] = [];
  let current = "";
  let inQuotes = false;

  for (const char of line) {
    if (char === '"') {
      inQuotes = !inQuotes;
    } else if (char === "," && !inQuotes) {
      result.push(current);
      current = "";
    } else {
      current += char;
    }
  }
  result.push(current);
  return result;
}

// ── ZIP Parser (lightweight, no dependencies) ───────────────────────

interface ZipEntry {
  name: string;
  offset: number;
  size: number;
}

async function parseZip(buffer: ArrayBuffer): Promise<Map<string, Uint8Array>> {
  const data = new Uint8Array(buffer);
  const files = new Map<string, Uint8Array>();

  // Buscar End of Central Directory Record (EOCD)
  let eocdOffset = data.length - 22;
  while (eocdOffset > 0) {
    const view = new DataView(data.buffer, eocdOffset, 4);
    if (view.getUint32(0, true) === 0x06054b50) break;
    eocdOffset--;
  }
  if (eocdOffset <= 0) return files;

  const eocdView = new DataView(data.buffer, eocdOffset, 22);
  const centralDirOffset = eocdView.getUint32(16, true);
  const totalEntries = eocdView.getUint16(10, true);

  // Leer Central Directory
  let offset = centralDirOffset;
  for (let i = 0; i < totalEntries; i++) {
    const headerView = new DataView(data.buffer, offset, 46);
    const signature = headerView.getUint32(0, true);
    if (signature !== 0x02014b50) break;

    const nameLen = headerView.getUint16(28, true);
    const extraLen = headerView.getUint16(30, true);
    const commentLen = headerView.getUint16(32, true);
    const localHeaderOffset = headerView.getUint32(42, true);

    const nameBytes = data.slice(offset + 46, offset + 46 + nameLen);
    const fileName = new TextDecoder().decode(nameBytes);

    // Leer Local File Header
    const localView = new DataView(data.buffer, localHeaderOffset, 30);
    const localNameLen = localView.getUint16(26, true);
    const localExtraLen = localView.getUint16(28, true);
    const compressedSize = localView.getUint32(18, true);

    const fileDataStart = localHeaderOffset + 30 + localNameLen + localExtraLen;
    const fileData = data.slice(fileDataStart, fileDataStart + compressedSize);

    files.set(fileName, fileData);

    offset += 46 + nameLen + extraLen + commentLen;
  }

  return files;
}

function readFile(zip: Map<string, Uint8Array>, name: string): string {
  for (const [key, data] of zip) {
    if (key.endsWith(name)) {
      return new TextDecoder().decode(data);
    }
  }
  return "";
}
