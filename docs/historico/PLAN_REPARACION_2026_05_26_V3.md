# Plan de reparación v3 — Transitly (foco: personalización)

**Fecha:** 2026-05-26
**Autor:** Claude Code (Opus 4.7)
**Estado:** aprobado por el usuario, pendiente de ejecución
**Plan anterior:** `docs/historico/PLAN_REPARACION_2026_05_26_V2.md` (v2 — fixes de personalización quedaron incompletos)

---

## TL;DR — Root cause de la personalización

> **Bug crítico encontrado**: `TransitColorScheme.of(bool isDark)` en
> `lib/core/theme/transit_colors.dart:61-62` siempre devuelve la paleta base
> (`TransitDarkColors`/`TransitLightColors`), ignorando completamente la
> paleta seleccionada por el usuario en el ThemeNotifier.
>
> ```dart
> factory TransitColorScheme.of(bool isDark) =>
>     isDark ? const TransitDarkColors() : const TransitLightColors();
> ```
>
> Como **todos los widgets** de la app pintan con este factory en lugar de
> `Theme.of(context).colorScheme`, las paletas, el modo claro, el alto
> contraste, los modos especiales — nada cambia visualmente aunque
> internamente el `ThemeData` sí se actualice.
>
> Toda la fase **F1** del plan reescribe este factory para que consulte el
> `ProviderContainer` y devuelva la paleta correcta. Es la única forma de
> que la personalización funcione sin tocar cada widget.

---

## Cómo usar este plan

Idéntico a planes v1 y v2:

1. Coordinador despacha agentes A1..A6 en olas paralelas con
   `subagent_type: general-purpose`, modo foreground.
2. Cada agente recibe **solo** su brief + el bloque `Contexto global`.
3. Tras Wave 1: integración + `flutter analyze && flutter test`.
4. Tras Wave 2: lo mismo. Tras Wave 3: smoke manual + opcional build APK.
5. Reglas de oro: tokens del design system, 0 warnings de analyze, commits
   en español con prefijo convencional, NO push/build sin permiso del usuario.

---

## Contexto global del proyecto (incluir en TODOS los briefs)

```
PROYECTO: Transitly (nexto-stop-v2)
DESCRIPCIÓN: App Flutter de transporte público para Jerez (operador COMUJESA).
  Demo académica con datos mock desde assets/mock/comujesa_data.json.
STACK: Flutter 3.9.2+, Riverpod 2.6.1, go_router 17.2.3, flutter_map 7.0.2,
  hive 2.2.3, geolocator 13.0.0, supabase_flutter 2.8.0.
DIRECTORIO: C:\Users\k\Desktop\all\clase\nexto-stop-v2
RAMA: master

REGLAS OBLIGATORIAS:
1. Usar SIEMPRE tokens (TransitColorScheme, TransitTypography, TransitSpacing).
2. Reusar widgets compartidos (Pressable, StaggerList, GlassCard, etc.).
3. `flutter analyze` 0 warnings tras tu cambio.
4. Commits en español con prefijo convencional.
5. NO ejecutar `flutter build apk` ni `git push` salvo si el usuario lo pide.
6. Para l10n: añadir claves al final del JSON; no regenerar (lo hace Wave 3).

ESTADO DE PLANES PREVIOS:
- v1 (PLAN_REPARACION_2026_05_26.md): muchas tareas marcadas como hechas
  pero algunos fixes quedaron parciales o no llegaron a producción.
- v2 (PLAN_REPARACION_2026_05_26_V2.md): igual. Específicamente el fix de
  paletas/personalización no funcionó porque NO se tocó
  `TransitColorScheme.of()`.
```

---

## Errores reportados (4) → cobertura

| # | Error | Agente |
|---|-------|--------|
| 1 | "Al cambiar el tamaño de letra da error" | A2 |
| 2 | "El logo nada más entrar en la app se ve cortado" | A3 |
| 3 | "Los cambios que se hacen en el apartado de apariencia no cambian nada" | A1 (core) + A4 (pulido por widget) |
| 4 | "Al darle a entrar en la cuenta de invitado da error 404" | A5 |

---

## Mapa de waves

```
WAVE 1 (4 agentes paralelos, sin solape de archivos)
├── A1  CORE THEMING: TransitColorScheme reactivo + buildTheme con paleta + alto contraste real
├── A2  CRASH font scale: diagnóstico + clamp + hardening de widgets que usan fontSize*fontScale
├── A3  Logo cortado en splash (nativo + Dart)
└── A5  404 invitado: routing /signin → /sign-in + auditar enlaces rotos

WAVE 2 (1 agente, depende de A1)
└── A4  Pulido por widget: barrer los widgets que ignoran ThemeData y migrarlos a tokens reactivos donde haga falta

WAVE 3 (coordinador, NO agente)
└── flutter gen-l10n + flutter analyze + flutter test + smoke manual + capturas antes/después
```

### Tabla de archivos por agente

| Agente | Archivos que modifica | Archivos NUEVOS |
|--------|------------------------|------------------|
| **A1** | `lib/core/theme/transit_colors.dart` (factory `of()`), `lib/shared/providers/theme_notifier.dart` (exponer paleta efectiva como `ColorScheme` reactiva), `lib/shared/providers/active_palette_provider.dart` (NUEVO), `lib/core/theme/high_contrast_theme.dart` (efecto real), `lib/core/theme/backgrounds/prefab_backgrounds.dart` (añadir IDs faltantes), `lib/features/appearance/widgets/background_selector.dart` (asegurar coherencia), `lib/features/appearance/widgets/accessibility_section.dart` (sustituir DropdownButton<ColorBlindMode> por BottomSheet selector bonito), `lib/features/home/tabs/map_tab.dart` (SOLO la línea que construye `TransitMap` para pasar `mapStyle` y `key` reactiva al cambio de tema/estilo), `lib/features/map/transit_map.dart` (recibir y propagar `key` a TileLayer si requiere), `lib/l10n/*.arb` (claves al final) | `lib/shared/providers/active_palette_provider.dart` |
| **A2** | `lib/features/appearance/widgets/font_section.dart`, `lib/app.dart` (hardening del builder), `lib/shared/providers/theme_notifier.dart` (clamp ya está, verificar), audit de widgets con `fontSize: N * fontScale` para eliminar overflows | (ninguno) |
| **A3** | `pubspec.yaml` (sección `flutter_native_splash`), `lib/features/splash/splash_screen.dart` (usar versión padded), `assets/branding/*` (verificar padding) | eventual `assets/branding/transitly_logo_white_padded_v2.png` si necesita más padding |
| **A4** | (en Wave 2) audit de widgets con `Theme.of(context).brightness == Brightness.dark` + `TransitColorScheme.of(isDark)` para asegurar que tras A1 todos pintan correctamente. NO se modifica `route_card.dart`, `transit_map.dart` ni `appearance/*` salvo correcciones puntuales reportadas por A1. | (ninguno) |
| **A5** | `lib/features/home/widgets/profile_header_card.dart` (corregir `/signin` → `/sign-in`), audit con `Grep` de todos los `context.push('/signin')` y similares en el repo, `lib/core/router/app_router.dart` (solo si falta alguna ruta legítima) | (ninguno) |

### Conflictos controlados

- **`lib/shared/providers/theme_notifier.dart`**: A1 lo edita ampliamente. A2 SOLO verifica que el clamp de `fontScale` (l. 141-147) está en sitio; si está, no toca el archivo. **Regla**: A1 lo edita; A2 hace `git status` antes de tocarlo, y si A1 ya commiteó, A2 verifica que el clamp sigue ahí.
- **`lib/l10n/*.arb`**: solo A1 añade claves. **Regla**: añadir al final, antes del `}` final.
- **`lib/features/home/tabs/map_tab.dart`**: solo A1 lo toca (línea de TransitMap). NO toca otras zonas.

---

## WAVE 1 — Briefs (despachar en paralelo)

### A1 — CORE THEMING: TransitColorScheme reactivo + buildTheme con paleta + alto contraste real

```text
ROL: Engineer Flutter senior, especialista en theming, Riverpod, design tokens.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

PROBLEMA REPORTADO POR EL USUARIO (énfasis MUY ALTO):
"Los cambios que se hacen en el apartado de apariencia no cambian nada."
"Las paletas no cambian nada el estilo de mapa tampoco el brillo si va, el
apartado de fondo tampoco funciona correctamente."
"El modo de daltonismo si va pero el desplegable es un poco feo."
"El modo contraste no hace nada."

ROOT CAUSE IDENTIFICADO (CONFIRMADO LEYENDO EL CÓDIGO):
- lib/core/theme/transit_colors.dart líneas 61-62:
    factory TransitColorScheme.of(bool isDark) =>
        isDark ? const TransitDarkColors() : const TransitLightColors();
- Todos los widgets de la app llaman `TransitColorScheme.of(isDark)` en sus
  builds para obtener colores. Este factory IGNORA completamente la paleta
  seleccionada por el usuario en el `ThemeNotifier`.
- Por eso aunque el usuario elija Sunrise/Forest/Ocean/Mono, todo sigue
  pintándose con TransitDarkColors. Las paletas se persisten pero no
  llegan al rendering.
- El ThemeData sí se construye con la paleta correcta vía `buildTheme()`
  (línea 243-257 del theme_notifier), pero ninguna pantalla lo usa porque
  cogen colores con el factory bypass.

OBJETIVO ABSOLUTO:
Hacer que `TransitColorScheme.of()` consulte la paleta efectiva del
ThemeNotifier en tiempo real, sin necesidad de pasar `ref` a cada widget.
Esto debe hacerse SIN romper los ~200 callsites existentes.

ARCHIVOS PERMITIDOS:
- lib/core/theme/transit_colors.dart
- lib/shared/providers/theme_notifier.dart
- lib/shared/providers/active_palette_provider.dart (NUEVO)
- lib/core/theme/high_contrast_theme.dart
- lib/core/theme/backgrounds/prefab_backgrounds.dart
- lib/features/appearance/widgets/background_selector.dart
- lib/features/appearance/widgets/accessibility_section.dart
- lib/features/home/tabs/map_tab.dart  ← SOLO la línea/construcción de
  TransitMap(...) para añadir `mapStyle:` y `key:` reactiva. NO toques
  otras partes del archivo.
- lib/features/map/transit_map.dart  ← SOLO si necesitas que reciba `key`
  diferente para forzar recarga del TileLayer al cambiar tema/estilo.
  Idealmente con un `ValueKey` desde map_tab. Si la propagación funciona
  con `widget.mapStyle`, no toques transit_map.dart.
- lib/l10n/app_es.arb, app_en.arb, app_ar.arb (añadir claves al FINAL)

ARCHIVOS PROHIBIDOS:
- lib/features/appearance/widgets/font_section.dart (es de A2)
- lib/features/splash/splash_screen.dart (es de A3)
- lib/features/home/widgets/profile_header_card.dart (es de A5)
- cualquier widget genérico (route_card.dart, glass_card.dart, etc.) salvo
  que sea estrictamente necesario y lo justifiques.

═══════════════════════════════════════════════════════════════════
TAREAS CONCRETAS (lee TODAS antes de empezar)
═══════════════════════════════════════════════════════════════════

T1. Provider global de paleta efectiva
   Crea lib/shared/providers/active_palette_provider.dart:

       import 'package:flutter/material.dart';
       import 'package:flutter_riverpod/flutter_riverpod.dart';
       import '../../core/theme/transit_colors.dart';
       import 'theme_notifier.dart';
       import 'theme_provider.dart';

       /// Devuelve el TransitColorScheme efectivo según la paleta seleccionada
       /// y el modo claro/oscuro actual.
       final activePaletteSchemeProvider = Provider<TransitColorScheme>((ref) {
         final notifier = ref.watch(themeNotifierProvider);
         final themeMode = ref.watch(themeModeProvider);
         final brightness = _resolveBrightness(themeMode);
         final palette = notifier.palette;
         if (brightness == Brightness.dark) {
           return palette.darkScheme ?? const TransitDarkColors();
         }
         return palette.lightScheme ?? const TransitLightColors();
       });

       Brightness _resolveBrightness(ThemeMode mode) {
         switch (mode) {
           case ThemeMode.dark: return Brightness.dark;
           case ThemeMode.light: return Brightness.light;
           case ThemeMode.system:
             // Fallback al brillo del sistema operativo en runtime
             final platform = WidgetsBinding.instance.platformDispatcher;
             return platform.platformBrightness;
         }
       }

T2. ProviderContainer estático para `TransitColorScheme.of`
   El factory `of(bool isDark)` se llama desde widgets que no tienen `ref`
   (StatelessWidget normales sin Consumer). Para que consulte el provider
   sin propagar `ref` por toda la app, usa un `ProviderContainer` global
   accesible al runtime.

   En lib/main.dart (verifica primero si ya existe un container; si la app
   usa `ProviderScope` solamente, expón el container raíz):

       // En main.dart, antes de runApp:
       final container = ProviderContainer();
       runApp(UncontrolledProviderScope(
         container: container,
         child: const TransitlyApp(),
       ));

   IMPORTANTE: si main.dart ya tiene su propia inicialización compleja, NO
   la rompas. En lugar de eso, crea un setter:

       // En active_palette_provider.dart:
       ProviderContainer? _appContainer;
       void registerAppContainer(ProviderContainer c) => _appContainer = c;
       ProviderContainer? get appContainer => _appContainer;

   Y en main.dart llama `registerAppContainer(container)` tras crearlo.

T3. Reescritura del factory `TransitColorScheme.of`
   En lib/core/theme/transit_colors.dart línea 61-62, reemplaza:

       factory TransitColorScheme.of(bool isDark) =>
           isDark ? const TransitDarkColors() : const TransitLightColors();

   por:

       factory TransitColorScheme.of(bool isDark) {
         final container = appContainer;  // del active_palette_provider
         if (container == null) {
           // Fallback durante boot/tests
           return isDark ? const TransitDarkColors() : const TransitLightColors();
         }
         try {
           final notifier = container.read(themeNotifierProvider);
           final palette = notifier.palette;
           if (isDark) {
             return palette.darkScheme ?? const TransitDarkColors();
           }
           return palette.lightScheme ?? const TransitLightColors();
         } catch (_) {
           return isDark ? const TransitDarkColors() : const TransitLightColors();
         }
       }

   - Importa `active_palette_provider.dart` y `theme_notifier.dart` desde
     este archivo (cuidado con ciclos de imports — si hay, mueve el factory
     a un archivo nuevo y reexporta).
   - El try/catch protege contra fallos durante hot reload o tests.

   CRÍTICO: esto hace que CADA llamada al factory devuelva la paleta correcta
   sin necesidad de modificar los ~200 callsites en la app. Pero como el
   factory NO depende de `ref.watch`, los widgets necesitan reconstruirse
   cuando cambia la paleta. Eso se logra ya hoy porque app.dart hace
   `ref.watch(themeNotifierProvider)` y eso reconstruye todo el árbol
   (MaterialApp → router → screens) → cada screen re-llama al factory en
   su nuevo build. Verifica con un smoke test que sí ocurre.

T4. buildTheme respeta paleta seleccionada (ya casi lo hace)
   En lib/shared/providers/theme_notifier.dart líneas 243-257:
       ThemeData buildTheme(Brightness brightness) {
         final p = palette;
         final scheme = brightness == Brightness.dark
             ? (p.darkScheme ?? const TransitDarkColors())
             : (p.lightScheme ?? const TransitLightColors());
         final base = buildTransitTheme(
           scheme,
           fontScale: _fontScale,
           dyslexiaFontEnabled: _dyslexiaFontEnabled,
         );
         if (_highContrast) {
           return HighContrastTheme.apply(base, scheme);
         }
         return base;
       }
   - Esto YA está bien. Verifica que prefab_palettes.dart tiene
     `darkScheme:` y `lightScheme:` definidos para TODAS las paletas
     (Sunrise, Forest, Midnight, Ocean, Mono solo tienen darkScheme — bug
     potencial cuando el usuario cambie a modo Light con paleta Sunrise.
     Añade `lightScheme:` a cada una usando una versión clarificada de los
     colores, o cae a TransitLightColors si no se quiere diseñar light
     para cada paleta).
   - Solución mínima: para paletas que no tengan light, usa
     `lightScheme: TransitLightColors()` (paleta default clara). Documenta
     que la "personalización profunda" en modo Light es trabajo futuro.

T5. Alto contraste con EFECTO real (no solo bordes)
   Reescribe lib/core/theme/high_contrast_theme.dart `apply(base, scheme)`:

       static ThemeData apply(ThemeData base, TransitColorScheme scheme) {
         final hcScheme = _hcSchemeFrom(scheme, base.brightness);
         return base.copyWith(
           scaffoldBackgroundColor: hcScheme.bgRoot,
           colorScheme: base.colorScheme.copyWith(
             primary: hcScheme.accent,
             onPrimary: hcScheme.bgRoot,
             surface: hcScheme.bgSurface,
             onSurface: hcScheme.textHi,
             outline: hcScheme.border,
           ),
           cardTheme: base.cardTheme.copyWith(
             color: hcScheme.bgSurface,
             shape: RoundedRectangleBorder(
               borderRadius: BorderRadius.circular(12),
               side: BorderSide(color: hcScheme.border, width: 2),
             ),
           ),
           inputDecorationTheme: base.inputDecorationTheme.copyWith(
             fillColor: hcScheme.bgInput,
             enabledBorder: OutlineInputBorder(
               borderRadius: BorderRadius.circular(12),
               borderSide: BorderSide(color: hcScheme.border, width: 2),
             ),
           ),
           dividerTheme: DividerThemeData(
             color: hcScheme.border, thickness: 1.5,
           ),
         );
       }

       static TransitColorScheme _hcSchemeFrom(
           TransitColorScheme s, Brightness b) {
         // Devuelve un wrapper con:
         // - bgRoot/bgSurface/bgRaised opacos 100% (sin glass)
         // - textHi blanco puro en dark, negro puro en light
         // - border grueso (2px ya aplicado en cardTheme/inputDecoration)
         // - accent saturado
         // Implementa como clase HighContrastWrapper que delega en s pero
         // sobrescribe los campos clave.
         return HighContrastWrapper(s, brightness: b);
       }

   - Crea la clase HighContrastWrapper que implements TransitColorScheme y
     reemplaza ciertos getters por valores de máximo contraste.
   - El cambio debe ser INMEDIATAMENTE visible al activar el toggle.

T6. Mapa cambia color con tema y estilo
   En lib/features/home/tabs/map_tab.dart, localiza la línea donde se
   construye `TransitMap(...)` (alrededor de la línea 189 según planes
   previos, pero verifica). Modifícala así:

       final mapStyle = ref.watch(themeNotifierProvider.select((n) => n.mapStyle));
       final themeMode = ref.watch(themeModeProvider);
       ...
       TransitMap(
         key: ValueKey('${isDark ? "d" : "l"}-$mapStyle'),
         isDark: isDark,
         mapStyle: mapStyle,
         ...
       )

   - El `key` fuerza a flutter_map a reconstruir el TileLayer cuando el
     tema o estilo cambia. Sin key, el TileLayer cachea las tiles oscuras
     aunque cambies a Light.
   - Importa themeNotifierProvider y themeModeProvider si no están.

T7. Backgrounds completos
   En lib/core/theme/backgrounds/prefab_backgrounds.dart, añade:
       ImageBackground('assets/bg/soft_grid.png')
       ImageBackground('assets/bg/topo_lines.png')
   - Si la clase ImageBackground no existe, créala siguiendo el patrón de
     NoneBackground/ShaderBackground/GradientBackground (que implementan
     AppBackground).
   - Si los PNGs no existen en `assets/bg/`, genera versiones programáticas
     en su lugar:
       GeneratedGridBackground(spacing: 32, color: Color(0x11FFFFFF))
       GeneratedTopoBackground(seed: 42)
     que pinten con CustomPainter usando el accent del scheme actual.
   - Si añades nuevos assets PNG, regístralos en pubspec.yaml sección
     `assets:`.

T8. Selector de daltonismo bonito (BottomSheet)
   En lib/features/appearance/widgets/accessibility_section.dart líneas 64-89,
   reemplaza el DropdownButton<ColorBlindMode> por un GestureDetector que
   muestra el modo actual + chevron, y al pulsar abre un BottomSheet:

       Future<void> _showColorBlindSheet(BuildContext context, WidgetRef ref) {
         final c = ref.read(activePaletteSchemeProvider);
         return showModalBottomSheet<void>(
           context: context,
           backgroundColor: c.bgSurface,
           shape: const RoundedRectangleBorder(
             borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
           ),
           builder: (ctx) {
             final current = ref.watch(themeNotifierProvider.select(
                 (n) => n.colorBlindMode));
             return SafeArea(
               child: Column(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   const SizedBox(height: 8),
                   Container(
                     width: 36, height: 4,
                     decoration: BoxDecoration(
                       color: c.textLo,
                       borderRadius: BorderRadius.circular(2),
                     ),
                   ),
                   const SizedBox(height: 12),
                   Text(l10n.appearanceColorBlindSheetTitle,
                       style: TransitTypography.heading(c.textHi)),
                   const SizedBox(height: 12),
                   ...ColorBlindMode.values.map((m) => RadioListTile<ColorBlindMode>(
                         value: m, groupValue: current,
                         title: Text(_cbmLabel(m),
                             style: TransitTypography.bodyPrimary(c.textHi)),
                         activeColor: c.accent,
                         onChanged: (v) {
                           if (v != null) {
                             ref.read(themeNotifierProvider).colorBlindMode = v;
                             Navigator.of(ctx).pop();
                           }
                         },
                       )),
                   const SizedBox(height: 12),
                 ],
               ),
             );
           },
         );
       }

   - Sustituye el DropdownButton<ColorBlindMode> por:
       GestureDetector(
         onTap: () => _showColorBlindSheet(context, ref),
         child: Row(
           mainAxisSize: MainAxisSize.min,
           children: [
             Text(_cbmLabel(cbm), style: TransitTypography.bodySmall(c.textHi)),
             const SizedBox(width: 4),
             Icon(Icons.expand_more, color: c.textMid, size: 18),
           ],
         ),
       )

T9. Claves l10n
   - En app_es.arb, app_en.arb, app_ar.arb añade al FINAL:
       "appearanceColorBlindSheetTitle": "Modo daltonismo" / "Color blindness mode" / "وضع عمى الألوان"
   - NO regeneres l10n.

═══════════════════════════════════════════════════════════════════
SMOKE MANUAL TRAS TUS CAMBIOS (CRÍTICO):
═══════════════════════════════════════════════════════════════════
1. Cambia paleta a Sunrise → toda la app debe tomar tonos naranjas en
   accent, headings, FABs, badges.
2. Cambia a Forest → tonos verdes.
3. Cambia a Ocean → tonos cyan/azul.
4. Cambia a Mono → grises.
5. Cambia a Light (con paleta Default) → la app cambia a fondo claro.
6. Cambia mapStyle de "streets" a "dark" → las tiles cambian al estilo.
7. Activa Alto Contraste → fondos opacos sin glass, bordes 2px, textos máximo
   contraste, los elementos visualmente "saltan".
8. Cambia fondo a "soft_grid" → ves la cuadrícula sutil de fondo.
9. Cambia daltonismo a Deuteranopia → ColorFilter aplica (ya funcionaba).
10. Pulsa el selector de daltonismo → BottomSheet se abre con radio list bonita.

═══════════════════════════════════════════════════════════════════
VERIFICACIÓN:
═══════════════════════════════════════════════════════════════════
- `flutter analyze` → 0 warnings.
- `flutter test` → verde (si hay tests de theming, deben pasar; añade test
  unitario que verifique que cambiar paleta cambia el scheme devuelto por
  activePaletteSchemeProvider).
- Smoke manual completo (lista de arriba).

COMMITS sugeridos (separados):
- feat(theme): TransitColorScheme reactivo a la paleta activa
- feat(theme): paletas aplican a todos los widgets via factory
- feat(theme): alto contraste con efecto real
- feat(map): tile layer reactivo a tema/estilo
- feat(theme): backgrounds adicionales + selector de daltonismo bonito

REPORTE FINAL:
- Confirma cada T1-T9.
- Si el ProviderContainer estático causó algún issue en tests, explica
  cómo lo resolviste.
- Stack trace del smoke manual: paso a paso qué cambia ahora vs antes.
- Claves arb añadidas.
- Listado de archivos modificados.
```

---

### A2 — Crash al cambiar el tamaño de letra

```text
ROL: Engineer Flutter, especialista en diagnóstico de runtime errors.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

PROBLEMA REPORTADO POR EL USUARIO:
"A la hora de cambiar el tamaño de la letra da error."

ESTADO ACTUAL DEL CÓDIGO (revisado):
- lib/features/appearance/widgets/font_section.dart líneas 56-66: Slider
  min 0.85, max 1.4, divisions 11.
- lib/features/appearance/widgets/font_section.dart línea 75: el preview
  usa `fontSize: 13 * fontScale` — dentro del rango (11.05 – 18.2), no
  crashea por sí solo.
- lib/shared/providers/theme_notifier.dart líneas 141-147: el setter
  `fontScale` YA tiene clamp(0.85, 1.4). El clamp no es la causa.
- lib/app.dart líneas 52-54: usa `MediaQuery.textScalerOf(context).scale(1.0)`
  con hardening de NaN/negativos y clamp final (0.8, 2.5). Tampoco crashea
  por sí solo.

HIPÓTESIS:
El crash no es del clamp ni del TextScaler — es de un widget que tiene
contenido fijo + RenderFlex overflowed que se vuelve fatal con textScale
alto. Posibles culpables:
- RouteCard (line code badge fijo 60px con text largo)
- Cards con ConstrainedBox(maxWidth: N) y texto interno sin Flexible
- TextField hint con maxLines:1 y texto en árabe (RTL) o cualquier locale
  con caracteres anchos
- Algún widget con `Row` que no permite shrink

OBJETIVO:
1. Reproducir el crash y capturar el stack trace exacto.
2. Identificar el widget culpable.
3. Arreglarlo con Flexible/Expanded/FittedBox según corresponda.

ARCHIVOS PERMITIDOS:
- lib/features/appearance/widgets/font_section.dart (verificar)
- lib/app.dart (hardening adicional si requiere)
- lib/shared/providers/theme_notifier.dart (SOLO verificar clamp; NO toques
  otros métodos — son territorio de A1)
- Cualquier widget que identifiques como culpable del crash. Para CADA
  modificación, lista el archivo y el motivo en el reporte.

ARCHIVOS PROHIBIDOS:
- TODO el resto de archivos que A1 toca (transit_colors, theme_notifier
  excepto el clamp, prefab_backgrounds, etc.).
- splash_screen.dart (es de A3)
- profile_header_card.dart (es de A5)

═══════════════════════════════════════════════════════════════════
TAREAS CONCRETAS:
═══════════════════════════════════════════════════════════════════

T1. Reproducir el crash
   - Ejecuta `flutter run` en modo debug.
   - Ve a Apariencia → sección "Tamaño de texto".
   - Mueve el slider hasta el máximo (140%).
   - Captura el stack trace EXACTO de la consola de Flutter / DevTools.
   - Si el crash es de tipo RangeError, IndexError, RenderFlex overflowed
     fatal, NoSuchMethodError, etc., apunta el widget y el archivo.

T2. Hardening preventivo (siempre)
   - En app.dart líneas 52-54, ya tienes:
       final rawSystem = MediaQuery.textScalerOf(context).scale(1.0);
       final systemScale = rawSystem.isFinite && rawSystem > 0 ? rawSystem : 1.0;
       final combined = (systemScale * themeNotifier.fontScale).clamp(0.8, 2.5);
     Está OK. Verifica que sigue así.

   - En theme_notifier.dart línea 141-147, el clamp(0.85, 1.4) ya existe.
     Verifica que sigue.

   - En font_section.dart línea 75, cambia `13 * fontScale` por algo más
     robusto: simplemente `13 * fontScale` ya queda en [11.05, 18.2], sin
     riesgo. Si crashea, el problema está en otro lado.

T3. Resolver el crash
   - Una vez identificado el widget culpable, aplica el fix mínimo:
     - Si es overflow: envuelve `Text` en `Expanded` o `Flexible`.
     - Si es texto fijo width: usa `FittedBox(fit: BoxFit.scaleDown, child: Text(...))`.
     - Si es `Container(width: N)` con Text dentro: cambia a
       `BoxConstraints(minWidth: N, maxWidth: N * 1.4)` o usa FittedBox.
   - NO hagas refactor masivo; SOLO los archivos del culpable.

T4. Si el crash es por dyslexia font (Google Fonts cargando fuente remota)
   - Comprobar si el crash sucede solo con `dyslexiaFontEnabled=true`.
   - Posible: GoogleFonts.atkinsonHyperlegibleTextTheme falla si no hay
     internet la primera vez. Solución: añadir un `runZonedGuarded` en el
     boot o cachear la fuente localmente (asset opcional). Documenta tu
     decisión.

═══════════════════════════════════════════════════════════════════
VERIFICACIÓN:
═══════════════════════════════════════════════════════════════════
- Slide el slider de 85% a 140% en CADA pantalla:
  - Home (tu próximo bus, paradas cerca, mis líneas, avisos)
  - Mapa (sheet de líneas)
  - Buscador
  - Tarjeta NFC
  - Perfil
  - Apariencia (autoreferencial — slider en su propia pantalla)
- En ningún caso debe crashear ni mostrar RenderFlex overflowed FATAL
  (los amarillos no fatales son tolerables si el contenido se trunca con
  ellipsis).

COMMIT(s):
- fix(a11y): crash al subir font scale resuelto (<widget culpable>)
- fix(a11y): hardening adicional del textScale en app.dart

REPORTE FINAL:
- Stack trace EXACTO del crash original (pega el output de flutter run).
- Widget identificado y línea exacta.
- Fix aplicado (snippet).
- Lista de pantallas verificadas tras el fix.
```

---

### A3 — Logo cortado en splash (nativo y Dart)

```text
ROL: Engineer Flutter, especialista en assets/branding y splash screens.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

PROBLEMA REPORTADO POR EL USUARIO:
"El logo nada más entrar en la app se ve cortado."

ESTADO ACTUAL DEL CÓDIGO (revisado):
- pubspec.yaml líneas 66-74: `flutter_launcher_icons` usa
  `assets/branding/transitly_logo_white_padded.png` con inset 0 (CORRECTO).
- pubspec.yaml líneas 76-82: `flutter_native_splash` usa
  `assets/branding/transitly_logo_white.png` SIN padding. El splash nativo
  de Android 12+ aplica una máscara circular y recorta el logo si llega
  al borde del cuadro.
- lib/features/splash/splash_screen.dart líneas 122-127: el splash Dart
  usa `transitly_logo_white.png` a 240x240. Si el PNG tiene contenido
  tocando los bordes, se ve cortado.

OBJETIVO:
1. Hacer que el splash nativo Android 12+ NO recorte el logo.
2. Hacer que el splash Dart use la versión padded del logo.
3. Verificar que la versión padded tiene MARGEN INTERNO suficiente
   (al menos 25% del ancho total como transparente alrededor).

ARCHIVOS PERMITIDOS:
- pubspec.yaml (secciones flutter_launcher_icons y flutter_native_splash)
- lib/features/splash/splash_screen.dart
- assets/branding/ (puedes añadir variantes si necesario)

ARCHIVOS PROHIBIDOS: cualquier otro código Dart.

═══════════════════════════════════════════════════════════════════
TAREAS CONCRETAS:
═══════════════════════════════════════════════════════════════════

T1. Inspeccionar las imágenes actuales
   - Abre con un visor el archivo
     assets/branding/transitly_logo_white.png  →  ¿tiene margen transparente
     alrededor del logo? ¿qué tamaño?
   - Abre assets/branding/transitly_logo_white_padded.png  →  ídem.
   - Reporta dimensiones de cada uno y observación de padding.

T2. Si la versión padded NO tiene padding suficiente, genera una nueva
   - Crea con ImageMagick (o Dart con `image` package en un script
     descartable) un PNG transitly_logo_white_padded_v2.png con:
       - Dimensiones cuadradas (ej. 1024x1024)
       - Logo blanco centrado al 60% del ancho (40% de transparencia)
   - Si no tienes ImageMagick disponible, redimensiona en Dart usando el
     SDK assets-pipeline:
       `dart run` con un script que use `image: ^4.0.0` para resize y
       composite.
   - Si NO es factible generar la imagen, documenta y deja la versión
     padded actual (verifica que su padding sea suficiente para inset 0).

T3. flutter_native_splash usa la versión padded
   - En pubspec.yaml línea 78:
     ```yaml
     flutter_native_splash:
       color: "#08081A"
       image: assets/branding/transitly_logo_white_padded.png
       android_12:
         icon_background_color: "#08081A"
         image: assets/branding/transitly_logo_white_padded.png
       fullscreen: false
     ```
   - Regenera:
       flutter pub get
       dart run flutter_native_splash:create

T4. splash_screen.dart Dart usa la versión padded
   - En splash_screen.dart línea 122-127, cambia:
       Image.asset('assets/branding/transitly_logo_white.png', ...)
     por:
       Image.asset('assets/branding/transitly_logo_white_padded.png', ...)
   - Si el tamaño aparente del logo dentro del cuadro queda muy pequeño
     ahora (porque el PNG ahora tiene 40% padding), aumenta el width/height
     del Image.asset a 300x300 para compensar.

T5. Iconos launcher (verificación)
   - flutter_launcher_icons ya usa la versión padded con inset 0. Si tras
     T3-T4 el icono del launcher se ve raro, ajusta `adaptive_icon_foreground_inset`
     a un valor positivo (4-8) y regenera con:
       dart run flutter_launcher_icons

═══════════════════════════════════════════════════════════════════
VERIFICACIÓN:
═══════════════════════════════════════════════════════════════════
- `flutter analyze`
- Build debug Android: `flutter build apk --debug` debe pasar (NO release).
- Instala el APK debug en dispositivo o emulador Android 12+:
  - Al abrir → splash nativo muestra logo completo, no recortado en máscara
    circular.
  - Tras splash → splash Dart muestra logo completo a buen tamaño visual.
  - Icono del launcher (long-press home, ver lista de apps) → logo completo
    sin recorte.
- Captura 3 screenshots (splash nativo, splash Dart, icono launcher) para
  el reporte.

COMMIT(s):
- fix(branding): splash y logo Dart usan versión padded sin recorte

REPORTE FINAL:
- Confirma cada T1-T5.
- Dimensiones del PNG inicial y final.
- Screenshots descritos (no embebidos, solo descripción de qué se ve).
```

---

### A5 — 404 al "Entrar como invitado" + audit de routing

```text
ROL: Engineer Flutter, especialista en go_router y navegación.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

PROBLEMA REPORTADO POR EL USUARIO:
"Al darle a entrar en la cuenta de invitado da error 404."

ROOT CAUSE IDENTIFICADO (CONFIRMADO LEYENDO EL CÓDIGO):
- lib/features/home/widgets/profile_header_card.dart línea 85:
    onTap: () => context.push('/signin'),
- lib/core/router/app_router.dart línea 86-87:
    GoRoute(
      path: '/sign-in',  ← CON GUIÓN
      pageBuilder: (context, state) => _slide(state, const SignInScreen()),
    )
- El botón "ENTRAR" (texto: l10n.profileGuestSignIn) intenta navegar a
  `/signin` (sin guión) pero la ruta registrada es `/sign-in`. Por eso
  go_router devuelve 404.

OBJETIVO:
1. Corregir el push para usar la ruta correcta.
2. Auditar el resto del repo en busca de navegaciones rotas similares.

ARCHIVOS PERMITIDOS:
- lib/features/home/widgets/profile_header_card.dart
- lib/core/router/app_router.dart (SOLO si encuentras rutas faltantes;
  no toques las existentes salvo añadir)
- Cualquier otro archivo donde encuentres un push roto (documenta en
  reporte).

ARCHIVOS PROHIBIDOS: theme/, splash/, font_section.dart (son de A1/A2/A3).

═══════════════════════════════════════════════════════════════════
TAREAS CONCRETAS:
═══════════════════════════════════════════════════════════════════

T1. Fix del 404 invitado
   - En lib/features/home/widgets/profile_header_card.dart línea 85,
     cambia:
       onTap: () => context.push('/signin'),
     por:
       onTap: () => context.push('/sign-in'),

T2. Audit de navegaciones rotas
   - Lista todas las rutas registradas en app_router.dart con Grep:
       rg "path:\s*'" lib/core/router/app_router.dart
   - Recoge en una lista (PATHS_VALIDOS).
   - Lista todas las llamadas `context.push('/...)`, `context.go('/...)`,
     `context.replace('/...)`, `GoRouter.of(context).go('/...')` en el repo:
       rg "context\.(push|go|replace)\(['\"]/" lib/
       rg "GoRouter.of\(context\)\.(push|go|replace)\(['\"]/" lib/
   - Para cada call, verifica que el path está en PATHS_VALIDOS o es un
     prefijo válido (ej. `/route/${id}` es válido si existe ruta
     `/route/:routeId`).
   - REPORTA cada mismatch.

T3. Fixes adicionales
   - Para cada mismatch encontrado, corrígelo si es trivial (typo, guión
     vs underscore). Si el path no existe en absoluto en el router, NO
     inventes — añade ese path al reporte como "ruta faltante" para que
     el coordinador decida si crearla.

T4. Cuenta de invitado: ¿realmente abre algo útil?
   - Tras el fix, el botón "ENTRAR" lleva a /sign-in (lib/features/auth/
     signin_screen.dart). Verifica que esa pantalla:
     - Carga sin error.
     - Tiene un flujo de login funcional O un botón de "Continuar como
       invitado".
   - Si la pantalla está vacía/rota, documenta. NO la arregles aquí (es
     trabajo de otro agente).

═══════════════════════════════════════════════════════════════════
VERIFICACIÓN:
═══════════════════════════════════════════════════════════════════
- `flutter analyze`
- `flutter test`
- Smoke manual: en home, pulsa el botón "ENTRAR" de la tarjeta de
  invitado → debería navegar a /sign-in sin 404.
- No realices otros fixes salvo los listados en T3.

COMMIT(s):
- fix(routing): typo /signin → /sign-in en profile_header_card
- fix(routing): rutas rotas adicionales (si hubiera)

REPORTE FINAL:
- Confirma T1.
- Lista completa de PATHS_VALIDOS encontrados.
- Lista completa de navegaciones encontradas con su status (ok/rota).
- Otros fixes aplicados (si hubiera).
- Si la pantalla /sign-in está rota tras la nav, lo documentas como
  pendiente.
```

---

## WAVE 2 — A4: Pulido por widget tras A1

> Esta wave es opcional pero recomendada para asegurar que tras A1 no
> queden focos sin migrar. Si el coordinador verifica el smoke de A1 y
> todo va bien, esta wave se puede omitir.

```text
ROL: Engineer Flutter, especialista en design system.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

CONTEXTO TRAS WAVE 1:
- A1 reescribió `TransitColorScheme.of()` para que consulte el provider
  global. Ahora cualquier widget que use `TransitColorScheme.of(isDark)`
  recibe la paleta seleccionada.
- TODOS los widgets deberían reaccionar al cambio de paleta automáticamente
  porque `app.dart` hace `ref.watch(themeNotifierProvider)` y eso
  reconstruye el árbol.
- PERO: algunos widgets pueden tener colores hardcoded (`Colors.white`,
  `Color(0xFF...)`) que NO usan TransitColorScheme y por tanto siguen sin
  cambiar al elegir paleta.

OBJETIVO:
Barrer el repo, listar TODOS los hardcodes de color en widgets visibles
(no en tests ni en archivos de theme), y reemplazar los que afecten
visualmente al cambiar paleta.

ARCHIVOS PERMITIDOS:
- Cualquier archivo en lib/ EXCEPTO:
  - lib/core/theme/** (es de A1)
  - lib/shared/providers/theme_notifier.dart (es de A1)
  - lib/features/appearance/** (es de A1)
  - lib/features/splash/** (es de A3)
  - lib/features/home/widgets/profile_header_card.dart (es de A5)

═══════════════════════════════════════════════════════════════════
TAREAS CONCRETAS:
═══════════════════════════════════════════════════════════════════

T1. Audit completo
   - Ejecuta:
       rg "Color\(0xFF" lib/ --type dart -g '!lib/core/theme/**' -g '!**/*.g.dart' -g '!**/*.freezed.dart'
       rg "Colors\.[a-zA-Z]+" lib/ --type dart -g '!lib/core/theme/**' -g '!**/*.g.dart' -g '!**/*.freezed.dart'
   - Lista cada hit con archivo:línea + color.

T2. Filtrar los hits que afectan al cambio de paleta
   - Hits aceptables (NO cambiar):
     - Colores semánticos de estado (rojo de error, verde de éxito, etc.)
       cuando son intencionalmente fijos.
     - Iconos de marca de operadores externos.
     - Sombras (Colors.black con alpha bajo).
   - Hits que SÍ cambiar:
     - Fondos de cards, paneles, sheets.
     - Bordes y dividers.
     - Texto principal/secundario.
     - Acentos (botones, FAB, headings).
   - Para cada hit cambiable, identifica el token equivalente:
     - Background → c.bgRoot / bgSurface / bgRaised / bgInput / bgElevated
     - Borde → c.border / borderFocus / divider
     - Texto → c.textHi / textMid / textLo / textDisabled
     - Acento → c.accent / accentMuted / accentBg
     - Estado → c.stateOnRoute / stateOnTime / stateDelay / stateCancelled / stateIdle

T3. Aplicar fixes
   - Para cada widget afectado, lee el archivo, encuentra el contexto,
     decide si ya tiene acceso a `c = TransitColorScheme.of(isDark)`. Si
     no, añade esa línea al build. Luego sustituye el hardcode por el
     token.

T4. Verificación cruzada con A1
   - El test smoke de A1 incluye "cambiar paleta a Sunrise → toda la app
     se vuelve naranja". Tras tu trabajo, ese smoke debe pasar al 100%.
     Si encuentras widgets que NO cambian, son los culpables.

═══════════════════════════════════════════════════════════════════
VERIFICACIÓN:
═══════════════════════════════════════════════════════════════════
- `flutter analyze`
- Smoke manual cruzado con A1: paleta Sunrise → ningún elemento queda
  en colores violetas/púrpuras (paleta default).

COMMIT:
refactor(theme): eliminar hardcodes de color en widgets (cobertura plena de paleta)

REPORTE FINAL:
- Audit count: cuántos hits encontrados, cuántos cambiados, cuántos
  intencionalmente dejados.
- Lista de archivos modificados.
```

---

## WAVE 3 — Verificación coordinador

1. **Regenerar l10n:**
   ```bash
   flutter gen-l10n
   ```
2. **Análisis y tests:**
   ```bash
   flutter analyze    # 0 warnings
   flutter test       # 100% verde
   ```
3. **Smoke manual (prioridad alta para personalización):**
   - **F3 PERSONALIZACIÓN (lo principal del plan v3)**:
     - Cambiar paleta → toda la app cambia visualmente (no solo el accent).
     - Cambiar modo claro/oscuro → mapa y app cambian.
     - Cambiar estilo de mapa → tiles cambian sin reiniciar.
     - Cambiar fondo → soft_grid, topo_lines, gradient, smoke se ven.
     - Slider de tamaño de letra hasta 140% → ningún crash en ninguna
       pantalla.
     - Toggle dislexia → tipografía cambia en todas las pantallas.
     - Daltonismo → BottomSheet bonito, ColorFilter aplica.
     - Alto contraste → bordes 2px, fondos sólidos, textos máx contraste.
   - **F2 LOGO**: splash nativo + splash Dart + icono launcher SIN recorte.
   - **F4 INVITADO**: pulsar "ENTRAR" en la tarjeta de invitado → carga
     /sign-in sin 404.
4. **Build APK release (opcional, solo si el usuario lo pide):**
   ```bash
   flutter build apk --release
   ```

---

## Riesgos y notas

- **A1 toca el corazón del theming.** Si el `ProviderContainer` estático
  causa problemas (tests, hot reload), tiene fallback al modo legacy
  (devuelve TransitDarkColors). El coordinador debe vigilar específicamente
  ese fallback durante `flutter test`.
- **El crash de fontScale (A2) no tiene root cause confirmado todavía.**
  El agente A2 debe reproducir antes de patchear. Si no logra reproducir,
  añadir defensa preventiva en widgets sospechosos.
- **Los planes v1 y v2 ya tocaron parte de este territorio.** v3 NO
  asume que estén aplicados — verifica el estado actual antes de tocar.
- **La regla "lightScheme: TransitLightColors() para paletas no-default"
  (T4 de A1)** es una decisión de tipo pragmático. Si el usuario quiere
  paletas Light personalizadas (Sunrise-light, Forest-light), es trabajo
  futuro y va en un plan v4.
- **WAVE 2 (A4) es opcional.** Si tras WAVE 1 el smoke de personalización
  pasa al 100%, no es necesaria. El coordinador decide.

---

## Cobertura final

| Error | Agente | Estado esperado tras plan |
|-------|--------|---------------------------|
| Cambiar tamaño de letra crashea | A2 | Slider funciona 85%-140% sin crash en ninguna pantalla |
| Logo cortado al entrar | A3 | Splash nativo, Dart y launcher icon completos |
| Cambios apariencia no aplican | A1 (+ A4) | Paletas, modo claro, mapStyle, fondo, alto contraste, daltonismo: todos producen cambio visible |
| Cuenta invitado 404 | A5 | Pulsar "ENTRAR" lleva a /sign-in sin error |
