# Plan de fixes post-MVP — 2026-05-25 (v2)

**Contexto**: tras la release `v1.0.0-mvp` (commit `f44c0b2`), la app arranca
correctamente. Este plan v2 incorpora una decisión clave del producto que
cambia el marco mental de varios fixes:

> **La app debe comportarse como app de producción real, no como demo.
> Usuarios anónimos tienen acceso completo a navegación, mapa, rutas, paradas
> y tiempos. Lo único que pierden sin registrarse es la persistencia en la
> nube de datos personales (favoritas se guardan en caché local, contribuciones
> y comunidad requieren cuenta).**

Esto significa:
- ❌ Nada de badges "DEMO" en la UI
- ❌ Nada de ocultar features pre-login (excepto las que de verdad requieren cuenta)
- ✅ Favoritas, preferencias, ajustes → caché local (Hive ya existe)
- ✅ Contribuciones, votos, comentarios, sincronía → requieren login con snackbar/CTA claro
- ✅ Tiempos de buses visibles para todos, lo más realistas posible (no random absurdo)

---

## Métricas de éxito (revisadas)

Para considerar la app "presentable como producto":

- [ ] Cero crashes en flujos principales
- [ ] Botón "atrás" funcional
- [ ] App utilizable sin registro: navegar mapa, ver rutas, paradas, tiempos
- [ ] Modo invitado puede guardar favoritas (en local), no se pierden al cerrar app
- [ ] Acciones que requieren cuenta → CTA claro, no error genérico
- [ ] Login + signup + recover password verificados
- [ ] Modo claro afecta a TODA la UI
- [ ] Mapa con ubicación del usuario en tiempo real
- [ ] Búsqueda funcional (sitios + rutas + paradas)
- [ ] Logo y branding correctos en ambos modos
- [ ] Animación de bienvenida simple pero pulida

---

## Decisiones del producto (Q&A con usuario)

1. **Menú accesibilidad va mal** → es la pantalla `accessible_buses_screen.dart` con overflow en la lista. **Mismo bug que F2.1.**
2. **"Zonas" no deja cambiar** → es el `city_picker_screen.dart` (la "zona principal" del usuario = `UserModel.primaryZoneId`). No persiste el cambio.
3. **Tiempos de buses** → **mantenerlos visibles para todos, sin badges DEMO**. App es producto real, los tiempos vienen de `MockRealtimeService` pero deben mejorarse para ser realistas (ver F4.3).
4. **Búsqueda en mapa** → implementación COMPLETA: autocomplete unificado que busca sitios (POIs), rutas (líneas) y paradas.
5. **Animación bienvenida** → simple pero bonita, usar `logoblanco.png` (ya disponible en Downloads).

---

## Bugs detallados

### F1 · Bloqueantes (crashes / flujos rotos)

#### F1.1 — Al entrar en perfil da error
- **Síntoma**: tap en tab perfil → pantalla de error o crash
- **Hipótesis**: tras el último commit, `ProfileHeaderCard` ya gestiona authUser==null
  correctamente. Pero algún otro widget del tab puede leer `currentUserProvider` y
  asumir sesión. Más probable: `ProfileLocationSection`, `ProfileNotificationsSection`,
  `ProfileAccessibilitySection`.
- **Diagnóstico necesario**:
  1. Abrir la app sin login y tap en perfil
  2. Capturar logcat completo (`adb logcat -d > log.txt`)
  3. Identificar el primer stack trace tras el tap
- **Archivos sospechosos**:
  - `lib/features/home/widgets/profile_location_section.dart`
  - `lib/features/home/widgets/profile_notifications_section.dart`
  - `lib/features/home/widgets/profile_accessibility_section.dart`
- **Estrategia de fix**: mismo patrón que ProfileHeaderCard — cada widget chequea
  `isAuthenticated`, si no muestra placeholder/CTA o variante invitado.
- **Verificación**: cold start sin login → tab perfil → no error
- **Esfuerzo**: M (30-60 min)
- **Severidad**: 🔴 P0

#### F1.2 — Botón "atrás" cierra la app
- **Síntoma**: pulsar back en cualquier pantalla cierra la app
- **Hipótesis**: GoRouter shell no tiene `PopScope`. Back desde tab principal
  intenta pop la ruta raíz → cierra app.
- **Archivos**: `lib/core/router/app_router.dart`, `lib/features/home/home_shell.dart`
- **Estrategia**:
  1. Envolver el shell en `PopScope(canPop: false, onPopInvoked: ...)`
  2. Si `navigationShell.currentIndex != 0` → ir al tab inicio
  3. Si estás en inicio → `SnackBar("Pulsa de nuevo para salir")`, segundo back → `SystemNavigator.pop()`
- **Verificación**: navegar mapa → back → vuelve a inicio; back en inicio → snackbar; back de nuevo → cierra
- **Esfuerzo**: M (30-45 min)
- **Severidad**: 🔴 P0

#### F1.3 — Botón notificaciones se queda cargando infinito
- **Síntoma**: tap en campana → spinner indefinido
- **Hipótesis**: `notificationStreamProvider` query Supabase sin gate de auth. Sin
  sesión, 401 silencioso, stream nunca emite.
- **Archivos**:
  - `lib/shared/providers/notification_stream_provider.dart`
  - `lib/features/notifications/notifications_screen.dart`
- **Estrategia**:
  1. Gate de auth en el provider. Sin sesión → emitir lista vacía + flag "needsAuth"
  2. Screen muestra empty state distinto según flag:
     - needsAuth=true → "Inicia sesión para ver notificaciones" + CTA
     - needsAuth=false (logged, sin notifs) → "No tienes notificaciones nuevas"
  3. Timeout 10s al stream → fallback empty state
- **Verificación**: tap en campana sin login → empty state inmediato con CTA
- **Esfuerzo**: M (30-60 min)
- **Severidad**: 🔴 P0

#### F1.4 — Personalizar apariencia: fondo queda en negro
- **Síntoma**: cambiar fondo (smoke/gradient/etc.) en /appearance → pantalla negra
- **Hipótesis**: `themeNotifier.backgroundId` cambia y persiste, pero `BackgroundWrapper`
  no rebuilds (provider listener mal conectado) o `backgroundFromId(id)` devuelve null.
- **Archivos**:
  - `lib/shared/widgets/background_wrapper.dart`
  - `lib/core/theme/backgrounds/app_background.dart`
  - `lib/core/theme/backgrounds/prefab_backgrounds.dart`
  - `lib/features/appearance/widgets/background_section.dart`
- **Diagnóstico**:
  1. Print del `backgroundId` actual al cambiar
  2. Verificar que `backgroundFromId(id)` no devuelve null
  3. Verificar que BackgroundWrapper escucha `themeNotifierProvider`
- **Estrategia de fix**: normalmente añadir `ref.watch(themeNotifierProvider)` en
  el builder de BackgroundWrapper para que rebuilds.
- **Verificación**: /appearance, cambiar fondo, ver que se actualiza al instante
- **Esfuerzo**: M (45-60 min)
- **Severidad**: 🔴 P0

---

### F2 · Layout & overflows

#### F2.1 + F2.5 — Pantalla `accessible_buses_screen` con overflow / texto vertical
- **Síntoma unificado**:
  - "ver lista de buses se ve todo el texto salido de la pantalla y vertical"
  - "el menú de accesibilidad va muy mal" → tras aclaración del usuario, también es esta pantalla
- **Hipótesis**: la lista de buses accesibles tiene un Row con número de línea, dirección,
  estado y tiempo. Sin Expanded/Wrap → al no caber, el texto colapsa vertical.
- **Archivos**:
  - `lib/features/accessible_buses/accessible_buses_screen.dart`
  - Quizás widgets de chip/badge dentro
- **Estrategia**:
  1. Auditar el item de la lista (probablemente `ListView.builder` → `Card` → `Row`)
  2. Cada Text envuelto en `Expanded` o el Row entero en `Wrap`
  3. `overflow: TextOverflow.ellipsis, maxLines: 1` donde corresponda
  4. Si hay muchos chips, usar `Wrap` con `spacing: 8, runSpacing: 4`
- **Verificación**: abrir pantalla, todos los textos legibles, sin overflow visible
- **Esfuerzo**: M (45 min)
- **Severidad**: 🟠 P1

#### F2.2 — "Buses cercanos": texto mal + sin dirección
- **Síntoma**: el widget de buses cercanos tiene texto mal formado + no muestra
  hacia dónde va cada línea
- **Hipótesis**:
  1. Layout: overflow similar a F2.1
  2. Falta de dato: `RouteModel` puede no tener `headsign` o no se está mostrando
- **Archivos**:
  - `lib/features/bus_estimation/` o widgets de "nearby" en home
  - `lib/shared/models/route_model.dart`
  - `assets/mock/comujesa_data.json`
- **Estrategia**:
  1. Localizar widget exacto
  2. Verificar campos disponibles en RouteModel
  3. Si falta headsign/direction, añadirlo al modelo y al JSON mock (ej: "Centro → Norte", "Sur → Centro")
  4. Layout fix
- **Verificación**: lista de buses cercanos legible, cada item: `[Línea] · [Destino] · [tiempo]`
- **Esfuerzo**: M (60 min)
- **Severidad**: 🟠 P1

#### F2.3 — Smoke background del feedback cortado abajo
- **Síntoma**: en pantalla de feedback, smoke no llega al borde inferior
- **Archivos**: `lib/features/feedback/`
- **Estrategia**: `Scaffold(extendBody: true)` + `Stack` con `Positioned.fill(child: SmokeBackground(...))`
- **Verificación**: scroll abajo en feedback, smoke continúa hasta el bottom
- **Esfuerzo**: S (15 min)
- **Severidad**: 🟡 P2

#### F2.4 — "Datos offline": texto operador se corta
- **Síntoma**: nombre del operador se corta en la pantalla de datos offline
- **Archivos**: `lib/features/profile/offline_data_screen.dart`
- **Estrategia**: `Expanded(child: Text(name, overflow: TextOverflow.ellipsis, maxLines: 1))`
- **Esfuerzo**: S (10 min)
- **Severidad**: 🟡 P2

#### F2.6 — "Zona principal" no se puede cambiar
- **Síntoma**: no deja cambiar la zona principal (city picker)
- **Hipótesis**: existe `lib/features/city_picker/city_picker_screen.dart` y
  `UserModel.primaryZoneId`. La pantalla puede:
  - No tener UI para guardar/persistir la selección
  - Persistir pero no refrescar el provider
  - Estar inaccesible (no hay link desde profile)
- **Archivos**:
  - `lib/features/city_picker/city_picker_screen.dart`
  - `lib/shared/providers/user_provider.dart`
  - Search en lib/ por `primaryZoneId` setter / mutation
- **Estrategia**:
  1. Reproducir: ¿desde dónde se accede al city picker? ¿hay link en profile?
  2. Verificar onSelect en CityPickerScreen — debe escribir a `userPreferences` o
     Supabase (si auth) + Hive (si guest)
  3. Para invitados → guardar en `userPreferences` box de Hive
  4. Para auth → escribir a `profiles.primary_zone_id` en Supabase
  5. Refrescar `currentUserProvider` tras cambio
- **Verificación**: cambiar zona → cerrar app → reabrir → zona persiste
- **Esfuerzo**: M (45-60 min)
- **Severidad**: 🟠 P1

---

### F3 · Mapa & geolocalización

#### F3.1 — Geolocalización tiempo real + botón "centrar en mi ubicación"
- **Síntoma**: el mapa no muestra ubicación del usuario, no hay botón estilo Google Maps
- **Archivos**:
  - `lib/features/map/transit_map.dart`
  - `lib/features/home/tabs/map_tab.dart`
  - Nuevo: `lib/features/map/layers/user_location_layer.dart`
  - Nuevo: `lib/shared/providers/user_location_provider.dart`
- **Estrategia**:
  1. Provider `userLocationProvider` con `StreamProvider<Position?>` usando
     `Geolocator.getPositionStream(LocationSettings(accuracy: high, distanceFilter: 5))`
  2. Antes: `Geolocator.requestPermission()` + `isLocationServiceEnabled()`
  3. `MarkerLayer` con `CircleMarker` (accuracy) + `Marker` (punto azul)
  4. `FloatingActionButton.small` con `Icons.my_location` bottom-right encima del nav.
     onTap → `MapController.move(userLatLng, zoom)`
  5. UX permiso denegado: snackbar + botón "Abrir ajustes"
- **Verificación**: abrir mapa → permiso → punto azul + círculo accuracy → tap FAB → centra
- **Esfuerzo**: L (60-90 min)
- **Severidad**: 🟠 P1

#### F3.2 — Filtros mapa tapados por nav bar
- **Síntoma**: panel de filtros queda parcialmente bajo el bottom nav
- **Archivos**: `lib/features/home/tabs/map_tab.dart` o widget de filtros
- **Estrategia**: `Padding(EdgeInsets.only(bottom: 96))` o SafeArea
- **Esfuerzo**: S (15 min)
- **Severidad**: 🟡 P2

#### F3.3 — Filtros por tipo de línea (urbanas / interurbanas / locales)
- **Síntoma**: el desplegable de líneas no permite filtrar por tipo
- **Archivos**:
  - `lib/shared/models/route_model.dart` (verificar campo `type`)
  - `assets/mock/comujesa_data.json`
  - Widget del desplegable en map_tab
- **Estrategia**:
  1. Verificar/añadir `RouteType` enum (urban/interurban/local) en modelo
  2. Asignar tipos en mock data (ej: U1-U9 urbanas, I1-I5 interurbanas, L1-L3 locales)
  3. Row de `ChoiceChip` encima del listado: Todas / Urbanas / Interurbanas / Locales
  4. StateProvider para el filtro activo
- **Verificación**: tap "Urbanas" → solo líneas urbanas en el listado y mapa
- **Esfuerzo**: M-L (60-75 min)
- **Severidad**: 🟠 P1

#### F3.4 — Búsqueda completa en mapa (sitios + rutas + paradas)
- **Síntoma**: search bar muestra "próximamente"
- **Decisión del usuario**: implementación COMPLETA
- **Archivos**:
  - Search widget en `lib/features/home/tabs/map_tab.dart` o nueva carpeta
  - Nuevo: `lib/shared/providers/map_search_provider.dart`
  - `lib/data/mock/mock_data_service.dart` (acceder a rutas + paradas)
  - Geocoding para sitios — puede usar Nominatim (OpenStreetMap) o MapTiler geocoding
- **Estrategia**:
  1. `SearchBar` con TextField + clear button
  2. `mapSearchProvider`: stream que combina 3 fuentes:
     - Rutas: filter `routes.where((r) => r.shortName.contains(q) || r.headsign.contains(q))`
     - Paradas: filter `stops.where((s) => s.name.contains(q))`
     - Sitios (POIs): query a Nominatim `https://nominatim.openstreetmap.org/search?q=...&limit=5&bounded=1&viewbox=...`
       (acotado al bounding box de Jerez para no traer resultados de Madrid)
  3. UI de resultados: `ListView` con secciones tipadas (`SEARCH_TYPE_HEADING`):
     - "RUTAS"
     - "PARADAS"
     - "LUGARES"
  4. Tap en resultado:
     - Ruta → push `/route/:id`
     - Parada → push `/stop/:id` + `MapController.move(stop.latLng, 17)`
     - Sitio → `MapController.move(latLng, 16)` + Marker temporal
  5. Debounce 300ms en el TextField para no spamear Nominatim
- **Verificación**: escribir "U2" → ve rutas U2 + paradas con U2 en nombre. Escribir
  "Plaza" → ve plazas como POI.
- **Esfuerzo**: L (90 min)
- **Severidad**: 🟠 P1

---

### F4 · Modo invitado funcional (production-like, no demo)

> Cambio de marco: la app es producto. Invitados navegan completo, pierden persistencia
> cloud + features comunidad. Sin badges DEMO en la UI.

#### F4.1 — Home tab: secciones personales con empty state, no ocultar
- **Antes**: el plan v1 decía "ocultar Mis líneas / paradas cerca / próximo bus sin login"
- **Ahora**: mantener visibles pero con empty state inteligente:
  - "Mis líneas" (favoritas) → si lista vacía → "Aún no tienes favoritas. Pulsa ☆ en cualquier línea para guardarla"
  - "Paradas cerca de ti" → siempre visible para todos (usa geolocalización del F3.1)
  - "Tu próximo bus" → solo si hay favoritas guardadas (en caché o cloud)
- **Archivos**: `lib/features/home/tabs/home_tab.dart` y widgets
- **Estrategia**:
  1. Convertir "Mis líneas" en provider que lee de `userFavoritesProvider` (Hive box `userFavorites`, ya existe)
  2. Empty state si lista vacía
  3. "Paradas cerca" usa `userLocationProvider` (de F3.1) — no requiere auth
- **Verificación**: cold start sin login → home funcional, secciones visibles con CTAs
- **Esfuerzo**: M (45-60 min)
- **Severidad**: 🟠 P1

#### F4.2 — Tiempos de buses realistas (no random, sin DEMO)
- **Síntoma**: tiempos son `MockRealtimeService` aleatorios → varían wildly entre rebuilds
- **Decisión**: mantenerlos visibles para todos, MEJORARLOS para que sean creíbles
- **Archivos**: `lib/data/mock/mock_realtime_service.dart`
- **Estrategia**:
  1. Tiempos derivados del schedule mock + offset determinista
  2. Para cada ruta: `nextDeparture = scheduledTime + smallRandomDelay(seed = routeId+now/minutes)`
  3. Resultado: el mismo bus muestra el mismo tiempo durante 1 minuto, luego rota
     coherentemente (no salta de "3 min" a "15 min" en un rebuild)
  4. Si el seed produce un tiempo negativo → mostrar "Llegando" o "En parada"
- **Verificación**: ver tiempos consistentes durante uso, no random absurdo
- **Esfuerzo**: M (45-60 min)
- **Severidad**: 🟡 P2

#### F4.3 — Favoritas en caché local (Hive) para invitados
- **Síntoma actual**: el box `userFavorites` existe pero seguramente solo se usa con login
- **Archivos**:
  - `lib/shared/providers/user_favorites_provider.dart` (ya tiene Hive)
  - Botón ☆/❤ en cada route/stop list item
- **Estrategia**:
  1. Verificar que `UserFavoritesNotifier` persiste a Hive sin requerir auth (ya parece así)
  2. Si autenticado: además sincronizar a Supabase `profiles.favorite_routes` (ya implementado?)
  3. UI consistente: el ☆ funciona idéntico en ambos modos. Sin error de "necesitas login".
  4. En login posterior: ofrecer migrar favoritas locales a la cuenta (snackbar)
- **Verificación**: invitado favorita 3 rutas → cierra app → reabre → favoritas siguen
- **Esfuerzo**: M (30-60 min, depende de qué ya esté hecho)
- **Severidad**: 🟠 P1

#### F4.4 — Acciones que requieren auth → snackbar + CTA (no error)
- **Síntoma**: si un invitado intenta reportar incidente, votar, comentar → error genérico
- **Estrategia**: helper `requireAuth(context, action: 'reportar incidente')` que:
  - Si auth → ejecuta callback
  - Si no → snackbar "Inicia sesión para [action]" + botón "ENTRAR" → push `/sign-in?next=...`
- **Archivos**:
  - Nuevo: `lib/shared/utils/require_auth.dart`
  - Cada botón de acción comunidad → envolver con helper
- **Esfuerzo**: M (60 min, varios puntos de uso)
- **Severidad**: 🟠 P1

---

### F5 · Branding & animación

#### F5.1 — Logo blanco para modo claro (usar `logoblanco.png`)
- **Síntoma**: logo actual (morado/negro) no se ve bien en fondo claro
- **Recurso disponible**: `C:\Users\k\Downloads\logoblanco.png` (175 KB)
- **Estrategia**:
  1. Copiar a `assets/branding/transitly_logo_white.png`
  2. Crear helper widget `TransitlyLogo` que recibe `isDark` y devuelve el PNG correcto:
     - isDark=true → `transitly_logo.png` (actual)
     - isDark=false → `transitly_logo_white.png` (nuevo)
  3. Grep `Image.asset.*transitly_logo` y migrar a `TransitlyLogo()`
- **Verificación**: toggle dark/light, logo se ve correcto en ambos
- **Esfuerzo**: S (20-30 min)
- **Severidad**: 🟠 P1

#### F5.2 — Auditoría modo claro completa
- **Síntoma**: aún hay rincones en oscuro tras el fix MVP
- **Estrategia**:
  1. Grep `Colors\.white\.withValues` → cada match es sospechoso (era para fondo oscuro)
  2. Grep `Color\(0xFF[0-9A-F]{6}\)` fuera de `transit_colors.dart`
  3. Para cada offender: usar `TransitColorScheme.of(isDark)` o crear variante en el scheme
- **Verificación**: toggle light, pantalla por pantalla — todo respeta el tema
- **Esfuerzo**: L (90-120 min)
- **Severidad**: 🟠 P1

#### F5.3 — Icono app con mucho zoom
- **Síntoma**: en launcher, el ícono se ve muy grande/cortado
- **Causa**: `flutter_launcher_icons` config en pubspec.yaml: `adaptive_icon_foreground_inset: 16`
  es muy bajo. Subir a 32-40.
- **Archivos**: `pubspec.yaml`
- **Estrategia**: cambiar inset, `dart run flutter_launcher_icons`, rebuild
- **Verificación**: instalar APK, ver ícono en launcher con margen
- **Esfuerzo**: S (10 min)
- **Severidad**: 🟠 P1

#### F5.4 — Animación de bienvenida simple
- **Recurso**: `logoblanco.png` para usar en la splash sobre fondo oscuro (más impactante)
- **Estrategia**:
  1. `lib/features/splash/splash_screen.dart` (verificar si existe o crear)
  2. Componentes:
     - Logo blanco centrado con `TweenAnimationBuilder` haciendo:
       - Fade-in 600ms (0 → 1 opacity)
       - Scale-in 600ms (0.8 → 1.0) con curve `Curves.easeOutBack`
     - Tagline "Plataforma universal de transporte público" con stagger 400ms tras el logo
     - Progress bar fina al fondo (1.2s total para preload de mockData/Hive)
     - Al completar → `context.go('/home')` con fade-out transition
  3. Total duración: ~1.5-2s, sensación pulida sin ser pesada
- **Verificación**: cold start → ver animación completa
- **Esfuerzo**: M (60-90 min, usando skill `flutter-animations`)
- **Severidad**: 🟡 P2

---

### F6 · Tech debt

#### F6.1 — Re-activar R8/shrink
- Pre-requisito: máquina con ≥8 GB RAM libre (este host: 5.6 GB libres)
- Archivos: `android/app/build.gradle.kts`
- Verificación: build → ~30% reducción de tamaño (de 41.5 MB a ~28 MB)
- Esfuerzo: S + tiempo de build (~5 min)
- Severidad: 🟢 P3

#### F6.2 — Pre-bundlear DM Sans (.ttf assets)
- Síntoma: warnings recurrentes "Could not load DMSans-*"
- Estrategia:
  1. Descargar DMSans-Light/Regular/Bold.ttf de Google Fonts
  2. `assets/fonts/dm_sans/`
  3. Declarar en pubspec.yaml con weights 300/400/700
- Verificación: build, no warnings
- Esfuerzo: S (15 min)
- Severidad: 🟢 P3

#### F6.3 — MapTiler API key real
- Estrategia: registrarse en maptiler.com (free 100k tiles/mes)
- Verificación: rebuild, tiles mejor calidad
- Esfuerzo: S (10 min)
- Severidad: 🟢 P3

---

### F7 · Testing flujos secundarios

- [ ] Sign in email/password
- [ ] Sign up + email verification
- [ ] Recover password
- [ ] Magic link
- [ ] NFC card scan
- [ ] Route detail
- [ ] Stop detail
- [ ] /activate-driver completo

**Esfuerzo**: L (2-3 horas)
**Severidad**: 🟡 P2

---

## Orden recomendado de ejecución

```
Fase A — P0 bloqueantes (~3-4 h)
  F1.1 perfil error
  F1.2 atrás cierra app
  F1.4 apariencia → negro
  F1.3 notificaciones loading
  → Verificar: cero crashes en flujos principales

Fase B — Visual & branding (~3 h)
  F5.3 icono zoom (5-10 min) ← quick win, regenera launcher
  F5.1 logo blanco modo claro (20-30 min)
  F5.2 audit modo claro (90 min)
  F4.1 home secciones empty state pre-login (60 min)
  → Verificar: app se ve "presentable" en cold start sin login

Fase C — Overflows & layout (~1.5 h)
  F2.3 smoke feedback
  F2.4 operador offline truncar
  F3.2 filtros tapados nav
  F2.1+F2.5 accessible_buses overflow
  → Verificar: ningún texto cortado en pantallas core

Fase D — Mapa & features (~4 h)
  F3.1 geolocalización + botón centrar (90 min)
  F3.3 filtros por tipo línea (60 min)
  F3.4 búsqueda completa (90 min)
  F2.2 buses cercanos + dirección (60 min)
  → Verificar: mapa completamente usable

Fase E — Modo invitado funcional (~2 h)
  F4.3 favoritas en Hive guest mode (60 min)
  F4.4 helper requireAuth + snackbars (60 min)
  F4.2 tiempos realistas (45 min)
  F2.6 city picker persiste (45 min)
  → Verificar: invitado puede usar todo, sus favoritas persisten

Fase F — Polish & animación (~2 h)
  F5.4 animación bienvenida (90 min)
  F6.2 bundle DM Sans (15 min)
  F6.3 MapTiler key (10 min)

Fase G — Testing & release (~3 h)
  F7 smoke tests todos los flujos
  Documentar bugs nuevos encontrados
  F6.1 R8 si host tiene RAM
  Tag v1.1.0-stable
```

**Total estimado**: ~18-20 horas (~3 días focused)

---

## Quick wins (~2 h, alto impacto visual)

| ID | Fix | Tiempo |
|----|-----|--------|
| F5.3 | Icono app inset 32 | 10 min |
| F2.3 | Smoke feedback bottom | 15 min |
| F2.4 | Operador offline truncar | 10 min |
| F3.2 | Filtros mapa sin overlap nav | 15 min |
| F5.1 | Logo blanco modo claro | 25 min |
| F6.2 | Bundle DM Sans | 15 min |
| F6.3 | MapTiler key | 10 min |
| F1.2 | Back button handler | 25 min |

---

## Tracking

Tras aprobar este plan v2:
1. Crear tasks via `TaskCreate` para cada bug (F1.1 → F7), una task por bug
2. Cada commit referencia el ID: `fix(F1.1): ...`, `feat(F3.4): ...`
3. Al final de cada fase, commit + verificación manual + push
4. Cuando fases A-E estén verdes → tag `v1.1.0-stable`
5. Cuando fase F-G verdes → tag `v1.2.0-production`
