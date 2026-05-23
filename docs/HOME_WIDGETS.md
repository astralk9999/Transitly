# Home Widgets — Contrato JSON

Transitly expone datos para widgets nativos (Android/iOS) mediante
`SharedPreferences`. El `WidgetDataWriter` (`lib/data/widgets_native/`) escribe
los datos; la app nativa (Kotlin/SwiftUI) los lee y renderiza el widget.

---

## 1. Próximo bus (`next_bus_<routeCode>`)

Clave: `next_bus_<routeCode>` (ej. `next_bus_L1`)

```json
{
  "stopName": "Plaza del Caballo",
  "routeCode": "L1",
  "etaMinutes": 8,
  "source": "driver",
  "updatedAt": "2026-05-15T10:23:00.000Z"
}
```

| Campo        | Tipo     | Descripción                                  |
|-------------|----------|----------------------------------------------|
| `stopName`   | String   | Nombre de la parada                          |
| `routeCode`  | String   | Código de la ruta (ej. L1, M2, C3)          |
| `etaMinutes` | int      | Minutos estimados hasta la llegada           |
| `source`     | String   | Origen del dato: `driver`, `official`, `estimated` |
| `updatedAt`  | ISO 8601 | Momento de la última actualización           |

---

## 2. Estado de línea (`line_status_<routeCode>`)

Clave: `line_status_<routeCode>` (ej. `line_status_M2`)

```json
{
  "routeCode": "M2",
  "upcoming": [
    {"stopName": "Plaza del Caballo", "etaMinutes": 5},
    {"stopName": "Estación FFCC",     "etaMinutes": 14},
    {"stopName": "Hospital",          "etaMinutes": 22}
  ],
  "updatedAt": "2026-05-15T10:23:00.000Z"
}
```

| Campo       | Tipo     | Descripción                              |
|------------|----------|------------------------------------------|
| `routeCode` | String   | Código de la ruta                        |
| `upcoming`  | Array    | Próximas paradas con `stopName` y `etaMinutes` |
| `updatedAt` | ISO 8601 | Momento de la última actualización       |

---

## 3. Configuración de widget

Claves en `SharedPreferences` (gestionadas por la pantalla de ajustes):

| Clave               | Tipo   | Descripción                |
|--------------------|--------|----------------------------|
| `widget_fav_stop`  | String | Nombre de la parada favorita |
| `widget_fav_line`  | String | Código de la línea favorita  |

---

## 4. Flujo de actualización

1. El usuario configura parada/línea favorita en **Perfil → Widgets**.
2. **[Trabajo futuro]** un refresco periódico en segundo plano (cada ~15 min)
   consultaría la API y llamaría a `WidgetDataWriter.writeNextBus()` /
   `writeMyLineStatus()`. **No implementado**: la dependencia `workmanager`
   se eliminó (la 0.5.2 usaba la API v1-embedding removida en Flutter 3.x y
   rompía el build de release; nunca llegó a cablearse en Dart). El refresco
   futuro debe usar `workmanager` ≥0.9 o el callback de fondo de
   `home_widget`.
3. Hoy los datos se persisten en `SharedPreferences` al configurar el widget.
4. El widget nativo lee `SharedPreferences` (Android) o `UserDefaults` con
   App Group (iOS) y se renderiza.
5. Opcionalmente, `HomeWidget.updateWidget()` fuerza el refresco del widget
   desde Dart.

---

## 5. Notas para implementación nativa

- **Android:** Leer `SharedPreferences` con el mismo `package` de la app
  Flutter. El widget usa `RemoteViews` y se actualiza con `AppWidgetManager`.
- **iOS:** Configurar un **App Group** compartido entre la app y el widget
  extension. Usar `UserDefaults(suiteName:)` con el suite del App Group.
- Las claves y el formato JSON son estables. No cambiar sin migrar.

---

## Decisión arquitectónica

# Home Widgets Decision

## Status: NOT implementing native home widgets

### Rationale
- workmanager was removed (broke APK build, API v1-embedding removed in Flutter 3.x)
- Maintenance burden vs value
- Push notifications provide better real-time updates

### Alternatives considered
- home_widget package: requires periodic background refresh
- FCM data-only notifications: already implemented

---

## Wearable (Nivel 1)

# Wearable Nivel 1 — Apple Watch + Wear OS

> Documentación para complications (watchOS) y tiles (Wear OS) en Transitly.
> Nivel 1 = integración nativa con widgets/tiles/complications leyendo del
> storage compartido App Group / DataStore.

---

## watchOS Complications

### Complication families

| Family | Descripción | Ejemplo Transitly |
|--------|-------------|-------------------|
| `.accessoryCircular` | Esfera circular pequeña | "🚌 L1 5'" (ícono + código + ETA) |
| `.accessoryRectangular` | Barra rectangular ancha | "L1 → Plaza del Caballo · 5 min" |
| `.accessoryInline` | Línea de texto en esfera | "L1 5' · M2 14'" |

### TimelineProvider

```swift
struct TransitlyComplication: TimelineEntry {
    let date: Date
    let routeCode: String
    let stopName: String
    let etaMinutes: Int
}

struct Provider: TimelineProvider {
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let defaults = UserDefaults(suiteName: "group.com.transitly.app")!
        let json = defaults.string(forKey: "next_bus_L1") ?? "{}"
        let data = json.data(using: .utf8)!
        let dict = try! JSONSerialization.jsonObject(with: data) as! [String: Any]

        let entry = TransitlyComplication(
            date: Date(),
            routeCode: dict["routeCode"] as? String ?? "L1",
            stopName: dict["stopName"] as? String ?? "...",
            etaMinutes: dict["etaMinutes"] as? Int ?? 0
        )

        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15 * 60)))
        completion(timeline)
    }
}
```

### Refresh

Gestionado por **WidgetKit**. El sistema decide la frecuencia según batería
y uso. No se puede forzar refresh manual desde la app sin
`WatchConnectivity` (no implementado en Nivel 1).

---

## Wear OS Tiles

### TileService

```kotlin
@Serializable
data class NextBusData(
    val stopName: String,
    val routeCode: String,
    val etaMinutes: Int,
    val updatedAt: String
)

class TransitlyTileService : TileService() {
    override fun onTileResourcesRequest(requestParams: ResourcesRequest): ListenableFuture<Resources> {
        return Futures.immediateFuture(Resources.Builder().build())
    }

    override fun onTileRequest(requestParams: TileRequest): ListenableFuture<Tile> {
        val data = readFromDataStore()
        return Futures.immediateFuture(
            Tile.Builder()
                .setResourcesVersion("1")
                .setFreshnessIntervalMillis(5 * 60 * 1000) // 5 min
                .setTileLayout(
                    Text.Builder()
                        .setText("${data.routeCode} → ${data.stopName} · ${data.etaMinutes} min")
                        .build()
                )
                .build()
        )
    }
}
```

### Refresh con WorkManager

```kotlin
class TileRefreshWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result {
        // Lee SharedPreferences del App Group Android
        val prefs = applicationContext.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val json = prefs.getString("flutter.next_bus_L1", "{}")

        // Parsea y escribe en DataStore para el Tile
        val data = Json.decodeFromString<NextBusData>(json!!)
        val dataStore = DataStore.getInstance(applicationContext)
        dataStore.put("next_bus", Json.encodeToString(data))

        TileService.getUpdater(applicationContext).requestUpdate(TransitlyTileService::class.java)
        return Result.success()
    }
}

// Programar en AndroidManifest o desde la app Flutter
val request = PeriodicWorkRequestBuilder<TileRefreshWorker>(15, TimeUnit.MINUTES).build()
WorkManager.getInstance(context).enqueueUniquePeriodicWork(
    "tile_refresh", ExistingPeriodicWorkPolicy.KEEP, request
)
```

### Activity de configuración

```kotlin
class TileConfigActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            ScalingLazyColumn {
                items(stops) { stop ->
                    Chip(
                        onClick = {
                            // Guardar parada favorita en DataStore
                            dataStore.put("fav_stop", stop.name)
                            TileService.getUpdater(this).requestUpdate(TransitlyTileService::class.java)
                            finish()
                        },
                        label = { Text(stop.name) }
                    )
                }
            }
        }
    }
}
```

---

## Arquitectura de datos compartidos

### Diagrama de flujo

```
┌──────────────────────────────────────────────────────────────┐
│                    FLUTTER APP (Dart)                        │
│                                                              │
│  Workmanager (15 min)                                        │
│       │                                                      │
│       ▼                                                      │
│  WidgetDataWriter (lib/data/widgets_native/)                 │
│       │                                                      │
│       │  writeNextBus() / writeMyLineStatus()                │
│       ▼                                                      │
│  SharedPreferences                                          │
└──────────────┬───────────────────────────────────────────────┘
               │
               │  App Group / DataStore
               │
     ┌─────────┴─────────┐
     │                   │
     ▼                   ▼
┌─────────────┐   ┌──────────────┐
│    iOS      │   │   Android    │
│             │   │              │
│ UserDefaults│   │ DataStore /  │
│ (suiteName) │   │ SharedPrefs  │
│      │      │   │      │       │
│      ▼      │   │      ▼       │
│  WidgetKit  │   │  TileService │
│ Complication│   │     Tile     │
└─────────────┘   └──────────────┘
```

### Contrato JSON

El contrato es el mismo definido en `docs/HOME_WIDGETS.md`:

- **Android:** `SharedPreferences` con clave `flutter.<key>` (prefijo automático de Flutter).
  El `TileService` lee del mismo `SharedPreferences` compartido.
- **iOS:** `UserDefaults(suiteName:)` con el App Group `group.com.transitly.app`.
  Complication y widget leen el mismo suite.
- **Wear OS DataStore:** capa intermedia que el `WorkManager` refresca cada 15 min
  leyendo de `SharedPreferences`.

### Claves usadas por wearables

| Clave | Contenido | Dónde se escribe | Quién lee |
|-------|-----------|------------------|-----------|
| `next_bus_<routeCode>` | JSON con stopName, routeCode, etaMinutes | WidgetDataWriter (Flutter) | Complication / Tile |
| `widget_fav_stop` | String con nombre de parada favorita | Pantalla de ajustes (Flutter) | Tile config |
| `widget_fav_line` | String con código de ruta favorita | Pantalla de ajustes (Flutter) | Complication selector |

---

## Limitaciones

| Limitación | Detalle |
|------------|---------|
| **Xcode + macOS** | watchOS complications requieren Xcode en macOS para compilar el Watch App target. Sin Mac no es posible. |
| **Dispositivo físico** | Las complications y tiles requieren Apple Watch / Wear OS físico para probar. Los simuladores no renderizan complications en esferas reales. |
| **WatchConnectivity** | No implementado en Nivel 1. El refresco entre app y complication no es inmediato (WidgetKit decide el timeline). |
| **Wear OS standalone** | El Tile depende de que el WorkManager del teléfono refresque el DataStore. Sin teléfono emparejado, el Tile muestra datos stale. |
| **Costes** | MapTiler free tier cubre 100k tiles/mes. Si las complications disparan fetch de mapa, cuidado con el límite. |
| **App Store Review** | Las apps con Watch companion requieren review adicional. Apple rechaza si el Watch app no aporta valor o es un mero placeholder. |

---

## Roadmap de niveles wearable

| Nivel | Descripción | Estado |
|-------|-------------|--------|
| **0** | Notificaciones automáticas vía sistema operativo | ✅ Completado (F21) |
| **1** | Complications (watchOS) + Tiles (Wear OS) con datos de App Group | ✅ Actual (F27) |
| **2** | Acciones interactivas (responder, marcar leído, quick actions) | ⏳ Futuro |
