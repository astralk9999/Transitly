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
2. Un `Workmanager` periodic task (cada 15 min) consulta la API y llama a
   `WidgetDataWriter.writeNextBus()` / `writeMyLineStatus()`.
3. Los datos se persisten en `SharedPreferences`.
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
