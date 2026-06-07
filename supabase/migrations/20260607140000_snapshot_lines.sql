-- RPC: devuelve las líneas de un operador como JSON listo para el snapshot
-- offline (esquema compatible con comujesa_data.json). Las coordenadas se
-- emiten como lat/lng numéricos (ST_Y/ST_X), no como geom binario.
create or replace function public.snapshot_lines(p_operator_id uuid)
returns jsonb
language sql
stable
as $$
  select coalesce(jsonb_agg(line order by line->>'code'), '[]'::jsonb)
  from (
    select jsonb_build_object(
      'code', r.code,
      'name', r.name,
      'color', coalesce(r.color, '#977DDF'),
      'serviceType', coalesce(r.metadata->>'serviceType', 'urban'),
      'polyline', case when r.metadata ? 'polyline_lod'
        then jsonb_build_object('type','LineString','coordinates', r.metadata->'polyline_lod')
        else null end,
      'stops', coalesce((
        select jsonb_agg(jsonb_build_object(
          'name', s.name,
          'officialCode', s.code,
          'order', rs.sequence + 1,
          'municipality', coalesce(s.metadata->>'municipality','Jerez de la Frontera'),
          'lat', round(ST_Y(s.geom::geometry)::numeric, 6),
          'lng', round(ST_X(s.geom::geometry)::numeric, 6),
          'hasShelter', coalesce((s.accessibility->>'shelter')::boolean, false),
          'isAccessible', coalesce((s.accessibility->>'wheelchair')::boolean, false),
          'hasBench', coalesce((s.accessibility->>'bench')::boolean, false)
        ) order by rs.sequence)
        from route_stops rs join stops s on s.id = rs.stop_id
        where rs.route_id = r.id and rs.direction = 0
      ), '[]'::jsonb),
      'schedules', coalesce((
        select jsonb_object_agg(day, times)
        from (
          select sc.day_type::text as day, jsonb_agg(to_char(sc.departure_time,'HH24:MI') order by sc.departure_time) as times
          from schedules sc where sc.route_id = r.id
          group by sc.day_type
        ) g
      ), '{}'::jsonb),
      'stopTimetables', coalesce((
        select jsonb_object_agg(day, trips)
        from (
          select sc.day_type::text as day,
            jsonb_agg(jsonb_build_object(
              'departure', to_char(sc.departure_time,'HH24:MI'),
              'offsets', sc.arrival_offsets
            ) order by sc.departure_time) as trips
          from schedules sc
          where sc.route_id = r.id and sc.arrival_offsets is not null
          group by sc.day_type
        ) t
      ), '{}'::jsonb)
    ) as line
    from routes r
    where r.operator_id = p_operator_id and r.source = 'official'
  ) lines;
$$;

grant execute on function public.snapshot_lines(uuid) to anon, authenticated;
