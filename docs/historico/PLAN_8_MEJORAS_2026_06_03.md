# Plan de acción — 8 mejoras tras auditoría del plan de cierre

**Fecha:** 2026-06-03
**Autor:** Claude Code (Opus 4.7)
**Estado:** propuesto
**Continuación de:** `PLAN_8_ITEMS_CIERRE_2026_06_03.md` (3 commits ejecutados; auditoría detectó 8 puntos mejorables y 1 falso positivo)
**Goal:** Cerrar las grietas del plan anterior — idempotencia del prewarmer, l10n de las pantallas widgets, dedupe + autocomplete, tri-state correcto, nivel zona en el árbol, y G1.bis (preserveAccent extendido a accent secundarios).
**Arquitectura:** 8 cambios aislados en 6 archivos. Todos son refinos del trabajo anterior, no añaden features.
**Stack:** Flutter 3.9.2 + Riverpod + Hive.

---

## 1. Tabla de mejoras

| ID | Mejora | Archivo principal | Tiempo | Severidad |
|----|--------|--------------------|--------|-----------|
| **A1.bis** | TilePrewarmer idempotente | `lib/data/fmtc/tile_prewarmer.dart` | 15 min | Media (desperdicia datos) |
| **C1.bis** | Añadir nivel "Zona" en árbol filtros | `lib/features/map/widgets/zone_company_line_tree.dart` | 30 min | Media (UX coherente) |
| **C2.bis** | Tri-state correcto (sin null en ciclo de tap) | `lib/features/map/widgets/zone_company_line_tree.dart` | 15 min | Alta (UX confusa) |
| **D1.bis** | l10n de las 4 pantallas widgets_config | 4 archivos + 3 `.arb` | 1 h | Alta (i18n broken) |
| **D2.bis** | Dedupe de paradas en config widget | `widget_next_bus_config_screen.dart` | 10 min | Media |
| **D3.bis** | Token tipográfico en preview badge | `widget_next_bus_config_screen.dart` | 5 min | Baja (coherencia) |
| **D4.bis** | Autocomplete línea (no dropdown plano) | `widget_next_bus_config_screen.dart` + `widget_my_line_config_screen.dart` | 30 min | Media |
| **G1.bis** | preserveAccent también en accentBg/accentMuted/borderFocus | `high_contrast_scheme.dart` | 20 min | Media |

Total: **~3 h** en una sesión.

---

## 2. Mejoras detalladas

### A1.bis — TilePrewarmer idempotente (15 min)

**Goal:** evitar que el prewarmer descargue tiles en cada arranque si el store ya está hidratado.

**Archivos:**
- Modify: `lib/data/fmtc/tile_prewarmer.dart`

**Causa actual:** `prewarmOnce()` siempre llama `download.startForeground()`. No verifica el estado del store.

**Steps:**

- [ ] **Paso 1**: Añadir check antes del download:
```dart
static const _minTilesToConsiderWarm = 50;

static Future<void> prewarmOnce() async {
  try {
    const style = 'streets';
    final storeName = FmtcService.storeName(style);
    final store = FMTCStore(storeName);

    final isReady = await store.manage.ready;
    if (!isReady) {
      await store.manage.create();
    }

    // NUEVO: idempotencia. Si el store ya tiene tiles, asumimos
    // que un arranque previo lo hidrató y skip.
    try {
      final stats = await store.stats.toMap();
      final tileCount = stats['tilesAvailable'] as int? ?? 0;
      if (tileCount >= _minTilesToConsiderWarm) {
        AppLogger.info(_logTag, 'skip prewarm: store has $tileCount tiles');
        return;
      }
    } catch (e) {
      AppLogger.warn(_logTag, 'stats check failed, will attempt prewarm', e);
    }

    AppLogger.info(_logTag, 'prewarming Jerez (zoom 13-15)');
    // ... resto igual
  }
}
```

- [ ] **Paso 2**: Smoke test:
  1. `adb shell pm clear com.transitly.transitly`.
  2. Arrancar app. Logs: `prewarming Jerez (zoom 13-15)` → `prewarm done: N tiles`.
  3. Cerrar y arrancar de nuevo. Logs: `skip prewarm: store has N tiles`.

**Criterio**: segundo arranque NO descarga nada.

---

### C1.bis — Nivel Zona en árbol (30 min)

**Goal:** árbol con 3 niveles `Zona → Compañías → Líneas`, no `Operador → Líneas`.

**Archivos:**
- Modify: `lib/features/map/widgets/zone_company_line_tree.dart`

**Causa actual:** el widget itera directamente sobre `operators`. Sin agrupación por zona.

**Steps:**

- [ ] **Paso 1**: Decidir cómo derivar la "Zona" del operador. Opciones:
  - (a) **Recomendada**: agrupar por `operator.region` (campo `OperatorModel` ya existente; si la mayoría son `'Jerez'`, queda una sola sección).
  - (b) Mapear por código postal o coordenadas → más complejo.

- [ ] **Paso 2**: Reescribir `build` con agrupación:
```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  // ... mismas variables locales
  
  // Agrupar operadores por region
  final byZone = <String, List<OperatorModel>>{};
  for (final op in operators) {
    final zone = op.region ?? 'Otras zonas';
    byZone.putIfAbsent(zone, () => []).add(op);
  }
  final zones = byZone.keys.toList()..sort();
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: zones.map((zone) {
      final opsInZone = byZone[zone]!;
      final routesInZone = routes.where(
        (r) => opsInZone.any((op) => op.id == r.operatorId),
      ).toList();
      
      final allDis = routesInZone.every((r) => f.disabledRouteIds.contains(r.id));
      final noneDis = routesInZone.every((r) => !f.disabledRouteIds.contains(r.id));
      
      return ExpansionTile(
        initiallyExpanded: true, // Zona expandida por defecto
        tilePadding: const EdgeInsets.symmetric(horizontal: 4),
        childrenPadding: const EdgeInsets.only(left: 12),
        iconColor: c.accent,
        collapsedIconColor: c.textMid,
        title: Row(
          children: [
            _TriStateCheckbox(
              value: noneDis ? true : (allDis ? false : null),
              c: c,
              onChanged: (v) => ctrl.setRoutesEnabled(
                routesInZone.map((r) => r.id),
                v == true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                zone,
                style: TransitTypography.heading(c.textHi),
              ),
            ),
          ],
        ),
        children: opsInZone.map((op) {
          // Sub-tree de cada operador (lo que ya teníamos)
          return _OperatorSubtree(op: op, ...);
        }).toList(),
      );
    }).toList(),
  );
}
```

- [ ] **Paso 3**: Extraer el sub-tree de operador a un widget privado `_OperatorSubtree` (refactor del actual `ExpansionTile`).

- [ ] **Paso 4**: Smoke test:
  1. Filtros abre con "Jerez" expandida.
  2. Dentro: COMUJESA expandible.
  3. Dentro: 19 líneas con su color.

**Criterio**: 3 niveles claros, scroll mínimo.

---

### C2.bis — Tri-state correcto (15 min)

**Goal:** el ciclo de tap NO debe incluir `null` (indeterminate). El usuario solo elige "todos ON" o "todos OFF".

**Archivos:**
- Modify: `lib/features/map/widgets/zone_company_line_tree.dart:90-122` (`_TriStateCheckbox`)

**Causa actual:** `onTap` en línea ~100 hace `value == true ? false : (value == false ? null : true)`. Eso convierte el estado mixed (null) en `true` y luego entra al ciclo `true → false → null → true`. El estado `null` es solo para MOSTRAR mixed; el usuario nunca debe llegar a null por click.

**Steps:**

- [ ] **Paso 1**: Cambiar lógica de tap a 2 estados:
```dart
class _TriStateCheckbox extends StatelessWidget {
  // ... params iguales

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Tap toggle: si tenemos algo activado (true o mixed null) → desactivar todo.
        // Si está todo desactivado (false) → activar todo.
        // Nunca producimos null por user-action: null es solo visual.
        final next = value == false ? true : false;
        onChanged?.call(next);
      },
      child: Container(
        width: 24, // ← antes 20; subimos para touch target
        height: 24,
        decoration: ...,
        child: value == true
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : value == null
                ? Icon(Icons.remove, size: 14, color: c.textLo) // visual mixed
                : null, // unchecked
      ),
    );
  }
}
```

- [ ] **Paso 2**: Verificar handler en `build` del tree:
```dart
onChanged: (v) => ctrl.setRoutesEnabled(
  opRoutes.map((r) => r.id),
  v == true, // ahora v solo es true o false, nunca null por click
),
```
Eliminar el branch `v == null → activar todas` que era contraintuitivo.

- [ ] **Paso 3**: Smoke test:
  1. Estado mixed (algunas líneas off, otras on).
  2. Tap en checkbox de Zona/Operador → todas pasan a OFF (porque `value` era `null` ≠ `false`, next = `false`).
  3. Tap de nuevo → todas pasan a ON.
  4. Tap individual en una línea desactiva esa sola.

**Criterio**: ciclo claro ON↔OFF; nunca confunde al usuario.

---

### D1.bis — l10n de las 4 pantallas widgets_config (1 h)

**Goal:** sustituir TODOS los strings hardcoded por `l10n.*` en ES/EN/AR.

**Archivos:**
- Modify: `lib/features/widgets_config/widgets_config_screen.dart`
- Modify: `lib/features/widgets_config/widget_next_bus_config_screen.dart`
- Modify: `lib/features/widgets_config/widget_my_line_config_screen.dart`
- Modify: `lib/features/widgets_config/widget_nfc_balance_config_screen.dart`
- Modify: `lib/l10n/app_es.arb`, `app_en.arb`, `app_ar.arb`

**Steps:**

- [ ] **Paso 1**: Añadir 14 claves a los 3 `.arb`. Patrón:

```json
"widgetsConfigTitle": "Widgets",
"widgetsConfigNextBusTitle": "Próximo bus",
"widgetsConfigNextBusDesc": "Muestra la próxima salida de tu parada habitual",
"widgetsConfigMyLineTitle": "Mi línea",
"widgetsConfigMyLineDesc": "Muestra el estado y próximas salidas de tu línea favorita",
"widgetsConfigNfcTitle": "Saldo bonobús",
"widgetsConfigNfcDesc": "Muestra el saldo de tu última lectura NFC",
"widgetsConfigPreviewLabel": "Vista previa",
"widgetsConfigRouteLabel": "Línea",
"widgetsConfigStopLabel": "Parada",
"widgetsConfigTestButton": "Probar widget",
"widgetsConfigSaveButton": "Guardar",
"widgetsConfigSaved": "Configuración guardada",
"widgetsConfigUpdated": "Widget actualizado",
"widgetsConfigUnconfigured": "Configura tu viaje",
"widgetsConfigScanNow": "Escanear tarjeta ahora",
```

Traducciones EN/AR equivalentes.

- [ ] **Paso 2**: En cada pantalla, sustituir:
```dart
// Antes:
title: Text('Próximo bus', style: ...)

// Después:
title: Text(l10n.widgetsConfigNextBusTitle, style: ...)
```

- [ ] **Paso 3**: Regenerar:
```bash
flutter gen-l10n
```

- [ ] **Paso 4**: Smoke test:
  1. App en español: "Próximo bus", "Guardar".
  2. Cambiar a inglés: "Next bus", "Save".
  3. Árabe: "الحافلة التالية", "حفظ".

**Criterio**: 0 strings hardcoded en castellano en `lib/features/widgets_config/`.

---

### D2.bis — Dedupe paradas en config widget (10 min)

**Goal:** el dropdown de paradas no debe mostrar la misma parada 2 veces (ida + vuelta del mismo trayecto).

**Archivos:**
- Modify: `lib/features/widgets_config/widget_next_bus_config_screen.dart:171`

**Causa actual:** llama `mockData.getStopsForRoute(_routeId!)` directo. Igual que en el sheet habitual antes del fix, devuelve outbound+inbound.

**Steps:**

- [ ] **Paso 1**: Copiar el helper desde `habitual_config_sheet.dart` (donde ya existe `_uniqueStopsFor`). Mejor: moverlo a un sitio compartido para reuso:
```dart
// New file: lib/data/mock/mock_data_extensions.dart
import 'mock_data_service.dart';
import '../../shared/models/stop_model.dart';

extension MockDataServiceExt on MockDataService {
  List<StopModel> getUniqueStopsForRoute(String routeId) {
    final seen = <String>{};
    final result = <StopModel>[];
    for (final s in getStopsForRoute(routeId)) {
      if (seen.add(s.id)) result.add(s);
    }
    return result;
  }
}
```

- [ ] **Paso 2**: Refactor `habitual_config_sheet.dart` para usar el extension method también (DRY).

- [ ] **Paso 3**: En `widget_next_bus_config_screen.dart:171`:
```dart
// Antes:
items: mockData
    .getStopsForRoute(_routeId!)
    .map((s) => DropdownMenuItem(...))

// Después:
items: mockData
    .getUniqueStopsForRoute(_routeId!)
    .map((s) => DropdownMenuItem(...))
```

- [ ] **Paso 4**: Smoke test:
  1. Pantalla "Próximo bus widget config".
  2. Elegir L8.
  3. Verificar que "Plaza del Caballo" aparece UNA vez, no dos.

**Criterio**: paradas únicas en dropdown.

---

### D3.bis — Token tipográfico en preview badge (5 min)

**Goal:** eliminar `TextStyle` inline del badge del preview card.

**Archivos:**
- Modify: `lib/features/widgets_config/widget_next_bus_config_screen.dart:241-245`

**Causa actual:** memoria [[feedback-design-tokens]] prohíbe `TextStyle` inline. El badge usa:
```dart
Text(routeCode,
    style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold)),
```

**Steps:**

- [ ] **Paso 1**: Sustituir por token:
```dart
Text(routeCode,
    style: TransitTypography.routeCode(Colors.white)),
```
`TransitTypography.routeCode` ya tiene `fontSize: 18, fontWeight: w700` con IBM Plex Mono (verificado en `transit_typography.dart:43-50`).

- [ ] **Paso 2**: Verificar visualmente que el badge se ve igual o mejor.

**Criterio**: 0 `TextStyle(...)` inline en widgets_config.

---

### D4.bis — Autocomplete línea en config widget (30 min)

**Goal:** sustituir el `DropdownButtonFormField<String>` plano por `Autocomplete<RouteModel>` con buscador, igual que el sheet habitual.

**Archivos:**
- Modify: `lib/features/widgets_config/widget_next_bus_config_screen.dart`
- Modify: `lib/features/widgets_config/widget_my_line_config_screen.dart`

**Causa actual:** dropdown con 19 líneas requiere scroll incómodo.

**Steps:**

- [ ] **Paso 1**: Extraer el patrón `Autocomplete<RouteModel>` del `habitual_config_sheet.dart:80-139` a un widget reusable:
```dart
// New: lib/features/widgets_config/widgets/route_autocomplete.dart
class RouteAutocomplete extends StatelessWidget {
  const RouteAutocomplete({
    super.key,
    required this.routes,
    required this.onSelected,
    required this.label,
    this.initialValue,
  });

  final List<RouteModel> routes;
  final ValueChanged<RouteModel> onSelected;
  final String label;
  final RouteModel? initialValue;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    return Autocomplete<RouteModel>(
      displayStringForOption: (r) => '${r.code} · ${r.name}',
      optionsBuilder: (text) {
        final q = text.text.trim().toLowerCase();
        if (q.isEmpty) return routes;
        return routes.where((r) =>
            r.code.toLowerCase().contains(q) ||
            r.name.toLowerCase().contains(q));
      },
      onSelected: onSelected,
      fieldViewBuilder: (ctx, controller, focusNode, onSubmitted) {
        if (initialValue != null && controller.text.isEmpty) {
          controller.text = '${initialValue!.code} · ${initialValue!.name}';
        }
        return TextField(
          controller: controller,
          focusNode: focusNode,
          style: TransitTypography.bodyPrimary(c.textHi),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TransitTypography.bodySecondary(c.textMid),
            filled: true,
            fillColor: c.bgInput,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            suffixIcon: Icon(Icons.search, color: c.textMid),
          ),
        );
      },
      optionsViewBuilder: (ctx, onSelect, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: c.bgRaised,
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (_, i) {
                  final r = options.elementAt(i);
                  return ListTile(
                    dense: true,
                    title: Text(
                      '${r.code} · ${r.name}',
                      style: TransitTypography.bodyPrimary(c.textHi),
                    ),
                    onTap: () => onSelect(r),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
```

- [ ] **Paso 2**: En `widget_next_bus_config_screen.dart:130-154`, sustituir:
```dart
// Antes:
DropdownButtonFormField<String>(value: _routeId, items: ..., onChanged: ...)

// Después:
RouteAutocomplete(
  routes: routes,
  label: l10n.widgetsConfigRouteLabel,
  initialValue: _routeId != null ? mockData.getRouteById(_routeId!) : null,
  onSelected: (r) {
    setState(() {
      _routeId = r.id;
      _stopId = null;
    });
  },
),
```

- [ ] **Paso 3**: Igual en `widget_my_line_config_screen.dart`.

- [ ] **Paso 4**: Refactor `habitual_config_sheet.dart` para reusar `RouteAutocomplete` (DRY).

- [ ] **Paso 5**: Smoke test:
  1. Pantalla widget "Próximo bus" → escribir "L1" → filtra a L1, L10, L11, L12...
  2. Tap en uno → seleccionado.

**Criterio**: buscador funcional en 3 pantallas (sheet + 2 widgets).

---

### G1.bis — preserveAccent extendido a secundarios (20 min)

**Goal:** cuando `preserveAccent` está on, no solo `accent` sino también `accentBg`, `accentMuted` y `borderFocus` deben derivar del accent del usuario.

**Archivos:**
- Modify: `lib/core/theme/high_contrast_scheme.dart`

**Causa actual:** solo `accent` (línea 29) respeta el flag. Los otros (`accentBg:33`, `accentMuted:35`, `borderFocus:24`) siguen amarillo/azul rígido. Resultado visual: accent naranja pero fondo de chips amarillo claro.

**Steps:**

- [ ] **Paso 1**: Cambiar `accentBg` y `accentMuted` para derivar del accent activo:
```dart
@override
Color get accent => _preserveAccent
    ? _base.accent
    : (_isDark ? const Color(0xFFFFFF00) : const Color(0xFF0000FF));

@override
Color get accentBg => _preserveAccent
    ? _base.accent.withValues(alpha: 0.13)  // 0x22 ≈ 0.13
    : (_isDark ? const Color(0x22FFFF00) : const Color(0x220000FF));

@override
Color get accentMuted => _preserveAccent
    ? _base.accent.withValues(alpha: 0.27) // 0x44 ≈ 0.27
    : (_isDark ? const Color(0x44FFFF00) : const Color(0x440000FF));
```

- [ ] **Paso 2**: `borderFocus` puede mantenerse blanco/negro (es el border de inputs activos, mejor en HC puro). Pero si quieres consistencia visual, hacer:
```dart
@override
Color get borderFocus => _preserveAccent
    ? _base.accent
    : (_isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000));
```
Recomendado mantener puro para evitar mal contraste con bgInput.

- [ ] **Paso 3**: Verificar `accentBg` cumple WCAG vs `bgRoot`:
  - En oscuro: accent naranja al 13% sobre negro = típicamente OK.
  - En claro: accent naranja al 13% sobre blanco = sutil pero visible.
  - Si en alguna paleta queda invisible, considerar subir alpha a 0.20.

- [ ] **Paso 4**: Smoke test:
  1. Paleta Sunset (accent naranja).
  2. HC ON + preserveAccent ON.
  3. Chip de filtro: fondo naranja muy sutil (no amarillo).
  4. Toggle switch activo: thumb naranja.

**Criterio**: HC con preserveAccent visualmente coherente.

---

## 3. Archivos modificados (resumen)

### Nuevos (2)
- `lib/data/mock/mock_data_extensions.dart`
- `lib/features/widgets_config/widgets/route_autocomplete.dart`

### Modificados (8)
- `lib/data/fmtc/tile_prewarmer.dart`
- `lib/features/map/widgets/zone_company_line_tree.dart`
- `lib/features/widgets_config/widgets_config_screen.dart`
- `lib/features/widgets_config/widget_next_bus_config_screen.dart`
- `lib/features/widgets_config/widget_my_line_config_screen.dart`
- `lib/features/widgets_config/widget_nfc_balance_config_screen.dart`
- `lib/features/home/widgets/habitual_config_sheet.dart` (refactor reuso)
- `lib/core/theme/high_contrast_scheme.dart`

### l10n
- `lib/l10n/app_es.arb`, `app_en.arb`, `app_ar.arb` (+14 claves cada uno)

### Sin tocar
- Wizard crear ruta, mapa principal, auth, perfil, recovery.

---

## 4. Plan de ejecución

### Sesión única (3 h)
Orden recomendado por independencia:

1. **A1.bis (15 min)** — toca un solo archivo, primero.
2. **G1.bis (20 min)** — toca un solo archivo, paralelo.
3. **C2.bis (15 min)** — toca tree.
4. **C1.bis (30 min)** — toca tree (mismo archivo, secuencial con C2).
5. **D3.bis (5 min)** — token preview, fast.
6. **D2.bis (10 min)** — dedupe, fast.
7. **D4.bis (30 min)** — Autocomplete + refactor.
8. **D1.bis (1 h)** — l10n (lo más laborioso, deja al final cuando todo el código esté quieto).
9. Build + smoke test (15 min).

### Dividido en 2 mini-sesiones
- **Mini 1 (1.5 h)**: A1 + G1 + C1 + C2 (perf + theming + filtros).
- **Mini 2 (1.5 h)**: D1 + D2 + D3 + D4 (widgets config completo).

---

## 5. Riesgos

- **R1: `store.stats.toMap()` puede no tener clave `tilesAvailable`.** Mitigación: try/catch + fallback a "proceder con prewarm" (peor caso = volver a descargar, no rompe).
- **R2: `OperatorModel.region` puede ser null para algunos operadores.** Mitigación: agrupar bajo `'Otras zonas'`.
- **R3: Refactor `habitual_config_sheet.dart` para reusar `RouteAutocomplete` puede romper su layout actual.** Mitigación: probar el sheet tras el cambio antes de commit.
- **R4: Cambiar tri-state ciclo puede confundir usuarios que ya aprendieron el ciclo viejo.** Mitigación: aceptable, el ciclo viejo era objetivamente confuso.
- **R5: l10n 14 claves nuevas pueden colisionar con claves existentes.** Mitigación: prefijo `widgetsConfig*` distintivo.
- **R6: `preserveAccent` con accents muy oscuros (ej. púrpura) puede dar `accentBg` invisible.** Mitigación: si en testing queda muy sutil, subir alpha a 0.20.

---

## 6. Criterios de aceptación

1. Arrancar dos veces seguidas: segunda vez SIN log de prewarm.
2. Filtros: tree con "Jerez" como sección raíz, COMUJESA dentro, líneas dentro.
3. Tri-state: tap en checkbox mixed → todas OFF. Tap → todas ON. Nunca queda en estado mixed por click del usuario.
4. Idioma inglés: pantallas widgets-config en inglés.
5. Idioma árabe: pantallas widgets-config en árabe + RTL.
6. Widget "Próximo bus" config: dropdown paradas sin duplicados.
7. Widget "Próximo bus" config: badge usa tipografía consistente con el resto.
8. Widget "Próximo bus" config: campo línea con buscador autocomplete.
9. HC + Sunset + preserveAccent: chips de filtro tono naranja sutil, no amarillo.

---

## 7. Próximos pasos

Cuando apruebes:
- **"arranca todo en orden"** → 3 h en una sesión.
- **"arranca mini 1"** → A1 + G1 + C1 + C2 (~1.5 h, perf + theming + filtros).
- **"arranca mini 2"** → D1-D4 (~1.5 h, widgets config completo).
- **"solo D"** → si lo más visible para el usuario son las pantallas widgets (~1.5 h).

Recomendado **"arranca todo en orden"** porque las mejoras son cortas y se complementan.

---

## Changelog

- **2026-06-03** — Plan creado tras auditoría detallada del plan 8-items. 8 mejoras identificadas con archivo:línea. A2.bis descartado como falso positivo (`MapConfig.tileUrl` ya saca apiKey del Env automáticamente).
