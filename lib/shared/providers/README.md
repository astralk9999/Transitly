# Providers

Estado global/compartido vive aquí. Regla de convivencia con `setState`:

| Tipo de estado                                                          | Dónde va                                      |
| ----------------------------------------------------------------------- | --------------------------------------------- |
| Dominio (usuario, tema, datos NFC, lookups derivados de `mockData`)     | **Riverpod** (provider en esta carpeta)       |
| UI efímero local al widget (controllers de texto, focus, flags de animación, página actual del PageView) | **`setState` / `StatefulWidget`**             |
| Controllers que coordinan un flujo de pantalla (p.ej. editor de rutas) | **`ChangeNotifier` local** al screen (p.ej. `RouteEditorController`, `LiveRecorderController`) |

## Archivos

- `theme_provider.dart` — `themeModeProvider` (light/dark/system).
- `is_dark_provider.dart` — helper `isDarkMode(ref, context)` que resuelve `themeModeProvider` + `MediaQuery.platformBrightness` a un booleano efectivo. **Usar siempre** en vez de duplicar la condición en cada pantalla.
- `user_provider.dart` — usuario actual (perfil pasajero vs. conductor según `isDriverModeProvider`).
- `nfc_provider.dart` — servicio + state notifier del escáner NFC.
- `route_lookup_providers.dart` — índices O(1) derivados de `mockData` (transfers por parada, etc.).

## Al crear un provider nuevo

1. Si deriva de otro, usa un `Provider` puro (no `StateProvider`). Los cálculos caros van detrás de un provider memoizado (ejemplo: `mapDataCacheProvider` en `features/map/`).
2. No metas estado UI efímero aquí. Si te cuesta decidir, pregúntate: "¿otra pantalla necesita este valor?" Si no, es local.
3. Los tests viven en `test/shared/providers/` con el mismo nombre.
