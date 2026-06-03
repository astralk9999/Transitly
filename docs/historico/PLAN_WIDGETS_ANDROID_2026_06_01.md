# Plan de acción — Widgets de pantalla de inicio Android para Transitly

**Fecha del plan:** 2026-06-01
**Autor:** Claude Code (Opus 4.7)
**Estado:** decisiones clave aprobadas por el usuario el 2026-06-01. Pendiente de iniciar Wave 0.
**Alcance:** solo Android nativo (iOS queda fuera de este plan; requiere Widget Extension separada en Swift/SwiftUI).

---

## 1. Contexto

Transitly es una app Flutter de transporte público para Jerez (operador COMUJESA, 19 líneas, 598 paradas reales). Hoy la única forma de consultar "¿cuándo pasa mi bus?" es abrir la app, esperar el splash, llegar al home y leer la tarjeta de viaje habitual.

El objetivo de este plan es **añadir widgets nativos para la pantalla de inicio del launcher Android** que muestren información en vivo sin abrir la app. Esto es lo que el usuario referenció con *"colocar widgets"*.

### Por qué importa
- **Inmediatez**: el usuario corre hacia la parada y mira el reloj del móvil; el widget le dice si va sobrado o no.
- **Acceso pasivo**: no requiere abrir la app, no consume batería de pantalla encendida.
- **Diferenciación**: ninguna competidora local de COMUJESA tiene widgets.
- **Reaprovechamiento**: la app ya tiene `homeHabitualConfigProvider` (viaje habitual) y `userFavoritesProvider.stops` (paradas favoritas) — solo falta exponerlos al widget.

---

## 2. Estado actual del repositorio (auditoría)

Verificado leyendo el código en la fecha del plan:

- **No existe** ningún `AppWidgetProvider` registrado en `android/app/src/main/AndroidManifest.xml`.
- **No existe** el directorio `android/app/src/main/res/xml/` con `appwidget-provider`.
- **No existe** dependencia `home_widget` ni `home_widget_glance` en `pubspec.yaml`.
- **Existe** `lib/shared/providers/widget_data_sync_provider.dart` (línea 84 de `home_shell.dart` hace `ref.watch(widgetDataSyncProvider)`) — ya hay un provider stub, pero hay que verificar si efectivamente escribe a SharedPreferences o solo es un placeholder. **Acción del Paso 0:** auditar este archivo antes de duplicar trabajo.
- **Existen** los providers de datos que el widget necesitará leer:
  - `homeHabitualConfigProvider` → routeId + stopId del viaje configurado
  - `userFavoritesProvider.stops` → Set<String> de paradas favoritas
  - `mockDataServiceProvider.getNextDeparturesForStop(stopId, N)` → próximas salidas (mock)
  - `nfcBalanceRepositoryProvider.getHistory().first.balance` → último saldo NFC escaneado

Esto significa que la capa de datos está lista; falta toda la capa de plataforma (Android nativo + bridge Flutter↔nativo) y el cron de refresco.

---

## 3. Tipos de widget propuestos

Recomiendo **3 widgets** distintos, no uno único configurable, porque Android permite al usuario añadir varios y mezclarlos. Cada uno cubre un caso de uso bien definido.

### Widget A — "Próximo bus" (tamaño 4×1)

**Caso de uso:** usuario en casa antes de salir.

**Contenido:**
```
┌─────────────────────────────────────────────────┐
│ ┌──┐  L8 → Estadio                     │
│ │L8│  ⏱ 4 min  ·  Plaza del Caballo   │
│ └──┘                                  3 más →   │
└─────────────────────────────────────────────────┘
```

- Badge cuadrado izq con código de línea + color de la línea.
- Centro: destino + minutos restantes del próximo bus.
- Subtítulo: nombre de la parada del viaje habitual.
- Esquina inferior derecha: "N más →" con el resto de salidas (tap → abre app en `/route/{id}`).

**Configuración del widget al añadirlo:** mostrar el viaje habitual configurado (`homeHabitualConfigProvider`). Si no hay viaje habitual configurado, el widget muestra un CTA "Toca para configurar →" que abre la app en el sheet de configuración.

**Refresh:** cada 60 segundos cuando hay un bus en < 5 min, cada 5 min en otro caso.

### Widget B — "Mis paradas favoritas" (tamaño 4×2)

**Caso de uso:** usuario con varias paradas habituales (casa, trabajo, gimnasio).

**Contenido:**
```
┌─────────────────────────────────────────────────┐
│ ⭐ Mis paradas                                   │
│ ──────────────────────────────────────────────   │
│ Plaza del Caballo      L8  3 min  L15 7 min  │
│ Estadio Chapín         L4  1 min  L8  9 min  │
│ Hospital               L2  pasó · L11 12 min  │
│ Universidad            (sin servicio ahora)    │
└─────────────────────────────────────────────────┘
```

- Hasta 4 paradas (las primeras del `userFavoritesProvider.stops`).
- Por cada parada: nombre + 2 próximas salidas.
- Tap en una fila → app en `/stop/{stopId}`.
- Tap en la cabecera → app en /home/inicio (sección "Mis paradas").

**Refresh:** cada 90 segundos.

### Widget C — "Saldo NFC" (tamaño 2×1)

**Caso de uso:** usuario quiere saber si tiene saldo antes de coger el bus, sin pasar la tarjeta.

**Contenido:**
```
┌──────────────────────┐
│ 💳 Saldo bonobús     │
│ 12,40 €              │
│ Actualizado: hace 2 h│
└──────────────────────┘
```

- Saldo de la última lectura NFC (`nfcBalanceRepositoryProvider`).
- Sello de tiempo relativo.
- Tap → app en `/home/tarjeta` (donde se escanea NFC).

**Refresh:** on-demand (cuando la app guarda un nuevo escaneo, el widget se actualiza). No tiene refresh periódico porque la lectura es manual con NFC.

---

## 4. Arquitectura técnica

### 4.1. Capas

```
┌─────────────────────────────────────────────────┐
│  ANDROID NATIVO (Kotlin)                        │
│   ├─ NextBusWidgetProvider (AppWidgetProvider)  │
│   ├─ MyStopsWidgetProvider                      │
│   ├─ NfcBalanceWidgetProvider                   │
│   ├─ WidgetRefreshWorker (WorkManager)          │
│   └─ Layouts XML (res/layout/widget_*.xml)      │
└─────────────────────────────────────────────────┘
                  ↕ (SharedPreferences compartidas)
┌─────────────────────────────────────────────────┐
│  FLUTTER (Dart)                                 │
│   ├─ home_widget (plugin)                       │
│   ├─ WidgetDataSyncService                      │
│   │    .pushNextBus()                           │
│   │    .pushMyStops()                           │
│   │    .pushNfcBalance()                        │
│   ├─ Background callback (refresh sin UI)        │
│   └─ Providers Riverpod existentes              │
└─────────────────────────────────────────────────┘
```

### 4.2. Plugin: `home_widget` ^0.7.0

Maduro, ampliamente usado, multiplataforma (Android + iOS). API base:
- `HomeWidget.saveWidgetData(key, value)` → escribe a SharedPreferences nativas.
- `HomeWidget.updateWidget(name: 'NextBusWidgetProvider', androidName: ...)` → fuerza el `onUpdate()` del provider Kotlin.
- `HomeWidget.registerBackgroundCallback(callback)` → permite que el widget llame a Dart sin abrir la app.

**Alternativa descartada:** `home_widget_glance`. Glance es la API moderna de widgets en Compose, pero el plugin aún es nuevo y limita layouts complejos. Dejamos preparada la migración pero no la hacemos en esta primera iteración.

### 4.3. Refresh policy — ESTRATEGIA "MÁS EFICIENTE" (decidida por el usuario)

**Principio rector:** el widget refresca cuando hay valor real para el usuario, nunca por inercia.

Cuatro mecanismos coordinados, **sin AlarmManager** (drena batería y los OEM agresivos lo matan igualmente):

| # | Mecanismo | Trigger | Coste energético | Latencia | Widget |
|---|-----------|---------|-------------------|----------|---------|
| 1 | **Push síncrono** | Eventos significativos en la app (configurar viaje, favorito nuevo, escaneo NFC, cambio de paleta) | ~0 (la app ya está despierta) | instantánea | A, B, C |
| 2 | **Push on lifecycle** | App pasa a `paused` o `detached` | ~0 (proceso ya activo) | instantánea | A, B, C |
| 3 | **WorkManager periódico con constraints** | Cada 15 min (mínimo Android); solo si hay red Y batería no `LOW` Y existe al menos un widget colocado | bajo (Doze friendly) | hasta 15 min | A, B |
| 4 | **WorkManager one-shot programado** | Al refrescar, si el próximo bus está a `T < 12 min`, programamos un one-shot worker a `T - 90 s` | bajísimo (1 wake-up dirigido por hora típica) | precisión ±2 min | A |

#### Por qué es lo más eficiente

- **Sin `AlarmManager.setExact`:** los exact alarms son la principal fuga de batería de los widgets transit. Doze los respeta cada vez menos en Android 13+. Y los launchers chinos los bloquean.
- **WorkManager con `Constraints`:** solo se ejecuta cuando hay red real (`NetworkType.CONNECTED`) y batería no crítica. Si el móvil está en modo avión, ahorra trabajo inútil.
- **One-shot dirigido en vez de polling:** en lugar de refrescar cada 60 s "por si acaso", calculamos cuándo necesitamos el siguiente refresh basándonos en los datos ya conocidos. Si el próximo bus llega en 8 min, programamos UN solo wake-up a los ~6.5 min. Cero polling intermedio.
- **Push síncrono en eventos:** cuando el usuario marca una parada como favorita, NO esperamos 15 min al siguiente periodic worker. Actualizamos el widget en el mismo proceso de Flutter sin coste extra.
- **`onEnabled()` y `onDisabled()` arrancan/cancelan workers:** si el usuario nunca añade un widget al launcher, **no se ejecuta absolutamente nada en background**. Si lo quita, los workers se cancelan inmediatamente.
- **Debounce de 5 s en `refreshWidgets()`:** si llegan 10 eventos en 1 s (típico al abrir/cerrar la app), solo un refresh real al final.
- **Caché Supabase de 90 s:** si el WorkManager se dispara dos veces seguidas, no llamamos a Supabase la segunda; servimos cache.

#### Tabla de wake-ups esperados (usuario medio, 8 h app cerrada)

| Estrategia | Wake-ups estimados/8 h | Comentario |
|------------|------------------------|------------|
| AlarmManager 60 s | 480 | Inviable, drena batería |
| WorkManager 15 min sin filtros | 32 | Tolerable pero todavía mucho |
| **Nuestra estrategia** | **8–12** | One-shot dirigido + periodic solo si red |

Resultado: **menos de un wake-up por hora promedio**, datos siempre frescos cuando importa.

### 4.4. Datos: REALES desde Supabase (decisión del usuario)

El usuario decidió que el widget debe mostrar **datos reales**, no mock. Esto añade una nueva capa de backend que la app actualmente no tiene completa: hoy `mockDataService` genera salidas pseudoaleatorias.

#### 4.4.1. Realidad actual del backend

- **Existe:** Supabase proyecto `mmzahxtiaurkgtmtehxk` con auth, perfiles, NFC scans, contribuciones, etc.
- **No existe aún:** feed GTFS-Realtime de COMUJESA. El operador no publica API pública oficial. Tampoco hay un endpoint Supabase de "próximas llegadas reales".
- **Existe parcialmente:** GTFS-Static (líneas, paradas, horarios programados) está en mock data, pero podría volcarse a Supabase fácilmente.

#### 4.4.2. Plan de datos reales en 3 capas

**Capa 1 — Estática (horarios programados)** — *disponible inmediatamente*
- Subir `assets/mock/comujesa_data.json` a Supabase como tablas `routes`, `stops`, `route_stops`, `scheduled_departures` (vía migration).
- Crear vista materializada `next_scheduled_arrivals(stop_id, route_id, scheduled_at, headsign)` que pre-calcula las próximas 6 salidas por (parada × ruta).
- RPC `get_next_arrivals_for_stop(p_stop_id text, p_limit int)` que devuelve JSON con la lista de llegadas con `minutes_until` calculado server-side.
- El widget llama esta RPC. **Es real en el sentido de "horario oficial publicado", aunque no es tiempo real de un bus físico moviéndose.**

**Capa 2 — Patches manuales de incidencias** — *complemento humano*
- Reutilizar `incidents` table existente (ya hay RLS y editor admin). Si hay incidencia activa (`active = true` y `stop_id` o `route_id` afecta), la RPC ajusta los tiempos o marca "Sin servicio".
- El widget muestra "⚠ Incidencia" cuando aplica.

**Capa 3 — Tiempo real cuando exista** — *futuro abierto*
- Cuando COMUJESA publique API (o cuando se integre un scraper legal), se sustituye la fuente sin tocar el widget.
- Contrato de la RPC se mantiene; el contenido pasa de "scheduled - delay" a "predicted_real_time".

#### 4.4.3. Por qué esto cuenta como "real"

- Los horarios son **los oficiales del operador**, no inventados aleatoriamente como el mock actual.
- Si llega una incidencia, el widget la refleja.
- La precisión de minutos depende solo de la exactitud del calendario publicado (típicamente ±2 min en horario normal).
- Cuando el operador publique GTFS-RT, el widget pasará a tiempo real sin re-implementación.

#### 4.4.4. Trabajo extra que esto añade al plan

Esto introduce una nueva wave **antes** de Wave 1:

- **Wave 0.5 — Migración de datos a Supabase** (~5 h)
  - Migration con esquemas `routes`, `stops`, `route_stops`, `scheduled_departures` + datos seed desde `comujesa_data.json`.
  - Vista materializada `next_scheduled_arrivals`.
  - RPC `get_next_arrivals_for_stop(stop_id, limit)`.
  - RPC `get_next_arrivals_for_route_stop(route_id, stop_id, limit)` (para Widget A).
  - RLS: lectura pública (datos públicos del operador), escritura solo a admin.
  - Triggers para refrescar la vista materializada cada noche.
- Actualizar Wave 1 para que el `WidgetDataSyncService` llame las RPCs de Supabase en lugar de mockData.
- Estrategia de cache: 90 s en memoria + persistencia en SharedPreferences para modo offline.
- Tiempo total revisado: **+5 h al plan original = 29 h**.

### 4.5. Localización en los widgets

Los layouts XML soportan recursos `strings.xml` por idioma (`values-es/`, `values-en/`, `values-ar/`). Las cadenas estáticas del widget ("Próximo bus", "Mis paradas", "Saldo bonobús") se localizan vía Android. Datos dinámicos (nombre de parada, minutos) los inyecta el provider Kotlin a partir de los valores guardados por Flutter.

Pendiente decidir: ¿el widget respeta el idioma de la app o el del sistema? Recomendación: **idioma del sistema** (Android no soporta cambiar idioma de widget desde la app sin recrearlo).

### 4.6. Theming del widget

Los widgets toman el color de la paleta activa del usuario. La app, al hacer `pushNextBus()`, escribe también:
- `accent_hex` → color del badge de línea y acentos.
- `bgroot_hex` → color de fondo del widget.
- `texthi_hex` → color del texto principal.

El layout XML usa `android:tint="@string/accent_color"` referenciado desde SharedPreferences. Si la paleta cambia, los widgets se refrescan vía `updateWidget()`.

---

## 5. Plan de implementación por waves

Diseñado para que cada wave deje un entregable usable y testeable. NO se mezclan capas (nativo vs Flutter) dentro de la misma wave para reducir bugs cruzados.

### Wave 0 — Auditoría previa (30 min, sin código nuevo)
*(estado: planificado)*

**Objetivo:** confirmar el estado real del repo antes de tocar nada.

**Tareas:**
1. Leer completo `lib/shared/providers/widget_data_sync_provider.dart`. Hay 3 escenarios posibles:
   - (a) Es un stub vacío → empezamos desde cero.
   - (b) Ya tiene escritura a `HomeWidget.saveWidgetData(...)` → solo falta la capa Android.
   - (c) Ya tiene escritura + plugin instalado → falta solo el AppWidgetProvider Kotlin.
2. Verificar `pubspec.yaml` línea de `home_widget`. Si existe pero `flutter pub deps` da conflicto, anotar versión a usar.
3. Verificar `android/app/build.gradle.kts` para confirmar `minSdkVersion` ≥ 23 (requerido por home_widget moderno).
4. Verificar permisos en `AndroidManifest.xml`. Para WorkManager con paradas favoritas no hace falta nada extra, pero confirmar que `INTERNET` está declarado (lo está, pero por si acaso).

**Entregable:** un mini-informe en este mismo .md (sección "Notas de auditoría") con los hallazgos. Si (b) o (c), el plan se acorta.

---

### Wave 0.5 — Backend Supabase para datos REALES (5 h) — NUEVA por decisión del usuario

**Objetivo:** dejar las RPCs reales que tanto la app como los widgets consumirán. Sin esto, los widgets solo podrían mostrar mock.

#### T0.5.1 — Migrations Supabase
- `routes` (id, code, name, color, service_type, headsign_a, headsign_b)
- `stops` (id, name, lat, lng, is_accessible)
- `route_stops` (route_id, stop_id, sequence, direction)
- `scheduled_departures` (id, route_id, stop_id, departure_time, days_of_week bitmask, valid_from, valid_until)
- `incidents` (ya existe — verificar columnas `stop_id`, `route_id`, `active`, `severity`)

Seed inicial: script SQL one-shot que vuelca `assets/mock/comujesa_data.json` (598 paradas + 19 líneas + horarios) a las tablas. Hacer **una sola vez** desde un edge function o migration.

#### T0.5.2 — Vista materializada
```sql
create materialized view next_scheduled_arrivals as
  select
    sd.stop_id,
    sd.route_id,
    r.code as route_code,
    r.color as route_color,
    rs.headsign,
    sd.departure_time,
    extract(epoch from (sd.departure_time - now())) / 60 as minutes_until
  from scheduled_departures sd
  join routes r on r.id = sd.route_id
  join route_stops rs on rs.route_id = sd.route_id and rs.stop_id = sd.stop_id
  where sd.departure_time > now()
    and sd.departure_time < now() + interval '2 hours'
    and (sd.days_of_week & (1 << extract(dow from now())::int)) != 0;
```
Refresh nocturno con `pg_cron`: `select cron.schedule('refresh-arrivals', '0 3 * * *', 'refresh materialized view concurrently next_scheduled_arrivals');`.

#### T0.5.3 — RPCs públicas
- `get_next_arrivals_for_stop(p_stop_id text, p_limit int default 4) returns json`
- `get_next_arrivals_for_route_stop(p_route_id text, p_stop_id text, p_limit int default 3) returns json`

Ambas:
- Filtran por `next_scheduled_arrivals` ordenado por `minutes_until ASC`.
- Aplican patch de incidencias: si hay `incident.active = true` afectando, marcan `delay_min` o `cancelled`.
- Devuelven JSON listo para serializar al SharedPreferences del widget.

RLS: lectura pública anónima (datos del operador, no privados). Escritura solo `service_role`.

#### T0.5.4 — Cache layer en Dart
Nueva clase `lib/data/arrivals/arrivals_repository.dart`:
```dart
class ArrivalsRepository {
  ArrivalsRepository(this._supabase, this._hive);

  Future<List<Arrival>> getForStop(String stopId, {int limit = 4}) async {
    final cacheKey = 'arrivals:$stopId:$limit';
    final cached = _readCache(cacheKey);
    if (cached != null && _ageSeconds(cacheKey) < 90) return cached;
    try {
      final res = await _supabase.rpc('get_next_arrivals_for_stop',
        params: {'p_stop_id': stopId, 'p_limit': limit});
      final list = (res as List).map(Arrival.fromJson).toList();
      _writeCache(cacheKey, list);
      return list;
    } catch (e) {
      return cached ?? [];  // modo offline: cache aunque sea viejo
    }
  }
}
```

Persistencia en Hive box `arrivals_cache`, claves con timestamp.

#### T0.5.5 — Hooks de la app
- `mockDataService.getNextDeparturesForStop()` se DEPRECA: la pestaña Inicio, los detalles de parada y los widgets pasan a usar `arrivalsRepositoryProvider`.
- Si Supabase responde con error o vacío (ej. parada sin tramo activo a esa hora), cae al mock como último fallback con badge "Datos no verificados".

**Entregable:** Supabase devuelve llegadas reales basadas en el calendario oficial; la UI de la app las consume igual que el widget hará.

---

### Wave 1 — Plumbing Flutter (4 h)
*(estado: planificado, depende de Wave 0.5)*

**Objetivo:** dejar listo el lado Dart para publicar datos al widget. Sin aún tener widget Android real, ya podemos verificar que SharedPreferences se rellenan correctamente.

**Tareas:**

#### T1.1 — Añadir dependencia
- `pubspec.yaml`: añadir `home_widget: ^0.7.0` bajo `dependencies:`.
- `flutter pub get`.

#### T1.2 — Crear `lib/shared/widgets_android/widget_data_sync_service.dart` (NUEVO)

API propuesta:
```dart
class WidgetDataSyncService {
  WidgetDataSyncService(this._ref);
  final Ref _ref;

  static const _appGroupId = 'transitly';
  static const _kNextBusJson = 'next_bus_v1';
  static const _kMyStopsJson = 'my_stops_v1';
  static const _kNfcBalance = 'nfc_balance_v1';
  static const _kThemeJson = 'theme_v1';

  Future<void> pushAll() async { ... }
  Future<void> pushNextBus() async { ... }
  Future<void> pushMyStops() async { ... }
  Future<void> pushNfcBalance() async { ... }
  Future<void> pushTheme(TransitColorScheme scheme) async { ... }

  Future<void> refreshWidgets() async {
    await HomeWidget.updateWidget(
      androidName: 'com.transitly.transitly.widgets.NextBusWidgetProvider',
    );
    await HomeWidget.updateWidget(
      androidName: 'com.transitly.transitly.widgets.MyStopsWidgetProvider',
    );
    await HomeWidget.updateWidget(
      androidName: 'com.transitly.transitly.widgets.NfcBalanceWidgetProvider',
    );
  }
}
```

Datos guardados (formato JSON serializado para flexibilidad):
- `next_bus_v1` = `{routeId, routeCode, routeColor, headsign, stopName, arrivals: [4, 12, 21]}`
- `my_stops_v1` = `[{stopId, name, arrivals: [{code, color, mins}, ...]}]`
- `nfc_balance_v1` = `{balance: 12.40, scannedAt: 1717248000}`
- `theme_v1` = `{accent: "#977DDF", bgRoot: "#08081A", textHi: "#FFFFFF"}`

#### T1.3 — Provider Riverpod que envuelve el servicio
```dart
final widgetDataSyncServiceProvider = Provider(
  (ref) => WidgetDataSyncService(ref),
);
```

#### T1.4 — Triggers de actualización
- `lib/main.dart` → tras `await Hive.initFlutter()`, llamar `await widgetDataSyncServiceProvider.read().pushAll()`. **Bloquea el arranque máximo 200 ms.**
- `lib/app.dart` → `WidgetsBindingObserver.didChangeAppLifecycleState` detecta `paused`, llama `pushAll()`. Así al cerrar la app el widget queda actualizado.
- `lib/data/nfc/nfc_balance_repository.dart` → tras `saveScan()`, llamar `pushNfcBalance()`.
- `lib/shared/providers/home_habitual_config_provider.dart` → al cambiar config, llamar `pushNextBus()`.
- `lib/shared/providers/user_favorites_provider.dart` → al cambiar stops favs, llamar `pushMyStops()`.

#### T1.5 — Background callback Dart
```dart
@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  if (uri?.host == 'updatewidget') {
    final container = ProviderContainer();
    await container.read(widgetDataSyncServiceProvider).pushAll();
    container.dispose();
  }
}
```
Registrarlo en `main.dart` con `HomeWidget.registerBackgroundCallback(backgroundCallback)`.

#### T1.6 — Test
- Smoke widget test: forzar `pushNextBus()`, leer `HomeWidget.getWidgetData()`, verificar JSON.
- Manual: con la app abierta, configurar viaje habitual, abrir DevTools de Android `adb shell run-as com.transitly.transitly cat /data/data/com.transitly.transitly/shared_prefs/HomeWidgetPreferences.xml` y confirmar que `next_bus_v1` está poblado.

**Entregable:** la app guarda datos correctamente; aún no se ve nada en el launcher.

---

### Wave 2 — Widget A "Próximo bus" Android (5 h)

**Objetivo:** el primer widget visible y funcional en el launcher.

#### T2.1 — Layout XML
`android/app/src/main/res/layout/widget_next_bus.xml` con la estructura visual del diseño.

Componentes:
- `LinearLayout` horizontal raíz con `android:background="@drawable/widget_bg"`.
- Badge cuadrado: `TextView` con `android:textStyle="bold"` y `android:background="@drawable/badge_bg"`.
- Centro: `LinearLayout` vertical con `headsign` y `time + stopName`.
- `widget_bg.xml` y `badge_bg.xml` en `res/drawable/`: rectángulos redondeados con color de fondo y bordes basados en `accent`.

#### T2.2 — Provider Kotlin
`android/app/src/main/kotlin/com/transitly/transitly/widgets/NextBusWidgetProvider.kt`:
```kotlin
class NextBusWidgetProvider : HomeWidgetProvider() {
  override fun onUpdate(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetIds: IntArray,
    widgetData: SharedPreferences,
  ) {
    appWidgetIds.forEach { widgetId ->
      val views = RemoteViews(context.packageName, R.layout.widget_next_bus)
      val json = widgetData.getString("next_bus_v1", null)
      if (json == null) {
        views.setTextViewText(R.id.headsign, context.getString(R.string.widget_configure_cta))
        views.setViewVisibility(R.id.time, View.GONE)
      } else {
        val data = JSONObject(json)
        views.setTextViewText(R.id.route_code, data.getString("routeCode"))
        views.setTextViewText(R.id.headsign, data.getString("headsign"))
        views.setTextViewText(R.id.stop_name, data.getString("stopName"))
        val arrivals = data.getJSONArray("arrivals")
        val firstArrival = arrivals.getInt(0)
        views.setTextViewText(R.id.time, "$firstArrival min")
        // tint badge con accent
        val accent = widgetData.getString("accent_hex", "#977DDF")!!
        views.setInt(R.id.badge_bg, "setColorFilter", Color.parseColor(accent))
      }
      // Pending intent al tap
      val intent = HomeWidgetLaunchIntent.getActivity(
        context, MainActivity::class.java, Uri.parse("transitly://route/${data?.getString("routeId")}"),
      )
      views.setOnClickPendingIntent(R.id.root, intent)
      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }
}
```

#### T2.3 — Configuración del provider
`android/app/src/main/res/xml/widget_next_bus_info.xml`:
```xml
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
  android:minWidth="250dp" android:minHeight="80dp"
  android:targetCellWidth="4" android:targetCellHeight="1"
  android:updatePeriodMillis="900000"  <!-- 15 min, mínimo Android -->
  android:initialLayout="@layout/widget_next_bus"
  android:previewImage="@drawable/widget_next_bus_preview"
  android:resizeMode="horizontal"
  android:widgetCategory="home_screen" />
```

#### T2.4 — Registro en `AndroidManifest.xml`
```xml
<receiver android:name=".widgets.NextBusWidgetProvider"
  android:exported="false">
  <intent-filter>
    <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
  </intent-filter>
  <meta-data android:name="android.appwidget.provider"
    android:resource="@xml/widget_next_bus_info" />
</receiver>
```

#### T2.5 — Deep link handling en `MainActivity`
Cuando el usuario toca el widget, debe abrir directamente la pantalla relevante:
- `transitly://route/{routeId}` → `/route/{id}` en GoRouter.
- `transitly://configure-habitual` → abre `showHabitualConfigSheet()`.

Implementar en `MainActivity.onNewIntent()` parsing del `data.toString()` y pasarlo a Flutter vía `MethodChannel`.

#### T2.6 — Strings
`res/values/strings.xml`:
```xml
<string name="widget_next_bus_label">Próximo bus</string>
<string name="widget_configure_cta">Toca para configurar →</string>
<string name="widget_no_service">Sin servicio ahora</string>
```
`res/values-en/strings.xml` y `res/values-ar/strings.xml` con traducciones.

#### T2.7 — Preview en el picker
`res/drawable/widget_next_bus_preview.png` (PNG estático del aspecto, ~250×80px). Se usa cuando el usuario añade widgets desde el launcher.

#### T2.8 — Test manual
- Build, install, añadir widget desde el launcher.
- Verificar: muestra "Toca para configurar →" si no hay viaje habitual.
- Configurar viaje en la app, cerrar app. El widget debe actualizarse en < 30 s.
- Tap en el widget → abre la app en la ruta correcta.

**Entregable:** widget de "Próximo bus" funcional en el launcher.

---

### Wave 3 — Widget B "Mis paradas" Android (4 h)

Estructura idéntica a Wave 2, pero con un `RemoteViews` más complejo (cuatro filas dinámicas) y refresh ligeramente distinto (90 s en vez de 60 s).

Diferencias clave respecto a Wave 2:
- Layout `widget_my_stops.xml` con un `LinearLayout` vertical de 4 filas + cabecera.
- Cada fila se rellena programáticamente desde `my_stops_v1` JSON.
- Si hay < 4 paradas favoritas, se ocultan las filas vacías con `View.GONE`.
- Si hay 0 paradas favoritas, el widget muestra un CTA "Añade paradas favoritas desde el mapa →".

Provider Kotlin: `MyStopsWidgetProvider.kt`.

**Entregable:** widget de paradas favoritas funcional.

---

### Wave 4 — Widget C "Saldo NFC" Android (2 h)

Más simple que A y B. Sin refresh periódico, solo on-demand desde la app cuando se escanea una tarjeta.

Layout: vertical, 3 líneas (label, balance, timestamp relativo).

Provider Kotlin: `NfcBalanceWidgetProvider.kt`.

Edge cases:
- Si nunca se ha escaneado tarjeta → "Escanea tu bonobús con NFC".
- Si la última lectura es > 30 días → mostrar advertencia.

**Entregable:** widget de saldo NFC funcional.

---

### Wave 5 — Refresh adaptativo "más eficiente" (4 h) — REVISADO

**Objetivo:** los widgets se mantienen al día con el mínimo posible de wake-ups. **SIN AlarmManager** (decisión del usuario "más eficiente").

#### T5.1 — Dependencias
- `pubspec.yaml`: `workmanager: ^0.5.2`.
- `android/app/build.gradle.kts`: `implementation("androidx.work:work-runtime-ktx:2.9.0")`.

#### T5.2 — `WidgetRefreshWorker.kt` — worker periódico
```kotlin
class WidgetRefreshWorker(ctx: Context, params: WorkerParameters) :
  CoroutineWorker(ctx, params) {
  override suspend fun doWork(): Result {
    if (!hasAnyWidgetPlaced(applicationContext)) {
      cancelAllWidgetWorkers(applicationContext)
      return Result.success()
    }
    // Llama al callback Dart vía HomeWidget plugin
    HomeWidget.backgroundCallback(applicationContext)?.invoke(
      Uri.parse("transitly://refresh-widgets")
    )
    return Result.success()
  }
}
```

Constraints:
```kotlin
Constraints.Builder()
  .setRequiredNetworkType(NetworkType.CONNECTED)
  .setRequiresBatteryNotLow(true)
  .build()
```

#### T5.3 — `WidgetOneShotScheduler.kt` — wake-up dirigido
```kotlin
object WidgetOneShotScheduler {
  fun scheduleNextRefresh(ctx: Context, etaMinutes: Int) {
    if (etaMinutes <= 0 || etaMinutes > 12) return  // fuera de ventana
    val delaySec = max(60L, ((etaMinutes - 1.5) * 60).toLong())
    val req = OneTimeWorkRequestBuilder<WidgetRefreshWorker>()
      .setInitialDelay(delaySec, TimeUnit.SECONDS)
      .setConstraints(Constraints.Builder()
        .setRequiredNetworkType(NetworkType.CONNECTED)
        .build())
      .build()
    WorkManager.getInstance(ctx)
      .enqueueUniqueWork("widget_one_shot", ExistingWorkPolicy.REPLACE, req)
  }
}
```

Esto se llama desde Dart después de cada refresh exitoso: si la próxima llegada es a `T = 8 min`, programa un wake-up a `T - 1.5 min = 6.5 min`. Un solo wake-up dirigido, no polling.

#### T5.4 — Lifecycle hooks de los widgets
- `onEnabled(context)` del primer widget añadido:
  - Programa el `PeriodicWorkRequest` cada 15 min con `KEEP` policy (no duplica).
  - Marca `is_widget_active = true` en SharedPreferences.
- `onDisabled(context)` del último widget retirado:
  - Cancela TODOS los workers (`cancelUniqueWork("widget_periodic")` y `cancelUniqueWork("widget_one_shot")`).
  - Marca `is_widget_active = false`.
  - **Resultado: 0 wake-ups si el usuario no usa widgets.**

#### T5.5 — Debounce en Dart
```dart
class _RefreshDebouncer {
  Timer? _timer;
  void schedule(Future<void> Function() task) {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 5), task);
  }
}
```
Usado en `WidgetDataSyncService.refreshWidgets()` para colapsar bursts.

#### T5.6 — Cache de 90 s a nivel Supabase RPC
Ya implementado en `ArrivalsRepository` (Wave 0.5). El worker que se ejecuta dos veces seguidas no llamará a Supabase la segunda; servirá cache.

#### T5.7 — Tabla de eficiencia esperada

Smoke benchmark a documentar tras la implementación: dejar el móvil 8 h con la app cerrada y los 3 widgets colocados, contar wake-ups con `adb shell dumpsys jobscheduler`.

Objetivos:
- Sin widgets colocados: 0 wake-ups.
- 1 widget A configurado, sin viaje activo nocturno: ≤ 4 wake-ups (uno por cada periodic worker dentro de su ventana operativa).
- 3 widgets en horario punta (07:00-09:00, 18:00-20:00): ≤ 12 wake-ups en esa franja.

**Entregable:** widgets always-fresh con un coste de batería medible y mínimo.

---

### Wave 6 — Theming dinámico (2 h)

**Objetivo:** los widgets reflejan la paleta personalizada que el usuario eligió en la app.

Tareas:
- `WidgetDataSyncService.pushTheme()` ya guarda los hex codes en `theme_v1` (Wave 1).
- Cada Provider Kotlin lee los hex y aplica `setColorFilter` / `setBackgroundColor` a las views relevantes en `onUpdate()`.
- Al cambiar paleta en la app, `themeNotifier` llama `pushTheme()` + `refreshWidgets()`.

**Edge case:** modo claro/oscuro. El widget debe respetar el scheme actual de la app. Si el sistema cambia de modo mientras la app está cerrada, el widget mantiene el último scheme guardado (no es perfecto, pero es lo aceptable).

**Entregable:** widgets que cambian de color cuando el usuario cambia paleta.

---

### Wave 7 — Polishing y QA (3 h)

- Iconos previews: 3 PNGs en `res/drawable-xxhdpi/widget_*_preview.png` para que el picker del launcher se vea bonito.
- Strings finales en `es`, `en`, `ar` revisados.
- Verificar en 3 launchers distintos:
  - Pixel Launcher (stock)
  - Nova Launcher
  - One UI (Samsung)
- Verificar en Android 13 y Android 14 (políticas de notificaciones y permisos cambiaron).
- Verificar en modo ahorro de batería: WorkManager respeta Doze; los widgets se actualizarán menos frecuentemente pero no quedarán colgados.

---

## 6. Archivos a crear/modificar

### Nuevos (Flutter)
- `lib/shared/widgets_android/widget_data_sync_service.dart`
- `lib/shared/widgets_android/widget_background_callback.dart`
- `test/shared/widgets_android/widget_data_sync_service_test.dart`

### Modificados (Flutter)
- `pubspec.yaml` (+ `home_widget`, `workmanager`)
- `lib/main.dart` (registro de callback + push inicial)
- `lib/app.dart` (lifecycle observer)
- `lib/data/nfc/nfc_balance_repository.dart` (hook post-scan)
- `lib/shared/providers/home_habitual_config_provider.dart` (hook post-save)
- `lib/shared/providers/user_favorites_provider.dart` (hook post-toggle)
- `lib/shared/providers/theme_notifier.dart` (hook post-palette-change)
- `lib/l10n/app_es.arb`, `app_en.arb`, `app_ar.arb` (claves nuevas)

### Nuevos (Android nativo)
- `android/app/src/main/kotlin/com/transitly/transitly/widgets/NextBusWidgetProvider.kt`
- `android/app/src/main/kotlin/com/transitly/transitly/widgets/MyStopsWidgetProvider.kt`
- `android/app/src/main/kotlin/com/transitly/transitly/widgets/NfcBalanceWidgetProvider.kt`
- `android/app/src/main/kotlin/com/transitly/transitly/widgets/WidgetRefreshWorker.kt`
- `android/app/src/main/res/layout/widget_next_bus.xml`
- `android/app/src/main/res/layout/widget_my_stops.xml`
- `android/app/src/main/res/layout/widget_nfc_balance.xml`
- `android/app/src/main/res/xml/widget_next_bus_info.xml`
- `android/app/src/main/res/xml/widget_my_stops_info.xml`
- `android/app/src/main/res/xml/widget_nfc_balance_info.xml`
- `android/app/src/main/res/drawable/widget_bg.xml`, `badge_bg.xml`
- `android/app/src/main/res/drawable-xxhdpi/widget_*_preview.png` (3 PNGs)
- `android/app/src/main/res/values/strings.xml` (claves widget_*)
- `android/app/src/main/res/values-en/strings.xml`
- `android/app/src/main/res/values-ar/strings.xml`

### Modificados (Android nativo)
- `android/app/src/main/AndroidManifest.xml` (3 `<receiver>` + permisos)
- `android/app/build.gradle.kts` (+ workmanager)
- `android/app/src/main/kotlin/.../MainActivity.kt` (deep link handler)

---

## 7. Decisiones clave — CONFIRMADAS por el usuario (2026-06-01)

| Decisión | **Elegido** | Justificación |
|----------|-------------|---------------|
| Plugin | **`home_widget ^0.7.0`** | Maduro, estable, soporta WorkManager bien |
| Plataformas | **Solo Android** (iOS fuera de scope) | Decisión del usuario; ahorra ~12 h |
| Tamaños | **3 widgets independientes** (A, B, C) | Decisión del usuario; mejor UX en el picker, cada uno con su lifecycle |
| Datos | **REALES**, no mock | Decisión del usuario. Implica nueva capa Supabase (ver sección 4.4 actualizada) |
| Refresh | **Estrategia híbrida adaptativa "más eficiente"** | Decisión del usuario. Detalle en sección 4.3 actualizada |
| Idioma | Sistema | Default razonable (Android no permite cambiarlo desde la app sin recrearlo) |
| Theming | Dinámico desde paleta | Coherencia con la app |
| Preview | PNGs estáticos | Compatible con Android 7+ (los XML preview son solo 12+) |

---

## 8. Riesgos identificados

- **R1: SharedPreferences corruptas tras update de la app.** Si cambiamos el schema de un JSON (`next_bus_v1` → `next_bus_v2`), los widgets viejos crashearán. **Mitigación:** versionar las claves y leer con try/catch en el provider Kotlin.
- **R2: Refresh no funciona en Xiaomi/Huawei con MIUI/EMUI.** Esos launchers matan WorkManager agresivamente. **Mitigación:** documentar en el README cómo añadir Transitly a la whitelist de batería.
- **R3: Bridge Flutter↔nativo se rompe en Flutter major version bump.** `home_widget` ha tenido breaking changes históricamente. **Mitigación:** fijar la versión en pubspec y tener tests de integración.
- **R4: Deep links no abren la pantalla correcta si la app ya estaba abierta.** GoRouter en estados específicos puede ignorar el `Uri`. **Mitigación:** documentar bien en `MainActivity.onNewIntent()` y testear todos los caminos.
- **R5: NFC widget muestra datos viejos.** Si la última lectura fue hace meses, el saldo es irrelevante. **Mitigación:** mostrar advertencia "Saldo desactualizado" si `scannedAt > 30 días`.
- **R6: Doble refresh accidental.** Si el callback se dispara desde la app + WorkManager simultáneamente, doble update. **Mitigación:** debounce de 5 s en `WidgetDataSyncService.refreshWidgets()`.

---

## 9. Estimación de tiempo — revisada con decisiones del usuario

| Wave | Tiempo estimado | Acumulado | Cambio respecto al plan original |
|------|-----------------|-----------|-----------------------------------|
| Wave 0 — Auditoría | 0.5 h | 0.5 h | — |
| **Wave 0.5 — Backend Supabase para datos reales** | **5 h** | **5.5 h** | **NUEVA por "datos reales"** |
| Wave 1 — Plumbing Flutter | 4 h | 9.5 h | conecta al repo Supabase, no mock |
| Wave 2 — Widget A | 5 h | 14.5 h | — |
| Wave 3 — Widget B | 4 h | 18.5 h | — |
| Wave 4 — Widget C | 2 h | 20.5 h | — |
| Wave 5 — Refresh adaptativo | **4 h** | **24.5 h** | **+1 h por estrategia híbrida + one-shot dirigido** |
| Wave 6 — Theming dinámico | 2 h | 26.5 h | — |
| Wave 7 — Polishing + QA | 3 h | 29.5 h | — |
| **Total** | **~30 h** | | +6 h vs plan original (datos reales + refresh adaptativo) |

A repartir en **5-6 sesiones** de 5-6 h cada una. Build APK al final de cada wave para test en dispositivo real.

### Ruta crítica recomendada

```
Wave 0 (auditoría)
  └─→ Wave 0.5 (Supabase) ────┐
                              ├─→ Wave 1 (Flutter) ──┐
  (paralelizable solo si      │                      │
   trabajaras con un Backend  │                      ├─→ Wave 2 (Widget A) ──┐
   y un Mobile en simultáneo) │                      │                      ├─→ Wave 5 (WorkManager)
                              │                      ├─→ Wave 3 (Widget B) ──┤
                              │                      │                      │
                              │                      └─→ Wave 4 (Widget C) ──┘
                              │                                              │
                              │                                              └─→ Wave 6 (theming)
                              │                                                  │
                              │                                                  └─→ Wave 7 (QA)
                              └────────────────── tests integración ─────────────┘
```

### Si quieres atajar (entrega mínima viable)

Solo **Widget A "Próximo bus"** con datos reales y refresh adaptativo:
- Wave 0 + 0.5 + 1 + 2 + 5 (sin Widget B ni C) + 6 + 7
- Total: **~22 h**
- Pierdes: paradas favoritas como widget y saldo NFC como widget.
- Ganas: tiempo y entrega rápida del caso de uso principal.

---

## 10. Criterios de aceptación (smoke test final)

Cuando todo el plan esté completo, estos casos deben pasar manualmente:

1. **Instalación fresca:** instalo APK, añado los 3 widgets al launcher. Los 3 muestran sus respectivos CTAs "configura" porque aún no hay datos.
2. **Configurar viaje habitual:** abro app → home → tarjeta "Configurar". Elijo línea + parada. Vuelvo al launcher. **El widget A muestra el próximo bus en < 30 s.**
3. **Añadir paradas favoritas:** desde el mapa, marco 3 paradas con estrella. Cierro app. **El widget B muestra las 3 paradas con sus próximas salidas.**
4. **Escanear NFC:** abro app → pestaña Tarjeta → escaneo bono. Cierro app. **El widget C muestra el saldo y "Actualizado: ahora".**
5. **Cambiar paleta:** abro app → Apariencia → cambio a paleta Sunrise. Cierro app. **Los 3 widgets cambian a colores naranjas/cálidos en < 10 s.**
6. **Refresh sin abrir app:** dejo el móvil 30 min sin tocar la app. **Los widgets A y B se actualizan al menos una vez** (mirar el contador de minutos).
7. **Tap navegación:** toco widget A → app abre directamente en detalle de la línea. Toco widget B fila 2 → abre detalle de la parada. Toco widget C → abre pestaña Tarjeta.
8. **Modo claro:** cambio a tema claro en la app. **Widgets cambian a fondo claro y texto oscuro.**
9. **Idioma:** cambio sistema a inglés. **Labels estáticos del widget cambian a "Next bus", "My stops", "NFC balance".**
10. **Quitar y volver a añadir widget:** elimino widget A del launcher. Lo vuelvo a añadir. **Muestra el mismo viaje habitual sin re-configurar.**

---

## 11. Notas de auditoría (a rellenar en Wave 0)

> *Esta sección se completa cuando se ejecute Wave 0. Si lo del provider stub existe ya con datos, podemos saltar a Wave 2 directamente.*

- [ ] `widget_data_sync_provider.dart` existe / es stub / es funcional
- [ ] `home_widget` ya en pubspec.yaml: sí/no, versión
- [ ] `minSdkVersion` actual: __
- [ ] `AndroidManifest.xml` tiene receivers de widget: sí/no
- [ ] Tests existentes relacionados: __

---

## 12. Próximos pasos

**Decisiones del usuario confirmadas (2026-06-01):**
- ✅ Solo Android (iOS fuera de scope)
- ✅ 3 widgets independientes (A, B, C)
- ✅ Datos REALES (introduce Wave 0.5 con backend Supabase)
- ✅ Refresh "más eficiente" (estrategia híbrida sin AlarmManager)

**Camino de ejecución acordado:**

1. **Wave 0 — Auditoría** (siguiente sesión, 30 min, sin código). Rellenar la sección 11 con hallazgos.
2. **Wave 0.5 — Backend Supabase** (siguiente sesión larga, 5 h). Migration + RPCs + cache repo.
3. **Wave 1 — Plumbing Flutter** (sesión 3, 4 h). Service + lifecycle hooks + tests.
4. **Wave 2 — Widget A** (sesión 4, 5 h). Primer widget visible.
5. **Wave 3 + Wave 4 — Widgets B y C** (sesión 5, 6 h).
6. **Wave 5 — Refresh adaptativo** (sesión 6, 4 h).
7. **Wave 6 + 7 — Theming + Polish** (sesión 7, 5 h). Build release y entrega.

**Sesiones estimadas:** 5-6 (~6h cada una).

Cuando quieras empezar, dime **"arranca Wave 0"** y hago la auditoría. Si prefieres saltar directo a **"arranca Wave 0.5"** porque ya confirmas que el provider stub está vacío, también.

---

## Changelog del plan

- **2026-06-01 14:30** — Plan inicial creado con 7 waves y 8 decisiones abiertas. Estimación: 24 h.
- **2026-06-01 16:45** — Decisiones del usuario aplicadas:
  - Plataforma: solo Android.
  - 3 widgets independientes.
  - Datos reales → añadida **Wave 0.5** con backend Supabase (+5 h).
  - Refresh "más eficiente" → reescrita **sección 4.3** y **Wave 5** con estrategia híbrida adaptativa sin AlarmManager (+1 h).
  - Nueva estimación total: **30 h**.
