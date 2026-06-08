# Funcionalidades desactivadas / pendientes de retomar

Registro de lo que se ha desactivado o reemplazado temporalmente, para poder
retomarlo más adelante. No borrar sin revisar.

## 2026-06-08

### Búsqueda de rutas (web/app)
- **Estado:** DESACTIVADA (no funcionaba correctamente).
- **Qué se hizo:** se ocultó/inhabilitó la entrada a la búsqueda de rutas.
- **Dónde retomar:** ver pestaña/acción de búsqueda (`/home/buscar`, SearchTab) y
  el sheet `map_search_sheet.dart`. Reactivar cuando la búsqueda devuelva
  resultados fiables (líneas + paradas + comunidad).

### Modo conductor — flujo antiguo
- **Estado:** REEMPLAZADO (HECHO) por un flujo simple: `DriverLiveScreen`
  (`lib/features/driver/driver_live_screen.dart`). El conductor elige línea +
  hora, da su ubicación e inicia; la app publica su posición GPS cada 5 s en
  `driver_live_trips` (Supabase, migración 050) y el mapa la pinta en vivo
  para TODOS (`liveBusesProvider` + Realtime, marcador `_LiveBusMarker`).
- **Acceso:** el FAB de conductor (home_shell) y la ruta `/driver/dashboard`
  abren ahora `DriverLiveScreen`. El bottom sheet `DriverPanel` ya NO se usa.
- **Qué queda desactivado del flujo viejo (sin acceso desde la UI, pero el
  código se conserva):** `DriverDashboardScreen`, `DriverPanel`,
  `StartRouteScreen`, editor de rutas (`/driver/editor/manual|live|post`,
  LiveRouteRecorder, ManualRouteEditor, PostRecordingEditor), historial/stats
  e import IA. Las rutas `/driver/*` siguen en `app_router.dart`.
- **Dónde retomar:** pantallas en `lib/features/driver/` y rutas `/driver/*`.
