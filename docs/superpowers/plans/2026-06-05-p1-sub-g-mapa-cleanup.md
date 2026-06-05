# Sub-plan G de P1 — Cleanup mapa: eliminar FilterPresets + fusionar zonas/líneas + rediseñar "X CERRAR"

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cerrar tres ítems P1 del bloque mapa que son cambios de UI/cleanup: (P1-05) eliminar la pantalla y entrada "Gestionar mis filtros" que es un placeholder de baja utilidad; (P1-07) fusionar las dos secciones "Mostrar líneas" + "Zonas" del sheet de filtros que muestran información solapada; (P1-08) rediseñar el pill "X CERRAR" que aparece al seleccionar una ruta para que sea más prominente y accesible.

> **Nota sobre P1-06.** El plan V16 incluye también "datos offline funcional con FMTC" en este bloque. Tras revisar el código (`OfflineRegionRepository` solo expone CRUD sin wiring real al descargador de tiles MapTiler — comentario "F20 conecta esto al descargador de tiles MapTiler" en el repo), el alcance real es grande: cablear `fmtc_region_service` al repo, propagar progreso async a la UI, manejar el espacio en disco. Se separa a un sub-plan H propio.

**Architecture:**

- **P1-05** — `lib/features/profile/filter_presets_screen.dart` carga, guarda y aplica presets de `MapFilterState` en SharedPreferences. La pantalla existe desde fase F19 sin completarse. La opción "Gestionar mis filtros" vive en `lib/features/home/widgets/profile_location_section.dart:72-76`. Fix: eliminar el archivo de pantalla, la ruta del go_router (`/profile/filters`), la entrada en `profile_location_section`, y los strings `.arb` ya quedan en l10n (no críticos para esta limpieza).

- **P1-07** — `lib/features/map/widgets/map_filter_sheet.dart:65-73` muestra dos secciones consecutivas: "Mostrar líneas" + "Zonas" con un `ZoneCompanyLineTree` que ya muestra la jerarquía zona→operador→línea. El bloque `_OperatorTree` previo es un selector más simple de "qué líneas activar". Funcionan SOBRE la misma fuente de datos. Fix: una sola sección "Líneas y zonas" que use solo `ZoneCompanyLineTree` (más completo). El `_OperatorTree` legacy se elimina.

- **P1-08** — `lib/features/home/tabs/map_tab.dart:700-725` el pill "X CERRAR" aparece arriba del sheet de rutas cuando hay una ruta seleccionada. Es pequeño, queda mal posicionado al lado del contador. Fix mínimo: rediseñarlo como un chip más prominente con tamaño WCAG 2.5.5 (mínimo 48dp), mejor color y posición (full-width o aligned-right con más padding). Plus opción: incluir el código de la ruta seleccionada en el chip (ej. "✕ Quitar L1") para que el usuario sepa qué se va a cerrar.

**Tech Stack:** Flutter Material, Riverpod 2.6.1, go_router (eliminar ruta), `shared_preferences` (limpiar key obsoleta).

---

## File Structure

**Delete:**
- `lib/features/profile/filter_presets_screen.dart`

**Modify:**
- `lib/core/router/app_router.dart` — eliminar ruta `/profile/filters`.
- `lib/features/home/widgets/profile_location_section.dart` — quitar entrada "Gestionar mis filtros".
- `lib/features/map/widgets/map_filter_sheet.dart` — fusionar "Mostrar líneas" + "Zonas" en una sección, eliminar `_OperatorTree`.
- `lib/features/home/tabs/map_tab.dart` — rediseñar pill "X CERRAR" (más grande, más claro).

---

## Task 1: Eliminar FilterPresets (P1-05)

### Step 1.1 — Buscar referencias al FilterPresetsScreen y a la ruta

- [ ] Buscar usos en código:

```bash
# Grep all references
```

- [ ] Usar Grep tool con patrón `FilterPresetsScreen|filter_presets_screen|/profile/filters` en `lib/`.

### Step 1.2 — Eliminar el archivo de pantalla

- [ ] Eliminar:

```bash
rm lib/features/profile/filter_presets_screen.dart
```

### Step 1.3 — Eliminar la ruta del go_router

- [ ] Editar `lib/core/router/app_router.dart`. Buscar y eliminar la entrada con `path: '/profile/filters'` o `path: 'filters'` dentro del scope de profile. Y el import correspondiente del archivo eliminado.

### Step 1.4 — Quitar la entrada en `ProfileLocationSection`

- [ ] En `lib/features/home/widgets/profile_location_section.dart`, eliminar el bloque (líneas 71-76 aprox.):

```dart
          GestureDetector(
            onTap: () => context.push('/profile/filters'),
            child: Text(l10n.profileZoneManageArrow,
                style: TransitTypography.bodySecondary(c.accent)),
          ),
```

…y el `Divider` que sigue si queda huérfano.

### Step 1.5 — Análisis para detectar imports rotos

- [ ] Ejecutar:

```bash
flutter analyze
```

Expected: 0 errors. Si el `flutter_lints` se queja de imports no usados, eliminarlos también.

### Step 1.6 — Smoke test manual

- [ ] `flutter run`.
- [ ] Perfil → la opción "Gestionar mis filtros" ya no aparece.
- [ ] Intentar navegar manualmente a `/profile/filters` → muestra el `NotFoundScreen` del router (esperado).

### Step 1.7 — Commit

```bash
git add -A
git commit -m "$(cat <<'EOF'
fix(profile): eliminar FilterPresets placeholder (P1-05)

La pantalla "Gestionar mis filtros" existía desde fase F19 sin completarse
y aportaba poco valor real (permitía guardar combinaciones de filtros del
mapa con nombre, pero nunca se cableó al modelo nuevo de filtros con zonas
y comunidad/oficial).

Limpieza:
- lib/features/profile/filter_presets_screen.dart eliminado.
- Ruta /profile/filters eliminada del go_router.
- Entrada "Gestionar mis filtros" eliminada de ProfileLocationSection.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Fusionar secciones "Mostrar líneas" + "Zonas" (P1-07)

### Step 2.1 — Estudiar `_OperatorTree` y decidir qué eliminar

- [ ] Localizar `_OperatorTree` en `map_filter_sheet.dart` (clase privada al final del archivo). Verificar qué hace exactamente — selector plano de "qué líneas activar".

- [ ] Comparar con `ZoneCompanyLineTree` (`lib/features/map/widgets/zone_company_line_tree.dart`). Es jerárquico (zona → operador → línea) y más completo.

- [ ] Decisión: `ZoneCompanyLineTree` cubre lo que hace `_OperatorTree` y añade la dimensión "zona". Eliminamos `_OperatorTree`.

### Step 2.2 — Reemplazar las dos secciones por una

- [ ] En `lib/features/map/widgets/map_filter_sheet.dart`, sustituir el bloque:

```dart
                  _SectionTitle(c: c, title: 'Mostrar líneas'),
                  _OperatorTree(
                    c: c, f: f, ctrl: ctrl, mockData: mockData,
                  ),
                  const SizedBox(height: 16),

                  _SectionTitle(c: c, title: 'Zonas'),
                  const ZoneCompanyLineTree(),
                  const SizedBox(height: 16),
```

por:

```dart
                  _SectionTitle(c: c, title: 'Líneas y zonas'),
                  const ZoneCompanyLineTree(),
                  const SizedBox(height: 16),
```

### Step 2.3 — Eliminar la clase `_OperatorTree` y sus dependencias internas

- [ ] Buscar en el archivo la definición de `_OperatorTree` y eliminarla completamente. Eliminar también imports que queden huérfanos (p.ej. si solo `_OperatorTree` usaba `mockData` en este contexto).

### Step 2.4 — Análisis + smoke test

- [ ] Ejecutar:

```bash
flutter analyze
```

Expected: 0 errors.

- [ ] `flutter run`.
- [ ] Abrir mapa → tap en filtros → el sheet muestra "Líneas y zonas" como UNA sola sección con la jerarquía completa.
- [ ] Toggle de una línea → afecta al mapa.
- [ ] Toggle de una zona entera → afecta a todas las líneas de esa zona.

### Step 2.5 — Commit

```bash
git add lib/features/map/widgets/map_filter_sheet.dart
git commit -m "$(cat <<'EOF'
fix(map): fusionar "Mostrar líneas" + "Zonas" en una sección (P1-07)

El sheet de filtros del mapa tenía dos secciones consecutivas que
mostraban información solapada: "Mostrar líneas" (selector plano via
_OperatorTree) y "Zonas" (jerárquico via ZoneCompanyLineTree).

Fix:
- Sola sección "Líneas y zonas" con ZoneCompanyLineTree (más completo).
- _OperatorTree eliminado del archivo.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Rediseñar pill "X CERRAR" (P1-08)

### Step 3.1 — Localizar el pill en `map_tab.dart`

- [ ] En `lib/features/home/tabs/map_tab.dart`, dentro de `_buildHandle` (líneas ~700-725), localizar:

```dart
              if (_selectedRouteId != null)
                Pressable(
                  onTap: _clearSelection,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: c.accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: c.accent.withValues(alpha: 0.20),
                          width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.clear, size: 14, color: c.accent),
                        const SizedBox(width: 6),
                        Text(
                          l10n.actionClose.toUpperCase(),
                          style: TransitTypography.bodySmall(c.accent),
                        ),
                      ],
                    ),
                  ),
                ),
```

### Step 3.2 — Sustituir por un chip más prominente que incluya el código de la ruta

- [ ] Necesitamos el `RouteModel` de la ruta seleccionada. Justo después de `final route = ...` o usando `mockData.getRouteById(_selectedRouteId!)`. Hacerlo dentro del `_buildHandle` o pasarlo desde el `build`. Para no propagar mucho, calcularlo inline.

- [ ] Reemplazar el bloque por:

```dart
              if (_selectedRouteId != null) ...[
                Builder(builder: (context) {
                  final mockData = ref.read(mockDataServiceProvider);
                  final route = mockData.getRouteById(_selectedRouteId!);
                  final routeLabel =
                      route != null ? 'L${route.code}' : 'ruta';
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: _clearSelection,
                      child: Container(
                        constraints: const BoxConstraints(
                            minHeight: 48, minWidth: 48),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: c.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: c.accent.withValues(alpha: 0.40),
                              width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.close, size: 18, color: c.accent),
                            const SizedBox(width: 8),
                            Text(
                              'Quitar $routeLabel',
                              style: TransitTypography.bodyPrimary(c.accent),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
```

Cambios clave:
1. `minHeight: 48 + minWidth: 48` cumple WCAG 2.5.5.
2. Padding más grande (16h, 10v) → área táctil real.
3. Border más visible (alpha 0.40 + width 1).
4. Texto "Quitar L1" en vez de solo "CERRAR" → el usuario sabe qué se cierra.
5. `InkWell` con `Material` permite ripple feedback al pulsar.

### Step 3.3 — Verificar import de mockDataServiceProvider

- [ ] `ref.read(mockDataServiceProvider)` ya se usa en otros sitios del archivo. Si no, añadir import.

### Step 3.4 — Análisis + smoke test

- [ ] Ejecutar:

```bash
flutter analyze
```

Expected: 0 errors.

- [ ] `flutter run`.
- [ ] Mapa → tocar una línea → en el header del sheet aparece "Quitar L1" como chip grande accesible.
- [ ] Pulsar el chip → la ruta se deselecciona y el chip desaparece.

### Step 3.5 — Commit

```bash
git add lib/features/home/tabs/map_tab.dart
git commit -m "$(cat <<'EOF'
fix(map): rediseñar chip "X CERRAR" del header con código de ruta (P1-08)

El pill "X CERRAR" arriba del sheet de rutas era muy pequeño (icono 14px
+ texto bodySmall + área táctil reducida), no cumplía WCAG 2.5.5 y no
indicaba qué línea se iba a deseleccionar.

Fix:
- Chip más grande con minHeight/minWidth 48dp.
- Padding 16h × 10v y border más visible.
- Texto "Quitar L1" (incluye código real de la ruta seleccionada).
- InkWell con feedback ripple.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Verificación final + tracking V16 + PR

### Step 4.1 — Suite + análisis final

- [ ] Ejecutar:

```bash
flutter analyze
flutter test
```

Expected: 0 errors. Mismos 19 timeouts pre-existentes en `card_tab_widget_test.dart`.

### Step 4.2 — Smoke test integrado

- [ ] `flutter run`.
- [ ] Perfil → no aparece "Gestionar mis filtros".
- [ ] Mapa → filtros → sección única "Líneas y zonas".
- [ ] Mapa → tap en línea → chip "Quitar L1" grande arriba del sheet.

### Step 4.3 — Tracking V16

- [ ] Marcar P1-05, P1-07, P1-08 como cerrados en
      `docs/historico/PLAN_REPARACION_2026_06_05_V16.md`.

- [ ] P1-06 sigue abierto — añadir nota sobre el sub-plan H futuro.

- [ ] Commit:

```bash
git add docs/historico/PLAN_REPARACION_2026_06_05_V16.md
git commit -m "chore: cerrar P1-05/P1-07/P1-08 en plan V16 (P1-06 a sub-H futuro)

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

### Step 4.4 — Push + PR

```bash
git push -u origin fix/p1-sub-g-mapa-cleanup
```

Abrir PR manualmente.

---

## Notas y consideraciones

**Sobre P1-06 diferido.** El `OfflineRegionRepository` solo expone CRUD básico (`forUser`, `add`, `delete`) sin wiring real a `flutter_map_tile_caching` para descarga efectiva de tiles. El comentario interno dice "F20 conecta esto al descargador de tiles MapTiler". El alcance real para hacerlo funcional incluye:
1. Cablear el método `add()` a `FmtcService` para que descargue el bounding box de la región (todos los zoom levels relevantes).
2. Reportar progreso async a la UI (`StreamProvider<DownloadProgress>` o similar).
3. En `delete()`, eliminar los tiles del store FMTC además de la entrada Hive.
4. UI: mostrar barra de progreso por región en `_RegionList`.

Eso es un sub-plan H propio con su test plan.

**Sobre `_OperatorTree`.** Asumo que el comportamiento queda totalmente cubierto por `ZoneCompanyLineTree`. Si en smoke test alguna funcionalidad falta (p.ej. el toggle global "ocultar todas las líneas"), añadirla como cabecera del `ZoneCompanyLineTree` en un mini-commit follow-up.

**Sobre las strings legacy en l10n.** Las entradas `filterPresetsTitle`, `filterPresetsDialogTitle`, etc. del .arb quedan huérfanas tras eliminar FilterPresets. No las elimino en este PR para no tocar i18n; un cleanup posterior del .arb las puede sacar sin afectar runtime.
