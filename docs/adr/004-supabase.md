# ADR-004: Supabase como backend

## Estado
Aceptado

## Contexto
La app necesita:
- Base de datos con API REST (PostgREST)
- Autenticación de usuarios (email, magic link)
- Tiempo real (Realtime para posiciones de buses, incidencias)
- Row-Level Security para multi-tenant
- Edge Functions para lógica serverless (GTFS import, notificaciones)
- Almacenamiento de archivos

## Decisión
Usamos **Supabase** como plataforma backend única.

## Alternativas consideradas

### Firebase
Descartado. Firestore es NoSQL → modelado relacional forzado. Sin RLS declarativo como Supabase (las security rules de Firestore son menos expresivas). Vendor lock-in fuerte.

### Backend propio (Dart/Node)
Descartado. Coste de mantenimiento desproporcionado para TFG/MVP. Supabase ofrece el stack completo con 0 infraestructura.

### Appwrite
Descartado. Menos madurez en Realtime, comunidad más pequeña, sin Edge Functions en el tier gratuito comparable.

## Consecuencias

### Positivas
- PostgREST → API REST autogenerada desde esquema SQL
- RLS default-deny → seguridad a nivel de base de datos
- Realtime (WebSocket) → posiciones de buses, incidencias en vivo
- Edge Functions (Deno/TypeScript) → lógica serverless con cold start bajo
- GoTrue → auth con email, magic link, OAuth (futuro)
- Storage → assets de perfil, GTFS files

### Negativas
- Dependencia externa: si Supabase cae, la app opera en modo offline (Hive cache)
- RLS complejo para queries multi-tenant (solucionado con 13 migraciones)
- `supabase_flutter` 2.x → dependencia pesada (~3MB en APK)
- Sin soporte nativo para `OFFLINE` en Realtime (solucionado con cola offline propia)

### Esquema
- 16 migraciones SQL en `supabase/migrations/` (12 números únicos: 001–007, 012–016; con duplicados de nomenclatura en 007, 014, 015)
- Proyecto: `mmzahxtiaurkgtmtehxk`
- `.env` excluido del repo; variables vía `--dart-define`

## Referencias
- `supabase/migrations/` — 16 migraciones
- `lib/data/<entity>/` — 12 repositorios (abstract, remote, local, mock, provider)
- `docs/SCALABILITY.md §B` — RLS y políticas
- Realtime activo en 5/12 repos: `bus_location`, `stop`, `route`, `incident`, `route_feedback` vía `RealtimeChannelManager` compartido
- Los 7 repos restantes (`route_suggestion`, `feature_request`, `operator`, `schedule`, `user_preferences`, `offline_region`, `notification`) usan snapshot sin suscripción WebSocket
