# Plan v14 — Sistema completo de rutas creadas por usuarios

**Fecha:** 2026-06-01
**Autor:** Claude Code (Opus 4.7)
**Plan anterior:** `PLAN_REPARACION_2026_05_31_V13.md`

---

## TL;DR

Sistema "Spotify de rutas de transporte" — cualquier usuario crea sus propias rutas con paradas y horarios, las comparte mediante búsqueda pública, código corto o link, y puede sugerirlas para promoción a "comunitaria" si pasa moderación admin. Diseñado para escalar a nivel nacional con multi-operador, gamificación por reputación, y paradas no convencionales (moteles, gasolineras, etc.).

## Decisiones tomadas contigo

- **Paradas**: el usuario crea sus propias paradas en cualquier punto (incluyendo moteles, gasolineras, estaciones de servicio para rutas largas inter-ciudad) y opcionalmente las sugiere para registro oficial.
- **Compartir**: buscador público global + código corto + enlace.
- **Límites por reputación** (gamificación): nivel 0 → 1 ruta, nivel 1 → 3, nivel 2 → 10, nivel 3 → 30, nivel 4 → 100.

---

## Arquitectura propuesta

```
┌─────────────────────────────────────────────────┐
│  USUARIO CREA RUTA                              │
│  ├─ Nombre / color / tipo (urbano/larga dist.)  │
│  ├─ Paradas (oficiales + custom)                │
│  ├─ Horarios por día (lun/vie/sáb/dom/festivo)  │
│  ├─ Visibility: public / unlisted / private     │
│  └─ Opcional: enviar a admin para comunidad     │
└─────────────────────────────────────────────────┘
                    │
        ┌───────────┼───────────┐
        ▼           ▼           ▼
   ┌─────────┐ ┌─────────┐ ┌──────────┐
   │ Público │ │ Código  │ │ Privado  │
   │ buscador│ │ A3F9K2  │ │ owner    │
   │ global  │ │ + link  │ │ only     │
   └─────────┘ └─────────┘ └──────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │ ADMIN PANEL           │
        │ ├─ Cola review rutas  │
        │ ├─ Cola paradas       │
        │ ├─ Aprobar → comunidad│
        │ └─ Rechazar + nota    │
        └───────────────────────┘
```

---

## Esquema de base de datos

### Migraciones nuevas en Supabase

```sql
-- 1) USER ROUTES (rutas creadas por usuarios)
CREATE TABLE user_routes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL CHECK (char_length(name) BETWEEN 3 AND 80),
  description TEXT CHECK (char_length(description) <= 500),
  route_color TEXT NOT NULL DEFAULT '#977DDF',
  service_type TEXT NOT NULL CHECK (service_type IN (
    'urban', 'interurban', 'long_distance', 'school', 'on_demand', 'custom'
  )),
  visibility TEXT NOT NULL DEFAULT 'private' CHECK (visibility IN (
    'public',     -- buscador público global
    'unlisted',   -- solo accesible vía código/link
    'private'     -- solo el autor
  )),
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN (
    'draft',              -- en edición
    'published',          -- visible según visibility
    'review_pending',     -- enviada al admin para comunidad
    'community_approved', -- promovida a comunidad
    'rejected',           -- admin rechazó
    'reported'            -- usuarios la reportaron, en review
  )),
  share_code TEXT UNIQUE,            -- 6 chars [A-Z2-9] excluyendo 0,O,1,I,L
  public_slug TEXT UNIQUE,           -- nano-id 12 chars
  total_distance_km NUMERIC(7,2),
  total_duration_min INT,
  view_count INT NOT NULL DEFAULT 0,
  vote_count INT NOT NULL DEFAULT 0,
  report_count INT NOT NULL DEFAULT 0,
  -- Geo bbox para spatial index (escalabilidad nacional)
  bbox_geom GEOMETRY(POLYGON, 4326),
  -- Multi-operador / multi-país
  country_code CHAR(2) DEFAULT 'ES',
  region TEXT,
  reviewed_by UUID REFERENCES auth.users(id),
  reviewed_at TIMESTAMPTZ,
  admin_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  published_at TIMESTAMPTZ
);
CREATE INDEX user_routes_author_idx ON user_routes(author_id);
CREATE INDEX user_routes_visibility_status_idx
  ON user_routes(visibility, status) WHERE status = 'published';
CREATE INDEX user_routes_bbox_gix ON user_routes USING GIST(bbox_geom);
CREATE INDEX user_routes_share_code_idx ON user_routes(share_code);
CREATE INDEX user_routes_public_slug_idx ON user_routes(public_slug);
-- Full-text search en español
ALTER TABLE user_routes ADD COLUMN search_vector TSVECTOR
  GENERATED ALWAYS AS (
    to_tsvector('spanish', coalesce(name, '') || ' ' || coalesce(description, ''))
  ) STORED;
CREATE INDEX user_routes_search_idx ON user_routes USING GIN(search_vector);

-- 2) USER STOPS (paradas custom no oficiales)
CREATE TABLE user_stops (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  official_stop_id UUID REFERENCES stops(id), -- null si es custom
  name TEXT NOT NULL CHECK (char_length(name) BETWEEN 2 AND 80),
  lat DOUBLE PRECISION NOT NULL,
  lng DOUBLE PRECISION NOT NULL,
  geom GEOMETRY(POINT, 4326) GENERATED ALWAYS AS (
    ST_SetSRID(ST_MakePoint(lng, lat), 4326)
  ) STORED,
  stop_type TEXT NOT NULL DEFAULT 'custom' CHECK (stop_type IN (
    'official',       -- = official_stop_id
    'urban_custom',   -- parada urbana inventada
    'hotel',          -- hotel (rutas larga distancia)
    'motel',          -- motel
    'gas_station',    -- gasolinera
    'rest_area',      -- área de servicio
    'beach',          -- playa
    'airport',        -- aeropuerto
    'train_station',  -- estación de tren
    'ferry',          -- puerto
    'landmark',       -- monumento / referencia
    'custom'          -- otro
  )),
  description TEXT,
  promotion_status TEXT DEFAULT 'none' CHECK (promotion_status IN (
    'none', 'requested', 'approved', 'rejected'
  )),
  promoted_to_official_at TIMESTAMPTZ,
  reviewed_by UUID REFERENCES auth.users(id),
  admin_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX user_stops_author_idx ON user_stops(author_id);
CREATE INDEX user_stops_geom_gix ON user_stops USING GIST(geom);
CREATE INDEX user_stops_promotion_idx ON user_stops(promotion_status)
  WHERE promotion_status = 'requested';

-- 3) USER ROUTE STOPS (pivote: paradas que componen una ruta)
CREATE TABLE user_route_stops (
  route_id UUID NOT NULL REFERENCES user_routes(id) ON DELETE CASCADE,
  user_stop_id UUID NOT NULL REFERENCES user_stops(id) ON DELETE CASCADE,
  order_index SMALLINT NOT NULL CHECK (order_index >= 0),
  -- Tiempo estimado entre esta parada y la siguiente (minutos)
  duration_to_next_min INT,
  -- Distancia hasta la siguiente parada
  distance_to_next_km NUMERIC(6,2),
  PRIMARY KEY (route_id, order_index)
);
CREATE INDEX user_route_stops_route_idx ON user_route_stops(route_id);
CREATE INDEX user_route_stops_stop_idx ON user_route_stops(user_stop_id);

-- 4) USER ROUTE SCHEDULES (horarios por día)
CREATE TABLE user_route_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  route_id UUID NOT NULL REFERENCES user_routes(id) ON DELETE CASCADE,
  day_type TEXT NOT NULL CHECK (day_type IN (
    'weekday', 'saturday', 'sunday', 'holiday',
    'summer', 'winter', 'every_day'
  )),
  departure_time TIME NOT NULL,
  -- Opcional: parada concreta desde la que sale (si null, primera parada)
  origin_stop_id UUID REFERENCES user_stops(id),
  notes TEXT
);
CREATE INDEX user_route_schedules_route_idx ON user_route_schedules(route_id);

-- 5) USER ROUTE VOTES (likes/votos para popularidad)
CREATE TABLE user_route_votes (
  route_id UUID NOT NULL REFERENCES user_routes(id) ON DELETE CASCADE,
  voter_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  voted_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (route_id, voter_id)
);

-- 6) USER ROUTE REPORTS (reportes de rutas problemáticas)
CREATE TABLE user_route_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  route_id UUID NOT NULL REFERENCES user_routes(id) ON DELETE CASCADE,
  reporter_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reason TEXT NOT NULL CHECK (reason IN (
    'spam', 'inappropriate', 'wrong_data', 'duplicated', 'other'
  )),
  description TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'dismissed')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7) USER ROUTE VIEWS (analytics)
CREATE TABLE user_route_views (
  id BIGSERIAL PRIMARY KEY,
  route_id UUID NOT NULL REFERENCES user_routes(id) ON DELETE CASCADE,
  viewer_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  viewed_at TIMESTAMPTZ DEFAULT NOW(),
  via_share_code BOOLEAN DEFAULT FALSE,
  via_public_link BOOLEAN DEFAULT FALSE
);
CREATE INDEX user_route_views_route_date_idx ON user_route_views(route_id, viewed_at DESC);

-- 8) Profile reputation (extender profiles existente)
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS
  reputation_level SMALLINT NOT NULL DEFAULT 0 CHECK (reputation_level BETWEEN 0 AND 4);
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS
  reputation_xp INT NOT NULL DEFAULT 0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS
  routes_created_count INT NOT NULL DEFAULT 0;
```

### Funciones SQL para enforcement y XP

```sql
-- Función que devuelve el cupo de rutas según nivel
CREATE OR REPLACE FUNCTION user_routes_quota(p_user_id UUID) RETURNS INT AS $$
  SELECT CASE reputation_level
    WHEN 0 THEN 1
    WHEN 1 THEN 3
    WHEN 2 THEN 10
    WHEN 3 THEN 30
    WHEN 4 THEN 100
    ELSE 1
  END FROM profiles WHERE id = p_user_id;
$$ LANGUAGE SQL STABLE;

-- Trigger BEFORE INSERT en user_routes para verificar cupo
CREATE OR REPLACE FUNCTION check_user_routes_quota() RETURNS TRIGGER AS $$
DECLARE
  current_count INT;
  quota INT;
BEGIN
  SELECT routes_created_count INTO current_count FROM profiles WHERE id = NEW.author_id;
  SELECT user_routes_quota(NEW.author_id) INTO quota;
  IF current_count >= quota THEN
    RAISE EXCEPTION 'route quota exceeded: % >= % (nivel %). Sube de nivel para crear más.',
      current_count, quota, (SELECT reputation_level FROM profiles WHERE id = NEW.author_id);
  END IF;
  -- Generar share_code y public_slug si están vacíos
  IF NEW.share_code IS NULL THEN
    NEW.share_code := generate_share_code();
  END IF;
  IF NEW.public_slug IS NULL THEN
    NEW.public_slug := generate_public_slug();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER user_routes_quota_check
  BEFORE INSERT ON user_routes
  FOR EACH ROW EXECUTE FUNCTION check_user_routes_quota();

-- Generadores de códigos
CREATE OR REPLACE FUNCTION generate_share_code() RETURNS TEXT AS $$
DECLARE
  alphabet TEXT := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789'; -- sin O,0,I,1,L
  code TEXT;
  attempts INT := 0;
BEGIN
  LOOP
    code := '';
    FOR i IN 1..6 LOOP
      code := code || substr(alphabet, (random() * 30)::int + 1, 1);
    END LOOP;
    EXIT WHEN NOT EXISTS (SELECT 1 FROM user_routes WHERE share_code = code);
    attempts := attempts + 1;
    IF attempts > 50 THEN
      RAISE EXCEPTION 'unable to generate share code';
    END IF;
  END LOOP;
  RETURN code;
END;
$$ LANGUAGE plpgsql VOLATILE;

CREATE OR REPLACE FUNCTION generate_public_slug() RETURNS TEXT AS $$
  SELECT encode(gen_random_bytes(9), 'base64')
    || ''
$$ LANGUAGE SQL VOLATILE;

-- Trigger AFTER INSERT que sube routes_created_count
CREATE OR REPLACE FUNCTION inc_routes_created_count() RETURNS TRIGGER AS $$
BEGIN
  UPDATE profiles SET routes_created_count = routes_created_count + 1
    WHERE id = NEW.author_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER user_routes_count_inc
  AFTER INSERT ON user_routes
  FOR EACH ROW EXECUTE FUNCTION inc_routes_created_count();

-- XP por acciones
-- crear ruta publicada: +10
-- ruta aprobada comunidad: +50
-- recibir voto: +1
-- promover parada oficial: +20
CREATE OR REPLACE FUNCTION add_xp(p_user_id UUID, p_xp INT) RETURNS VOID AS $$
DECLARE
  new_xp INT;
  new_level INT;
BEGIN
  UPDATE profiles SET reputation_xp = reputation_xp + p_xp
    WHERE id = p_user_id
    RETURNING reputation_xp INTO new_xp;
  new_level := CASE
    WHEN new_xp >= 5000 THEN 4
    WHEN new_xp >= 1000 THEN 3
    WHEN new_xp >= 200 THEN 2
    WHEN new_xp >= 50 THEN 1
    ELSE 0
  END;
  UPDATE profiles SET reputation_level = new_level WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql;
```

### RLS Policies

```sql
ALTER TABLE user_routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_stops ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_route_stops ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_route_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_route_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_route_reports ENABLE ROW LEVEL SECURITY;

-- USER ROUTES
CREATE POLICY "Owner sees own routes" ON user_routes
  FOR SELECT USING (auth.uid() = author_id);
CREATE POLICY "Public routes visible to all authenticated" ON user_routes
  FOR SELECT USING (
    visibility = 'public' AND status IN ('published', 'community_approved')
  );
CREATE POLICY "Unlisted routes visible by share_code/slug" ON user_routes
  FOR SELECT USING (
    visibility = 'unlisted' AND status = 'published'
    -- enforcement adicional vía Edge Function que valida el código
  );
CREATE POLICY "Admin sees all routes" ON user_routes
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );
CREATE POLICY "Owner inserts" ON user_routes
  FOR INSERT WITH CHECK (auth.uid() = author_id);
CREATE POLICY "Owner updates own" ON user_routes
  FOR UPDATE USING (auth.uid() = author_id);
CREATE POLICY "Admin reviews" ON user_routes
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );
CREATE POLICY "Owner deletes own" ON user_routes
  FOR DELETE USING (auth.uid() = author_id);

-- USER STOPS (similar, permisos más laxos para lectura porque las paradas
-- se ven en cualquier ruta donde aparezcan)
CREATE POLICY "Stops visible if in any visible route" ON user_stops
  FOR SELECT USING (
    auth.uid() = author_id OR
    EXISTS (
      SELECT 1 FROM user_route_stops urs
      JOIN user_routes ur ON ur.id = urs.route_id
      WHERE urs.user_stop_id = user_stops.id
      AND (ur.visibility = 'public' OR ur.author_id = auth.uid())
    )
  );
-- Resto similar
```

---

## Pantallas Flutter (UI)

### Wizard "Crear ruta"

`lib/features/create_route/create_route_wizard.dart`

5 pasos con `Stepper` o `PageView`:

1. **Info básica**
   - TextField "Nombre" (3-80 chars, autovalidate)
   - TextArea "Descripción" (opcional, 500 chars)
   - Selector de color (rueda de colores con preview de badge)
   - Dropdown "Tipo de servicio" (urbano / interurbano / larga distancia / escolar / a demanda / custom)

2. **Paradas**
   - Botón "Añadir parada" → modal con tabs:
     - **Oficial**: buscador autocomplete sobre `stops` actuales
     - **Crear nueva**: nombre + lat/lng (map picker) + tipo (motel/gasolinera/...) + descripción opcional
   - Reorderable list de paradas añadidas, drag-to-sort
   - Botón eliminar parada
   - Cada parada custom muestra badge "Sugerir como oficial" → marca `promotion_status = requested`

3. **Horarios**
   - Botón "+ Añadir salida" → modal:
     - Hora (TimePicker)
     - Día (chips: L-V / Sáb / Dom / Festivo / Verano / Invierno / Todos)
   - Lista de salidas agrupadas por día_type
   - Botón "Generar frecuencia" (modal para cada-N-minutos en rango)

4. **Visibilidad**
   - Radio buttons:
     - 🌍 **Pública** (aparece en buscador global)
     - 🔗 **Solo con código/enlace** (oculta del buscador)
     - 🔒 **Privada** (solo tú la ves)

5. **Resumen y sugerencia**
   - Preview de la ruta en miniMapa con polyline
   - Estadísticas: X paradas · Y km · Z minutos
   - Checkbox "Quiero proponerla como ruta comunitaria oficial" → cambia status a `review_pending`
   - Botón **PUBLICAR** (o "Guardar borrador")

### Pantalla "Mis rutas"

`lib/features/my_routes/my_routes_screen.dart`

- Lista de rutas creadas con cards: badge color, nombre, paradas count, visibility icon, status badge
- Stats card arriba: "X rutas · Y visitas · Nivel Z (XP/required)"
- Botón flotante "+" para abrir wizard
- Pull to refresh

### Pantalla "Comunidad" (buscador público)

`lib/features/community/community_routes_screen.dart`

- Buscador con full-text search (debounce 300ms)
- Filtros: tipo servicio / municipio / orden (populares / recientes / cercanas)
- Lista paginada (20 por página)
- Cards con preview: nombre + autor + paradas + votos + visitas
- Tap → pantalla detalle

### Pantalla "Detalle ruta de usuario"

`lib/features/route_detail/user_route_detail_screen.dart`

- Header con color de la ruta + nombre + autor avatar
- Stats: votos / visitas / paradas / km / minutos
- Mapa con polyline + paradas marcadas
- Lista de horarios
- Botones:
  - 👍 **Votar** (toggle)
  - 📤 **Compartir** → modal con código + link + WhatsApp/Email + QR
  - ⭐ **Favorito**
  - 🚩 **Reportar** (modal con motivo)

### Pantalla "Compartir ruta"

Modal `lib/features/share/share_route_modal.dart`:

```
┌─────────────────────────┐
│   Compartir "Mi ruta X" │
├─────────────────────────┤
│  Código: A3F9K2         │
│  [📋 Copiar]            │
│                         │
│  Link público:          │
│  transitly.app/r/xxx... │
│  [📋 Copiar]            │
│                         │
│  [QR Code]              │
│                         │
│  Enviar por:            │
│  [WhatsApp] [Email]     │
└─────────────────────────┘
```

### Panel admin

`lib/features/admin/route_moderation_screen.dart`

- Tab "Rutas pendientes" — lista filtrada `WHERE status = 'review_pending'`
- Tab "Paradas pendientes" — lista filtrada `WHERE promotion_status = 'requested'`
- Por cada ítem: preview + datos + botones **Aprobar** / **Rechazar (con motivo)**

---

## Estructura

```
WAVE 1 — Backend Supabase (1 agente)
└── A1  Migraciones SQL completas + triggers + RLS + funciones XP

WAVE 2 — Repos Flutter (3 agentes paralelos)
├── A2  user_routes_repository.dart + provider
├── A3  user_stops_repository.dart + provider
└── A4  user_route_schedules_repository.dart + reputation_provider

WAVE 3 — UI Crear/Editar (3 agentes paralelos)
├── A5  Wizard crear ruta (5 pasos)
├── A6  Mapa picker para parada custom
└── A7  Selector de horarios

WAVE 4 — UI Consumir/Compartir (3 agentes paralelos)
├── A8  Buscador comunidad + lista pública
├── A9  Detalle ruta usuario + voto + reportar
└── A10 Modal compartir (código + link + QR + WhatsApp)

WAVE 5 — Admin (1 agente)
└── A11 Panel moderación rutas + paradas

WAVE 6 — Integración (coordinador)
└── Routing /community, /my-routes, /create-route, /r/:slug
    flutter clean + build + install
```

### Archivos NUEVOS

```
lib/data/user_routes/
  user_routes_repository.dart
  user_route_models.dart
lib/data/user_stops/
  user_stops_repository.dart
  user_stop_models.dart
lib/data/reputation/
  reputation_repository.dart

lib/shared/providers/
  user_routes_provider.dart
  user_stops_provider.dart
  reputation_provider.dart
  community_routes_provider.dart

lib/features/create_route/
  create_route_wizard.dart
  steps/
    step_basic_info.dart
    step_stops.dart
    step_schedules.dart
    step_visibility.dart
    step_summary.dart
  widgets/
    stop_picker_modal.dart
    schedule_editor.dart

lib/features/my_routes/
  my_routes_screen.dart
  my_route_card.dart

lib/features/community/
  community_routes_screen.dart
  community_route_card.dart
  community_filters.dart

lib/features/route_detail/
  user_route_detail_screen.dart
  user_route_share_modal.dart
  user_route_report_modal.dart

lib/features/admin/
  route_moderation_screen.dart
  stop_promotion_screen.dart
```

---

## WAVE 1 — Brief

### A1 — Backend Supabase completo

```text
ROL: Engineer Supabase + Postgres senior.

TAREAS:

T1. Aplicar migración con TODAS las tablas, funciones, triggers, RLS.
   (Ver SQL en sección "Esquema de base de datos" del plan.)

T2. Verificar que las extensiones postgis, pg_cron, pg_net están
   habilitadas (postgis sí, las otras se habilitaron en v13).

T3. Crear Edge Function `validate_share_code` que valida un código:
   ```typescript
   serve(async (req) => {
     const { code } = await req.json();
     const { data, error } = await supabase
       .from('user_routes')
       .select('id, name, public_slug')
       .eq('share_code', code.toUpperCase())
       .eq('status', 'published')
       .single();
     if (error || !data) return new Response('Not found', { status: 404 });
     // Log view
     await supabase.from('user_route_views').insert({
       route_id: data.id,
       viewer_id: (await auth())?.user?.id,
       via_share_code: true,
     });
     return new Response(JSON.stringify(data));
   });
   ```

T4. Edge Function `promote_stop_to_official` (admin only):
   - Verifica que el caller es admin
   - Inserta en `stops` con los datos de la `user_stops`
   - Marca `promoted_to_official_at = now()`
   - Asigna XP +20 al author de la user_stop

T5. Edge Function `approve_user_route_to_community` (admin only):
   - Cambia `status = 'community_approved'`
   - Asigna XP +50 al author
   - Opcional: copia a la tabla `routes` oficial

VERIFICACIÓN:
- Smoke: insertar ruta con auth.uid() → triggers asignan share_code + slug.
- Cuotas: usuario nivel 0 puede crear 1, al insertar la 2da → error.
```

---

## Roadmap de implementación

| Sprint | Items | Estimación |
|--------|-------|------------|
| **Sprint 1** | Backend SQL + repos Flutter + provider básico | 2 días |
| **Sprint 2** | Wizard crear ruta + mapa picker | 3 días |
| **Sprint 3** | UI mis rutas + detalle + compartir | 2 días |
| **Sprint 4** | Buscador comunidad + filtros + paginación | 2 días |
| **Sprint 5** | Panel admin + flujo moderación | 1 día |
| **Sprint 6** | Pulido + tests + a11y + i18n (es/en/ar) | 2 días |

**Total: ~12 días de desarrollo**.

---

## Notas de escalabilidad nacional

- **Multi-operador**: la columna `country_code` y `region` permiten particionar por país. `routes` oficiales también tienen `operator_id`. Para Andalucía, Madrid, Cataluña, etc. se pueden tener operators separados.
- **Spatial index**: `bbox_geom` con GIST → búsquedas geográficas en milisegundos incluso con millones de rutas.
- **Full-text search**: índice GIN sobre `search_vector` permite buscar por palabras parciales en español.
- **Particionamiento futuro** (cuando >100k rutas): partición de `user_route_views` por mes (`PARTITION BY RANGE (viewed_at)`).
- **Rate limiting**: en cada Edge Function que cree datos, verificar X requests por minuto por user_id (con Redis o pg_net).
- **CDN para tiles**: ya hay FMTC. Para rutas comunitarias populares se podrían pre-renderizar previews en S3.

---

## Fix al margen — Vault para el cron de borrado de cuenta

El error `42501: permission denied to set parameter "app.settings.service_role_key"` se ha resuelto cambiando el cron para que use **Supabase Vault** en lugar de `ALTER DATABASE`.

**Lo que tienes que hacer en Supabase Dashboard** (una sola vez):

1. Ve a **Supabase Dashboard → Settings → API**
2. Copia la clave de **`service_role` secret** (NO la `anon`)
3. Ve a **Supabase Dashboard → Project Settings → Vault** (o **Database → Vault**)
4. Busca el secret llamado **`service_role_key`**
5. Edita su valor y reemplaza el placeholder `PLACEHOLDER_REPLACE_ME` por la clave real
6. Guarda

Una vez hecho, el cron diario funcionará automáticamente.
