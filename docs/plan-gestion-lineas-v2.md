# Plan de acción — Gestión de líneas/paradas/zonas/moderación v2

Rama: `feat/comujesa-lineas-horarios-offline`
Decisiones confirmadas: moderación **unificada en una bandeja**, horarios **por parada**, **tabla `zones` nueva** con aprobación, **todo en esta tanda** (fases internas).

---

## FASE 0 — Cimientos de datos (migración 034)

### 0.1 Zonas
- Tabla `zones(id, name, zone_type, parent_zone_id, status, created_by, operator_id?, created_at)`.
  - `status zone_status` = `active | pending` (recomendaciones de comunidad nacen `pending`).
- `routes.zone_id` y `stops.zone_id` (FK nullable a zones).
- Seed: zona `Jerez de la Frontera` (active) y backfill de rutas/paradas existentes a esa zona.
- RPCs SECURITY DEFINER:
  - `zone_upsert(id,name,type,parent,operator_id)` → admin/operator_admin crean/activan.
  - `zone_recommend(name,type)` → cualquiera; inserta `pending` + notifica a staff.
  - `zone_set_status(id,status)` → solo staff (aprobar/rechazar).
  - `list_zones(include_pending bool)` → lectura.

### 0.2 Changelog real
- Tabla `route_changelog(id, route_id, change_type, description, changed_by, created_at)`.
- RPC `log_route_change(route_id, type, description)` (interno).
- Integración: `admin_route_upsert`, `admin_stop_move/add/remove`, `admin_trip_upsert/delete`
  escriben una entrada (p.ej. "Horario actualizado · laborables", "Parada Esteve añadida").
- RPC `list_route_changelog(route_id)`.

### 0.3 Horarios por parada
- Reutilizo `schedules.arrival_offsets` (JSONB, diseñado para esto): cada **expedición** = 1 fila
  `schedules` con `departure_time` (hora 1ª parada) + `arrival_offsets = [{stop_id, "HH:MM"}, ...]`.
- RPCs `admin_trip_upsert(id, route, day_type, direction, stop_times JSONB)` y `admin_trip_delete(id)`,
  `admin_list_trips(route_id)`.

### 0.4 Moderación unificada (sin migrar datos)
- VISTA `moderation_inbox` que normaliza con UNION:
  `route_feedback`, `route_suggestions`, `feature_requests`, `incidents`, `zones(status=pending)`.
  Campos comunes: `source, id, type_label, title, description, status, author_id, operator_id,
  target_route_id, target_stop_id, created_at`.
- RPC `moderation_resolve(source, id, action, award_points int, staff_note text)`:
  - Aplica el estado correcto a la tabla origen (arregla el error Postgres por columnas inexistentes).
  - `action` ∈ `review | accept | reject | apply`.
  - Si `award_points>0` → `add_xp(author, points)` (ya notifica XP).
  - Inserta notificación al autor: "en revisión" / "resuelto/aplicado" / "rechazado".
- RPC `moderation_counts()` para badges.

### 0.5 Códigos de operadora
- `redeem_operator_admin_code(code)` (espejo del de driver) → asigna `role=operator_admin` +
  `profiles.operator_id` + `driver_assignments`. (enum `invitation_kind` ya tiene `operator_admin`.)
- En alta de operadora (admin) y dashboard de operadora: generar códigos `driver` y `operator_admin`.

---

## FASE 1 — Editor de línea (UX)
- **Color**: reemplazar el picker propio por `showColorPickerDialog` de `flex_color_picker`
  (idéntico a `step_basic_info.dart` / Apariencia).
- **Estado**: rediseñar; quitar redundancia (verified/official) → control segmentado con descripción.
- **Zona**: selector de zona (lista + "crear/recomendar zona nueva" inline).
- Reflejar cambios en changelog (Fase 0.2).

## FASE 2 — Gestión de líneas (lista)
- Filtros con **fondo sólido** (estilo `admin_requests` `_statusChip`/searchBar), no transparentes.
- Añadir filtro por **zona** y por **operadora**.

## FASE 3 — Paradas
- **Parada compartida**: `admin_stop_move` ya actualiza la parada global → afecta a todas las líneas.
  Mostrar aviso "la usan N líneas" antes de mover/editar.
- **Menús sólidos**: bottom sheets de 3-puntos y "añadir parada" con fondo opaco (bgElevated).
- **Añadir parada**: buscador + opción "crear parada nueva aquí" inline (escalable).
- **Botón guardar**: acumular reordenado/cambios en local; un solo "Guardar orden" (sin recarga por cambio).
- **Gestión de paradas** (pantalla nueva tipo gestión de líneas): listar, buscar, crear, editar, por
  zona/operadora.

## FASE 4 — Horarios por parada
- Editor nuevo: tabs día/dirección → lista de expediciones; cada expedición edita la hora de paso por
  **cada parada** de la línea. Añadir/duplicar/eliminar expedición; generar por frecuencia opcional.

## FASE 5 — Comunidad: crear ruta al día
- Paridad con el editor admin: **código de línea**, estado, zona (selector/recomendar).
- Revisar campos que falten respecto al editor de admin.

## FASE 6 — Bandeja unificada (moderación + solicitudes + feedback)
- Pantalla única que consume `moderation_inbox` con filtros por **tipo** (mejora parada/línea,
  sugerencia ruta, propuesta zona, alta operador, RGPD, escalado) y por estado.
- Mostrar correctamente la **etiqueta/tipo** que envió el usuario.
- Acciones: en revisión / aceptar / aplicar / rechazar vía `moderation_resolve` (toggle "dar puntos").
- **operator_admin** ve lo de su operadora; **admin** ve todo + escalados.
- Notificaciones automáticas al autor en cada transición.

## FASE 7 — Changelog en detalle de ruta
- `route_detail_changelog` lee de `list_route_changelog` (BD real) en vez de mock.

## FASE 8 — Cierre
- `flutter analyze` limpio en lo tocado, build `--dart-define-from-file`, instalar, commit por fase.

---

### Notas de seguridad
- Toda escritura por RPC `SECURITY DEFINER` con `_can_manage_operator()` o `is_admin()`.
- `moderation_resolve` valida que operator_admin solo toque submissions de su operadora.
