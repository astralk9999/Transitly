-- RPC: guarda el TRAZADO (polilínea multinivel) de una ruta oficial en
-- routes.metadata.polyline_lod, que es de donde lo lee snapshot_lines para
-- pintarlo en el mapa. Hasta ahora admin_route_upsert no escribía el trazado,
-- por lo que las líneas creadas por admin/operador salían sin recorrido.
--
-- p_polyline_lod: objeto { "lod0": [[lng,lat],...], ..., "lod4": [...] }.
-- También deriva la columna geom (LINESTRING) desde lod4 para coherencia
-- geográfica; si esa derivación fallara, no aborta (geom es secundario).

create or replace function public.admin_route_set_polyline(
  p_id uuid,
  p_polyline_lod jsonb
) returns void
language plpgsql security definer set search_path = public as $$
declare v_op uuid;
begin
  select operator_id into v_op from routes where id = p_id;
  if v_op is null then
    raise exception 'Ruta no encontrada';
  end if;
  if not _can_manage_operator(v_op) then
    raise exception 'No autorizado para editar esta ruta';
  end if;

  update routes set
    metadata = coalesce(metadata, '{}'::jsonb)
               || jsonb_build_object('polyline_lod', p_polyline_lod)
  where id = p_id;

  -- geom desde lod4 (cada punto es [lng, lat]). Secundario: try/catch.
  begin
    if p_polyline_lod ? 'lod4'
       and jsonb_array_length(p_polyline_lod->'lod4') >= 2 then
      update routes set geom = (
        select ST_SetSRID(ST_MakeLine(p.pt order by p.ord), 4326)
        from (
          select ST_MakePoint((e->>0)::float8, (e->>1)::float8) as pt, ord
          from jsonb_array_elements(p_polyline_lod->'lod4')
               with ordinality as t(e, ord)
        ) p
      )
      where id = p_id;
    end if;
  exception when others then
    null;
  end;
end;
$$;

grant execute on function public.admin_route_set_polyline(uuid, jsonb)
  to authenticated;
