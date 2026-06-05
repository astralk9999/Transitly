# Sub-plan E de P1 — Privacidad real + reorganización accesibilidad + alto contraste arreglado

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cerrar tres ítems P1: (P1-01) la pantalla de Privacidad tiene fondo y mejor feedback aunque el wiring Supabase ya funciona; (P1-02) la sección "Accesibilidad" del perfil refleja el estado real y dislexia/daltonismo se mueven a la pantalla de Accesibilidad fuera de Apariencia; (P1-03) el switch de alto contraste no rompe el layout y el sub-toggle "Conservar acento" tiene su propia fila.

**Architecture:**

P1-01 — `privacy_screen.dart` ya consume `privacyConsentRepositoryProvider`, inserta filas en `data_exports` y `data_deletion_requests`, e invoca las Edge Functions correspondientes. Los tres puntos débiles son visuales y de UX: la pantalla usa `c.bgRoot` directamente sobre Scaffold sin shader/wrapper, los SnackBars de éxito desaparecen rápido y no hay indicador de progreso durante el await. Fix: envolver el contenido con el mismo patrón de fondo que el resto de la app (`SmokeBackground` o `BackgroundWrapper`), añadir un loader inline mientras dura el await del export/borrado, mostrar SnackBars con duración explícita.

P1-02 — Dos cambios:
1. `profile_accessibility_section.dart:46` muestra un label estático `l10n.profileColorBlindModeNone` que SIEMPRE dice "ninguno". Fix: hacer el label dinámico leyendo `themeNotifierProvider.colorBlindMode`, `dyslexiaFontEnabled` y `highContrast`; construir una cadena resumen tipo "Daltonismo: deuteranopia · Dislexia: ON · Contraste alto".
2. La fuente para dislexia vive en `appearance/widgets/font_section.dart:79-95` (toggle dentro de Apariencia). El selector de daltonismo vive en `appearance/widgets/accessibility_section.dart:119-158`. Ambos se mueven a `accessibility_settings_screen.dart` como secciones propias. En Apariencia queda solo: paleta, brightness, font scale, reduce motion, shaders/background.

P1-03 — `appearance/widgets/accessibility_section.dart:198-223` tiene el sub-Switch "Conservar acento" añadido DENTRO del mismo `Row` que el Switch "Alto contraste" (el `if (highContrast) Padding(...)` quedó como tercer hijo del Row). Resultado: cuando el toggle se enciende, el sub-toggle aparece pegado al Switch del padre comprimiendo el ancho. Fix mínimo: cambiar la estructura a Column con dos Rows separadas. El sub-toggle solo es interactivo si `highContrast = true`.

> **Decisión sobre Off/AA/AAA del plan V16.** El plan V16 P1-03 menciona un `SegmentedButton<ContrastLevel>` con tres niveles. Eso requiere convertir `bool highContrast` en un enum + adaptar `HighContrastTheme.apply` para diferenciar AA vs AAA (alcance grande). En este sub-plan limito al fix de layout y la limpieza visual; el rediseño Off/AA/AAA queda como follow-up explícito documentado al final.

**Tech Stack:** Flutter Material, Riverpod 2.6.1, `ThemeNotifier` (ya persiste en Hive guest box), `BackgroundWrapper`/`SmokeBackground` del repo, Supabase auth + tables ya configuradas.

---

## File Structure

**Modify:**
- `lib/features/home/widgets/profile_accessibility_section.dart` — label dinámico que refleja el estado real.
- `lib/features/profile/accessibility_settings_screen.dart` — nuevas secciones Dislexia + Daltonismo.
- `lib/features/appearance/widgets/font_section.dart` — quitar toggle de dislexia.
- `lib/features/appearance/widgets/accessibility_section.dart` — quitar selector daltonismo + arreglar layout alto contraste/preserveAccent.
- `lib/features/privacy/privacy_screen.dart` — añadir fondo, mejorar feedback con loader.

**Create:**
- `test/features/home/widgets/profile_accessibility_summary_test.dart` — verifica el label dinámico.

---

## Task 1: Label dinámico en ProfileAccessibilitySection (P1-02 parte 1)

**Files:**
- Modify: `lib/features/home/widgets/profile_accessibility_section.dart`
- Test: `test/features/home/widgets/profile_accessibility_summary_test.dart`

### Step 1.1 — Test failing del label dinámico

- [ ] Crear `test/features/home/widgets/profile_accessibility_summary_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/features/home/widgets/profile_accessibility_section.dart';
import 'package:transitly/shared/models/user_preferences.dart';

void main() {
  group('buildAccessibilitySummary', () {
    test('all defaults → "Sin ajustes activos"', () {
      final s = buildAccessibilitySummary(
        colorBlindMode: ColorBlindMode.none,
        dyslexiaEnabled: false,
        highContrast: false,
      );
      expect(s, equals('Sin ajustes activos'));
    });

    test('only dyslexia ON', () {
      final s = buildAccessibilitySummary(
        colorBlindMode: ColorBlindMode.none,
        dyslexiaEnabled: true,
        highContrast: false,
      );
      expect(s, equals('Dislexia activa'));
    });

    test('only color blind mode', () {
      final s = buildAccessibilitySummary(
        colorBlindMode: ColorBlindMode.deuteranopia,
        dyslexiaEnabled: false,
        highContrast: false,
      );
      expect(s, equals('Daltonismo: deuteranopia'));
    });

    test('only high contrast', () {
      final s = buildAccessibilitySummary(
        colorBlindMode: ColorBlindMode.none,
        dyslexiaEnabled: false,
        highContrast: true,
      );
      expect(s, equals('Contraste alto'));
    });

    test('combo of all three is joined with " · "', () {
      final s = buildAccessibilitySummary(
        colorBlindMode: ColorBlindMode.tritanopia,
        dyslexiaEnabled: true,
        highContrast: true,
      );
      expect(s, equals(
          'Daltonismo: tritanopia · Dislexia activa · Contraste alto'));
    });
  });
}
```

### Step 1.2 — Run, ver falla

- [ ] Ejecutar:

```bash
flutter test test/features/home/widgets/profile_accessibility_summary_test.dart
```

Expected: error porque `buildAccessibilitySummary` no existe.

### Step 1.3 — Implementar el helper y usarlo en el widget

- [ ] Reemplazar `lib/features/home/widgets/profile_accessibility_section.dart` por:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/models/user_preferences.dart';
import '../../../shared/providers/is_dark_provider.dart';
import '../../../shared/providers/theme_notifier.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_text.dart';

/// Helper expuesto para test. Construye un resumen legible del estado de
/// los ajustes de accesibilidad activos. Devuelve "Sin ajustes activos"
/// cuando todo está en defaults.
String buildAccessibilitySummary({
  required ColorBlindMode colorBlindMode,
  required bool dyslexiaEnabled,
  required bool highContrast,
}) {
  final parts = <String>[];
  if (colorBlindMode != ColorBlindMode.none) {
    parts.add('Daltonismo: ${colorBlindMode.name}');
  }
  if (dyslexiaEnabled) {
    parts.add('Dislexia activa');
  }
  if (highContrast) {
    parts.add('Contraste alto');
  }
  if (parts.isEmpty) return 'Sin ajustes activos';
  return parts.join(' · ');
}

class ProfileAccessibilitySection extends ConsumerWidget {
  const ProfileAccessibilitySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = isDarkMode(ref, context);
    final c = TransitColorScheme.of(isDark);
    final l10n = AppLocalizations.of(context);

    final colorBlindMode = ref
        .watch(themeNotifierProvider.select((n) => n.colorBlindMode));
    final dyslexiaEnabled = ref
        .watch(themeNotifierProvider.select((n) => n.dyslexiaFontEnabled));
    final highContrast = ref
        .watch(themeNotifierProvider.select((n) => n.highContrast));

    final summary = buildAccessibilitySummary(
      colorBlindMode: colorBlindMode,
      dyslexiaEnabled: dyslexiaEnabled,
      highContrast: highContrast,
    );

    return GlassCard(
      blur: 16,
      fillOpacity: 0.05,
      borderRadius: 14,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientText(
            l10n.profileSectionAccessibility,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
            gradient: c.gradientAccent,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => context.push('/profile/accessibility'),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    summary,
                    style: TransitTypography.bodyPrimary(c.textHi),
                  ),
                ),
                Icon(Icons.chevron_right, size: 20, color: c.textLo),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, thickness: 0.5, color: c.border),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => context.push('/profile/offline-regions'),
            child: Row(
              children: [
                Icon(Icons.map_outlined, size: 18, color: c.accent),
                const SizedBox(width: 8),
                Text(
                  l10n.offlineRegionsMapLink,
                  style: TransitTypography.bodyPrimary(c.accent),
                ),
                const Spacer(),
                Icon(Icons.chevron_right, size: 20, color: c.accent),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, thickness: 0.5, color: c.border),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => context.push('/profile/widgets'),
            child: Row(
              children: [
                Icon(Icons.widgets_outlined, size: 18, color: c.accent),
                const SizedBox(width: 8),
                Text(
                  l10n.widgetsTitle,
                  style: TransitTypography.bodyPrimary(c.accent),
                ),
                const Spacer(),
                Icon(Icons.chevron_right, size: 20, color: c.accent),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### Step 1.4 — Run, ver pasa

- [ ] Ejecutar:

```bash
flutter test test/features/home/widgets/profile_accessibility_summary_test.dart
```

Expected: 5 PASS.

### Step 1.5 — Commit

```bash
git add lib/features/home/widgets/profile_accessibility_section.dart \
        test/features/home/widgets/profile_accessibility_summary_test.dart
git commit -m "$(cat <<'EOF'
fix(profile): label dinámico en sección Accesibilidad (P1-02 parte 1)

Antes ProfileAccessibilitySection mostraba el literal "Modo: Ninguno"
incluso cuando dislexia/daltonismo/alto contraste estaban activos.

Ahora se construye un resumen legible con
buildAccessibilitySummary(...) que refleja el estado real del
ThemeNotifier. Tests cubren defaults, cada flag por separado y la
combinación de los tres.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Mover dislexia + daltonismo a AccessibilitySettingsScreen (P1-02 parte 2)

**Files:**
- Modify: `lib/features/profile/accessibility_settings_screen.dart` — añadir secciones Dislexia + Daltonismo.
- Modify: `lib/features/appearance/widgets/font_section.dart` — quitar toggle de dislexia.
- Modify: `lib/features/appearance/widgets/accessibility_section.dart` — quitar selector de daltonismo (queda reduce motion + alto contraste).

### Step 2.1 — Quitar el toggle de dislexia de `font_section.dart`

- [ ] Editar `lib/features/appearance/widgets/font_section.dart`. Eliminar:

```dart
    final dyslexia =
        ref.watch(themeNotifierProvider.select((n) => n.dyslexiaFontEnabled));
```

…y el bloque entero del Row con el switch (líneas 78-95):

```dart
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.appearanceDyslexiaFont,
                  style: TransitTypography.bodyPrimary(c.textHi),
                ),
              ),
              Switch.adaptive(
                value: dyslexia,
                activeTrackColor: c.accent,
                onChanged: (v) {
                  ref.read(themeNotifierProvider).dyslexiaFontEnabled = v;
                },
              ),
            ],
          ),
```

Resultado: `FontSection` queda con solo el slider de tamaño y la preview de texto.

### Step 2.2 — Quitar el selector de daltonismo de `appearance/widgets/accessibility_section.dart`

- [ ] Editar `lib/features/appearance/widgets/accessibility_section.dart`. Eliminar:

```dart
  String _cbmLabel(ColorBlindMode mode) { ... }
  void _showCbmSheet(...) { ... }
```

…y dentro del `build`, eliminar el `Row` del selector (líneas 119-158, el bloque que incluye el GestureDetector con `_showCbmSheet`):

```dart
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.appearanceColorBlindMode, ...
              GestureDetector(
                onTap: () => _showCbmSheet(context, ref, c), ...
              ),
            ],
          ),
          const SizedBox(height: 12),
```

Y eliminar la variable `final cbm = ref.watch(...colorBlindMode)`.

Resultado: `AccessibilitySection` de Apariencia queda con solo reduce motion + (P1-03) alto contraste.

> **Nota.** Esta sección "AccessibilitySection" sigue viviendo en Apariencia porque reduce motion sigue siendo allí (junto con shaders/background). Renombrarla a "AnimationsSection" sería más fiel ahora — pero ese es polish opcional fuera del alcance P1.

### Step 2.3 — Añadir las secciones Dislexia + Daltonismo en `accessibility_settings_screen.dart`

- [ ] Editar `lib/features/profile/accessibility_settings_screen.dart`. Tras el bloque `_LanguageSection` añadir dos secciones nuevas en el `ListView` (entre `_SystemPreferencesSection` y `_LanguageSection`):

```dart
                const SizedBox(height: 16),
                _DyslexiaSection(c: c),
                const SizedBox(height: 16),
                _ColorBlindSection(c: c),
                const SizedBox(height: 16),
```

…y añadir al final del archivo las clases:

```dart
class _DyslexiaSection extends ConsumerWidget {
  const _DyslexiaSection({required this.c});

  final TransitColorScheme c;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final dyslexia = ref
        .watch(themeNotifierProvider.select((n) => n.dyslexiaFontEnabled));

    return GlassCard(
      blur: 16,
      fillOpacity: 0.05,
      borderRadius: 14,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientText(
            l10n.appearanceDyslexiaFont,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
            gradient: c.gradientAccent,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Usa OpenDyslexic, una fuente diseñada para mejorar la '
                  'legibilidad en personas con dislexia.',
                  style: TransitTypography.bodySmall(c.textLo),
                ),
              ),
              Switch.adaptive(
                value: dyslexia,
                activeTrackColor: c.accent,
                onChanged: (v) {
                  ref.read(themeNotifierProvider).dyslexiaFontEnabled = v;
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ColorBlindSection extends ConsumerWidget {
  const _ColorBlindSection({required this.c});

  final TransitColorScheme c;

  String _label(AppLocalizations l10n, ColorBlindMode mode) {
    return switch (mode) {
      ColorBlindMode.none => l10n.appearanceColorBlindNone,
      ColorBlindMode.protanopia => l10n.appearanceColorBlindProtanopia,
      ColorBlindMode.deuteranopia => l10n.appearanceColorBlindDeuteranopia,
      ColorBlindMode.tritanopia => l10n.appearanceColorBlindTritanopia,
      ColorBlindMode.protanomaly => l10n.appearanceColorBlindProtanomaly,
      ColorBlindMode.deuteranomaly => l10n.appearanceColorBlindDeuteranomaly,
      ColorBlindMode.tritanomaly => l10n.appearanceColorBlindTritanomaly,
      ColorBlindMode.achromatopsia => l10n.appearanceColorBlindAchromatopsia,
      ColorBlindMode.achromatomaly => l10n.appearanceColorBlindAchromatomaly,
    };
  }

  void _showSheet(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final cbm = ref.read(themeNotifierProvider).colorBlindMode;
    showModalBottomSheet<ColorBlindMode>(
      context: context,
      backgroundColor: c.bgRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.appearanceColorBlindSheetTitle,
                    style: TransitTypography.sectionLabel(c.textHi),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: ColorBlindMode.values.map((mode) {
                    return RadioListTile<ColorBlindMode>(
                      value: mode,
                      groupValue: cbm,
                      activeColor: c.accent,
                      title: Text(
                        _label(l10n, mode),
                        style: TransitTypography.bodyPrimary(c.textHi),
                      ),
                      onChanged: (v) {
                        if (v != null) {
                          ref.read(themeNotifierProvider).colorBlindMode = v;
                        }
                        Navigator.pop(sheetContext, v);
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cbm = ref
        .watch(themeNotifierProvider.select((n) => n.colorBlindMode));

    return GlassCard(
      blur: 16,
      fillOpacity: 0.05,
      borderRadius: 14,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientText(
            l10n.appearanceColorBlindMode,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
            gradient: c.gradientAccent,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _showSheet(context, ref, l10n),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _label(l10n, cbm),
                    style: TransitTypography.bodyPrimary(c.textHi),
                  ),
                ),
                Icon(Icons.unfold_more, size: 18, color: c.textMid),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

> **Nota imports.** Añadir al inicio del archivo si no están:
> ```dart
> import '../../shared/models/user_preferences.dart';
> ```
> (Para `ColorBlindMode`.)

### Step 2.4 — Smoke test manual

- [ ] `flutter run`.
- [ ] Apariencia → ya no aparece toggle de dislexia ni selector de daltonismo.
- [ ] Perfil → Accesibilidad → aparecen las dos secciones nuevas.
- [ ] Cambiar daltonismo a deuteranopia → volver al perfil → la card "Accesibilidad" ahora muestra "Daltonismo: deuteranopia".
- [ ] Activar dislexia → volver al perfil → "Daltonismo: deuteranopia · Dislexia activa".

### Step 2.5 — Commit

```bash
git add lib/features/profile/accessibility_settings_screen.dart \
        lib/features/appearance/widgets/font_section.dart \
        lib/features/appearance/widgets/accessibility_section.dart
git commit -m "$(cat <<'EOF'
fix(a11y): mover dislexia y daltonismo a la pantalla de Accesibilidad (P1-02 parte 2)

Eran ajustes de accesibilidad metidos en Apariencia. Tras el reposito-
nado, Apariencia queda con paleta + brightness + tamaño de fuente +
reduce motion + alto contraste + shaders. Accesibilidad gana dos cards
nuevas (Dislexia, Daltonismo) que reutilizan los setters del
ThemeNotifier ya existentes.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Arreglar layout alto contraste + sub-toggle "Conservar acento" (P1-03)

**Files:**
- Modify: `lib/features/appearance/widgets/accessibility_section.dart`

### Step 3.1 — Reestructurar el bloque de Alto contraste como Column con dos Rows

- [ ] En `lib/features/appearance/widgets/accessibility_section.dart`, reemplazar el bloque del switch "Alto contraste" + sub-toggle (las líneas que antes terminaban en `],`):

```dart
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.appearanceHighContrast,
                      style: TransitTypography.bodyPrimary(c.textHi),
                    ),
                    Text(
                      l10n.appearanceHighContrastSubtitle,
                      style: TransitTypography.bodySmall(c.textLo),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: highContrast,
                activeTrackColor: c.accent,
            onChanged: (v) {
              ref.read(themeNotifierProvider).highContrast = v;
            },
          ),
          if (highContrast)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.appearanceHcPreserveAccent,
                      style: TransitTypography.bodySecondary(c.textHi),
                    ),
                  ),
                  Switch.adaptive(
                    value: ref.watch(themeNotifierProvider
                        .select((n) => n.hcPreserveAccent)),
                    activeTrackColor: c.accent,
                    onChanged: (v) {
                      ref.read(themeNotifierProvider).hcPreserveAccent = v;
                    },
                  ),
                ],
              ),
            ),
            ],
          ),
```

por:

```dart
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.appearanceHighContrast,
                          style: TransitTypography.bodyPrimary(c.textHi),
                        ),
                        Text(
                          l10n.appearanceHighContrastSubtitle,
                          style: TransitTypography.bodySmall(c.textLo),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: highContrast,
                    activeTrackColor: c.accent,
                    onChanged: (v) {
                      ref.read(themeNotifierProvider).highContrast = v;
                    },
                  ),
                ],
              ),
              if (highContrast)
                Padding(
                  padding: const EdgeInsets.only(top: 12, left: 4),
                  child: Row(
                    children: [
                      Icon(Icons.subdirectory_arrow_right,
                          size: 16, color: c.textLo),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.appearanceHcPreserveAccent,
                              style: TransitTypography.bodySecondary(c.textHi),
                            ),
                            Text(
                              'Si está OFF el alto contraste usa B/N puro.',
                              style: TransitTypography.bodySmall(c.textLo),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: ref.watch(themeNotifierProvider
                            .select((n) => n.hcPreserveAccent)),
                        activeTrackColor: c.accent,
                        onChanged: (v) {
                          ref.read(themeNotifierProvider).hcPreserveAccent = v;
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
```

Cambios clave:
1. Envolver todo el bloque en una `Column` para que el sub-toggle ocupe SU PROPIA fila.
2. El sub-toggle solo aparece si `highContrast` está activo.
3. Pequeña jerarquía visual con un icono `subdirectory_arrow_right` y texto descriptivo extra.
4. Padding superior 12 + indent izquierdo 4 para diferenciarlo visualmente del padre.

### Step 3.2 — Análisis + smoke test

- [ ] Ejecutar:

```bash
flutter analyze
flutter test
```

Expected: 0 errors.

- [ ] `flutter run`.
- [ ] Apariencia → activar Alto contraste → el sub-toggle "Conservar acento de paleta" aparece en una nueva fila justo debajo, con un icono de indentación.
- [ ] Probar en modo claro → texto sigue legible.
- [ ] Toggle del sub-switch funciona y la paleta se aplica/quita según ON/OFF.

### Step 3.3 — Commit

```bash
git add lib/features/appearance/widgets/accessibility_section.dart
git commit -m "$(cat <<'EOF'
fix(a11y): sub-toggle "Conservar acento" en su propia fila (P1-03)

El sub-Switch "Conservar acento de paleta" se añadía como tercer hijo
del mismo Row que el Switch "Alto contraste". Resultado: al encender el
toggle padre, el sub-toggle aparecía pegado a su derecha comprimiendo
el ancho y rompiendo la jerarquía visual. En modo claro el texto se
veía mal por el mismo motivo.

Fix:
- Estructura nueva: Column con Row(padre) y Row(hijo) como hermanas.
- Sub-toggle indentado con icono subdirectory_arrow_right + texto
  descriptivo extra.
- Sub-toggle solo aparece si el switch padre está ON.

La versión Off/AA/AAA con SegmentedButton<ContrastLevel> del plan V16
queda pendiente como follow-up (requiere convertir el bool del notifier
en enum + adaptar HighContrastTheme.apply para AA vs AAA).

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Privacidad — fondo + mejor feedback (P1-01)

**Files:**
- Modify: `lib/features/privacy/privacy_screen.dart`

### Step 4.1 — Añadir SmokeBackground y loader durante export/borrado

- [ ] En `lib/features/privacy/privacy_screen.dart`, añadir el import:

```dart
import '../../shared/widgets/smoke_background.dart';
```

- [ ] Añadir estado para los dos botones del bloque "Mis datos" (data export + deletion). Tras los campos existentes (línea ~33), añadir:

```dart
  bool _exporting = false;
  bool _deleting = false;
```

- [ ] Sustituir el método `_requestDataExport` por:

```dart
  Future<void> _requestDataExport() async {
    final authState = ref.read(authStateProvider).valueOrNull;
    if (authState is! AuthAuthenticated) return;
    final l10n = AppLocalizations.of(context);
    if (!mounted) return;
    setState(() => _exporting = true);
    try {
      final client = ref.read(supabaseClientProvider);
      await client.from('data_exports').insert({
        'user_id': authState.user.id,
        'status': 'queued',
      });
      try {
        await client.functions.invoke(
          'generate_data_export',
          body: {'user_id': authState.user.id},
        );
      } catch (e) {
        AppLogger.warn('Privacy',
            'generate_data_export edge function invoke failed', e);
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(l10n.privacyDataExportRequested),
            duration: const Duration(seconds: 4),
          ));
      }
    } catch (e, st) {
      AppLogger.error('Privacy', 'data export request failed', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            backgroundColor:
                TransitColorScheme.of(Theme.of(context).brightness ==
                        Brightness.dark)
                    .stateDelay,
            duration: const Duration(seconds: 6),
            content: Text('Error solicitando exportación: $e'),
          ));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }
```

- [ ] Reemplazar el método `_showDeletionRequestDialog` envolviendo la lógica final con el mismo patrón try/catch/finally + setState `_deleting`:

```dart
  Future<void> _showDeletionRequestDialog() async {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(l10n.privacyDeleteConfirmTitle,
            style: TransitTypography.heading(c.textHi)),
        content: Text(l10n.privacyDeleteConfirmMessage,
            style: TransitTypography.bodySecondary(c.textMid)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.privacyDeleteConfirmCancel,
                style: TransitTypography.bodySecondary(c.textMid)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.privacyDeleteConfirmAction,
                style: TransitTypography.bodyPrimary(c.stateCancelled)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;
    setState(() => _deleting = true);

    try {
      final client = ref.read(supabaseClientProvider);
      final authState = ref.read(authStateProvider).valueOrNull;
      if (authState is! AuthAuthenticated) return;
      await client.from('data_deletion_requests').insert({
        'user_id': authState.user.id,
        'status': 'requested',
        'requested_at': DateTime.now().toUtc().toIso8601String(),
        'scheduled_at': DateTime.now()
            .toUtc()
            .add(const Duration(days: 30))
            .toIso8601String(),
      });
      try {
        await client.functions.invoke('delete_user');
      } catch (e) {
        AppLogger.warn(
            'Privacy', 'delete_user edge function invoke failed', e);
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(l10n.privacyDeletionRequested),
            duration: const Duration(seconds: 5),
          ));
      }
    } catch (e, st) {
      AppLogger.error('Privacy', 'data deletion request failed', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            backgroundColor: c.stateDelay,
            duration: const Duration(seconds: 6),
            content: Text('Error solicitando borrado: $e'),
          ));
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }
```

### Step 4.2 — Indicar loader en los `_ActionTile`s

- [ ] Modificar la clase `_ActionTile` para aceptar un `bool loading`:

```dart
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.c,
    this.color,
    this.onTap,
    this.loading = false,
  });

  final IconData icon;
  final String label;
  final TransitColorScheme c;
  final Color? color;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final inkColor = color ?? c.accent;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: loading ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: inkColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TransitTypography.bodyPrimary(inkColor)),
            ),
            if (loading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(inkColor),
                ),
              )
            else
              Icon(Icons.chevron_right, size: 20, color: inkColor),
          ],
        ),
      ),
    );
  }
}
```

- [ ] En el `build` principal, pasar `loading: _exporting` al action tile de "Descargar datos" y `loading: _deleting` al de "Solicitar borrado".

### Step 4.3 — Envolver el body con SmokeBackground

- [ ] Reemplazar el `body: ListView(...)` actual del `Scaffold` por:

```dart
      body: Stack(
        children: [
          Positioned.fill(
            child: SmokeBackground(color: c.accent, isDark: isDark),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                /* ... contenido existente ... */
              ],
            ),
          ),
        ],
      ),
```

> Mantener el `backgroundColor: c.bgRoot` del Scaffold para el caso fallback en plataformas que no rendericen el shader.

### Step 4.4 — Análisis + smoke test

- [ ] Ejecutar:

```bash
flutter analyze
flutter test
```

Expected: 0 errors.

- [ ] `flutter run`.
- [ ] Login → Perfil → Privacidad → verifica que la pantalla tiene fondo de shader como el resto.
- [ ] Tocar "Descargar mis datos" → aparece spinner durante el await → snackbar con texto de éxito que dura 4s.
- [ ] Tocar "Solicitar borrado" → dialog → confirmar → spinner → snackbar 5s.
- [ ] Errores simulados (red caída): snackbar rojo con duración 6s y mensaje del error.

### Step 4.5 — Commit

```bash
git add lib/features/privacy/privacy_screen.dart
git commit -m "$(cat <<'EOF'
fix(privacy): añadir fondo y mejor feedback durante export/borrado (P1-01)

El wiring Supabase ya funcionaba (privacy_consents, data_exports,
data_deletion_requests + edge functions) pero la pantalla:
- Carecía del fondo shader del resto de la app.
- No mostraba progreso mientras await terminaba (el botón se sentía
  inerte).
- Los snackbars de éxito desaparecían demasiado rápido y los errores se
  silenciaban en logs sin avisar al usuario.

Fix:
- SmokeBackground envuelve el contenido (consistente con resto de
  pantallas full-screen).
- Spinner inline en los _ActionTile mientras dura el await.
- SnackBars con duración explícita (4-6s) y mensaje rojo en errores.
- try/catch/finally para garantizar el reset del flag de loading.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Verificación final + tracking V16 + PR

### Step 5.1 — Suite + análisis final

- [ ] Ejecutar:

```bash
flutter analyze
flutter test
```

Expected: 0 errors. Mismos 19 timeouts pre-existentes en `card_tab_widget_test.dart`.

### Step 5.2 — Smoke test integrado

- [ ] `flutter run`.
- [ ] Tour: Privacidad con fondo + feedback → Apariencia sin dislexia/daltonismo → Accesibilidad con secciones nuevas + Alto contraste con sub-toggle en su propia fila → resumen dinámico en la card del perfil.

### Step 5.3 — Tracking V16

- [ ] Marcar P1-01, P1-02 y P1-03 como cerrados en
      `docs/historico/PLAN_REPARACION_2026_06_05_V16.md` con
      referencias a los commits y notas sobre limitaciones.

- [ ] Commit:

```bash
git add docs/historico/PLAN_REPARACION_2026_06_05_V16.md
git commit -m "chore: cerrar P1-01/P1-02/P1-03 en plan V16

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

### Step 5.4 — Push + PR

```bash
git push -u origin fix/p1-sub-e-privacidad-accesibilidad
```

Abrir PR manualmente desde la URL.

---

## Notas y consideraciones

**Sobre los strings hardcodeados en el resumen.** En Task 1 el helper devuelve cadenas en castellano hardcodeadas. Lo correcto sería usar `AppLocalizations` para soporte multi-idioma. Para alcance P1 mantengo simple; si el TFG requiere multi-idioma estricto, añadir entradas en los .arb y reemplazar las cadenas (follow-up).

**Sobre el rediseño Off/AA/AAA del plan V16.** Requiere:
1. Sustituir `bool highContrast` por `ContrastLevel { off, aa, aaa }` en `ThemeNotifier` (con persistencia en guest box).
2. Adaptar `HighContrastTheme.apply` para producir dos variantes (AA con 4.5:1 manteniendo paleta, AAA con 7:1 o B/N puro).
3. Migración de datos existentes (`bool true` → `aa`, `bool false` → `off`).
4. UI con `SegmentedButton<ContrastLevel>` en lugar del Switch + sub-toggle.

Es un bloque coherente propio que recomendaría hacer en un sub-plan dedicado más adelante (cuando se aborde P2-X o se prepare la defensa del TFG).

**Sobre `appearance/widgets/accessibility_section.dart` tras quitarle daltonismo.** Queda solo con reduce motion + alto contraste. Renombrar la clase a `AnimationsAndContrastSection` sería más fiel; lo dejo como TODO opcional para no expandir el diff.
