# Plan de reparación v6 — Transitly (cierre tras review)

**Fecha:** 2026-05-27
**Autor:** Claude Code (Opus 4.7)
**Origen:** review completa post-v5 que detectó 7 puntos pendientes (2 P0 críticos en `presentation/`, 3 P1 en la app móvil, 1 P2 antiguo, 1 P3 cosmético).
**Plan anterior:** `PLAN_REPARACION_2026_05_26_V5.md`.

---

## TL;DR

| # | Prioridad | Problema | Lado | Agente |
|---|-----------|----------|------|--------|
| 1 | 🔴 P0 | 24 atributos `class=` malformados con `data-delay` dentro de las comillas, en 5 secciones | Presentation | A1 |
| 2 | 🔴 P0 | APK físico no está en `presentation/public/` → botón "Descargar APK" da 404 | Presentation | A2 |
| 3 | 🟡 P1 | No se pueden guardar **varias** paletas custom con nombre (feature pedido) | App móvil | A3 |
| 4 | 🟡 P1 | Marker de usuario sin círculo de precisión + caché FMTC no separada por estilo (mapa no cambia con estilo/tema) | App móvil | A4 |
| 5 | 🟢 P2 | Widgets nativos Android sin implementar (pendiente desde plan v2) | App móvil | A5 |
| 6 | 🟢 P3 | 68 infos `prefer_const_constructors` en tests | App móvil | Coordinador (auto-fix) |

---

## Estructura

```
WAVE 1 (4 agentes paralelos, sin solape de archivos)
├── A1  Fix HTML/CSS: 5 secciones Astro con `class=` roto
├── A2  Subir APK a presentation/public/ + verificar deploy workflow
├── A3  Paletas custom: varias con nombre, persistidas en Hive
└── A4  Mapa: círculo de precisión + caché FMTC por estilo

WAVE 2 (1 agente, depende de nada)
└── A5  Widgets nativos Android (carry-over de planes v2-v5)

WAVE 3 (coordinador, NO agente)
└── dart fix --apply + flutter analyze + flutter test + smoke + deploy presentation
```

### Tabla de archivos por agente

| Agente | Archivos que modifica | Archivos NUEVOS |
|--------|------------------------|------------------|
| **A1** | `presentation/src/components/Section03Solution.astro`, `Section06Features.astro`, `Section09Quality.astro`, `Section11Security.astro`, `Section14Download.astro` | — |
| **A2** | `presentation/public/` (añadir APK), opcional `presentation/src/components/Section14Download.astro` (href a release de GitHub) | `presentation/public/transitly-v1.0.0-mvp.apk` (o usar URL externa) |
| **A3** | `lib/shared/providers/theme_notifier.dart`, `lib/features/appearance/widgets/palette_section.dart`, `lib/features/appearance/custom_palette_screen.dart`, `lib/l10n/app_*.arb` (claves al final) | `lib/shared/models/named_custom_palette.dart` |
| **A4** | `lib/features/map/layers/user_location_layer.dart`, `lib/shared/providers/user_location_provider.dart`, `lib/data/fmtc/fmtc_provider.dart`, `lib/features/home/tabs/map_tab.dart` (SOLO el `ref.watch(fmtcTileProviderProvider…)`) | — |
| **A5** | `android/app/src/main/AndroidManifest.xml`, `lib/data/widgets_native/widget_data_writer.dart`, `lib/features/widgets_native/widgets_settings_screen.dart`, `pubspec.yaml` (assets si requiere) | `android/app/src/main/kotlin/.../widgets/TransitlyNextBusWidget.kt`, `…/widgets/TransitlyMyLineWidget.kt`, `android/app/src/main/res/xml/widget_next_bus_info.xml`, `…/widget_my_line_info.xml`, `android/app/src/main/res/layout/widget_next_bus.xml`, `…/widget_my_line.xml`, `lib/shared/providers/widget_data_provider.dart` |

### Conflictos controlados

- `lib/features/home/tabs/map_tab.dart`: A4 toca **solo** la línea de `ref.watch(fmtcTileProviderProvider…)`. Si el cambio requiere refactor mayor, A4 abre PR separado.
- `lib/l10n/*.arb`: solo A3 añade claves. Al final del JSON.

---

## Contexto global (pegar en todos los briefs)

```
PROYECTO: Transitly (nexto-stop-v2) — App Flutter de transporte público para Jerez.
STACK: Flutter 3.9.2+, Riverpod 2.6.1, go_router 17.2.3, flutter_map 7.0.2,
hive 2.2.3, flutter_map_tile_caching 10.0.0, home_widget 0.7.0, Astro (presentation/).
DIRECTORIO: C:\Users\k\Desktop\all\clase\nexto-stop-v2
RAMA: master

REGLAS:
- 0 warnings de flutter analyze tras tu cambio.
- Tokens del design system siempre (TransitColorScheme, TransitTypography, TransitSpacing).
- Commits en español con prefijo convencional.
- NO ejecutar flutter build apk --release ni git push salvo si lo pide el usuario.
- Para l10n: añadir claves al final del JSON. NO regenerar.

ESTADO ACTUAL (verificado en review 2026-05-27):
- flutter analyze: 0 errores, 0 warnings, 68 infos (solo prefer_const_constructors en tests).
- Tests: 453 passed.
- App móvil: la mayoría de los fixes v1-v5 están aplicados (KeyedSubtree+visualKey,
  TransitColorScheme reactivo, paletas Default oscuro/claro, Atkinson Hyperlegible
  empaquetada, FAB anclado al sheet, smoke opacity solo al painter).
- Presentation: deployed via .github/workflows/deploy-presentation.yml a GitHub Pages
  cada push a master que toque presentation/. Astro v5+.
```

---

## WAVE 1 — Briefs

### A1 — Fix HTML/CSS: 24 atributos `class=` malformados

```text
ROL: Engineer frontend, audit de HTML/CSS en Astro.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

PROBLEMA:
24 atributos `class=` en 5 secciones de Astro tienen `data-delay="N"` DENTRO
de las comillas del class. Esto rompe el atributo (las clases CSS posteriores
NO se aplican) y deja atributos basura en el HTML.

Ejemplo del bug (Section03Solution.astro:11):
    <article class="glass-card hover-lift p-6 reveal reveal data-delay="100" group hover:border-transit-accent/40 transition-all duration-300">

El navegador parsea:
    class="glass-card hover-lift p-6 reveal reveal data-delay="   ← cierra ahí
    100"   ← atributo basura
    group   ← atributo basura
    hover:border-transit-accent/40 transition-all duration-300"   ← más basura

Resultado: las clases `group`, `hover:border-transit-accent/40`, `transition-all`
y `duration-300` NO se aplican, y `reveal` aparece duplicado. Hover/transición/
animaciones rotas en esos elementos.

ARCHIVOS PERMITIDOS:
- presentation/src/components/Section03Solution.astro (6 ocurrencias)
- presentation/src/components/Section06Features.astro (8 ocurrencias)
- presentation/src/components/Section09Quality.astro (4 ocurrencias)
- presentation/src/components/Section11Security.astro (2 ocurrencias)
- presentation/src/components/Section14Download.astro (4 ocurrencias)

ARCHIVOS PROHIBIDOS: cualquier otro.

═══════════════════════════════════════════════════════════════════
TAREAS CONCRETAS:
═══════════════════════════════════════════════════════════════════

T1. Patrón de fix (aplicar a las 24 ocurrencias)
   Antes:
       class="… reveal data-delay="100" …"
   Después:
       class="… reveal …" data-delay="100"

   En la práctica, para cada hit, encuentra la subcadena:
       reveal data-delay="N"
   dentro de un `class="…"` y:
   1) Quita ese subfragmento del valor del `class`.
   2) Después del `class="…"` añade el atributo separado:
       data-delay="N"
   3) Si el `class` original tiene `reveal` repetido (algunos ejemplos como
      `class="… reveal reveal data-delay="100" …"`), deja solo UNO de los
      `reveal`.

T2. Script o búsqueda automatizada
   Recomendado: usar Edit con `replace_all: true` en cada archivo, o bien
   un script Python/Node de un solo uso. Ejemplo de regex para sustitución
   masiva (Node/Python):

       /reveal\s+data-delay="(\d+)"/g  →  reemplazar por  reveal

   y luego añadir `data-delay="$1"` como atributo separado del elemento.

   Si la sustitución regex resulta engorrosa con HTML enriquecido, edita
   manualmente las 24 ocurrencias. Son 5 archivos pequeños.

T3. Limpiar duplicados de `reveal`
   Mientras editas, si encuentras `reveal reveal` (porque alguien añadió
   reveal dos veces), reemplaza por `reveal` solo.

T4. Verificación con `npm run build`
   Tras tus cambios:
       cd presentation
       npm run build
   Debe pasar sin errores. El output HTML resultante en
   `presentation/dist/index.html` debe tener cada `data-delay="N"` como
   atributo SEPARADO del `class`, no dentro.

═══════════════════════════════════════════════════════════════════
VERIFICACIÓN:
═══════════════════════════════════════════════════════════════════
- Tras T4, abre `presentation/dist/index.html` y busca con grep:
      grep -c 'data-delay="[0-9]*"' presentation/dist/index.html
  Debe coincidir con el número de elementos `data-delay` originales (≈24).
- Verifica que NO queda ninguna ocurrencia de
      grep 'class=".*data-delay=' presentation/dist/index.html
  Debe ser 0.
- Ejecuta `npm run dev` y abre la URL local. Las secciones 3, 6, 9, 11, 14
  deben tener hover effects y transiciones funcionando (passar el cursor
  sobre las cards muestra el efecto definido en `hover:border-…`).

COMMIT:
fix(presentation): atributos class malformados con data-delay dentro

REPORTE FINAL:
- Lista de archivos cambiados con número de hits por archivo.
- Confirmación de `npm run build` OK.
- Cuántos `data-delay` quedan correctamente como atributo separado.
```

---

### A2 — APK físico en `presentation/public/`

```text
ROL: Engineer release/DevOps.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

PROBLEMA:
`presentation/src/components/Section14Download.astro:16` apunta a:
    href={`${import.meta.env.BASE_URL}/transitly-v1.0.0-mvp.apk`}

Pero el archivo `transitly-v1.0.0-mvp.apk` NO está en
`presentation/public/`. Cuando Astro construye el sitio, no se copia
nada llamado así a `presentation/dist/`. Cuando GitHub Pages sirve la
página, el botón "Descargar APK" devuelve 404.

DECISIÓN A TOMAR:
Hay dos opciones razonables. Elige UNA y aplícala.

OPCIÓN A — APK al repo (más simple, +20-40 MB en presentation/public/)
   - Construye un APK release: `flutter build apk --release`
   - Copia el APK resultante (`build/app/outputs/flutter-apk/app-release.apk`)
     a `presentation/public/transitly-v1.0.0-mvp.apk`.
   - Astro lo copiará a `dist/` en el build → GitHub Pages lo servirá.
   - Pros: funciona inmediatamente, sin dependencias externas.
   - Cons: +30 MB al repo y al artefacto de GH Pages.

OPCIÓN B — Release de GitHub (recomendado para producción)
   - Crea un release v1.0.0-mvp en
     https://github.com/astralk9999/Transitly/releases con el APK adjunto.
   - Cambia `Section14Download.astro:16` para que el href apunte a:
       href="https://github.com/astralk9999/Transitly/releases/download/v1.0.0-mvp/transitly-v1.0.0-mvp.apk"
   - Pros: el APK no pesa en GH Pages ni en el repo de presentation.
   - Cons: requiere que el usuario tenga permisos de release en GitHub.

ARCHIVOS PERMITIDOS:
- presentation/public/ (añadir APK si Opción A)
- presentation/src/components/Section14Download.astro (si Opción B)
- .gitignore (verificar que NO ignora .apk en presentation/public/ si Opción A)

═══════════════════════════════════════════════════════════════════
TAREAS CONCRETAS (elige UNA):
═══════════════════════════════════════════════════════════════════

OPCIÓN A:
T1. Verifica que existe ya un APK release:
       ls -la build/app/outputs/flutter-apk/
   Si no existe, NO ejecutes `flutter build apk --release` sin permiso
   explícito del usuario; deja documentado en el reporte que el usuario
   tiene que ejecutarlo y luego copiar.

T2. Si el APK existe, copia:
       cp build/app/outputs/flutter-apk/app-release.apk \
          presentation/public/transitly-v1.0.0-mvp.apk

T3. Verifica `.gitignore` no excluye `.apk` en `presentation/public/`:
       grep -E "\.apk$|/build/" .gitignore
   Si hay regla que ignora .apk globalmente, añade excepción:
       !presentation/public/*.apk

T4. Smoke build:
       cd presentation && npm run build
       ls -la dist/ | grep apk    # debe aparecer el APK copiado a dist

OPCIÓN B:
T1. Modifica Section14Download.astro línea 16:
       Antes: href={`${import.meta.env.BASE_URL}/transitly-v1.0.0-mvp.apk`}
       Después: href="https://github.com/astralk9999/Transitly/releases/download/v1.0.0-mvp/transitly-v1.0.0-mvp.apk"
   Y añade target="_blank" rel="noopener" si no están.

T2. Documenta en el reporte: el usuario debe crear el release v1.0.0-mvp
    con el APK adjunto en GitHub para que el link funcione. Hasta que lo
    haga, el botón devolverá 404 en el release page.

T3. Smoke build:
       cd presentation && npm run build
   Verifica que `dist/index.html` tiene el nuevo href.

═══════════════════════════════════════════════════════════════════
VERIFICACIÓN:
═══════════════════════════════════════════════════════════════════
- Si Opción A: `ls presentation/dist/transitly-v1.0.0-mvp.apk` muestra el
  archivo tras `npm run build`.
- Si Opción B: el href en `dist/index.html` es la URL de GitHub releases.
- En ambos casos, abre la página servida (npm run dev) y haz clic en
  "Descargar APK". Debe iniciarse la descarga (Opción A) o navegar al
  release (Opción B), no devolver 404 dentro del sitio.

COMMIT:
fix(presentation): APK descargable (opción <A|B>)

REPORTE FINAL:
- Opción elegida.
- Pasos hechos por ti y pasos que el usuario debe completar manualmente.
- Tamaño del APK si Opción A.
```

---

### A3 — Paletas custom: varias con nombre, persistidas en Hive

```text
ROL: Engineer Flutter senior, persistencia y design system.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

PROBLEMA REPORTADO POR EL USUARIO HACE TURNOS:
"Al crear paletas quiero que se le pueda poner un nombre y se guarde en cache."
"Varias paletas con nombre" (decisión confirmada).

ESTADO ACTUAL:
- theme_notifier.dart línea 50: `static const _customPaletteId = 'custom'`
  → un solo slot.
- Líneas 81-99: getter `palette` solo soporta una paleta custom con id fijo.
- custom_palette_screen.dart no tiene TextField de nombre.

OBJETIVO:
Soportar varias paletas custom con nombre, persistidas en Hive. UI para
crear, listar y eliminar.

ARCHIVOS PERMITIDOS:
- lib/shared/providers/theme_notifier.dart (extender, NO romper API)
- lib/shared/models/named_custom_palette.dart (NUEVO)
- lib/features/appearance/widgets/palette_section.dart (mostrar custom + X)
- lib/features/appearance/custom_palette_screen.dart (TextField nombre)
- lib/l10n/app_es.arb, app_en.arb, app_ar.arb (claves al final)

ARCHIVOS PROHIBIDOS: cualquier otro.

═══════════════════════════════════════════════════════════════════
TAREAS CONCRETAS:
═══════════════════════════════════════════════════════════════════

T1. Modelo NamedCustomPalette
   Crea lib/shared/models/named_custom_palette.dart:

       import 'package:flutter/material.dart';

       class NamedCustomPalette {
         const NamedCustomPalette({
           required this.id,
           required this.name,
           required this.colors,
         });

         final String id;             // "custom-{epochMs}"
         final String name;
         final Map<String, Color> colors;  // primary, secondary, bgRoot, bgSurface, textHi

         factory NamedCustomPalette.fromHive(Map<dynamic, dynamic> raw) {
           final colorsRaw = (raw['colors'] as Map).cast<dynamic, dynamic>();
           return NamedCustomPalette(
             id: raw['id'] as String,
             name: raw['name'] as String,
             colors: colorsRaw.map((k, v) => MapEntry(
                 k.toString(), Color(int.parse(v.toString(), radix: 16)))),
           );
         }

         Map<String, dynamic> toHive() => {
           'id': id,
           'name': name,
           'colors': colors.map((k, v) =>
               MapEntry(k, v.value.toRadixString(16).padLeft(8, '0'))),
         };
       }

T2. Extender ThemeNotifier
   En theme_notifier.dart añade:
   - Campo: `List<NamedCustomPalette> _customPalettes = [];`
   - Getter: `List<NamedCustomPalette> get customPalettes => List.unmodifiable(_customPalettes);`
   - Hive box name: `static const _customPalettesBoxName = 'custom_palettes';`
   - Métodos:
       Future<void> saveCustomPalette(NamedCustomPalette p) async {
         final idx = _customPalettes.indexWhere((x) => x.id == p.id);
         if (idx >= 0) {
           _customPalettes[idx] = p;
         } else {
           _customPalettes.add(p);
         }
         notifyListeners();
         await _persistCustomPalettes();
       }
       Future<void> removeCustomPalette(String id) async {
         _customPalettes.removeWhere((x) => x.id == id);
         if (_paletteId == id) _paletteId = 'default';
         notifyListeners();
         await _persistCustomPalettes();
       }
       Future<void> _loadCustomPalettes() async {
         final box = await Hive.openBox(_customPalettesBoxName);
         final raw = box.get('list', defaultValue: <Map>[]) as List;
         _customPalettes = raw.map((e) =>
             NamedCustomPalette.fromHive(e as Map)).toList();
       }
       Future<void> _persistCustomPalettes() async {
         final box = await Hive.openBox(_customPalettesBoxName);
         await box.put('list',
             _customPalettes.map((p) => p.toHive()).toList());
       }

   - Llama `_loadCustomPalettes()` desde `init()` y `loadGuest()`.

   - Modifica el getter `palette` para que si `_paletteId` empieza por
     `'custom-'` localice la NamedCustomPalette y devuelva un AppPalette
     con un TransitCustomColors generado desde sus colors. Si no se
     encuentra, fallback a 'default'.

   - Incluye `_customPalettes.length` y los IDs/nombres en `visualKey`
     para que cualquier add/remove dispare rebuild del árbol (recuerda:
     el KeyedSubtree en app.dart usa visualKey).

T3. UI: TextField de nombre en custom_palette_screen
   - Añade un TextField al inicio del formulario con
     `decoration: InputDecoration(labelText: l10n.appearancePaletteName)`.
   - Controller `_nameController`.
   - Al guardar:
       final id = 'custom-${DateTime.now().millisecondsSinceEpoch}';
       final p = NamedCustomPalette(
         id: id,
         name: _nameController.text.trim().isEmpty
             ? 'Mi paleta'
             : _nameController.text.trim(),
         colors: {/* 5 colores recogidos */},
       );
       await ref.read(themeNotifierProvider).saveCustomPalette(p);
       ref.read(themeNotifierProvider).paletteId = p.id;
       if (mounted) context.pop();

T4. UI: lista de custom en PalettesSection
   En palette_section.dart, debajo del GridView de prefabs, si
   `customPalettes.isNotEmpty`, añade un segundo bloque con título
   `l10n.appearanceCustomPalettesSection` ("MIS PALETAS") y otro GridView
   iterando sobre `notifier.customPalettes`:

       GridView.builder(
         shrinkWrap: true,
         physics: const NeverScrollableScrollPhysics(),
         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
           crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10,
           childAspectRatio: 2.2,
         ),
         itemCount: customs.length,
         itemBuilder: (_, i) {
           final cp = customs[i];
           final selected = cp.id == paletteId;
           return _CustomPaletteCard(
             palette: cp,
             selected: selected,
             c: c,
             onTap: () => ref.read(themeNotifierProvider).paletteId = cp.id,
             onDelete: () => _confirmDelete(context, ref, cp),
           );
         },
       )

   - `_CustomPaletteCard` similar al PaletteCard de prefabs pero con un
     icono X arriba a la derecha que abre AlertDialog de confirmación
     y llama a `removeCustomPalette(cp.id)`.

T5. Migración del campo legacy `customColors`
   El theme_notifier antiguo guardaba un único `_customColors` en
   UserPreferences. Si encuentras un valor legacy no vacío al cargar:
   - Crea automáticamente una NamedCustomPalette con id
     `'custom-legacy'` y nombre "Mi paleta" + esos colores.
   - Vacía el campo viejo en la siguiente persistencia.

T6. Claves l10n (al final del JSON, sin regenerar)
   - app_es.arb:
       "appearancePaletteName": "Nombre de la paleta",
       "appearanceCustomPalettesSection": "MIS PALETAS",
       "appearanceDeletePaletteConfirm": "¿Eliminar esta paleta?"
   - app_en.arb:
       "appearancePaletteName": "Palette name",
       "appearanceCustomPalettesSection": "MY PALETTES",
       "appearanceDeletePaletteConfirm": "Delete this palette?"
   - app_ar.arb:
       "appearancePaletteName": "اسم النموذج",
       "appearanceCustomPalettesSection": "نماذجي",
       "appearanceDeletePaletteConfirm": "حذف هذا النموذج؟"

═══════════════════════════════════════════════════════════════════
VERIFICACIÓN:
═══════════════════════════════════════════════════════════════════
- `flutter analyze` 0 warnings.
- Smoke:
  1. Apariencia → "+ Crear paleta personalizada" → wizard con TextField
     de nombre.
  2. Escribe "Mi neón", elige 5 colores, guarda → vuelves a Apariencia y
     en "MIS PALETAS" aparece "Mi neón" seleccionada. Toda la app cambia
     a esos colores.
  3. Crea otra "Forest noche" → ambas aparecen.
  4. Pulsa X de "Mi neón" → confirmación → desaparece y vuelve a Default.
  5. Cierra/abre la app → "Forest noche" persiste en Hive.

COMMIT(s):
- feat(theme): paletas custom con nombre persistidas en Hive
- feat(theme): UI para listar y eliminar paletas custom

REPORTE FINAL:
- Confirma T1-T6.
- Claves l10n añadidas y archivos.arb modificados.
- Snippets de saveCustomPalette/removeCustomPalette.
- Confirmación de migración del campo legacy si encontraste datos viejos.
```

---

### A4 — Mapa: círculo de precisión + caché FMTC por estilo

```text
ROL: Engineer Flutter senior, flutter_map + geolocator + flutter_map_tile_caching.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

DECISIONES PREVIAS DEL USUARIO:
- Mostrar círculo de precisión alrededor del marker de usuario.
- Bug del estilo de mapa que no cambia y modo claro que no actualiza mapa
  PUEDE persistir por caché FMTC reutilizando tiles del estilo anterior.

ESTADO ACTUAL:
- lib/features/map/layers/user_location_layer.dart: 56 líneas, sin
  CircleMarker ni accuracy. Solo pinta el marker central.
- lib/data/fmtc/fmtc_provider.dart línea 7:
    final fmtcTileProviderProvider = Provider<FMTCTileProvider?>(...);
  Es un Provider único — no separado por estilo. Cuando cambias mapStyle,
  el TileLayer pide otra URL pero FMTC puede devolver la tile cacheada
  del estilo anterior si comparten clave en el store.

OBJETIVO:
1. Mostrar círculo de precisión en el marker de usuario.
2. Separar caché FMTC por estilo (family) para que cambiar mapStyle se
   refleje visualmente.

ARCHIVOS PERMITIDOS:
- lib/features/map/layers/user_location_layer.dart
- lib/shared/providers/user_location_provider.dart (ampliar para exponer
  accuracy)
- lib/data/fmtc/fmtc_provider.dart
- lib/features/home/tabs/map_tab.dart (SOLO la línea
  `ref.watch(fmtcTileProviderProvider)` para pasarle el estilo)

ARCHIVOS PROHIBIDOS: cualquier otro.

═══════════════════════════════════════════════════════════════════
TAREAS CONCRETAS:
═══════════════════════════════════════════════════════════════════

T1. Exponer accuracy en el provider de ubicación
   En lib/shared/providers/user_location_provider.dart:
   - Cambia el tipo del stream para emitir un objeto con LatLng y double
     accuracy:

         class UserLocationFix {
           const UserLocationFix({required this.position, required this.accuracy});
           final LatLng position;
           final double accuracy;  // metros
         }

         final userLocationStreamProvider =
             StreamProvider.autoDispose<UserLocationFix?>((ref) {
           ...
           positionStream.listen((pos) {
             if (!controller.isClosed) {
               controller.add(UserLocationFix(
                 position: LocationService.toLatLng(pos),
                 accuracy: pos.accuracy,
               ));
             }
           });
           ...
         });

   - Compatibilidad: si muchos sitios leen `LatLng` directamente, expone
     también un `userLocationLatLngProvider` derivado que devuelve solo
     `LatLng?`:

         final userLocationLatLngProvider = Provider<LatLng?>((ref) =>
             ref.watch(userLocationStreamProvider).valueOrNull?.position);

     Y migra los callsites que ya esperan `LatLng?` para usar este
     provider.

T2. UserLocationLayer con CircleMarker
   En lib/features/map/layers/user_location_layer.dart:
   - El widget recibe ahora UserLocationFix (no solo LatLng).
   - Pinta dos capas en orden:

       return Stack(children: [
         CircleLayer(circles: [
           CircleMarker(
             point: fix.position,
             radius: fix.accuracy,             // metros
             useRadiusInMeter: true,
             color: c.accent.withValues(alpha: 0.10),
             borderColor: c.accent.withValues(alpha: 0.35),
             borderStrokeWidth: 1,
           ),
         ]),
         MarkerLayer(markers: [
           Marker(
             point: fix.position,
             width: 22, height: 22,
             child: _buildUserMarker(c),
           ),
         ]),
       ]);

   - `_buildUserMarker(c)` devuelve un Container circular azul con borde
     blanco (tipo Google Maps), o el diseño existente.
   - Caps a accuracy mínima 8 (si pos.accuracy < 8, usa 8 metros) para que
     siempre se vea algo. Cap máximo 200 metros para no llenar la pantalla.

T3. Caché FMTC por estilo
   En lib/data/fmtc/fmtc_provider.dart:
   - Convierte el provider en family:

         final fmtcTileProviderProvider =
             Provider.family<TileProvider?, String>((ref, style) {
           final fmtcSvc = ref.watch(fmtcServiceProvider);
           if (!fmtcSvc.isReady) return null;
           // Un store por estilo. La API exacta puede variar según versión
           // de flutter_map_tile_caching. Ejemplo:
           final store = FMTCStore('jerez-$style');
           return store.getTileProvider();
         });

   - Si la creación del store es side-effect (necesita create() async),
     gestiónalo dentro de FmtcService al inicializar todos los estilos:
     en FmtcService.initialise itera sobre `MapConfig.mapStyles.keys` y
     `await FMTCStore('jerez-$style').manage.create();` para cada uno.

T4. map_tab.dart pasa el estilo al provider
   En lib/features/home/tabs/map_tab.dart, donde está
   `ref.watch(fmtcTileProviderProvider)` (probablemente línea ~313):
   - Cámbialo por:
         final mapStyle = ref.watch(themeNotifierProvider.select((n) => n.mapStyle));
         final fmtcTp = ref.watch(fmtcTileProviderProvider(mapStyle));
   - Si la variable `mapStyle` ya existe en el build, reutilízala.
   - El `key:` del TransitMap ya incluye `mapStyle` (verificado en review)
     así que recreará la capa cuando cambie.

T5. Smoke
   - Abre el mapa con GPS encendido → marker visible CON círculo de
     precisión semitransparente alrededor.
   - Cambia mapStyle en Apariencia (streets → dark → light → basic) →
     las tiles cambian (sea por descarga online en primer cambio, sea
     por caché en cambios siguientes).
   - Cambia de modo oscuro a claro → mapa cambia.

═══════════════════════════════════════════════════════════════════
VERIFICACIÓN:
═══════════════════════════════════════════════════════════════════
- `flutter analyze` 0 warnings.
- Smoke completo (T5).
- En offline (modo avión), las tiles ya descargadas para el estilo activo
  se sirven; las nuevas (de otros estilos) no aparecen hasta volver
  online. Documenta esto.

COMMIT(s):
- feat(map): círculo de precisión en marker de usuario
- fix(map): caché FMTC separada por estilo (tiles reactivos al cambio)

REPORTE FINAL:
- Confirma T1-T5.
- Si tuviste que actualizar callsites de userLocationStreamProvider,
  lista los archivos modificados.
- Tamaño aproximado de los stores FMTC tras navegar por 2-3 estilos.
- Comportamiento offline tras el split de stores.
```

---

## WAVE 2 — A5: Widgets nativos Android

```text
ROL: Engineer Android + Flutter, AppWidgetProvider y home_widget package.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

PROBLEMA REPORTADO POR EL USUARIO HACE VARIOS TURNOS:
"Me siguen sin aparecer widgets en el móvil."

Pendiente desde el plan v2. Los planes v3, v4 y v5 lo aplazaron.

ESTADO ACTUAL:
- pubspec.yaml línea 32: `home_widget: ^0.7.0` instalado.
- lib/data/widgets_native/widget_data_writer.dart: tiene métodos
  writeNextBus y writeMyLineStatus pero NUNCA se invocan.
- lib/features/widgets_native/widgets_settings_screen.dart: en release
  mode muestra "Coming Soon".
- Android: NO existe ningún AppWidgetProvider, ni receiver registrado en
  AndroidManifest.xml, ni xml/widget_*_info.xml, ni layout xml.

OBJETIVO:
Implementar dos widgets nativos Android funcionales:
1. "Próximo bus" — muestra próxima salida de la parada favorita.
2. "Estado mi línea" — muestra estado de servicio de la línea favorita.

ARCHIVOS PERMITIDOS:
- android/app/src/main/AndroidManifest.xml
- android/app/src/main/kotlin/com/transitly/transitly/widgets/TransitlyNextBusWidget.kt (NUEVO)
- android/app/src/main/kotlin/com/transitly/transitly/widgets/TransitlyMyLineWidget.kt (NUEVO)
- android/app/src/main/res/xml/widget_next_bus_info.xml (NUEVO)
- android/app/src/main/res/xml/widget_my_line_info.xml (NUEVO)
- android/app/src/main/res/layout/widget_next_bus.xml (NUEVO)
- android/app/src/main/res/layout/widget_my_line.xml (NUEVO)
- android/app/src/main/res/drawable/widget_bg.xml (NUEVO)
- lib/data/widgets_native/widget_data_writer.dart
- lib/features/widgets_native/widgets_settings_screen.dart
- lib/shared/providers/widget_data_provider.dart (NUEVO)

ARCHIVOS PROHIBIDOS: cualquier otro.

═══════════════════════════════════════════════════════════════════
TAREAS CONCRETAS:
═══════════════════════════════════════════════════════════════════

T1. TransitlyNextBusWidget.kt (Kotlin)
   Crea android/app/src/main/kotlin/com/transitly/transitly/widgets/TransitlyNextBusWidget.kt:

       package com.transitly.transitly.widgets

       import android.appwidget.AppWidgetManager
       import android.content.Context
       import android.content.SharedPreferences
       import android.widget.RemoteViews
       import com.transitly.transitly.R
       import com.transitly.transitly.MainActivity
       import es.antonyoung.home_widget.HomeWidgetProvider
       import es.antonyoung.home_widget.HomeWidgetLaunchIntent
       import org.json.JSONObject

       class TransitlyNextBusWidget : HomeWidgetProvider() {
         override fun onUpdate(
             context: Context,
             appWidgetManager: AppWidgetManager,
             appWidgetIds: IntArray,
             widgetData: SharedPreferences,
         ) {
           appWidgetIds.forEach { id ->
             val views = RemoteViews(context.packageName, R.layout.widget_next_bus)
             val routeCode = widgetData.getString("widget_fav_line", "L1") ?: "L1"
             val json = widgetData.getString("next_bus_$routeCode", null)
             views.setTextViewText(R.id.widget_route_code, routeCode)
             if (json != null) {
               try {
                 val obj = JSONObject(json)
                 views.setTextViewText(R.id.widget_next_time, obj.optString("time", "—"))
                 views.setTextViewText(R.id.widget_stop_name, obj.optString("stop", ""))
               } catch (_: Exception) {
                 views.setTextViewText(R.id.widget_next_time, "—")
                 views.setTextViewText(R.id.widget_stop_name, "")
               }
             } else {
               views.setTextViewText(R.id.widget_next_time, "—")
               views.setTextViewText(R.id.widget_stop_name, "Configurar")
             }
             val pendingIntent = HomeWidgetLaunchIntent.getActivity(
               context, MainActivity::class.java)
             views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
             appWidgetManager.updateAppWidget(id, views)
           }
         }
       }

   IMPORTANTE: verifica el import path correcto del package home_widget
   0.7.0 (`es.antonyoung.home_widget.HomeWidgetProvider` o el equivalente
   actual leyendo el README de home_widget en pub.dev). Si el package
   cambió de nombre, ajusta los imports.

T2. TransitlyMyLineWidget.kt
   Mismo patrón pero leyendo `widget_my_line` y `line_status_$code` desde
   SharedPreferences. Muestra: código de línea, estado (En servicio /
   Retrasada / Cancelada), última actualización.

T3. Layouts XML
   - widget_next_bus.xml en res/layout/:

       <?xml version="1.0" encoding="utf-8"?>
       <LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
           android:id="@+id/widget_root"
           android:layout_width="match_parent"
           android:layout_height="match_parent"
           android:background="@drawable/widget_bg"
           android:orientation="vertical"
           android:padding="12dp">
         <TextView android:id="@+id/widget_route_code"
             android:layout_width="wrap_content"
             android:layout_height="wrap_content"
             android:textColor="#977DDF"
             android:textSize="22sp"
             android:textStyle="bold"
             tools:text="L1"/>
         <TextView android:id="@+id/widget_next_time"
             android:layout_width="wrap_content"
             android:layout_height="wrap_content"
             android:textColor="#F0F0FA"
             android:textSize="18sp"
             android:layout_marginTop="6dp"
             tools:text="14:23"/>
         <TextView android:id="@+id/widget_stop_name"
             android:layout_width="wrap_content"
             android:layout_height="wrap_content"
             android:textColor="#8888A8"
             android:textSize="12sp"
             android:layout_marginTop="2dp"
             tools:text="Plaza del Arenal"/>
       </LinearLayout>

   - widget_my_line.xml similar pero con campos: code, status, lastUpdate.
   - widget_bg.xml en res/drawable/:

       <?xml version="1.0" encoding="utf-8"?>
       <shape xmlns:android="http://schemas.android.com/apk/res/android"
           android:shape="rectangle">
         <solid android:color="#08081A"/>
         <stroke android:width="1dp" android:color="#1E1E3A"/>
         <corners android:radius="12dp"/>
       </shape>

T4. XML metadata
   - widget_next_bus_info.xml en res/xml/:

       <?xml version="1.0" encoding="utf-8"?>
       <appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
           android:minWidth="180dp"
           android:minHeight="80dp"
           android:updatePeriodMillis="900000"
           android:initialLayout="@layout/widget_next_bus"
           android:previewImage="@mipmap/ic_launcher"
           android:resizeMode="horizontal|vertical"
           android:widgetCategory="home_screen"/>

   - widget_my_line_info.xml análogo apuntando a widget_my_line.

T5. AndroidManifest
   Dentro de <application> en AndroidManifest.xml, añade:

       <receiver android:name=".widgets.TransitlyNextBusWidget"
                 android:exported="true">
         <intent-filter>
           <action android:name="android.appwidget.action.APPWIDGET_UPDATE"/>
         </intent-filter>
         <meta-data android:name="android.appwidget.provider"
                    android:resource="@xml/widget_next_bus_info"/>
       </receiver>
       <receiver android:name=".widgets.TransitlyMyLineWidget"
                 android:exported="true">
         <intent-filter>
           <action android:name="android.appwidget.action.APPWIDGET_UPDATE"/>
         </intent-filter>
         <meta-data android:name="android.appwidget.provider"
                    android:resource="@xml/widget_my_line_info"/>
       </receiver>

   `android:exported="true"` es obligatorio para Android 12+ (API 31+).

T6. WidgetDataWriter cableado con HomeWidget API
   Reescribe lib/data/widgets_native/widget_data_writer.dart:

       import 'dart:convert';
       import 'package:home_widget/home_widget.dart';

       class WidgetDataWriter {
         static const _appGroupId = 'group.com.transitly.transitly';

         static Future<void> writeNextBus(String routeCode,
             Map<String, dynamic> payload) async {
           await HomeWidget.setAppGroupId(_appGroupId);
           await HomeWidget.saveWidgetData('widget_fav_line', routeCode);
           await HomeWidget.saveWidgetData(
               'next_bus_$routeCode', jsonEncode(payload));
           await HomeWidget.updateWidget(
             name: 'TransitlyNextBusWidget',
             androidName: 'TransitlyNextBusWidget',
           );
         }

         static Future<void> writeMyLineStatus(String routeCode,
             Map<String, dynamic> payload) async {
           await HomeWidget.setAppGroupId(_appGroupId);
           await HomeWidget.saveWidgetData('widget_my_line', routeCode);
           await HomeWidget.saveWidgetData(
               'line_status_$routeCode', jsonEncode(payload));
           await HomeWidget.updateWidget(
             name: 'TransitlyMyLineWidget',
             androidName: 'TransitlyMyLineWidget',
           );
         }
       }

   Verifica el API exacto del home_widget 0.7.0 en pub.dev; los nombres
   de los métodos pueden variar ligeramente.

T7. Provider que dispara el write
   Crea lib/shared/providers/widget_data_provider.dart:

       import 'package:flutter_riverpod/flutter_riverpod.dart';
       import '../../data/widgets_native/widget_data_writer.dart';
       import 'derived/home_providers.dart';

       /// Escucha el viaje habitual + próxima salida y persiste para el
       /// widget nativo Android.
       final widgetDataSyncProvider = Provider<void>((ref) {
         final cfg = ref.watch(homeHabitualConfigProvider);
         if (!cfg.isConfigured) return;
         final route = ref.watch(routeByIdProvider(cfg.routeId!));
         if (route == null) return;
         final nextDeparture = ref.watch(nextDepartureProvider(
           (routeId: cfg.routeId!, stopId: cfg.stopId!)));
         nextDeparture.whenData((dep) {
           if (dep == null) return;
           WidgetDataWriter.writeNextBus(route.code, {
             'time': dep.scheduledTime,
             'stop': dep.stopName,
           });
         });
       });

   Asegúrate de invocar este provider desde algún ConsumerWidget vivo
   (ej. en el `_TransitlyAppWithLifecycle` o `HomeShell`) para que se
   active al arrancar.

T8. Desbloquear release mode en widgets_settings_screen
   En lib/features/widgets_native/widgets_settings_screen.dart, elimina
   el bloqueo "Coming Soon" en release (líneas 91-101 según planes
   previos). Que la pantalla funcione siempre.

═══════════════════════════════════════════════════════════════════
VERIFICACIÓN:
═══════════════════════════════════════════════════════════════════
- `flutter analyze` 0 warnings.
- `flutter build apk --debug` debe pasar sin errores nativos.
- Instala el APK debug en un dispositivo o emulador Android.
- Long-press en el home de Android → Widgets → busca "Transitly".
- Añade el widget "Próximo bus" al escritorio.
- Configura un viaje habitual en la app → vuelve al escritorio → el
  widget se actualiza con el código de línea y próxima salida.

COMMIT(s):
- feat(widgets-android): home widget nativo "Próximo bus"
- feat(widgets-android): home widget nativo "Estado mi línea"
- feat(widgets): cableado WidgetDataWriter con providers

REPORTE FINAL:
- Confirma T1-T8.
- Si encontraste limitaciones del package home_widget 0.7.0, documéntalas.
- Si la build debug pasa pero no tienes dispositivo para verificar el
  widget visualmente, deja claro en el reporte que la verificación
  visual queda pendiente para el usuario.
```

---

## WAVE 3 — Coordinador (NO agente)

1. **Auto-fix de los 68 infos de `prefer_const_constructors` (P3):**
   ```bash
   dart fix --apply
   ```
   Esto añade `const` automáticamente en los tests donde corresponde.

2. **Análisis y tests:**
   ```bash
   flutter analyze    # objetivo: 0 issues
   flutter test       # objetivo: 453+ passed
   ```

3. **Build presentation y verificación:**
   ```bash
   cd presentation && npm run build
   ```
   Inspecciona `presentation/dist/index.html`:
   - 0 ocurrencias de `class=".*data-delay=`.
   - El archivo `transitly-v1.0.0-mvp.apk` está presente (si Opción A de A2).

4. **Smoke completo en dispositivo Android:**
   - A1: secciones 3/6/9/11/14 con hover y transiciones funcionando.
   - A2: botón "Descargar APK" inicia descarga.
   - A3: paletas custom con nombre — crear, listar, seleccionar, eliminar,
     persistir.
   - A4: marker con círculo de precisión + cambiar estilo de mapa muestra
     tiles distintas.
   - A5: añadir widget al home → muestra próximo bus.

5. **Deploy presentation (opcional, automático al push a master):**
   El workflow `.github/workflows/deploy-presentation.yml` ya está
   configurado. Solo verifica que el push a master incluya cambios en
   `presentation/**` y que GitHub Actions despliegue sin errores.

---

## Riesgos y notas

- **A2 Opción B** requiere que el usuario tenga acceso al panel de
  releases de GitHub. Si no, ir por Opción A.
- **A3 (custom palettes)** debe extender `visualKey` para incluir los
  IDs de las paletas custom; si no, añadir una paleta no fuerza rebuild.
- **A4 (FMTC family)** puede multiplicar uso de disco. Documentar.
- **A5 (widgets Android)** requiere dispositivo real para verificar
  visualmente. Build debug debería pasar; smoke visual queda pendiente
  para el usuario si no hay device disponible.
- **Coordinador WAVE 3 paso 1** (`dart fix --apply`) puede tocar
  archivos fuera del scope acordado. Si modifica algo no esperado,
  revisar el diff antes del commit.

---

## Cobertura final

| # | Problema reportado en review | Agente | Acción |
|---|-------------------------------|--------|--------|
| 1 | 24 `class=` malformados en 5 secciones .astro | A1 | Separar `data-delay` del `class` |
| 2 | APK 404 en GH Pages | A2 | Opción A (copiar a public/) o B (URL release) |
| 3 | Paletas custom con nombre + cache | A3 | NamedCustomPalette + Hive + UI |
| 4 | Círculo de precisión + tiles no cambian con estilo | A4 | CircleMarker + FMTC family |
| 5 | Widgets nativos Android | A5 | Kotlin + manifest + layouts |
| 6 | 68 infos `prefer_const_constructors` | Coordinador | `dart fix --apply` |
