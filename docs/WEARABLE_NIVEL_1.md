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
