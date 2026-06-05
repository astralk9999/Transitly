# Sub-plan F de P1 — Widgets Android: tamaño + tema + frecuencia (P1-04)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cerrar P1-04 a nivel **Flutter** (modelo + UI) sin tocar layouts XML Android. Añade tres capacidades a las pantallas de configuración de los 3 widgets (Next Bus, My Line, NFC Balance): selector de **tamaño S/M/L**, selector de **tema independiente** (auto/claro/oscuro/marca) y selector de **frecuencia de refresco** (15/30/60 min). El preview en vivo y los selectores de parada/línea ya funcionan en el código actual.

**Architecture:** Las 3 pantallas comparten el mismo patrón: header + preview + selectores específicos del widget. La extensión es ortogonal — añadir un `WidgetAppearancePanel` reutilizable que vive **debajo** del contenido específico de cada pantalla. La configuración se persiste en un nuevo provider compartido `widgetAppearanceConfigProvider` con su propio Hive box. El `WidgetDataWriter` se extiende para escribir los nuevos campos al canal nativo Android (luego el layout XML puede leerlos cuando se haga el follow-up nativo).

> **Decisión sobre la frecuencia de refresco efectiva.** Hoy el refresco periódico real lo hacía `workmanager` que se retiró del `pubspec.yaml` por un crash de embedding v1 (`workmanager eliminado: declarado pero nunca cableado en Dart, y la 0.5.2 usa la API v1-embedding...`). Mientras no se reemplace, el selector de "frecuencia" persiste la elección del usuario y se envía al lado nativo a través de `WidgetDataWriter`, pero el refresco efectivo sigue siendo el patrón actual: on-resume + manual (botón Refrescar/TEST). Documentado en notas.

**Tech Stack:** Riverpod 2.6.1 `StateNotifierProvider`, Hive box `widget_appearance_config`, `SegmentedButton` Material, `home_widget` 0.7.0 ya integrado.

---

## File Structure

**Create:**
- `lib/shared/providers/widget_appearance_config_provider.dart` — modelo `WidgetAppearanceConfig` + notifier + provider + persistencia Hive.
- `lib/features/widgets_config/widgets/widget_appearance_panel.dart` — UI reutilizable con los 3 segmented buttons + preview hints.
- `test/shared/providers/widget_appearance_config_test.dart` — tests del notifier (defaults, persist, load).

**Modify:**
- `lib/features/widgets_config/widget_next_bus_config_screen.dart` — insertar el panel + propagar config al `WidgetDataWriter` + refresh manual ya existe.
- `lib/features/widgets_config/widget_my_line_config_screen.dart` — insertar el panel + refresh manual + propagar config.
- `lib/features/widgets_config/widget_nfc_balance_config_screen.dart` — insertar el panel (solo tamaño/tema/frecuencia tienen sentido aquí).
- `lib/data/widgets_native/widget_data_writer.dart` — extender los métodos `writeNextBus`/`writeMyLineStatus`/`writeNfcBalance` para aceptar `size`, `theme`, `refreshMinutes`.

---

## Task 1: Modelo + provider + persistencia (P1-04 base)

**Files:**
- Create: `lib/shared/providers/widget_appearance_config_provider.dart`
- Test: `test/shared/providers/widget_appearance_config_test.dart`

### Step 1.1 — Test failing del modelo

- [ ] Crear `test/shared/providers/widget_appearance_config_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:transitly/shared/providers/widget_appearance_config_provider.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('hive_widget_cfg_test_');
    Hive.init(dir.path);
  });

  setUp(() async {
    if (await Hive.boxExists('widget_appearance_config')) {
      await Hive.deleteBoxFromDisk('widget_appearance_config');
    }
  });

  test('default config: medium / auto / 60 min', () async {
    final n = WidgetAppearanceConfigNotifier();
    await n.ready;
    expect(n.state.size, WidgetSize.medium);
    expect(n.state.theme, WidgetTheme.auto);
    expect(n.state.refreshMinutes, 60);
  });

  test('setSize updates state and persists', () async {
    final n = WidgetAppearanceConfigNotifier();
    await n.ready;
    await n.setSize(WidgetSize.large);
    expect(n.state.size, WidgetSize.large);

    final n2 = WidgetAppearanceConfigNotifier();
    await n2.ready;
    expect(n2.state.size, WidgetSize.large);
  });

  test('setTheme + setRefreshMinutes both persist independently', () async {
    final n = WidgetAppearanceConfigNotifier();
    await n.ready;
    await n.setTheme(WidgetTheme.dark);
    await n.setRefreshMinutes(15);
    expect(n.state.theme, WidgetTheme.dark);
    expect(n.state.refreshMinutes, 15);

    final n2 = WidgetAppearanceConfigNotifier();
    await n2.ready;
    expect(n2.state.theme, WidgetTheme.dark);
    expect(n2.state.refreshMinutes, 15);
  });

  test('setRefreshMinutes only accepts 15/30/60 (otherwise noop)', () async {
    final n = WidgetAppearanceConfigNotifier();
    await n.ready;
    await n.setRefreshMinutes(60);
    await n.setRefreshMinutes(45);
    expect(n.state.refreshMinutes, 60);
  });
}
```

### Step 1.2 — Implementar el provider

- [ ] Crear `lib/shared/providers/widget_appearance_config_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

enum WidgetSize { small, medium, large }

enum WidgetTheme { auto, light, dark, brand }

class WidgetAppearanceConfig {
  const WidgetAppearanceConfig({
    this.size = WidgetSize.medium,
    this.theme = WidgetTheme.auto,
    this.refreshMinutes = 60,
  });

  final WidgetSize size;
  final WidgetTheme theme;
  final int refreshMinutes;

  WidgetAppearanceConfig copyWith({
    WidgetSize? size,
    WidgetTheme? theme,
    int? refreshMinutes,
  }) {
    return WidgetAppearanceConfig(
      size: size ?? this.size,
      theme: theme ?? this.theme,
      refreshMinutes: refreshMinutes ?? this.refreshMinutes,
    );
  }
}

class WidgetAppearanceConfigNotifier
    extends StateNotifier<WidgetAppearanceConfig> {
  WidgetAppearanceConfigNotifier() : super(const WidgetAppearanceConfig()) {
    _loadFuture = _load();
  }

  static const _boxName = 'widget_appearance_config';
  static const _kSize = 'size';
  static const _kTheme = 'theme';
  static const _kRefresh = 'refreshMinutes';
  static const _allowedRefresh = <int>[15, 30, 60];

  late final Future<void> _loadFuture;
  Future<void> get ready => _loadFuture;

  Future<void> _load() async {
    final box = await Hive.openBox<dynamic>(_boxName);
    final size = _parseSize(box.get(_kSize) as String?);
    final theme = _parseTheme(box.get(_kTheme) as String?);
    final refresh = box.get(_kRefresh) as int?;
    state = WidgetAppearanceConfig(
      size: size,
      theme: theme,
      refreshMinutes:
          (refresh != null && _allowedRefresh.contains(refresh))
              ? refresh
              : 60,
    );
  }

  Future<void> setSize(WidgetSize value) async {
    state = state.copyWith(size: value);
    final box = await Hive.openBox<dynamic>(_boxName);
    await box.put(_kSize, value.name);
  }

  Future<void> setTheme(WidgetTheme value) async {
    state = state.copyWith(theme: value);
    final box = await Hive.openBox<dynamic>(_boxName);
    await box.put(_kTheme, value.name);
  }

  Future<void> setRefreshMinutes(int value) async {
    if (!_allowedRefresh.contains(value)) return;
    state = state.copyWith(refreshMinutes: value);
    final box = await Hive.openBox<dynamic>(_boxName);
    await box.put(_kRefresh, value);
  }

  WidgetSize _parseSize(String? raw) {
    if (raw == null) return WidgetSize.medium;
    return WidgetSize.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => WidgetSize.medium,
    );
  }

  WidgetTheme _parseTheme(String? raw) {
    if (raw == null) return WidgetTheme.auto;
    return WidgetTheme.values.firstWhere(
      (t) => t.name == raw,
      orElse: () => WidgetTheme.auto,
    );
  }
}

final widgetAppearanceConfigProvider = StateNotifierProvider<
    WidgetAppearanceConfigNotifier, WidgetAppearanceConfig>(
  (ref) => WidgetAppearanceConfigNotifier(),
);
```

### Step 1.3 — Tests pasan

- [ ] Ejecutar:

```bash
flutter test test/shared/providers/widget_appearance_config_test.dart
```

Expected: 4 tests PASS.

### Step 1.4 — Commit

```bash
git add lib/shared/providers/widget_appearance_config_provider.dart \
        test/shared/providers/widget_appearance_config_test.dart
git commit -m "$(cat <<'EOF'
feat(widgets): modelo + provider para tamaño/tema/refrescamiento (P1-04 base)

Nuevo WidgetAppearanceConfig compartido entre los 3 widgets (Next Bus,
My Line, NFC Balance):
- size: small / medium / large
- theme: auto / light / dark / brand
- refreshMinutes: 15 / 30 / 60 (defaults a 60)

Persiste en Hive box widget_appearance_config con setters individuales
para no acoplar las pantallas. Tests cubren defaults, persistencia y
validación del intervalo.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Widget reutilizable `WidgetAppearancePanel`

**Files:**
- Create: `lib/features/widgets_config/widgets/widget_appearance_panel.dart`

### Step 2.1 — Crear el panel reutilizable

- [ ] Crear `lib/features/widgets_config/widgets/widget_appearance_panel.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../shared/providers/widget_appearance_config_provider.dart';
import '../../../shared/widgets/glass_card.dart';

/// Panel reutilizable con los 3 selectores de apariencia del widget:
/// tamaño, tema independiente y frecuencia de refresco. Se inserta al
/// final de cada pantalla de configuración de widget.
class WidgetAppearancePanel extends ConsumerWidget {
  const WidgetAppearancePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final cfg = ref.watch(widgetAppearanceConfigProvider);
    final notifier = ref.read(widgetAppearanceConfigProvider.notifier);

    return GlassCard(
      blur: 12,
      fillOpacity: 0.05,
      borderRadius: 12,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('APARIENCIA DEL WIDGET',
              style: TransitTypography.sectionTitle(c.textMid)),
          const SizedBox(height: 14),

          Text('Tamaño', style: TransitTypography.bodySecondary(c.textHi)),
          const SizedBox(height: 6),
          SegmentedButton<WidgetSize>(
            segments: const [
              ButtonSegment(value: WidgetSize.small, label: Text('S')),
              ButtonSegment(value: WidgetSize.medium, label: Text('M')),
              ButtonSegment(value: WidgetSize.large, label: Text('L')),
            ],
            selected: {cfg.size},
            onSelectionChanged: (s) {
              if (s.isNotEmpty) notifier.setSize(s.first);
            },
            style: _segmentedStyle(c),
          ),
          const SizedBox(height: 14),

          Text('Tema', style: TransitTypography.bodySecondary(c.textHi)),
          const SizedBox(height: 6),
          SegmentedButton<WidgetTheme>(
            segments: const [
              ButtonSegment(value: WidgetTheme.auto, label: Text('Auto')),
              ButtonSegment(value: WidgetTheme.light, label: Text('Claro')),
              ButtonSegment(value: WidgetTheme.dark, label: Text('Oscuro')),
              ButtonSegment(value: WidgetTheme.brand, label: Text('Marca')),
            ],
            selected: {cfg.theme},
            onSelectionChanged: (s) {
              if (s.isNotEmpty) notifier.setTheme(s.first);
            },
            style: _segmentedStyle(c),
          ),
          const SizedBox(height: 14),

          Text('Frecuencia de refresco',
              style: TransitTypography.bodySecondary(c.textHi)),
          const SizedBox(height: 6),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 15, label: Text('15 min')),
              ButtonSegment(value: 30, label: Text('30 min')),
              ButtonSegment(value: 60, label: Text('1 h')),
            ],
            selected: {cfg.refreshMinutes},
            onSelectionChanged: (s) {
              if (s.isNotEmpty) notifier.setRefreshMinutes(s.first);
            },
            style: _segmentedStyle(c),
          ),
          const SizedBox(height: 8),
          Text(
            'La frecuencia se aplica al refresco periódico cuando esté '
            'disponible; por ahora el widget se actualiza al abrir la app '
            'y con el botón Refrescar / TEST.',
            style: TransitTypography.bodySmall(c.textLo),
          ),
        ],
      ),
    );
  }

  ButtonStyle _segmentedStyle(TransitColorScheme c) {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return c.accent;
        return c.bgRaised;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return c.textMid;
      }),
      side: WidgetStateProperty.all(
        BorderSide(color: c.border, width: 1),
      ),
    );
  }
}
```

### Step 2.2 — Análisis aislado

- [ ] Ejecutar:

```bash
flutter analyze lib/features/widgets_config/widgets/widget_appearance_panel.dart
```

Expected: 0 errors.

### Step 2.3 — Commit

```bash
git add lib/features/widgets_config/widgets/widget_appearance_panel.dart
git commit -m "$(cat <<'EOF'
feat(widgets): WidgetAppearancePanel reutilizable (P1-04 UI)

Card con 3 SegmentedButton (tamaño S/M/L, tema auto/claro/oscuro/marca,
frecuencia 15/30/60min) que escribe en widgetAppearanceConfigProvider.

Se insertará en las 3 pantallas de configuración (Next Bus, My Line,
NFC Balance) en los siguientes commits.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Insertar panel en las 3 pantallas

### Step 3.1 — Next Bus

- [ ] En `lib/features/widgets_config/widget_next_bus_config_screen.dart`, añadir import:

```dart
import 'widgets/widget_appearance_panel.dart';
```

- [ ] Tras la `Row` de botones TEST/SAVE (antes del último `]`), añadir:

```dart
            const SizedBox(height: 24),
            const WidgetAppearancePanel(),
```

### Step 3.2 — My Line

- [ ] Mismo import en `widget_my_line_config_screen.dart`.

- [ ] Al final del `Column` raíz (tras el último elemento), añadir:

```dart
            const SizedBox(height: 24),
            const WidgetAppearancePanel(),
```

### Step 3.3 — NFC Balance

- [ ] Mismo import en `widget_nfc_balance_config_screen.dart`.

- [ ] Al final del `Column` raíz:

```dart
            const SizedBox(height: 24),
            const WidgetAppearancePanel(),
```

### Step 3.4 — Análisis + tests

- [ ] Ejecutar:

```bash
flutter analyze
flutter test
```

Expected: 0 errors.

### Step 3.5 — Commit

```bash
git add lib/features/widgets_config/widget_next_bus_config_screen.dart \
        lib/features/widgets_config/widget_my_line_config_screen.dart \
        lib/features/widgets_config/widget_nfc_balance_config_screen.dart
git commit -m "$(cat <<'EOF'
feat(widgets): insertar WidgetAppearancePanel en las 3 pantallas (P1-04)

Las 3 pantallas de configuración (Next Bus, My Line, NFC Balance) ahora
muestran el panel de apariencia común al final de su contenido. La
config persiste en Hive y se compartirá entre los 3 widgets.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Verificación + tracking V16 + PR

### Step 4.1 — Suite + análisis

- [ ] Ejecutar:

```bash
flutter analyze
flutter test
```

Expected: 0 errors. Mismos 19 timeouts pre-existentes.

### Step 4.2 — Smoke test

- [ ] `flutter run`.
- [ ] Perfil → Widgets → "Próximo Bus" → ve los selectores nuevos abajo.
- [ ] Cambiar tamaño a L → cerrar y reabrir la pantalla → conserva L.
- [ ] Mismo flujo para My Line y NFC Balance.

### Step 4.3 — Tracking V16

- [ ] Marcar P1-04 como **parcial** en el plan V16 — UI Flutter completa, refresco periódico real diferido por `workmanager` retirado.

- [ ] Commit:

```bash
git add docs/historico/PLAN_REPARACION_2026_06_05_V16.md
git commit -m "chore: cerrar P1-04 parcial en plan V16 (UI Flutter)

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

### Step 4.4 — Push + PR

```bash
git push -u origin fix/p1-sub-f-widgets
```

Abrir PR manualmente.

---

## Notas y consideraciones

**Sobre la "preview en vivo".** El `_PreviewCard` actual del widget Next Bus ya muestra el código, hora y parada en formato similar al widget Android. Una preview que mimic el **layout real Android con tamaño S/M/L** requeriría refactorizar el `_PreviewCard` como mockup, fuera del alcance de este sub-plan. Queda como follow-up.

**Sobre el refresco periódico real.** `workmanager` se retiró del pubspec porque la versión 0.5.2 usaba la API v1-embedding ya removida en Flutter 3.x. Alternativas:
- Actualizar a `workmanager` 0.6+ si ya soporta v2.
- Usar AlarmManager nativo Android (Kotlin Service).
- Confirmar que el approach actual "on-resume + manual" es suficiente para el TFG y documentarlo.

Mientras tanto el selector de frecuencia persiste la elección y se envía al lado nativo (cuando `WidgetDataWriter` reciba el campo nuevo); el refresco efectivo no cambia hasta que se elija la alternativa.

**Sobre el `WidgetDataWriter`.** No se modifica en este sub-plan para mantener el diff acotado. El siguiente paso natural es extender los métodos para aceptar `size`/`theme`/`refresh` y propagarlos al canal `home_widget`. Eso queda como follow-up por separado para no expandir el PR.

**Sobre los buscadores de parada/línea.** El user reportó que "no aparecen líneas/paradas reales". Tras revisar el código, `RouteAutocomplete` (Next Bus) y la lista de favoritos (My Line) ya leen del `mockDataServiceProvider`. Si en smoke test siguen vacíos, el bug es de hidratación del mock — debería estar arreglado por sub-B (P0-01 fallback a mock cuando routesBox vacío). Verificar en smoke test.
