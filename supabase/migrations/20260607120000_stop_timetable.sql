-- RPC: horario completo de paso por una parada (todas las líneas con
-- arrival_offsets cargados), agrupable por línea y tipo de día en cliente.
-- Devuelve una fila por (línea, día, hora de paso). RLS de schedules/routes
-- ya restringe a rutas visibles (oficiales públicas).
create or replace function public.stop_timetable(p_stop_id uuid)
returns table(
  route_id uuid,
  route_code text,
  route_color text,
  day_type text,
  pass_time text
)
language sql
stable
as $$
  select r.id,
         r.code,
         r.color,
         s.day_type::text,
         (e->>'t') as pass_time
  from schedules s
  join routes r on r.id = s.route_id
  cross join lateral jsonb_array_elements(coalesce(s.arrival_offsets, '[]'::jsonb)) e
  where e->>'s' = p_stop_id::text
  order by r.code, s.day_type, (e->>'t');
$$;

grant execute on function public.stop_timetable(uuid) to anon, authenticated;

-- Variante por NOMBRE de parada: la app (modo mock) usa ids del JSON, pero el
-- seed y el JSON salen de la misma fuente, así que el nombre casa 1:1. Único
-- operador (COMUJESA) por ahora; añadir operador si se vuelve multi-operador.
create or replace function public.stop_timetable_by_name(p_name text)
returns table(
  route_id uuid,
  route_code text,
  route_color text,
  day_type text,
  pass_time text
)
language sql
stable
as $$
  with sids as (
    select id::text as sid from stops where name = p_name
  )
  select r.id,
         r.code,
         r.color,
         s.day_type::text,
         (e->>'t') as pass_time
  from schedules s
  join routes r on r.id = s.route_id
  cross join lateral jsonb_array_elements(coalesce(s.arrival_offsets, '[]'::jsonb)) e
  where e->>'s' in (select sid from sids)
  order by r.code, s.day_type, (e->>'t');
$$;

grant execute on function public.stop_timetable_by_name(text) to anon, authenticated;
