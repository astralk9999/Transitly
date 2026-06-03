# Plan de reparación v13 — Transitly (mapa, perfil, fondos, accesibilidad)

**Fecha:** 2026-05-31
**Autor:** Claude Code (Opus 4.7)
**Plan anterior:** `PLAN_REPARACION_2026_05_29_V12.md`

---

## TL;DR — 15 items reportados

| # | Item | Tipo | Agente |
|---|------|------|--------|
| 1 | Mapa al cambiar oscuro→claro deja de ir (cambiar mapStyle lo arregla) | Bug | A1 |
| 2 | Estás lejos de Jerez → "mi ubicación" + "ubicación de línea" → ninguna se ve | Bug | A2 |
| 3 | En modo claro, fondo de Apariencia se ve oscuro | Bug | A3 |
| 4 | Ninguno de los fondos nuevos (Aurora/Beams/Balatro/etc.) funciona | Bug | A4 |
| 5 | Gradiente siempre azul, quiero que use color primario de la paleta | Mejora | A5 |
| 6 | Perfil solo accesible clicando badge + al entrar no se ve nada | Bug | A6 |
| 7 | "Mis contribuciones" muestra `12 reportes, 3 verificados` falso | Bug | A7 |
| 8 | Widgets/Accesibilidad/etc. solo se accede por letras/flecha → toda la fila tocable | Mejora | A8 |
| 9 | Widgets siguen sin aparecer en lista del teléfono + menú config widgets mejorar | Bug+Feature | A9 |
| 10 | "Seleccionar operador inicio" sobra → reemplazar por saludo contextual | Mejora | A10 |
| 11 | Configurar viaje habitual con autocomplete + recientes (no dropdown de 19 líneas) | Mejora | A11 |
| 12 | PopUp añadir favorito feo + dura demasiado | Mejora | A12 |
| 13 | Pulsar "mostrar paradas" deja de ir todo | Bug crítico | A13 |
| 14 | Privacidad: nada funcional | Bug | A14 |
| 15 | Eliminar cuenta promete 30 días → implementar real con cola en Supabase | Feature | A14 |

---

## Decisiones tomadas contigo

- **Viaje habitual**: buscador con autocomplete + recientes.
- **Contribuciones**: datos REALES de reportes, sugerencias enviadas, líneas creadas, líneas compartidas, feedback. El `12/3` actual es mock falso.
- **Eliminar cuenta**: implementar borrado real con periodo de gracia 30 días (tabla `account_deletion_requests` + Edge Function cron).
- **Reemplazar operador inicio**: saludo contextual ("👋 Buenos días, [nombre]" según hora).

---

## Estructura

```
WAVE 1 (5 agentes paralelos) — Bugs mapa + fondos
├── A1  Mapa: cambio tema oscuro→claro mantiene tiles funcionando
├── A2  Mapa: líneas visibles aunque estés lejos de Jerez
├── A3  Apariencia: fondo respeta modo claro/oscuro real
├── A4  Fondos nuevos: verificar y arreglar render (Aurora/Beams/Balatro/etc.)
└── A5  Gradiente accent: usa el color primario de la paleta activa

WAVE 2 (5 agentes paralelos) — Perfil + UX
├── A6  Perfil: acceso directo desde nav + render correcto
├── A7  Mis contribuciones con datos REALES (Supabase)
├── A8  Filas de Ajustes tocables completas (no solo texto/flecha)
├── A9  Widgets Android nativos (5ª iter) + UI config widgets mejorada
└── A10 Saludo contextual reemplaza "operador inicio"

WAVE 3 (3 agentes paralelos) — Features
├── A11 Viaje habitual: buscador autocomplete + recientes
├── A12 PopUp favorito: rediseño + duración corta (1.2s)
├── A13 "Mostrar paradas": fix crash + Privacidad funcional
└── A14 Eliminar cuenta real con cola 30 días (Supabase)

WAVE 4 (coordinador)
└── flutter clean + build APK + install
```

### Tabla de archivos por agente

| Agente | Archivos clave |
|--------|----------------|
| A1 | `lib/features/home/tabs/map_tab.dart` (bypass FMTC también al cambiar tema, no solo estilo) |
| A2 | `lib/features/home/tabs/map_tab.dart` (`_centerOnUser` + handler `onGoToLine` con `_didInitialCenter = false`) |
| A3 | `lib/shared/widgets/background_wrapper.dart` (usar scheme correcto del themeMode actual) |
| A4 | `lib/core/theme/backgrounds/app_background.dart` (verificar painters), `lib/shared/widgets/background_wrapper.dart` (asegurar wrapper procesa todos los patterns) |
| A5 | `lib/core/theme/palettes/app_palette.dart` (extender API), `lib/core/theme/transit_colors.dart` (gradientAccent reactivo) |
| A6 | `lib/features/home/tabs/profile_tab.dart`, `lib/features/home/widgets/profile_header_card.dart` |
| A7 | `lib/features/profile/my_contributions_screen.dart` (NUEVO o existente), providers de datos reales |
| A8 | `lib/features/profile/profile_tab.dart`, `lib/shared/widgets/profile_row.dart` (envolver con InkWell de fila completa) |
| A9 | `android/app/src/main/AndroidManifest.xml`, `android/app/src/main/kotlin/.../widgets/*.kt` (NUEVOS), `android/app/src/main/res/xml/widget_*.xml`, `lib/features/widgets_native/widgets_settings_screen.dart` |
| A10 | `lib/features/home/widgets/profile_header_card.dart` (saludo contextual) |
| A11 | `lib/features/home/widgets/habitual_config_sheet.dart` (rediseño completo) |
| A12 | `lib/shared/widgets/favorite_added_snackbar.dart` (NUEVO o reescribir el existente) |
| A13 | `lib/features/map/transit_map.dart` (fix `showAllStops` que crashea), `lib/features/profile/privacy_screen.dart` (funcional) |
| A14 | `supabase/migrations/*_account_deletion.sql` (NUEVO), `supabase/functions/process-account-deletions/` (NUEVO Edge Function), `lib/features/profile/delete_account_screen.dart` (real) |

### Conflictos controlados

- `map_tab.dart`: A1, A2, A13 lo tocan. Edits puntuales en distintos métodos.
- `profile_tab.dart`: A6 y A8 lo tocan. Coordinar.
- `profile_header_card.dart`: A6, A8, A10. Coordinar.
- `background_wrapper.dart`: A3 y A4. Edits relacionados, ideal mismo agente — los dejo separados pero coordinados.

---

## WAVE 1 — Briefs

### A1 — Mapa: cambio oscuro→claro mantiene tiles

```text
ROL: Engineer Flutter, flutter_map.

PROBLEMA:
Al cambiar themeMode de oscuro a claro, el mapa deja de cargar tiles
(quedan grises). Workaround actual: cambiar el mapStyle en Apariencia
"despierta" el mapa.

CAUSA RAÍZ:
En map_tab.dart, el bloque que recrea el MapController detecta cambios
de `mapStyle` o `isDark` vía `_lastMapKey`. PERO el bypass FMTC con
`_bypassFmtcUntil` solo se activa explícitamente al cambiar mapStyle.
Cuando cambia ISDARK (themeMode), el controller se recrea pero FMTC
sigue sirviendo tiles cacheadas que pueden corresponder a un estilo
distinto del que ahora corresponde al tema light/dark.

TAREAS:

T1. En map_tab.dart, dentro del bloque
   `if (_lastMapKey != null && _lastMapKey != currentMapKey)`,
   asegúrate de que el bypass FMTC se activa SIEMPRE que cambie la key
   (no solo cuando cambie mapStyle). Como `currentMapKey` ya incluye
   `isDark`, basta con verificar que el bypass se aplica en todos
   los cambios.

T2. Asegurar que tras el bypass, cuando vuelve a usar FMTC (después
   de 3s), las tiles cacheadas sean del estilo correcto. Si el bug
   persiste, alargar el bypass a 5s.

T3. Verificar que `fmtcTileProviderProvider(mapStyle)` tiene una family
   por estilo (debería ser así desde v9). Si por error retorna el
   mismo provider para todos los estilos, ahí está el bug.

VERIFICACIÓN:
- Cambiar tema oscuro→claro en Apariencia → volver al mapa → tiles
  cargan en <3s sin necesidad de cambiar mapStyle.

COMMIT:
fix(map): tiles se refrescan al cambiar themeMode (no solo mapStyle)
```

### A2 — Líneas visibles aunque estés lejos de Jerez

```text
ROL: Engineer Flutter.

PROBLEMA:
Si estás físicamente lejos de Jerez y pulsas:
1. FAB "ir a mi ubicación" → mapa centra en tu posición real (sin
   líneas porque no hay datos mock fuera de Jerez)
2. Luego "ubicación de la línea X" en RouteCard → debería centrar en
   el bbox de la línea (en Jerez), pero NO se ven las líneas.

CAUSA:
- map_tab.dart `_centerOnUser` mueve el mapa a tu posición. OK.
- `onGoToLine` de RouteCard llama `_mapController.fitCamera(bounds)`.
  Eso mueve la cámara al bbox de la línea. Las polylines del cache
  YA están dibujadas. Si no se ven, puede ser que:
  - El bypass FMTC esté activo y las tiles no han cargado
  - El zoom del fitCamera quede demasiado bajo y los polylines
    queden por debajo del threshold de LOD
  - Hay un re-centrado automático que mueve el mapa otra vez tras
    el fitCamera

TAREAS:

T1. En `onGoToLine` de map_tab.dart (handler de RouteCard.onGoToLine):
   - Tras `fitCamera`, FORZAR `_didInitialCenter = true` para evitar
     que `_tryInitialCenter` re-mueva el mapa.
   - Asegurar que el padding del fitCamera deja zoom >= 12 (donde los
     polylines son visibles).

T2. Verificar `_filteredRoutes` no excluye líneas estando lejos de Jerez:
   - Si `f.onlyAccessible` está activo y no hay paradas accesibles
     cerca, podría filtrar todo. Lectura defensiva.

T3. Smoke: simular ubicación en Madrid (cualquier ciudad lejos), pulsar
   FAB ubicación, luego pulsar GPS de L1 → el mapa debe centrarse en
   Jerez y mostrar la polyline de L1.

COMMIT:
fix(map): polylines visibles tras fitCamera incluso si estás lejos de
Jerez
```

### A3 — Fondo Apariencia respeta modo claro/oscuro

```text
ROL: Engineer Flutter.

PROBLEMA:
En modo claro, la pantalla Apariencia sigue mostrando fondo oscuro
(el shader Smoke negro). Debería ser claro acorde al tema.

CAUSA:
El BackgroundWrapper usa `palette.scheme` que es la versión dark de
la paleta. Cuando el themeMode es light, debería usar `palette.lightScheme`.
Mira `palette.isDark` para decidir.

TAREAS:

T1. En background_wrapper.dart, antes de leer `palette.scheme.bgRoot`,
   determinar el scheme efectivo:

       final brightness = MediaQuery.platformBrightnessOf(context);
       // O mejor: leer del themeModeProvider directamente.
       final themeMode = ref.watch(themeModeProvider);
       final isDark = themeMode == ThemeMode.dark ||
           (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
       final scheme = isDark
           ? (palette.darkScheme ?? const TransitDarkColors())
           : (palette.lightScheme ?? const TransitLightColors());

   Pasar `scheme` a los painters en lugar de `palette.scheme`.

T2. Para ShaderBackground (Smoke), pasar `isDark: isDark` (no
   `palette.isDark` que solo refleja la paleta por defecto).

T3. Verificar que los procedural painters reciben el bgColor del scheme
   light (que es claro, no oscuro).

VERIFICACIÓN:
- Cambiar a modo claro → Apariencia → fondo Smoke se ve sobre base
  CLARA (no negra).
- Probar también Aurora, Gradient, Beams, etc.

COMMIT:
fix(theme): backgroundWrapper usa scheme efectivo según themeMode
```

### A4 — Fondos nuevos no funcionan

```text
ROL: Engineer Flutter, CustomPainter.

PROBLEMA:
"Ninguno de los nuevos fondos va". Aurora, Beams, DotField,
FloatingLines, Dither, Balatro, ColorBends.

INVESTIGACIÓN:
- background_wrapper.dart maneja `ProceduralBackground(:final pattern)`
  con un switch que llama a SoftGridPainter y TopoLinesPainter.
- Los otros 7 patterns NO están en el switch del wrapper.
  El builder por defecto del AppBackground crea un CustomPaint con
  _ProceduralPainter pero el wrapper IGNORA ese builder y usa sus
  propios painters.

TAREAS:

T1. En background_wrapper.dart, ampliar el match de
   `ProceduralBackground(:final pattern)` para que use el builder
   nativo del AppBackground:

       ProceduralBackground() => Stack(
         fit: StackFit.expand,
         children: [
           Container(color: scheme.bgRoot),
           Opacity(
             opacity: opacity,
             child: bg.builder(context),  // ← usa _ProceduralPainter
           ),
           child,
         ],
       ),

   Eliminar los casos especiales de softGrid y topoLines: el builder
   nativo ya las maneja.

T2. Asegurar que los painters _drawAurora, _drawBeams, _drawDotField,
   _drawFloatingLines, _drawDither, _drawBalatro, _drawColorBends
   están implementados en app_background.dart `_ProceduralPainter`.
   (Verificación rápida — sé que están porque ya los implementé.)

T3. Smoke: Apariencia → Fondo → cada uno de los 9 fondos:
   None / Smoke / Gradient / SoftGrid / TopoLines / Aurora / Beams /
   DotField / FloatingLines / Dither / Balatro / ColorBends.
   Cada uno debe renderizar visible distinto.

COMMIT:
fix(theme): backgroundWrapper delega a AppBackground.builder para
patterns procedurales (Aurora/Beams/Balatro/etc.)
```

### A5 — Gradiente usa color primario de la paleta

```text
ROL: Engineer Flutter, design tokens.

PROBLEMA:
`c.gradientAccent` (usado en GradientText, botones, etc.) siempre
muestra azul/púrpura. Debería derivarse del `accent` de la paleta
activa.

CAUSA:
En `transit_colors.dart`, `gradientAccent` es:
    LinearGradient get gradientAccent => const LinearGradient(
      colors: [Color(0xFF977DDF), Color(0xFFB8A5F0)],
    );
Eso es HARDCODED — ignora qué paleta esté activa.

TAREAS:

T1. En cada esquema (TransitDarkColors, TransitLightColors,
   TransitSunriseColors, etc.), `gradientAccent` debe derivar de
   su propio `accent`. Ya debería ser así para los esquemas no-default,
   pero verifica.

T2. Para `TransitDarkColors` y `TransitLightColors`, fijar
   `gradientAccent` derivado del accent:
       LinearGradient get gradientAccent => LinearGradient(
         colors: [accent, _lighten(accent, 0.18)],
       );
   con _lighten helper.

T3. Verificar GradientText usa `c.gradientAccent` (que ahora respeta
   la paleta).

T4. Smoke: cambiar paleta a Sunrise → gradiente naranja. A Forest →
   verde. A Ocean → azul. A Mono → gris.

COMMIT:
fix(theme): gradientAccent derivado del accent de cada paleta
```

---

## WAVE 2 — Briefs

### A6 — Perfil: acceso + render

```text
ROL: Engineer Flutter, navegación.

PROBLEMAS:
1. Para abrir el perfil solo se puede clicando un badge específico
   (no la fila entera ni un botón claro en el nav).
2. Una vez dentro, "no se ve ni el perfil ni nada".

INVESTIGAR:
- Cómo se accede al perfil hoy.
- Qué se renderiza en ProfileTab y ProfileHeaderCard.

TAREAS:

T1. Asegurar que el bottom nav o un menú visible tiene entrada "Perfil"
   con icono explícito tipo `Icons.person`.

T2. profile_tab.dart al entrar debe mostrar:
   - ProfileHeaderCard (avatar, nombre, email)
   - Lista de secciones (Favoritas, Contribuciones, Apariencia,
     Accesibilidad, Notificaciones, Widgets, Privacidad, Eliminar).

T3. Si el `Scaffold` actual tiene `backgroundColor: Colors.transparent`
   pero algún ancestor pinta opaco, el render queda invisible. Verificar
   z-order y forzar `c.bgRoot` como fallback.

VERIFICACIÓN:
- Pulsar tab "Perfil" → se ve correctamente sin tener que tap exacto
  en el badge.

COMMIT:
fix(profile): acceso directo desde nav + render visible
```

### A7 — Mis contribuciones con datos reales

```text
ROL: Engineer Flutter senior, Supabase queries.

PROBLEMA:
"Mis contribuciones" muestra `12 reportes, 3 verificados` (MOCK FALSO).
Debe mostrar datos REALES: incidencias reportadas, sugerencias enviadas,
líneas creadas, líneas compartidas, feedback enviado.

TAREAS:

T1. Crear/actualizar `lib/features/profile/my_contributions_screen.dart`:
   - Provider que cuenta del usuario actual en Supabase:
     - `incidents` count
     - `route_suggestions` count
     - `route_feedback` count
     - `routes_created` (si existe tabla)
     - `route_shares` count

T2. UI con tarjetas de cada métrica:
       ContributionTile(
         icon: Icons.report,
         label: 'Incidencias',
         count: incidentCount,
       )

T3. Eliminar el `12 / 3` hardcoded del profile_header_card.

T4. Si no hay sesión (guest), mostrar mensaje "Inicia sesión para ver
   tus contribuciones".

VERIFICACIÓN:
- Login → Perfil → Mis contribuciones → datos reales.
- Sin login → mensaje.

COMMIT:
feat(profile): contribuciones con datos reales de Supabase
```

### A8 — Filas tocables completas

```text
ROL: Engineer Flutter UI.

PROBLEMA:
En el menú de Ajustes/Perfil, las filas (Apariencia, Widgets,
Accesibilidad, etc.) solo son tocables al pulsar el texto o la flecha
lateral. El espacio entre medio NO responde → incómodo.

TAREAS:

T1. Auditar `profile_tab.dart` y widgets de fila tipo `ProfileRow`.
   Envolver la fila completa con `InkWell` o `Material(InkWell)`:

       InkWell(
         onTap: onTap,
         child: Padding(
           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
           child: Row(
             children: [
               Icon(...),
               const SizedBox(width: 12),
               Expanded(child: Text(label)),
               Icon(Icons.chevron_right),
             ],
           ),
         ),
       )

T2. Verificar área tocable ≥ 48dp altura (touch target WCAG).

VERIFICACIÓN:
- Pulsar entre el icono y la flecha de cualquier fila → abre.

COMMIT:
fix(profile): filas tocables en toda su superficie
```

### A9 — Widgets Android nativos REALES

```text
ROL: Engineer Android + Flutter.

PROBLEMA (5ª iter):
Los widgets siguen sin aparecer en la lista del teléfono. Plan v2/v4/v5
los listaron pero NO se implementaron. Hay que crear AppWidgetProvider
en Kotlin + manifest + layouts XML + cableado Dart.

DOCUMENTACIÓN del plan v2 (anexo A7) sigue siendo válida. Aplicar:

T1. Crear `android/app/src/main/kotlin/com/transitly/transitly/widgets/TransitlyNextBusWidget.kt`
   (clase Kotlin extendiendo HomeWidgetProvider del package home_widget).

T2. Crear layouts XML en `android/app/src/main/res/layout/widget_next_bus.xml`.

T3. Crear metadata XML en `android/app/src/main/res/xml/widget_next_bus_info.xml`.

T4. Registrar receiver en `android/app/src/main/AndroidManifest.xml`:
       <receiver android:name=".widgets.TransitlyNextBusWidget"
                 android:exported="true">
         <intent-filter>
           <action android:name="android.appwidget.action.APPWIDGET_UPDATE"/>
         </intent-filter>
         <meta-data android:name="android.appwidget.provider"
                    android:resource="@xml/widget_next_bus_info"/>
       </receiver>

T5. Cablear `lib/data/widgets_native/widget_data_writer.dart` para que
   use HomeWidget.saveWidgetData + HomeWidget.updateWidget cuando el
   usuario marque una línea como favorita o configure el viaje habitual.

T6. Mejorar UI de `widgets_settings_screen.dart`:
   - Mostrar lista de widgets disponibles con preview
   - Instrucciones claras ("Long-press en home → Widgets → Transitly")
   - Botón "Configurar parada del widget"

VERIFICACIÓN:
- Build APK → instalar → long-press home Android → Widgets → buscar
  Transitly → debe aparecer el widget. Añadirlo al escritorio.
- Widget muestra el próximo bus de la línea favorita.

COMMITS:
- feat(widgets-android): TransitlyNextBusWidget nativo
- feat(widgets-android): cableado WidgetDataWriter con providers
- feat(widgets): UI config widgets mejorada con preview
```

### A10 — Saludo contextual reemplaza operador

```text
ROL: Engineer Flutter.

PROBLEMA:
El header del perfil dice "Operador de inicio: COMUJESA" o similar.
El usuario nunca cambia esto + es confuso.

TAREAS:

T1. En profile_header_card.dart, sustituir el dropdown/text del
   operador por:

       Text('👋 ${greetingByHour(now)}, ${userName}',
            style: TransitTypography.heading(c.textHi))

   Donde greetingByHour devuelve:
       hour < 12 → 'Buenos días'
       hour < 20 → 'Buenas tardes'
       else → 'Buenas noches'

T2. Si es invitado, mostrar "👋 Buenos días" sin nombre.

T3. Quitar todo código relacionado con seleccionar operador en el
   profile (la lógica subyacente puede quedar en services para uso
   futuro, no destruir).

COMMIT:
feat(profile): saludo contextual en lugar de selector de operador
```

---

## WAVE 3 — Briefs

### A11 — Viaje habitual con autocomplete

```text
ROL: Engineer Flutter, UX.

PROBLEMA:
El sheet de "configurar viaje habitual" actual tiene dropdowns con 19
líneas y 598 paradas. Inutilizable.

DECISIÓN: buscador con autocomplete + recientes.

ARCHIVO:
- lib/features/home/widgets/habitual_config_sheet.dart (reescribir)

TAREAS:

T1. Nuevo layout:
   1) Campo "¿A qué parada vas?" (TextField con autocomplete sobre
      `mockData.stops` filtrando por nombre).
   2) Sección "Recientes" (últimas 3 paradas elegidas, persistidas en
      Hive).
   3) Sección "Favoritas" (paradas que el usuario haya marcado favoritas).
   4) Bajo el campo, mostrar 5 sugerencias por defecto (paradas más
      populares — por número de rutas que pasan).

T2. Al seleccionar una parada, OPCIONAL paso 2: elegir línea (filtrada
   a las que pasan por esa parada).
   Si la parada tiene 1 línea → autoseleccionar.

T3. Hive box `recent_stops` para persistir las 10 últimas elegidas.

T4. UI con tarjetas (no dropdowns), badges de color por línea.

VERIFICACIÓN:
- Configurar viaje habitual en <10 segundos sin scroll infinito.

COMMIT:
refactor(home): viaje habitual con buscador autocomplete + recientes
```

### A12 — PopUp favorito rediseño + duración

```text
ROL: Engineer Flutter UI.

PROBLEMA:
PopUp/SnackBar al añadir línea a favoritos "deja mucho que desear y
dura demasiado".

TAREAS:

T1. Reemplazar el SnackBar actual por uno custom:
   - Duración: 1.2 segundos (no 4s default)
   - Diseño: badge de color de la línea + nombre + "★ Añadida"
   - Animación: slide-in desde abajo con fade, slide-out al cerrar.
   - Posición: bottom con margen 24dp del borde.

T2. Crear helper `showFavoriteAddedSnackbar(context, route)`.

T3. Sustituir todos los lugares donde se añade/quita favorito por
   este helper.

VERIFICACIÓN:
- Marcar línea como favorita → snackbar visible 1.2s con color de la
  línea y desaparece.

COMMIT:
feat(favorites): snackbar pulido con badge de color y duración corta
```

### A13 — "Mostrar paradas" crash + Privacidad funcional

```text
ROL: Engineer Flutter senior.

PROBLEMAS:
1. Al activar "Mostrar paradas" en filtros, "deja de ir todo" (probable
   crash o freeze por exceso de markers).
2. Pantalla de Privacidad: nada funcional.

TAREAS:

T1. "Mostrar paradas":
   - En transit_map.dart cuando `showAllStops == true`, ahora hace
     unión de TODAS las paradas de TODAS las rutas visibles = 598
     paradas. Flutter map probablemente colapsa.
   - SOLUCIÓN: aplicar culling por viewport antes de crear markers.
     Solo pasar a buildStopMarkers las paradas dentro de `_visibleBounds`.
     Esto reduce de 598 a ~20-50 markers visibles a zoom 13-14.
   - Además limitar a max 150 markers visibles.

T2. Privacidad funcional:
   - Pantalla `lib/features/profile/privacy_screen.dart` (o crear).
   - Toggles reales:
     - "Análisis de uso (PostHog)" → escribe a `privacy_consents`
       Supabase y desactiva PostHog en runtime
     - "Reportes de crash (Sentry)" → idem
     - "Compartir datos anónimos" → idem
   - Listado de datos personales que tenemos del usuario + botón
     "Descargar mis datos" (Edge Function que devuelve JSON).

VERIFICACIÓN:
- Activar "Mostrar paradas" en filtros → no se cuelga + se ven solo
  las del viewport.
- Toggle "Análisis de uso" en Privacidad → al desactivarlo, PostHog
  llama `optOut()` inmediatamente.

COMMITS:
- fix(map): culling por viewport en showAllStops para evitar freeze
- feat(privacy): toggles funcionales conectados a Supabase
```

### A14 — Eliminar cuenta real con gracia 30 días

```text
ROL: Engineer Flutter + Supabase (SQL + Edge Function).

DECISIÓN: borrado real con periodo de gracia 30 días.

TAREAS:

T1. Migración SQL en Supabase:
   ```sql
   CREATE TABLE IF NOT EXISTS account_deletion_requests (
     user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
     requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
     execute_at TIMESTAMPTZ NOT NULL GENERATED ALWAYS AS
       (requested_at + INTERVAL '30 days') STORED,
     cancelled_at TIMESTAMPTZ
   );
   ALTER TABLE account_deletion_requests ENABLE ROW LEVEL SECURITY;
   CREATE POLICY "Users see their own requests"
     ON account_deletion_requests FOR SELECT USING (auth.uid() = user_id);
   CREATE POLICY "Users create their own request"
     ON account_deletion_requests FOR INSERT WITH CHECK (auth.uid() = user_id);
   CREATE POLICY "Users cancel their own request"
     ON account_deletion_requests FOR UPDATE USING (auth.uid() = user_id);
   ```

T2. Edge Function `process-account-deletions`:
   ```typescript
   // supabase/functions/process-account-deletions/index.ts
   serve(async () => {
     const now = new Date().toISOString();
     const { data: due } = await supabaseAdmin
       .from('account_deletion_requests')
       .select('user_id')
       .lte('execute_at', now)
       .is('cancelled_at', null);
     for (const req of due ?? []) {
       await supabaseAdmin.auth.admin.deleteUser(req.user_id);
       await supabaseAdmin
         .from('account_deletion_requests')
         .delete()
         .eq('user_id', req.user_id);
     }
     return new Response('OK');
   });
   ```
   Configurar cron diario en Supabase Dashboard.

T3. Pantalla `lib/features/profile/delete_account_screen.dart`:
   - Si ya hay request pendiente: mostrar "Tu cuenta se eliminará el
     [execute_at]. Puedes cancelar en cualquier momento" + botón
     "Cancelar eliminación".
   - Si no: confirmación + botón "Eliminar mi cuenta en 30 días".

T4. UI clara explicando qué pasa con sus datos durante los 30 días y
   tras la eliminación.

VERIFICACIÓN:
- Login → Perfil → Eliminar → confirmar → ver pending → Cancelar →
  pending desaparece.
- Crear request → en Supabase Dashboard SQL Editor: `UPDATE
  account_deletion_requests SET requested_at = NOW() - INTERVAL '31 days'
  WHERE user_id = '...'` → ejecutar Edge Function manualmente → usuario
  eliminado.

COMMITS:
- feat(account): migration account_deletion_requests con RLS
- feat(account): Edge Function process-account-deletions
- feat(account): UI eliminar cuenta con periodo de gracia 30 días
```

---

## WAVE 4 — Coordinador

```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # si A11 o A14 modificaron freezed
flutter analyze
flutter build apk --release --dart-define-from-file=dart_defines.json
flutter install --release -d 000871487002528
```

### Smoke crítico

1. **A1**: cambiar tema oscuro→claro → mapa carga tiles claras.
2. **A2**: simular ubicación lejos → "ir a línea L1" → polyline visible.
3. **A3**: modo claro → Apariencia → fondo claro coherente.
4. **A4**: Apariencia → seleccionar Aurora, Beams, Balatro, etc. → render distinto cada uno.
5. **A5**: cambiar paleta a Sunrise → gradiente naranja en todos los GradientText.
6. **A6**: tap "Perfil" → todo visible.
7. **A7**: Mis contribuciones muestra números reales.
8. **A8**: tap entre icono y flecha de Apariencia/Widgets/etc → entra.
9. **A9**: long-press home Android → Widgets → Transitly → widget añadible.
10. **A10**: header del perfil dice "👋 Buenos días, [nombre]".
11. **A11**: viaje habitual con buscador de paradas.
12. **A12**: snackbar al favoritar dura 1.2s con badge de color.
13. **A13**: toggle "mostrar paradas" → no crash; Privacidad funcional.
14. **A14**: eliminar cuenta → request creado + posibilidad de cancelar.

---

## Cobertura

| # | Item | Agente |
|---|------|--------|
| 1 | Mapa oscuro→claro deja de ir | A1 |
| 2 | Líneas no se ven lejos de Jerez | A2 |
| 3 | Fondo apariencia oscuro en modo claro | A3 |
| 4 | Fondos nuevos no funcionan | A4 |
| 5 | Gradiente siempre azul | A5 |
| 6 | Perfil sin acceso + render | A6 |
| 7 | Contribuciones falsas | A7 |
| 8 | Filas no tocables completas | A8 |
| 9 | Widgets Android + UI config | A9 |
| 10 | Operador inicio → saludo | A10 |
| 11 | Viaje habitual escalable | A11 |
| 12 | PopUp favorito | A12 |
| 13 | Mostrar paradas crash + Privacidad | A13 |
| 14 | Eliminar cuenta real | A14 |
