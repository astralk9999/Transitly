# PLAN DE ACCIÓN — REMEDIACIÓN INTEGRAL v2

**Estado base:** `master @ 1c77f1f` (2026-05-22)
**Origen:** `docs/historico/AUDIT_2026_05_22.md` (auditoría independiente deep-dive con 13 sub-agentes paralelos).
**Reemplaza a:** `docs/historico/PLAN_ACCION_REMEDIACION_v1.md` (congelado en `master @ 396a1e6`, 2026-05-18 — pre-auditoría).
**Objetivo:** llevar el scorecard de 5.4/10 → 10/10 en 7 fases con un primer checkpoint pre-defensa TFG en 3-4 horas.

---

## A. CONTEXTO Y REGLAS

### A.1 Punto de partida verificado

| Métrica | Valor real | Fuente |
|---------|-----------|--------|
| Tests pasando | **304 + 1 skipped** | `flutter test` ejecutado 2026-05-22 |
| Cobertura global | **24,77 %** | `awk` sobre `coverage/lcov.info` |
| Migraciones SQL locales | **15 archivos** | `supabase/migrations/` |
| Cajas Hive abiertas | **16 boxes** | `hive_init.dart:71-92` |
| Features | **27 carpetas** | `lib/features/` |
| Repositorios | **12 SWR + 4 sin SWR** | `lib/data/*/` |
| APK release | **77.024.450 B = 73,46 MiB** | `build/app/outputs/flutter-apk/app-release.apk` |
| Jobs CI | **5** (analyze, test, build, build-android, gitleaks) | `.github/workflows/ci.yml` |
| Mega plan cerrado real | **≈100/190 (52,6 %)** | Muestreo 30 ítems con 9 falsos cierres |

### A.2 Scorecard inicial (objetivo 10/10 en F6)

| Área | Inicio | F0 | F1 | F2 | F3 | F4 | F5 | F6 |
|------|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| Arquitectura | 8.0 | 8.0 | 8.5 | 8.5 | 8.5 | 8.5 | 9.5 | 10 |
| Código | 6.5 | 7.0 | 8.0 | 8.0 | 8.5 | 8.5 | 9.5 | 10 |
| Tests | 5.0 | 5.0 | 6.0 | 6.5 | 7.0 | 7.5 | 8.0 | 10 |
| Documentación | 5.5 | 7.0 | 8.5 | 9.0 | 9.0 | 9.5 | 9.5 | 10 |
| Seguridad | 6.0 | 6.5 | 7.0 | 8.5 | 9.0 | 9.0 | 9.5 | 10 |
| Accesibilidad | 5.0 | 5.5 | 7.5 | 7.5 | 7.5 | 8.0 | 8.5 | 10 |
| Observabilidad | 4.0 | 4.5 | 5.0 | 6.0 | 7.0 | 9.0 | 9.5 | 10 |
| Release-readiness | 3.0 | 3.5 | 4.0 | 6.0 | 8.5 | 9.0 | 9.5 | 10 |
| **MEDIA** | **5.4** | **5.9** | **6.8** | **7.5** | **8.1** | **8.6** | **9.2** | **10** |
| **TFG defensa** | **7.0** | **7.5** | **8.5** | **9.0** | **9.0** | **9.5** | **9.5** | **10** |
| **Producción** | **4.0** | **4.0** | **5.0** | **6.5** | **8.0** | **8.5** | **9.5** | **10** |

### A.3 Reglas transversales (NO negociables)

1. **Cada paso termina con `flutter analyze` = 0 y `flutter test` verde.** Si rompe, se revierte y se reabre.
2. **Ningún ítem se considera "cerrado" sin grep verificable** en `lib/`, `supabase/`, `test/` o en un comando reproducible.
3. **Cada paso es PR-able** (atómico, mensaje conventional commits).
4. **Documentación se actualiza junto con el código** (no en PRs separados que generan drift).
5. **Cifras del bloque "Estado verificado" de `00_MAESTRO.md` se regeneran con `tool/verify_state.sh`** — nunca se editan a mano.
6. **No se introducen TODOs/HACKs** sin issue de seguimiento.
7. **No se cierra una fase sin re-correr el scorecard** y actualizar la tabla A.2.

### A.4 Leyenda

- **Esfuerzo:** `S` <2h · `M` ½–1 día · `L` 2–5 días · `XL` >1 semana
- **Riesgo build:** `🟢` bajo · `🟡` medio · `🔴` alto
- **Tipo:** `fix` defecto · `req` requisito · `debt` deuda · `doc` documentación · `ops` acción externa · `feat` feature nueva

---

## FASE 0 — PRE-DEFENSA TFG (≈3-4 horas)

**Objetivo:** evitar fallos triviales que un tribunal detecta en 5 minutos. TFG 7.0 → 7.5. **Sin tocar arquitectura.** Cada paso es <30 min y reversible.

### F0.1 · Arreglar botón "AÑADIR A MIS LÍNEAS"

**Por qué:** la acción principal del detalle de ruta tiene `onPressed: () {}` literal. El tribunal pulsa el botón en una demo, no pasa nada, pierdes la nota.

**Archivo:** `lib/features/route_detail/route_detail_screen.dart:181`

**Acción:**
1. Localiza la línea con `Grep`:
   ```bash
   grep -n "isFavorite ? null : ()" lib/features/route_detail/route_detail_screen.dart
   ```
2. Identifica el provider del estado de favoritos (probablemente `userFavoritesProvider` en `lib/shared/providers/`).
3. Reemplaza el `() {}` por una llamada real al notifier:
   ```dart
   onPressed: isFavorite
       ? () => ref.read(userFavoritesProvider.notifier).removeLine(route.id)
       : () => ref.read(userFavoritesProvider.notifier).addLine(route.id),
   ```
4. Si el provider no existe aún (es muy probable que sea solo lectura), añade el método `addLine(String routeId)` en el notifier respectivo, persistiendo en Hive box `userFavorites`.

**Verificación:**
- `Grep -n "onPressed: () {}" lib/features/route_detail/` ⇒ 0 hits
- Test manual: pulsar el botón en la app → toast confirmando, estrella cambia color, `flutter test` verde.
- Idealmente: añadir `test/features/route_detail/add_favorite_line_test.dart` con `testWidgets`.

**Esfuerzo:** S · **Riesgo:** 🟢 · **Tipo:** fix

---

### F0.2 · Eliminar hardcodes flagrantes

**Por qué:** "Ana Martín", "VIAJERO 450", ETA aleatoria y "actualizado hace 2 días" delatan datos inventados en 3 segundos.

**Archivos:**
- `lib/features/driver/driver_panel.dart:54` — `'COMUJESA · Ana Martín'`
- `lib/features/profile/achievements_screen.dart:95` — `'VIAJERO', 450` hardcoded
- `lib/features/driver/active_route_screen.dart:173,182` — `'en 0.${(nextIdx % 5)+1} km'`, `'~${(nextIdx % 4)+1} min'`
- `lib/features/route_detail/widgets/route_detail_header.dart:100` — `DataFreshnessIndicator(DateTime.now().subtract(Duration(days:2)))`
- `lib/features/contributions/my_contributions_screen.dart:121` — `ReputationBadge(ReputationLevel.contributor)`

**Acción:**
1. **driver_panel:54** → `final user = ref.watch(currentUserProvider);` y mostrar `user.name ?? l10n.driverPanelGuest`.
2. **achievements_screen:95** → `final reputation = ref.watch(reputationProvider);` y usar `reputation.level.label`, `reputation.score`.
3. **active_route_screen:173,182** → si el mock no tiene datos reales, mostrar `--` o etiqueta `l10n.eta_unavailable` ("ETA no disponible"), NO inventar.
4. **route_detail_header:100** → leer `route.lastUpdatedAt` del modelo. Si null, ocultar el `DataFreshnessIndicator`.
5. **my_contributions_screen:121** → `final user = ref.watch(currentUserProvider);` → `ReputationBadge(user.reputationLevel ?? ReputationLevel.newcomer)`.

**Verificación:**
- `Grep -n "Ana Martín\|VIAJERO.*450\|days: 2\|ReputationLevel\.contributor" lib/` ⇒ 0 hits
- Manual: abrir cada pantalla con usuario A y usuario B → datos distintos.

**Esfuerzo:** M · **Riesgo:** 🟢 · **Tipo:** fix

---

### F0.3 · Renombrar referencias rotas en runbook

**Por qué:** `docs/runbooks/migration_rollback.md` cita migraciones `002_rls_policies.sql` y `008_gtfs_seed.sql` que **no existen**. Un tribunal con `ls supabase/migrations/` lo detecta.

**Acción:**
1. Lista las migraciones reales:
   ```bash
   ls supabase/migrations/
   # 001_init.sql, 002_rls.sql, 003_rls_fixes.sql, 004_storage.sql,
   # 005_functions.sql, 006_vote_helpers.sql, 007_invitation_helpers.sql,
   # 007_notification_triggers.sql, 012_reputation.sql, 013_offline_export.sql,
   # 014_audit_log.sql, 014_push_tokens.sql, 015_privacy_consents.sql,
   # 015_push_triggers.sql, 016_data_exports.sql
   ```
2. Edita `docs/runbooks/migration_rollback.md`:
   - Sustituye toda mención de `002_rls_policies.sql` por `002_rls.sql` + `003_rls_fixes.sql`.
   - Borra la sección de `008_gtfs_seed.sql` (no existe). Añade nota: "No hay seed.sql — datos mock cargados desde `assets/mock/comujesa_data.json`".
   - Añade rollback para 012, 013, 014, 015, 016 (las que existen).
3. Edita `docs/runbooks/sentry_spike.md` y `docs/runbooks/push_down.md`:
   - Sustituye `lib/firebase_setup.dart` por la ruta real: `lib/data/push/firebase_setup.dart`.

**Verificación:**
- Para cada `.sql` citado en runbooks: `ls supabase/migrations/<archivo>` debe existir.
- Para cada `.dart` citado en runbooks: `ls <ruta>` debe existir.

**Esfuerzo:** S · **Riesgo:** 🟢 · **Tipo:** doc

---

### F0.4 · Crear `tool/verify_state.sh`

**Por qué:** las cifras del `00_MAESTRO.md` están desfasadas porque se editan a mano. La solución es generarlas con un script reproducible que cualquiera puede ejecutar.

**Archivo nuevo:** `tool/verify_state.sh`

**Contenido:**
```bash
#!/usr/bin/env bash
# Genera el bloque "Estado verificado" de docs/00_MAESTRO.md
# Uso: tool/verify_state.sh > /tmp/estado.md && diff -u /tmp/estado.md <(sed -n '/<!-- BEGIN ESTADO -->/,/<!-- END ESTADO -->/p' docs/00_MAESTRO.md)

set -euo pipefail

HEAD_REF=$(git rev-parse --short HEAD)
DATE_TODAY=$(date +%Y-%m-%d)
COMMIT_DATE=$(git log -1 --format=%cd --date=short)

# Tests
TEST_OUTPUT=$(flutter test 2>&1 | tail -3)
TEST_PASSED=$(echo "$TEST_OUTPUT" | grep -oP '\+\K\d+' | head -1)
TEST_SKIPPED=$(echo "$TEST_OUTPUT" | grep -oP '~\K\d+' | head -1 || echo 0)

# Cobertura
COVERAGE=$(awk -F'[:,]' '/^DA:/ {t++; if($3>0) h++} END {printf "%.2f", h/t*100}' coverage/lcov.info)

# APK size (si existe)
APK_BYTES=$(stat -c%s build/app/outputs/flutter-apk/app-release.apk 2>/dev/null || echo 0)
APK_MIB=$(awk "BEGIN {printf \"%.2f\", $APK_BYTES/1048576}")

# Migraciones
MIGRATIONS=$(ls supabase/migrations/*.sql 2>/dev/null | wc -l)

# Features
FEATURES=$(ls -d lib/features/*/ 2>/dev/null | wc -l)

# Boxes Hive (cuenta openBox en hive_init.dart)
BOXES=$(grep -c "openBox\|openLazyBox" lib/data/cache/hive_init.dart)

# Commits totales
COMMITS_TOTAL=$(git log --oneline | wc -l)

# Jobs CI
JOBS_CI=$(grep -c "^  [a-z].*:$" .github/workflows/ci.yml || echo "?")

# Analyze (debería ser 0 issues)
ANALYZE_ISSUES=$(flutter analyze 2>&1 | grep -c "info\|warning\|error" || echo 0)

cat <<EOF
<!-- BEGIN ESTADO -->
**Estado verificado ($DATE_TODAY · master @ $HEAD_REF · commit $COMMIT_DATE)**

- \`flutter analyze\`: **$ANALYZE_ISSUES issues**
- \`flutter test\`: **$TEST_PASSED passed + $TEST_SKIPPED skipped**
- Cobertura global: **$COVERAGE %**
- APK release: **$APK_MIB MiB** ($APK_BYTES bytes)
- Migraciones SQL: **$MIGRATIONS**
- Features: **$FEATURES**
- Boxes Hive: **$BOXES**
- Commits totales: **$COMMITS_TOTAL**
- CI jobs: **$JOBS_CI**

> Bloque autogenerado por \`tool/verify_state.sh\`. NO editar a mano.
<!-- END ESTADO -->
EOF
```

**Pasos:**
1. `mkdir -p tool && touch tool/verify_state.sh`
2. Pega el contenido
3. `chmod +x tool/verify_state.sh`
4. Prueba: `./tool/verify_state.sh` debe imprimir el bloque
5. Añade a `.gitattributes`: `tool/*.sh text eol=lf`

**Verificación:**
- `./tool/verify_state.sh` ejecuta sin error y todas las cifras son no-cero.
- Las cifras coinciden con la auditoría (304 / 24.77 / 15 / 27 / 16).

**Esfuerzo:** S · **Riesgo:** 🟢 · **Tipo:** debt

---

### F0.5 · Sustituir el bloque "Estado verificado" de 00_MAESTRO.md

**Por qué:** F0.4 generó el bloque autogenerable. Ahora hay que insertarlo en el doc maestro.

**Archivo:** `docs/00_MAESTRO.md` (líneas 10-14 aprox.)

**Acción:**
1. Abre `docs/00_MAESTRO.md`.
2. Localiza el bloque actual de "Estado verificado".
3. Reemplázalo por:
   ```markdown
   <!-- BEGIN ESTADO -->
   (placeholder — autogenerado por tool/verify_state.sh)
   <!-- END ESTADO -->
   ```
4. Ejecuta `./tool/verify_state.sh > /tmp/estado.md && python3 -c "import sys; ..." ` o más simple, copia manualmente el output del script entre los marcadores.

**Verificación:**
- Cifras visibles en `00_MAESTRO.md` coinciden con `tool/verify_state.sh` output.
- `Grep -n "BEGIN ESTADO" docs/00_MAESTRO.md` ⇒ 1 hit.

**Esfuerzo:** S · **Riesgo:** 🟢 · **Tipo:** doc

---

### F0.6 · Marcar features "estantería" honestamente

**Por qué:** mejor llamarlas "trabajo futuro" que dejar que el tribunal pulse "PUBLICAR RUTA" y vea que no hace nada.

**Acción:**
1. **`lib/features/widgets_native/widgets_settings_screen.dart`**:
   ```dart
   @override
   Widget build(BuildContext context) {
     if (kReleaseMode) {
       return Scaffold(
         appBar: AppBar(title: Text(l10n.widgetsSettingsTitle)),
         body: Center(child: Text(l10n.featureComingSoon)),
       );
     }
     // ... resto solo en debug
   }
   ```
2. **`lib/features/driver/ai_schedule_import.dart`**: añade banner permanente:
   ```dart
   Banner(
     message: 'PROTOTIPO',
     location: BannerLocation.topEnd,
     child: ...
   )
   ```
3. **`lib/features/driver/route_editor/post_recording_editor.dart:258-280`**: cambia los botones "GUARDAR BORRADOR" y "PUBLICAR RUTA" para que digan "GUARDAR LOCAL (prototipo)" — solo persisten a Hive draft, no a Supabase. Cambia el texto.
4. Añade clave en `lib/l10n/app_es.arb`:
   ```json
   "featureComingSoon": "Funcionalidad disponible en próxima versión.",
   "@featureComingSoon": {"description": "Placeholder para features en construcción"}
   ```
   y traduce a `app_en.arb`, `app_ar.arb`. Regenera con `flutter gen-l10n`.

**Verificación:**
- `Grep -n "PUBLICAR RUTA" lib/` ⇒ 0 hits o todos como "GUARDAR LOCAL".
- En release: la pantalla widgets nativos muestra "próxima versión" en lugar de UI engañosa.

**Esfuerzo:** S · **Riesgo:** 🟢 · **Tipo:** fix

---

### F0.7 · Buscador de rutas → estado honesto

**Por qué:** `search_tab.dart:104-189` siempre muestra L1/L4/L5 con tiempos inventados. Mejor un empty state honesto.

**Archivo:** `lib/features/home/tabs/search_tab.dart:104-189`

**Acción:**
1. Borra el bloque hardcoded de 3 ResultsCard.
2. Sustitúyelo por:
   ```dart
   if (_query.isEmpty)
     EmptyState(
       icon: Icons.search,
       title: l10n.searchEmptyTitle,
       subtitle: l10n.searchEmptySubtitle,
     )
   else
     // TODO: integrar búsqueda real cuando el algoritmo esté listo
     EmptyState(
       icon: Icons.construction,
       title: l10n.searchUnderConstructionTitle,
       subtitle: l10n.searchUnderConstructionSubtitle,
       action: TransitButton(
         label: l10n.searchReportRouteAction,
         onPressed: () => context.push('/suggestions/suggest'),
       ),
     ),
   ```
3. Añade claves a `app_*.arb`:
   - `searchEmptyTitle`: "Escribe un origen y un destino"
   - `searchEmptySubtitle`: "Te mostraremos las rutas más rápidas"
   - `searchUnderConstructionTitle`: "Buscador en construcción"
   - `searchUnderConstructionSubtitle`: "Mientras tanto, puedes sugerirnos rutas que falten"
   - `searchReportRouteAction`: "Sugerir ruta"

**Verificación:**
- `Grep -n "DIRECTA · 25 min · 1,30 €" lib/` ⇒ 0 hits
- Manual: escribir cualquier cosa en el buscador → ya no aparecen 3 resultados fake.

**Esfuerzo:** S · **Riesgo:** 🟢 · **Tipo:** fix

---

### F0.8 · Guard kReleaseMode en debug showcase

**Por qué:** `/debug/showcase` accesible en release; easter egg en `profile_about_section.dart` lo abre con 5 taps.

**Archivos:**
- `lib/core/router/app_router.dart:391` (ruta `/debug/showcase`)
- `lib/features/home/widgets/profile_about_section.dart:166-171` (easter egg)

**Acción:**
1. En `app_router.dart`:
   ```dart
   GoRoute(
     path: '/debug/showcase',
     builder: (ctx, state) {
       if (kReleaseMode) {
         return const NotFoundScreen();
       }
       return const ComponentShowcaseScreen();
     },
   ),
   ```
   Añade `import 'package:flutter/foundation.dart';` arriba.
2. En `profile_about_section.dart:166-171`:
   ```dart
   onTap: kReleaseMode ? null : () { _aboutTapCount++; ... }
   ```

**Verificación:**
- `Grep -n "showcase" lib/core/router/app_router.dart | grep -i release` ⇒ 1 hit (el guard)
- En release: navegar a `/debug/showcase` muestra NotFound.

**Esfuerzo:** S · **Riesgo:** 🟢 · **Tipo:** fix

---

### F0.9 · Persistir hasSeenOnboarding

**Por qué:** `splash_screen.dart:73` siempre redirige a `/onboarding` → cada cold start lo vuelve a mostrar.

**Archivo:** `lib/features/splash/splash_screen.dart:73`

**Acción:**
1. Usa la box Hive `userPreferences` (existente):
   ```dart
   final prefs = ref.read(hiveBoxProvider('userPreferences')).requireValue;
   final seen = prefs.get('hasSeenOnboarding', defaultValue: false) as bool;
   if (!seen) {
     context.go('/onboarding');
   } else if (session != null) {
     context.go('/home');
   } else {
     context.go('/auth/signin');
   }
   ```
2. En `onboarding_screen.dart`, cuando el usuario pulsa "Empezar":
   ```dart
   final prefs = ref.read(hiveBoxProvider('userPreferences')).requireValue;
   await prefs.put('hasSeenOnboarding', true);
   if (mounted) context.go('/auth/signin');
   ```

**Verificación:**
- Test manual: completar onboarding → matar app → relanzar → no muestra onboarding.
- `Grep -n "hasSeenOnboarding" lib/` ⇒ 2 hits (splash + onboarding).

**Esfuerzo:** S · **Riesgo:** 🟢 · **Tipo:** fix

---

### F0.10 · Verificación final Fase 0

**Acción:**
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter build apk --debug
./tool/verify_state.sh > /tmp/estado.md && cat /tmp/estado.md
```

**Criterio de aceptación:**
- `flutter analyze`: 0 issues
- `flutter test`: 304+ passed, 0 failed
- APK debug: compila
- `verify_state.sh`: output coherente con cifras reales
- Demo manual en emulador: search no muestra fakes, route_detail botón añadir funciona, driver_panel muestra tu nombre, onboarding solo primera vez

**Commit:**
```bash
git checkout -b chore/fase-0-pre-defensa
git add -A
git commit -m "chore(fase-0): pre-defensa TFG fixes — bug onPressed, hardcodes, verify_state.sh"
```

**Esfuerzo total Fase 0:** ≈3-4 horas · **Estado posterior:** TFG 7.5/10 · Producción 4.0/10 (sin cambios) · Media 5.9/10

---

## FASE 1 — HARDENING TFG (≈1 semana)

**Objetivo:** TFG 7.5 → 8.5. Reconciliar documentación con código, corregir A11Y verificable estáticamente, automatizar verificaciones.

### F1.1 · Reconciliar cifras de tests en TODOS los docs

**Por qué:** 5 cifras distintas (175, 201, 245, 292, 304) entre docs. La real es 304+1.

**Archivos a tocar:**
- `README.md` (líneas 52, 120)
- `AGENTS.md:27`
- `docs/MEGA_PLAN_REFINAMIENTO.md:7`
- `docs/PENDIENTE_PARA_CERRAR.md:13`
- `docs/PENDIENTES.md:31`
- `multiagent/state/project.json`
- `docs/tfg/01_analisis_contexto.md` (citas a tests)
- `docs/tfg/02_diseno_proyecto.md`
- `docs/tfg/04_desarrollo_implementacion.md` (tabla §4.1)
- `docs/tfg/05_evaluacion_documentacion.md` (referencias a 148→175)
- `docs/tfg/08_presentacion.md`

**Acción (en cada uno):**
1. Buscar cualquier cifra "X tests" o "X/X" con `Grep`.
2. Sustituir por `304 + 1 skipped` o `305 totales`.
3. Sustituir cobertura `~26%`, `25,5%`, `24,30%` por **24,77 %**.
4. Sustituir cifra "13 migraciones" por **15** o explicar "13 originales + 2 nuevas en 014/015".
5. Sustituir cifra "20 features" o "25 features" por **27**.
6. Sustituir cifra "9 boxes" en ADR-003 por **16** (ver F1.2).
7. Sustituir commit `3a31fb3` en 8 docs TFG por **`1c77f1f`** o quitar el ancla.

**Automatización opcional:** crea `tool/sync_docs.sh`:
```bash
#!/usr/bin/env bash
TESTS="304 + 1 skipped"
COVERAGE="24,77 %"
MIGRATIONS=15
FEATURES=27
BOXES=16
HEAD_REF=$(git rev-parse --short HEAD)

# Patrón find-replace masivo (cuidado con falsos positivos)
sed -i "s|\\b175/175\\b|$TESTS|g" README.md AGENTS.md docs/MEGA_PLAN_REFINAMIENTO.md
sed -i "s|\\b201/201\\b|$TESTS|g" README.md
# etc.
```

**Verificación:**
- `Grep -rn "175/175\|201/201\|245/245\|292/292" docs/ README.md AGENTS.md` ⇒ 0 hits.
- `Grep -rn "13 migraciones\|9 cajas\|~20 features" docs/` ⇒ 0 hits.

**Esfuerzo:** M · **Riesgo:** 🟢 · **Tipo:** doc

---

### F1.2 · Sincronizar ADR-003 (Hive) y ADR-004 (Supabase)

**Por qué:** ADR-003 dice "9 cajas activas" → realidad 16. ADR-004 dice "13 migraciones" → 15.

**Acción:**

**`docs/adr/003-hive.md`:**
1. Reescribe la sección "Consequences" con la lista real de 16 boxes:
   ```markdown
   ### Cajas activas (16)
   - operators, routes, stops, schedules — datos GTFS
   - incidents, routeFeedback, routeSuggestions, featureRequests — UGC
   - notifications, userPreferences, userFavorites, offlineRegions — usuario
   - pendingActions, deadLetterActions — sync queue
   - authSessionMeta, editorDrafts — runtime state
   ```
2. Reconcilia con `lib/data/cache/hive_init.dart:71-92` con un `grep` count.
3. Añade nota: "Verificable con `grep -c 'openBox\|openLazyBox' lib/data/cache/hive_init.dart` = 16".

**`docs/adr/004-supabase.md`:**
1. Reescribe lista de migraciones (15 con colisiones).
2. Lista los 12 repositorios SWR + 4 repositorios sin SWR (auth, analytics, privacy_consent, nfc).
3. Documenta las dos Edge Functions locales (`import_gtfs`, `send_notification`) — añadir nota: "estado despliegue verificable con `mcp__supabase__list_edge_functions`".

**Verificación:**
- `Grep "9 cajas\|9 boxes" docs/adr/003-hive.md` ⇒ 0 hits.
- `Grep "13 migraciones" docs/adr/004-supabase.md` ⇒ 0 hits.

**Esfuerzo:** S · **Riesgo:** 🟢 · **Tipo:** doc

---

### F1.3 · Regenerar CONTRAST_MATRIX y arreglar `textLo`

**Por qué:** el doc miente — cita colores que no existen en `transit_colors.dart`. Y los colores reales fallan AA.

**Acción A — script reproducible:**

Crea `tool/contrast_check.dart`:
```dart
import 'dart:io';
import 'dart:math' as math;
import 'package:transitly/core/theme/transit_colors.dart';

double _luminance(int hex) {
  double channel(int v) {
    final c = v / 255.0;
    return c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  }
  final r = channel((hex >> 16) & 0xFF);
  final g = channel((hex >> 8) & 0xFF);
  final b = channel(hex & 0xFF);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double ratio(int fg, int bg) {
  final lFg = _luminance(fg);
  final lBg = _luminance(bg);
  final hi = math.max(lFg, lBg);
  final lo = math.min(lFg, lBg);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  final pairs = {
    'dark.textHi/bgRoot': [0xF0F0FA, 0x08081A],
    'dark.textMid/bgRoot': [0x8888A8, 0x08081A],
    'dark.textLo/bgRoot': [0x4A4A68, 0x08081A], // FALLA
    'light.textHi/bgRoot': [0x111118, 0xF4F4FB],
    'light.textLo/bgRoot': [0x8888A0, 0xF4F4FB], // FALLA
  };
  for (final entry in pairs.entries) {
    final r = ratio(entry.value[0], entry.value[1]);
    final aa = r >= 4.5 ? 'PASS' : (r >= 3.0 ? 'AA-large' : 'FAIL');
    stdout.writeln('${entry.key.padRight(30)} ${r.toStringAsFixed(2)}:1  $aa');
  }
}
```

**Acción B — fix de colores:**
1. En `lib/core/theme/transit_colors.dart:111`:
   ```dart
   // ANTES: static const Color textLo = Color(0xFF4A4A68);
   static const Color textLo = Color(0xFF7A7A98);  // ≈4.6:1 sobre #08081A
   ```
2. En `lib/core/theme/transit_colors.dart:164`:
   ```dart
   // ANTES: static const Color textLo = Color(0xFF8888A0);
   static const Color textLo = Color(0xFF6C6C84);  // ≈4.6:1 sobre #F4F4FB
   ```
3. Si el cambio produce regresiones visuales (texto deja de "desaparecer" donde debería), considera renombrar el actual `textLo` a `textDecorative` y crear `textLo` con el valor correcto.

**Acción C — regenerar el doc:**
1. Ejecuta `dart run tool/contrast_check.dart > docs/CONTRAST_MATRIX.md` (con un header que añadas).
2. Header sugerido:
   ```markdown
   # Matriz de contraste WCAG 2.2
   > Autogenerado por `dart run tool/contrast_check.dart` desde `lib/core/theme/transit_colors.dart`.
   > Re-ejecutar tras cualquier cambio de paleta.
   > Último regen: $(date +%Y-%m-%d)
   ```

**Verificación:**
- `dart run tool/contrast_check.dart` muestra todos los pares PASS o AA-large (ningún FAIL para texto normal).
- `Grep "5B5890\|9B97C2" docs/CONTRAST_MATRIX.md` ⇒ 0 hits (colores fake antiguos eliminados).
- Test widget de contrast en `test/core/theme/contrast_test.dart` que falla si algún par baja de 4.5:1.

**Esfuerzo:** M · **Riesgo:** 🟡 (puede romper apariencia visual) · **Tipo:** fix + doc

---

### F1.4 · Añadir Semantics/tooltip a 26 IconButton y NotificationBell

**Por qué:** 0 usos de `semanticLabel`/`semanticsLabel` en `lib/`. Lectores de pantalla quedan ciegos.

**Acción A — wrapper helper:**
Crea `lib/shared/widgets/transit_icon_button.dart`:
```dart
import 'package:flutter/material.dart';

class TransitIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;  // semantics label + tooltip
  final double size;

  const TransitIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tooltip,
      button: true,
      enabled: onPressed != null,
      child: Tooltip(
        message: tooltip,
        child: SizedBox(
          width: size,
          height: size,
          child: IconButton(
            icon: Icon(icon),
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}
```

**Acción B — sustituir IconButton sin tooltip:**

Búscalos:
```bash
grep -rn "IconButton(" lib/features/ lib/shared/ | grep -v tooltip
```

Para cada uno, sustituye por `TransitIconButton(...)` con `tooltip: l10n.<key>`. Crea las claves en ARB:
- `lib/features/operator_admin/invitation_codes_screen.dart:190` → `tooltip: l10n.generateInvitationCode`
- `lib/features/operator_admin/drivers_screen.dart:135` → `tooltip: l10n.revokeDriver`
- `lib/features/city_picker/city_picker_screen.dart:35` → `tooltip: l10n.close`
- `lib/features/route_detail/widgets/route_detail_feedback_section.dart:40,53` → `tooltip: l10n.editFeedback`, `tooltip: l10n.deleteFeedback`
- … (continuar con los ~26 restantes)

**Acción C — NotificationBell y DriverFab:**
1. `lib/features/home/home_shell.dart:179-222` (_NotificationBell):
   ```dart
   Semantics(
     label: l10n.notificationsTooltip,
     value: unreadCount > 0 ? l10n.notificationsUnreadCount(unreadCount) : null,
     button: true,
     child: InkWell(
       onTap: ...,
       child: SizedBox(
         width: 48, height: 48,  // antes 44×44
         child: ...
       ),
     ),
   ),
   ```
2. `lib/features/home/home_shell.dart:127-158` (_DriverFab):
   ```dart
   FloatingActionButton(
     tooltip: l10n.driverPanelActivate,
     ...
   )
   ```

**Verificación:**
- `Grep -c "tooltip:\|semanticLabel:\|Semantics(" lib/` ⇒ ≥40 hits (antes era ~9 tooltip).
- Test widget A11Y: `meetsGuideline(androidTapTargetGuideline)` para los botones afectados.

**Esfuerzo:** M · **Riesgo:** 🟢 · **Tipo:** fix

---

### F1.5 · `if (!mounted) return;` en 24 sitios

**Por qué:** `setState` post-`await` sin guard puede lanzar `setState() called after dispose()`.

**Archivos identificados (24 sitios):**
1. `lib/features/auth/recover_password_screen.dart:49-50`
2. `lib/features/auth/magic_link_screen.dart:48-49`
3. `lib/features/auth/email_verify_pending_screen.dart:34-35`
4. `lib/features/admin/admin_operators_screen.dart:48-50`
5. `lib/features/offline/widgets/region_download_sheet.dart:165-167`
6. `lib/features/auth/activate_driver_screen.dart:74-83`
7. Resto: usa `Grep -rn "await.*\n.*setState" lib/features/` para enumerar.

**Acción tipo:**
```dart
// ANTES
final result = await someAsyncCall();
setState(() => _state = result);

// DESPUÉS
final result = await someAsyncCall();
if (!mounted) return;
setState(() => _state = result);
```

**Patrón regex de búsqueda:**
```bash
grep -B 1 "setState(" lib/features/**/*.dart | grep -A 1 "await"
```

**Verificación:**
- Para cada uno de los 24 sitios: el `if (!mounted) return;` debe ir entre el `await` y el `setState`.
- `flutter test`: ningún test debería fallar tras la introducción.
- Idealmente: añadir lint `use_build_context_synchronously: error` en `analysis_options.yaml`.

**Esfuerzo:** M · **Riesgo:** 🟢 · **Tipo:** fix

---

### F1.6 · Migrar ~120 strings hardcoded ES a ARB

**Por qué:** la app no es realmente trilingüe; tribunal con dispositivo en inglés/árabe ve español por todas partes.

**Estrategia:**
1. **Audita los strings**:
   ```bash
   grep -rn "'[A-ZÁÉÍÓÚÑ][A-ZÁÉÍÓÚÑa-zñ ]*[A-ZÁÉÍÓÚÑa-zñ]'" lib/features/ \
     | grep -v "l10n\.\|app_es\.\|app_en\.\|app_ar\." \
     | grep -v "// " > /tmp/hardcoded_strings.txt
   wc -l /tmp/hardcoded_strings.txt  # debería caer de ~120 a <10
   ```
2. **Prioridad por feature** (mayor visibilidad):
   - Auth: 8 strings (banners de error, hints)
   - Home/route_detail/stop_detail: ~30
   - Driver (panel, dashboard, active_route): ~25
   - Incidents, feedback, suggestions, profile: ~40
   - Admin, operator_admin: ~10
   - Showcase, debug: omitibles (no producción)

3. **Por cada string**:
   - Añade clave a `lib/l10n/app_es.arb`:
     ```json
     "driverPanelTitle": "MODO CONDUCTOR",
     "@driverPanelTitle": {"description": "Header del panel del conductor"},
     ```
   - Traduce a `app_en.arb` y `app_ar.arb`.
   - Regenera: `flutter gen-l10n`.
   - Sustituye en código: `'MODO CONDUCTOR'` → `l10n.driverPanelTitle`.

**Bloques destacados a migrar:**
- `incidents/report_incident_sheet.dart` — etiquetas grid (No pasó/Retraso/Lleno/Desvío/Avería/Otro/Puntual/Amable/Limpio)
- `driver/driver_panel.dart` — todo el panel
- `driver/active_route_screen.dart` — toolbar + dialogs
- `driver/start_route_screen.dart` — selectores
- `feedback/feedback_screen.dart` — todo
- `suggestions/suggest_route_screen.dart` — formulario completo

**Verificación:**
- `tool/check_no_hardcoded.sh` (nuevo):
   ```bash
   #!/usr/bin/env bash
   HITS=$(grep -rn "'[A-ZÁÉÍÓÚÑ][A-Z ]\{4,\}'" lib/features/ lib/shared/ | grep -v "l10n\." | wc -l)
   echo "Hardcoded ES strings: $HITS"
   if [ "$HITS" -gt 5 ]; then exit 1; fi
   ```
- En CI: `tool/check_no_hardcoded.sh` debe pasar.

**Esfuerzo:** L · **Riesgo:** 🟡 (errores i18n pueden no ser detectados por tests) · **Tipo:** fix

---

### F1.7 · Activar job semgrep CI bloqueante

**Por qué:** `.semgrep/rules.yaml` existe pero no se ejecuta en CI.

**Archivo:** `.github/workflows/ci.yml`

**Acción:**
Añade un job nuevo:
```yaml
  semgrep:
    name: Semgrep SAST
    runs-on: ubuntu-latest
    timeout-minutes: 10
    container:
      image: returntocorp/semgrep
    steps:
      - uses: actions/checkout@v4
      - run: semgrep ci --config=.semgrep/rules.yaml --error
```

Asegúrate de que `.semgrep/rules.yaml` tiene `severity: ERROR` en `no-hardcoded-es-strings`, `no-print-in-lib`, `no-hardcoded-supabase-url` (ya está).

**Verificación:**
- Push una rama de prueba con un `print('test')` en `lib/` → CI debe fallar en el job semgrep.
- Tras corregir: CI verde.

**Esfuerzo:** S · **Riesgo:** 🟢 · **Tipo:** ops

---

### F1.8 · Goldens reales con `matchesGoldenFile`

**Por qué:** `design_system_golden_test.dart` es render-only sin `matchesGoldenFile`. PRO-Snr-15 / PRO-QA-04 son falsos cierres.

**Acción:**
1. Reestructura el test:
   ```dart
   testWidgets('TransitButton primary light', (tester) async {
     await tester.pumpWidget(_wrap(
       const TransitButton.primary(label: 'Aceptar', onPressed: null),
       brightness: Brightness.light,
     ));
     await expectLater(
       find.byType(TransitButton),
       matchesGoldenFile('goldens/transit_button_primary_light.png'),
     );
   });
   ```
2. Repite para los 8 widgets declarados × 2 brillos = 16 goldens:
   - TransitButton (primary, secondary, danger)
   - TransitInput
   - TransitChip
   - GlassCard
   - StatusBadge
   - ReputationBadge
   - RouteCard
   - StopListItem
3. Genera goldens con `flutter test --update-goldens test/widget/design_system_golden_test.dart`.
4. Commitea `test/widget/goldens/*.png` (~16 PNGs, ~50-200 KB cada uno).
5. Añade a `.gitattributes`:
   ```
   *.png binary
   ```

**Verificación:**
- `Grep -c "matchesGoldenFile" test/` ⇒ ≥16 hits.
- CI corre goldens y falla si algún PNG no coincide (regresión visual).
- Idealmente: subir goldens también a Linux/macOS (anti-rendering-drift) con `flutter test --update-goldens` por OS.

**Esfuerzo:** M · **Riesgo:** 🟡 (goldens fallan en CI por diferencias OS) · **Tipo:** req

---

### F1.9 · Reescribir sección "Arquitectura" del manual técnico

**Por qué:** `06_manual_tecnico.md` cita "13 migraciones" y describe estructura desfasada.

**Archivo:** `docs/tfg/06_manual_tecnico.md`

**Acción:**
1. Reescribir la sección "4. Arquitectura" con cifras reales (auto desde `verify_state.sh`).
2. Insertar diagrama actualizado (Mermaid) con las 27 features.
3. Listar las 15 migraciones con propósito de cada una.
4. Listar las 16 cajas Hive con propósito.
5. Documentar las 4 capas (domain/local/remote/mock) con ejemplo concreto (operator dominio).
6. Eliminar referencia a `firebase_setup.dart` raíz (la ruta real es `lib/data/push/firebase_setup.dart`).

**Verificación:**
- Las cifras del manual coinciden con `verify_state.sh`.
- `Grep "13 migraciones\|9 cajas\|firebase_setup.dart" docs/tfg/06_manual_tecnico.md` (excluyendo `lib/data/push/`) ⇒ 0 hits.

**Esfuerzo:** M · **Riesgo:** 🟢 · **Tipo:** doc

---

### F1.10 · Pre-commit hook lefthook que regenera estado

**Por qué:** evitar que el drift documental vuelva.

**Archivo:** `lefthook.yml`

**Acción:**
Añade bloque:
```yaml
pre-commit:
  parallel: true
  commands:
    verify-state:
      run: |
        if git diff --cached --name-only | grep -q "lib/\|test/\|supabase/migrations/\|.github/workflows/"; then
          ./tool/verify_state.sh > /tmp/estado_new.md
          if ! diff -q /tmp/estado_new.md <(sed -n '/<!-- BEGIN ESTADO -->/,/<!-- END ESTADO -->/p' docs/00_MAESTRO.md) > /dev/null 2>&1; then
            echo "ERROR: docs/00_MAESTRO.md está desincronizado. Ejecuta tool/verify_state.sh y commitea."
            exit 1
          fi
        fi
```

**Verificación:**
- Cambia `lib/main.dart`, intenta commit sin regenerar maestro → hook falla.
- Tras regenerar: hook pasa.

**Esfuerzo:** S · **Riesgo:** 🟢 · **Tipo:** ops

---

### F1.11 · Verificación final Fase 1

**Acción:**
```bash
./tool/verify_state.sh
./tool/check_no_hardcoded.sh
dart run tool/contrast_check.dart
flutter analyze
flutter test
```

**Criterio:**
- 0 issues analyze
- 305+ tests
- 0 hardcoded ES strings (o ≤5 con justificación)
- Todos los pares de contraste PASS o AA-large
- Pre-commit hook bloquea drift

**Estado posterior:** TFG 8.5/10 · Producción 5.0/10 · Media 6.8/10

---

## FASE 2 — SQL + BACKEND SUPABASE (≈1 semana)

**Objetivo:** desbloquear migraciones corruptas, reactivar backend real, implementar GDPR.

### F2.1 · Reconciliar migración 014_audit_log.sql

**Por qué:** P0 absoluto. Duplica tabla de `001_init.sql:407` con esquema incompatible; policy referencia columna inexistente.

**Acción:**
1. Lee `supabase/migrations/014_audit_log.sql` íntegro.
2. **Decisión:** mantener el esquema de `001_init.sql:407` (`id UUID`) y eliminar la duplicación de `014`. Si `014` añade algo útil (índices, columnas), migrarlo como `016_audit_log_extras.sql`.
3. Renombrar el archivo:
   ```bash
   git mv supabase/migrations/014_audit_log.sql supabase/migrations/016_audit_log_extras.sql
   ```
4. Editar `016_audit_log_extras.sql`:
   - `CREATE TABLE` → `ALTER TABLE` añadiendo solo columnas/índices nuevos.
   - Policy `audit_log_select_admin`: cambiar `'admin' = ANY(roles)` por `role = 'admin'` (singular, según `001:130`).
5. Verificar `claim_invitation_code` en `005_functions.sql:64` que escribe en `target_kind`, `target_id`, `payload` — si esas columnas faltan, añadirlas en `016`.

**Verificación:**
- `psql ... -c "\d audit_log"` muestra columnas coherentes.
- Test SQL: ejecutar `claim_invitation_code('codigo_test')` en proyecto vacío y comprobar que escribe en `audit_log`.

**Esfuerzo:** M · **Riesgo:** 🔴 (rompe migraciones si hay backend con datos) · **Tipo:** fix

---

### F2.2 · Reconciliar migración 015_privacy_consents.sql

**Por qué:** P0. Define columna `consent_type` mientras código Dart usa `consent_kind`. Salva-vidas: `001:438` ya creó la tabla con `consent_kind` → `015` fallará con "table exists" pero el conflicto debe limpiarse.

**Acción:**
1. Lee `001_init.sql:435-440` para confirmar el esquema canónico.
2. **Decisión:** la tabla ya existe en `001`; `015` solo puede añadir columnas/índices o renombrar. Si solo intentaba `CREATE TABLE` duplicado, **borrar el archivo**:
   ```bash
   git rm supabase/migrations/015_privacy_consents.sql
   ```
3. Si añadía algo útil, mover a `017_privacy_consents_indices.sql` con `IF NOT EXISTS`.

**Verificación:**
- `Grep "consent_type" supabase/` ⇒ 0 hits (o solo en docs).
- `Grep "consent_kind" supabase/` ⇒ 1+ hits (canónico).

**Esfuerzo:** S · **Riesgo:** 🔴 · **Tipo:** fix

---

### F2.3 · Resolver colisiones de prefijo 007 y 014

**Por qué:** `007_invitation_helpers.sql` y `007_notification_triggers.sql` colisionan. `014_push_tokens.sql` también con `014_audit_log.sql`.

**Acción:**
1. Renumerar manteniendo orden lógico:
   ```bash
   git mv supabase/migrations/007_notification_triggers.sql supabase/migrations/008_notification_triggers.sql
   git mv supabase/migrations/014_push_tokens.sql supabase/migrations/015_push_tokens.sql
   # 014_audit_log ya se movió a 016 en F2.1
   # 015_privacy_consents ya se eliminó en F2.2
   git mv supabase/migrations/015_push_triggers.sql supabase/migrations/018_push_triggers.sql
   ```
2. Actualizar referencias internas a estos archivos en `docs/runbooks/migration_rollback.md`, `docs/adr/004-supabase.md`.

**Verificación:**
- `ls supabase/migrations/ | sort | uniq -c | grep "^ *2"` ⇒ vacío (no duplicados).
- Numeración consecutiva: 001, 002, 003, 004, 005, 006, 007, 008, 012, 013, 015, 016, 018 (faltan 009-011, 014, 017 — añadir nota en README).

**Esfuerzo:** S · **Riesgo:** 🟡 · **Tipo:** fix

---

### F2.4 · Reactivar/recrear proyecto Supabase + aplicar migraciones

**Por qué:** el proyecto remoto está pausado o vacío (timeout en SQL, 0 publishable keys).

**Acción:**
1. Entrar a `supabase.com/dashboard/project/mmzahxtiaurkgtmtehxk`.
2. Si está pausado: pulsar "Restore". Si está eliminado: crear nuevo proyecto, actualizar `--project-ref` en `supabase/config.toml` y en `.env`.
3. Crear publishable key (anon) en Settings → API.
4. Actualizar `.env` con la nueva key.
5. Aplicar migraciones:
   ```bash
   supabase link --project-ref <nuevo-ref>
   supabase db push
   ```
6. Verificar con MCP:
   ```bash
   # En claude:
   mcp__supabase__list_tables  # ≥30 tablas esperables
   mcp__supabase__list_migrations  # 13 archivos aplicados (tras F2.1-F2.3)
   mcp__supabase__get_advisors --type security  # debería ser []
   ```

**Verificación:**
- `flutter run` arranca sin error de "missing anon key".
- Signup en la app crea fila en `auth.users` y `profiles`.

**Esfuerzo:** M · **Riesgo:** 🟡 (acción externa, depende de cuenta Supabase) · **Tipo:** ops

---

### F2.5 · Desplegar Edge Functions con secrets

**Por qué:** 0 edge functions desplegadas; `SENTRY_EDGE_FUNCTIONS.md` describe instrumentación inexistente.

**Acción:**
1. Subir secrets:
   ```bash
   supabase secrets set FCM_SERVICE_ACCOUNT_JSON="$(cat fcm-sa.json)"
   supabase secrets set SENTRY_DSN="https://...@sentry.io/..."
   supabase secrets set ALLOWED_ORIGINS="https://transitly.app,http://localhost:3000"
   ```
2. Desplegar:
   ```bash
   supabase functions deploy send_notification --verify-jwt
   supabase functions deploy import_gtfs --no-verify-jwt
   ```
3. Probar:
   ```bash
   curl -X POST https://<ref>.supabase.co/functions/v1/send_notification \
     -H "Authorization: Bearer <anon>" \
     -H "Content-Type: application/json" \
     -d '{"user_id":"...", "title":"Test", "body":"Test"}'
   ```

**Verificación:**
- `mcp__supabase__list_edge_functions` ⇒ 2 funciones.
- Logs visibles en `mcp__supabase__get_logs --service edge-function`.

**Esfuerzo:** M · **Riesgo:** 🟡 · **Tipo:** ops

---

### F2.6 · Implementar age verification (Art. 8 GDPR)

**Por qué:** `signup_screen.dart:1-175` no tiene DOB ni validación. `AGE_VERIFICATION.md` la documenta pero no existe.

**Acción:**
1. Crea migración `019_profiles_dob.sql`:
   ```sql
   ALTER TABLE profiles ADD COLUMN dob date;
   ALTER TABLE profiles ADD CONSTRAINT profiles_dob_min_age
     CHECK (dob IS NULL OR dob <= current_date - interval '16 years');
   ```
2. `supabase db push`.
3. En `signup_screen.dart` añade un campo de fecha:
   ```dart
   DateTime? _dob;
   TextButton.icon(
     icon: const Icon(Icons.calendar_today),
     label: Text(_dob == null ? l10n.signupDobPlaceholder : DateFormat.yMd().format(_dob!)),
     onPressed: () async {
       final picked = await showDatePicker(
         context: context,
         initialDate: DateTime(2008),
         firstDate: DateTime(1900),
         lastDate: DateTime.now(),
       );
       if (picked != null) setState(() => _dob = picked);
     },
   ),
   ```
4. Antes de enviar el signup:
   ```dart
   if (_dob == null) {
     _showError(l10n.signupDobRequired);
     return;
   }
   final age = DateTime.now().difference(_dob!).inDays ~/ 365;
   if (age < 16) {
     _showError(l10n.signupAgeBelowMinimum);
     return;
   }
   ```
5. Tras crear cuenta, actualizar profile:
   ```dart
   await Supabase.instance.client.from('profiles').update({'dob': _dob!.toIso8601String().substring(0, 10)}).eq('id', user.id);
   ```

**Verificación:**
- Signup con DOB <16 años → bloqueado con error claro.
- Signup con DOB ≥16 → cuenta creada y `dob` persistida.
- `SELECT * FROM profiles WHERE dob IS NULL;` ⇒ 0 nuevas filas tras esta fase.

**Esfuerzo:** M · **Riesgo:** 🟡 · **Tipo:** req

---

### F2.7 · Edge Function `delete_user` (Right to be Forgotten)

**Por qué:** `data_deletion_requests` se acumulan sin worker. Art. 17 GDPR.

**Acción:**
1. Crea `supabase/functions/delete_user/index.ts`:
   ```typescript
   import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

   Deno.serve(async (req) => {
     const { userId } = await req.json();
     const supabase = createClient(
       Deno.env.get("SUPABASE_URL")!,
       Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
     );

     // DELETE en tablas con FK a usuario (orden inverso a creación)
     const tables = ['user_favorites', 'user_cards', 'route_feedback',
                     'incident_reports', 'feedback_messages', 'route_suggestions',
                     'votes', 'data_exports', 'privacy_consents', 'device_tokens',
                     'profiles'];
     for (const t of tables) {
       await supabase.from(t).delete().eq('user_id', userId);
     }

     // auth.admin.deleteUser
     const { error } = await supabase.auth.admin.deleteUser(userId);
     if (error) throw error;

     // Marcar request como ejecutada
     await supabase.from('data_deletion_requests')
       .update({ executed_at: new Date().toISOString() })
       .eq('user_id', userId);

     return new Response(JSON.stringify({ ok: true }), { status: 200 });
   });
   ```
2. Desplegar: `supabase functions deploy delete_user --verify-jwt`.
3. Programar pg_cron:
   ```sql
   SELECT cron.schedule('delete_user_worker', '0 3 * * *', $$
     SELECT net.http_post(
       url := 'https://<ref>.supabase.co/functions/v1/delete_user',
       headers := jsonb_build_object('Authorization', 'Bearer <service_role>'),
       body := jsonb_build_object('userId', user_id)
     )
     FROM data_deletion_requests
     WHERE executed_at IS NULL AND scheduled_at <= now();
   $$);
   ```

**Verificación:**
- En la app: solicitar borrado → 30 días después (o cambiar `scheduled_at`) el cron ejecuta → cuenta + datos eliminados.
- Logs cron visibles en `cron.job_run_details`.

**Esfuerzo:** L · **Riesgo:** 🔴 (borrado destructivo, validar en proyecto staging) · **Tipo:** req

---

### F2.8 · purge_old_* (Data Retention)

**Por qué:** `DATA_RETENTION.md:45-72` documenta funciones que no existen.

**Acción:**
1. Crea `020_data_retention_functions.sql`:
   ```sql
   CREATE OR REPLACE FUNCTION purge_old_bus_positions() RETURNS void AS $$
   BEGIN
     DELETE FROM bus_positions WHERE recorded_at < now() - interval '7 days';
   END;
   $$ LANGUAGE plpgsql SECURITY DEFINER;

   CREATE OR REPLACE FUNCTION purge_old_notifications() RETURNS void AS $$
   BEGIN
     DELETE FROM notifications WHERE created_at < now() - interval '90 days' AND read_at IS NOT NULL;
   END;
   $$ LANGUAGE plpgsql SECURITY DEFINER;

   SELECT cron.schedule('purge_bus_positions', '0 2 * * *', 'SELECT purge_old_bus_positions();');
   SELECT cron.schedule('purge_notifications', '0 3 * * 0', 'SELECT purge_old_notifications();');
   ```

**Verificación:**
- `SELECT * FROM cron.job;` muestra los 2 jobs.
- Tras 1 día: `SELECT count(*) FROM bus_positions WHERE recorded_at < now() - interval '7 days';` ⇒ 0.

**Esfuerzo:** S · **Riesgo:** 🟡 · **Tipo:** req

---

### F2.9 · Tests Deno reales para edge functions

**Por qué:** `PRO-QA-21` falso cierre. `EDGE_FUNCTION_TESTS.md` describe sin existir.

**Acción:**
1. Crea `supabase/functions/send_notification/test.ts`:
   ```typescript
   import { assertEquals, assertExists } from "https://deno.land/std/assert/mod.ts";

   Deno.test("send_notification rejects empty userId", async () => {
     const res = await fetch("http://localhost:54321/functions/v1/send_notification", {
       method: "POST",
       headers: { "Content-Type": "application/json" },
       body: JSON.stringify({}),
     });
     assertEquals(res.status, 400);
   });

   Deno.test("send_notification accepts valid payload", async () => {
     // ... con mock FCM
   });
   ```
2. Similar para `import_gtfs/test.ts` y `delete_user/test.ts`.
3. Local: `supabase functions serve` + en otro shell `deno test --allow-net supabase/functions/*/test.ts`.
4. CI: añade job:
   ```yaml
   edge-functions-test:
     runs-on: ubuntu-latest
     steps:
       - uses: actions/checkout@v4
       - uses: denoland/setup-deno@v1
       - run: deno test --allow-net --allow-env supabase/functions/*/test.ts
   ```

**Verificación:**
- `ls supabase/functions/*/test.ts` ⇒ 3 archivos.
- CI job verde.

**Esfuerzo:** L · **Riesgo:** 🟡 · **Tipo:** req

---

### F2.10 · Worker para data_exports (Art. 20 Portabilidad)

**Acción:**
1. Crea `supabase/functions/generate_data_export/index.ts` que:
   - Lee `data_exports` con `executed_at IS NULL`.
   - Por cada user_id: query todas las tablas → genera JSON → sube a Storage bucket `exports/` con expiración 7 días.
   - Actualiza `data_exports.executed_at` y `download_url`.
   - Envía notificación push o email con link.
2. Programa cron diario.

**Verificación:**
- Solicitar exportación en app → tras N minutos, descargar ZIP/JSON con tus datos.

**Esfuerzo:** L · **Riesgo:** 🟡 · **Tipo:** req

---

### F2.11 · Verificación final Fase 2

**Acción:**
```bash
mcp__supabase__list_tables                # ≥30 tablas
mcp__supabase__list_migrations            # 14 archivos
mcp__supabase__get_advisors --security    # []
mcp__supabase__list_edge_functions        # ≥4 (send_notification, import_gtfs, delete_user, generate_data_export)
flutter test                              # 305+ verde
deno test supabase/functions/*/test.ts    # verde
```

**Estado posterior:** TFG 9.0/10 · Producción 6.5/10 · Media 7.5/10

---

## FASE 3 — PUSH + RELEASE (≈1 semana)

**Objetivo:** Push notifications end-to-end y APK firmado release-ready. Producción 6.5 → 8.0.

### F3.1 · flutterfire configure → firebase_options.dart

**Estado (2026-05-23):** PENDIENTE. El archivo `lib/firebase_options.dart` no existe. Sin esto, push notifications no funcionan en device real (en demo TFG sobre emulador, FCM no se demuestra). Bloqueador release pero no TFG.

**Acción:**
```bash
dart pub global activate flutterfire_cli
flutterfire configure \
  --project=transitly-prod \
  --platforms=android,ios,web \
  --android-package-name=app.transitly \
  --ios-bundle-id=app.transitly
```

Esto genera `lib/firebase_options.dart` con `DefaultFirebaseOptions.currentPlatform`.

**Verificación:**
- `ls lib/firebase_options.dart` existe.
- Contenido con `apiKey`, `appId`, `messagingSenderId`, `projectId`.

**Esfuerzo:** S · **Riesgo:** 🟢 · **Tipo:** ops

---

### F3.2 · Bajar google-services.json + GoogleService-Info.plist

**Acción:**
1. Desde Firebase Console → Project Settings → Your apps → Android → "google-services.json" → descarga.
2. Mueve a `android/app/google-services.json`.
3. Repite para iOS → mueve a `ios/Runner/GoogleService-Info.plist`.
4. Añade a `.gitignore` (los archivos son secretos):
   ```
   android/app/google-services.json
   ios/Runner/GoogleService-Info.plist
   ```
5. Sube ambos a GitHub Secrets como base64:
   ```bash
   base64 -w 0 android/app/google-services.json | gh secret set GOOGLE_SERVICES_JSON
   base64 -w 0 ios/Runner/GoogleService-Info.plist | gh secret set GOOGLE_SERVICES_INFO_PLIST
   ```

**Verificación:**
- `ls android/app/google-services.json` y `ls ios/Runner/GoogleService-Info.plist` existen localmente.
- En CI: ambos secrets configurados.

**Esfuerzo:** S · **Riesgo:** 🟢 · **Tipo:** ops

---

### F3.3 · Plugin Google Services en Gradle

**Archivo:** `android/app/build.gradle.kts` y `android/build.gradle.kts`

**Acción:**
1. `android/settings.gradle.kts` (raíz):
   ```kotlin
   id("com.google.gms.google-services") version "4.4.2" apply false
   ```
2. `android/app/build.gradle.kts`:
   ```kotlin
   plugins {
       id("com.android.application")
       id("kotlin-android")
       id("com.google.gms.google-services")  // ← añadir
       id("dev.flutter.flutter-gradle-plugin")
   }
   ```

**Verificación:**
- `flutter build apk --debug` compila sin error.
- En logs build: "google-services" plugin aplicado.

**Esfuerzo:** S · **Riesgo:** 🟡 · **Tipo:** ops

---

### F3.4 · Declarar canal FCM en Manifest

**Archivo:** `android/app/src/main/AndroidManifest.xml`

**Acción:**
Dentro de `<application>`:
```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="transitly_push" />
<meta-data
    android:name="com.google.firebase.messaging.default_notification_icon"
    android:resource="@drawable/ic_notification" />
<meta-data
    android:name="com.google.firebase.messaging.default_notification_color"
    android:resource="@color/notification_color" />

<service
    android:name=".TransitlyMessagingService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>
```

Crea `android/app/src/main/res/values/colors.xml`:
```xml
<resources>
    <color name="notification_color">#977DDF</color>
</resources>
```

Y `android/app/src/main/res/drawable/ic_notification.xml` (vector blanco transparente para evitar Android 5+ silhouette).

**Verificación:**
- `Grep "default_notification_channel_id" android/` ⇒ 1 hit.
- En el código: `PushService` crea el canal con id `transitly_push` con `AndroidNotificationChannel`.

**Esfuerzo:** S · **Riesgo:** 🟢 · **Tipo:** ops

---

### F3.5 · iOS APNs + Entitlements

**Archivos:**
- `ios/Runner/Runner.entitlements` (nuevo)
- `ios/Runner/Info.plist`

**Acción:**
1. Crea `ios/Runner/Runner.entitlements`:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>aps-environment</key>
       <string>production</string>
       <key>com.apple.developer.usernotifications.communication</key>
       <true/>
   </dict>
   </plist>
   ```
2. En Xcode (Runner.xcodeproj):
   - Capabilities → Push Notifications: ON
   - Capabilities → Background Modes: Remote notifications ON
3. En `Info.plist` añade dentro de `<dict>`:
   ```xml
   <key>UIBackgroundModes</key>
   <array>
       <string>fetch</string>
       <string>remote-notification</string>
   </array>
   ```

**Verificación:**
- `cat ios/Runner/Runner.entitlements | grep aps-environment` muestra valor.
- `Grep "UIBackgroundModes" ios/Runner/Info.plist` ⇒ 1 hit.

**Esfuerzo:** S · **Riesgo:** 🟢 · **Tipo:** ops

---

### F3.6 · Instanciar PushService completamente

**Archivo:** `lib/main.dart` y `lib/data/push/push_service.dart`

**Acción:**
1. En `main.dart` tras `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`:
   ```dart
   await PushService.instance.bootstrap();
   ```
2. En `PushService.bootstrap()`:
   ```dart
   Future<void> bootstrap() async {
     // Permiso (Android 13+ y iOS)
     final settings = await _messaging.requestPermission(
       alert: true, badge: true, sound: true,
     );
     if (settings.authorizationStatus == AuthorizationStatus.denied) return;

     // Canal Android
     await _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
       ?.createNotificationChannel(const AndroidNotificationChannel(
         'transitly_push', 'Transitly',
         description: 'Avisos de rutas, incidencias y horarios',
         importance: Importance.high,
       ));

     // Token
     final token = await _messaging.getToken();
     if (token != null) await _registerToken(token);
     _messaging.onTokenRefresh.listen(_registerToken);

     // Foreground
     FirebaseMessaging.onMessage.listen(_onForeground);

     // Background tap → app abre
     FirebaseMessaging.onMessageOpenedApp.listen(_onTap);

     // App killed tap → app abre
     final initial = await _messaging.getInitialMessage();
     if (initial != null) _onTap(initial);
   }

   void _onTap(RemoteMessage message) {
     final deeplink = message.data['deeplink'];
     if (deeplink != null) {
       _navigationKey.currentState?.pushNamed(deeplink);
     }
   }
   ```
3. Background handler en `main.dart` ANTES de `runApp`:
   ```dart
   @pragma('vm:entry-point')
   Future<void> _onBackgroundMessage(RemoteMessage message) async {
     // Procesamiento mínimo (no UI)
   }
   void main() async {
     // ...
     FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);
     runApp(...);
   }
   ```

**Verificación:**
- Test E2E: enviar push desde Firebase Console → recibir en device en foreground, background, killed.
- Tap en notif con `data.deeplink="/route/L1"` → app navega a esa ruta.

**Esfuerzo:** M · **Riesgo:** 🟡 · **Tipo:** req

---

### F3.7 · Revocar token en signOut

**Archivo:** `lib/data/auth/auth_repository_supabase.dart`

**Acción:**
```dart
@override
Future<void> signOut() async {
  final uid = _client.auth.currentUser?.id;
  if (uid != null) {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _client.from('device_tokens').delete().eq('token', token);
    }
    await FirebaseMessaging.instance.deleteToken();
  }
  await _client.auth.signOut();
}
```

**Verificación:**
- Tras signOut → token borrado de `device_tokens`.
- Tras login con otra cuenta → token nuevo registrado.

**Esfuerzo:** S · **Riesgo:** 🟢 · **Tipo:** fix

---

### F3.8 · Keystore Android real + signingConfig

**Acción:**
1. Genera keystore:
   ```bash
   keytool -genkey -v -keystore android/app/release.keystore \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias transitly
   # password: <fuerte, guardar en password manager>
   ```
2. Crea `android/key.properties` (en `.gitignore`):
   ```
   storePassword=...
   keyPassword=...
   keyAlias=transitly
   storeFile=release.keystore
   ```
3. Edita `android/app/build.gradle.kts`:
   ```kotlin
   import java.util.Properties
   import java.io.FileInputStream

   val keystoreProperties = Properties()
   val keystorePropertiesFile = rootProject.file("key.properties")
   if (keystorePropertiesFile.exists()) {
       keystoreProperties.load(FileInputStream(keystorePropertiesFile))
   }

   android {
       signingConfigs {
           create("release") {
               keyAlias = keystoreProperties["keyAlias"] as String
               keyPassword = keystoreProperties["keyPassword"] as String
               storeFile = file(keystoreProperties["storeFile"] as String)
               storePassword = keystoreProperties["storePassword"] as String
           }
       }
       buildTypes {
           release {
               signingConfig = signingConfigs.getByName("release")
           }
       }
   }
   ```
4. Sube `release.keystore` (base64) y `key.properties` (base64) a GitHub Secrets como `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEY_PROPERTIES_BASE64`.

**Verificación:**
- `flutter build apk --release` produce APK firmado.
- `jarsigner -verify -verbose build/app/outputs/flutter-apk/app-release.apk` ⇒ "jar verified".

**Esfuerzo:** M · **Riesgo:** 🔴 (perder keystore = no poder actualizar app en Play Store nunca; guardar en múltiples sitios) · **Tipo:** ops

---

### F3.9 · CI build AAB + jarsigner -verify

**Archivo:** `.github/workflows/ci.yml`

**Acción:**
Sustituye el job `build-android` por:
```yaml
build-android:
  name: Build Android AAB
  runs-on: ubuntu-latest
  timeout-minutes: 30
  steps:
    - uses: actions/checkout@v4
    - uses: subosito/flutter-action@v2
    - run: |
        echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > android/app/release.keystore
        echo "${{ secrets.ANDROID_KEY_PROPERTIES_BASE64 }}" | base64 -d > android/key.properties
        echo "${{ secrets.GOOGLE_SERVICES_JSON_BASE64 }}" | base64 -d > android/app/google-services.json
    - run: flutter pub get
    - run: flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
    - run: |
        # Verificar firma
        jarsigner -verify -verbose build/app/outputs/bundle/release/app-release.aab
    - run: |
        # Bundle size check (50 MB max para AAB)
        AAB_SIZE=$(stat -c%s build/app/outputs/bundle/release/app-release.aab)
        echo "AAB size: $AAB_SIZE"
        if [ "$AAB_SIZE" -gt 52428800 ]; then exit 1; fi
    - uses: actions/upload-artifact@v4
      with:
        name: app-release-aab
        path: build/app/outputs/bundle/release/app-release.aab
```

**Verificación:**
- Push a `main` → CI produce AAB firmado + verified.

**Esfuerzo:** M · **Riesgo:** 🟡 · **Tipo:** ops

---

### F3.10 · ToS y Privacy Policy URLs reales

**Acción:**
1. Crea `assets/legal/terms_es.md`, `terms_en.md`, `terms_ar.md` con contenido legal real (puedes basarlo en plantillas como Termly o reescribir).
2. Crea `assets/legal/privacy_es.md`, `privacy_en.md`, `privacy_ar.md` (referenciar GDPR, derechos, contacto DPO, retención de datos).
3. Añade a `pubspec.yaml`:
   ```yaml
   flutter:
     assets:
       - assets/legal/
   ```
4. Crea `lib/features/legal/legal_viewer_screen.dart` con WebView o `flutter_markdown` que lee el `.md` según locale actual.
5. En `privacy_screen.dart:300`:
   ```dart
   ListTile(
     title: Text(l10n.privacyTos),
     onTap: () => context.push('/legal/terms'),
   ),
   ListTile(
     title: Text(l10n.privacyPolicy),
     onTap: () => context.push('/legal/privacy'),
   ),
   ```
6. Añade ruta en `app_router.dart`.

**Verificación:**
- En la app: pulsar "Términos" → abre el .md con contenido legal real.

**Esfuerzo:** L · **Riesgo:** 🟢 · **Tipo:** req

---

### F3.11 · ABI splits para release

**Acción:**
1. En CI, cambia el job de build:
   ```yaml
   - run: flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/symbols
   ```
   Esto genera 3 APKs:
   - `app-armeabi-v7a-release.apk` (~25 MB)
   - `app-arm64-v8a-release.apk` (~28 MB)
   - `app-x86_64-release.apk` (~30 MB)
2. AAB ya es split-per-abi automáticamente al subir a Play Store.

**Verificación:**
- Cada APK por ABI < 35 MB.
- `aapt dump badging app-arm64-v8a-release.apk | grep native-code`.

**Esfuerzo:** S · **Riesgo:** 🟢 · **Tipo:** ops

---

### F3.12 · Verificación final Fase 3

**Acción E2E:**
1. Push end-to-end: enviar notif desde Supabase edge function → llegar a device foreground/background/killed → tap → deeplink navega.
2. AAB firmado pasa `jarsigner -verify`.
3. Tamaño por ABI <35 MB.
4. App ya no muestra "Sin notificaciones disponibles" si tienes permisos.
5. `flutter test` verde con `firebase_options.dart` mockeado en tests.

**Estado posterior:** TFG 9.0/10 · Producción 8.0/10 · Media 8.1/10

---

## FASE 4 — OBSERVABILIDAD + GDPR COMPLETO (≈1 semana)

### F4.1 · Sentry spans en 6 puntos críticos

**Acción tipo (auth.signIn):**

En `lib/data/auth/auth_repository_supabase.dart`:
```dart
@override
Future<UserModel> signIn(String email, String password) async {
  final tx = Sentry.startTransaction('auth.signIn', 'auth');
  try {
    final response = await _client.auth.signInWithPassword(email: email, password: password);
    tx.setData('user_id_short', response.user!.id.substring(0, 8));
    await tx.finish(status: const SpanStatus.ok());
    return UserModel.fromSupabase(response.user!);
  } catch (e) {
    tx.throwable = e;
    await tx.finish(status: SpanStatus.internalError());
    rethrow;
  }
}
```

Repite para:
- `lib/features/map/transit_map.dart` initState → `Sentry.startTransaction('map.initial_render', 'render')`
- `lib/data/nfc/nfc_card_service.dart` readCard → `Sentry.startTransaction('nfc.read', 'nfc')`
- `lib/data/route/remote/route_remote_repository.dart` byId → `Sentry.startTransaction('network.fetch_routes', 'http')`
- `lib/data/push/push_service.dart` send → `'push.send'`
- `lib/data/auth/...` refresh → `'auth.refresh'`

**Verificación:**
- `Grep -c "Sentry.startTransaction" lib/` ⇒ ≥6 hits.
- En Sentry dashboard: aparecen 6 nuevas operations con percentiles.

**Esfuerzo:** M · **Riesgo:** 🟢 · **Tipo:** req

---

### F4.2 · Sentry imports en edge functions

**Archivo:** `supabase/functions/*/index.ts`

**Acción:**
```typescript
import * as Sentry from "https://deno.land/x/sentry/index.mjs";

Sentry.init({
  dsn: Deno.env.get("SENTRY_DSN"),
  tracesSampleRate: 0.2,
  environment: Deno.env.get("ENVIRONMENT") ?? "production",
});

Deno.serve(async (req) => {
  const tx = Sentry.startTransaction({ name: "send_notification", op: "http.server" });
  try {
    // ... lógica
    tx.setStatus("ok");
    return new Response("ok", { status: 200 });
  } catch (e) {
    Sentry.captureException(e);
    tx.setStatus("internal_error");
    return new Response("error", { status: 500 });
  } finally {
    tx.finish();
  }
});
```

**Verificación:**
- `Grep "Sentry.init" supabase/functions/` ⇒ ≥2 hits.
- Logs Sentry muestran transactions edge.

**Esfuerzo:** S · **Riesgo:** 🟢 · **Tipo:** req

---

### F4.3 · beforeSend filtra PII completa

**Archivo:** `lib/core/utils/sentry_setup.dart:25-28`

**Acción:**
```dart
static SentryEvent? _beforeSend(SentryEvent event, Hint hint) {
  // Scrub IP (ya estaba)
  event = event.copyWith(request: event.request?.copyWith(env: {}));
  if (event.user != null) {
    event = event.copyWith(user: event.user!.copyWith(ipAddress: null, email: null));
  }

  // Scrub emails en mensajes y stack traces
  final emailRegex = RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+');
  if (event.message?.formatted != null) {
    final scrubbed = event.message!.formatted!.replaceAll(emailRegex, '[email]');
    event = event.copyWith(message: event.message!.copyWith(formatted: scrubbed));
  }

  // Scrub tokens Bearer
  final bearerRegex = RegExp(r'Bearer\s+[A-Za-z0-9._-]+');
  // (aplicar a request.headers, request.cookies, extra)

  // Scrub query params con token
  final tokenQueryRegex = RegExp(r'(\?|&)(token|api_key|apikey)=[^&]+');

  // Scrub headers sensibles
  if (event.request?.headers != null) {
    final headers = Map<String, String>.from(event.request!.headers!);
    headers.remove('Authorization');
    headers.remove('apikey');
    headers.remove('Cookie');
    event = event.copyWith(request: event.request!.copyWith(headers: headers));
  }

  return event;
}
```

**Verificación:**
- Test unitario: lanzar exception con email/token en mensaje → `_beforeSend` lo escruba.
- En Sentry: 0 eventos con `@` literal o `Bearer ...`.

**Esfuerzo:** M · **Riesgo:** 🟢 · **Tipo:** fix

---

### F4.4 · Implementar 17 eventos PostHog

**Acción:**

Para cada uno de los 17 eventos catalogados en `docs/POSTHOG_EVENTS.md`, añade la llamada en el feature correspondiente:

| Evento | Archivo a tocar |
|--------|-----------------|
| `signup_completed` | `lib/features/auth/signup_screen.dart` tras éxito |
| `signin_completed` | `lib/features/auth/signin_screen.dart` |
| `route_viewed` | `lib/features/route_detail/route_detail_screen.dart` initState |
| `stop_viewed` | `lib/features/stop_detail/stop_detail_screen.dart` initState |
| `incident_reported` | `lib/features/incidents/report_incident_sheet.dart` submit |
| `feedback_sent` | `lib/features/feedback/feedback_screen.dart` submit |
| `route_suggested` | `lib/features/suggestions/suggest_route_screen.dart` submit |
| `favorite_added` | `lib/shared/providers/user_favorites.dart` addLine |
| `favorite_removed` | idem removeLine |
| `nfc_card_scanned` | `lib/features/home/tabs/card_tab.dart` scan success |
| `offline_region_downloaded` | `lib/features/offline/widgets/region_download_sheet.dart` completion |
| `theme_changed` | `lib/shared/providers/theme_notifier.dart` |
| `language_changed` | `lib/shared/providers/locale_provider.dart` |
| `notification_received` | `lib/data/push/push_service.dart` _onForeground |
| `notification_tapped` | idem _onTap |
| `error_displayed` | `lib/shared/widgets/error_card.dart` |
| `app_opened` | `lib/main.dart` post-bootstrap |

Cada llamada tipo:
```dart
ref.read(analyticsServiceProvider).track('route_viewed', {
  'route_id': route.id,
  'operator': route.operatorId,
});
```

**Verificación:**
- `Grep "analyticsService.track\|analyticsServiceProvider.*track" lib/features/` ⇒ ≥17 hits.
- En PostHog dashboard: 17 events emitidos durante sesión de prueba.

**Esfuerzo:** L · **Riesgo:** 🟢 · **Tipo:** req

---

### F4.5 · Fix AppLogger en release

**Archivo:** `lib/core/utils/app_logger.dart:22-55`

**Acción:**
```dart
class AppLogger {
  static const _enabled = bool.fromEnvironment('APP_LOGGER', defaultValue: kDebugMode);

  static void warn(String message, {Object? error, StackTrace? stackTrace}) {
    // Siempre añadir breadcrumb (incluso en release para Sentry)
    Sentry.addBreadcrumb(Breadcrumb(
      message: message,
      level: SentryLevel.warning,
      data: error != null ? {'error': error.toString()} : null,
    ));
    if (_enabled) {
      developer.log(message, name: 'WARN', error: error, stackTrace: stackTrace);
    }
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    // Siempre captura
    Sentry.captureException(error ?? Exception(message), stackTrace: stackTrace);
    if (_enabled) {
      developer.log(message, name: 'ERROR', error: error, stackTrace: stackTrace);
    }
  }
}
```

**Verificación:**
- Test: build release con `--dart-define=APP_LOGGER=false` → llamar `warn()` → Sentry recibe breadcrumb pero no se imprime en consola.

**Esfuerzo:** S · **Riesgo:** 🟢 · **Tipo:** fix

---

### F4.6 · Decisión sobre home widgets nativos

**Opción A — implementar (4-5 días):**
1. Android: crear `android/app/src/main/kotlin/app/transitly/widgets/TransitlyWidgetProvider.kt`:
   ```kotlin
   class TransitlyWidgetProvider : HomeWidgetProvider() {
       override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray, data: SharedPreferences) {
           ids.forEach { id ->
               val views = RemoteViews(context.packageName, R.layout.transitly_widget)
               views.setTextViewText(R.id.widget_route, data.getString("next_route", "—"))
               views.setTextViewText(R.id.widget_minutes, "${data.getInt("next_minutes", 0)} min")
               manager.updateAppWidget(id, views)
           }
       }
   }
   ```
2. Layout `android/app/src/main/res/layout/transitly_widget.xml`.
3. Manifest declaration `<receiver android:name=".widgets.TransitlyWidgetProvider">`.
4. iOS: crear `ios/HomeWidget/HomeWidget.swift` con WidgetKit.
5. Conectar Dart: `WidgetDataWriter.writeNextDeparture(routeId, minutes)` llamado desde callback push.

**Opción B — eliminar (1 día):**
1. `flutter pub remove home_widget`.
2. `rm -rf lib/features/widgets_native/`.
3. `rm docs/HOME_WIDGETS.md docs/WEARABLE_NIVEL_1.md`.
4. Eliminar ruta del router.
5. Eliminar entradas del mega plan.

**Decisión recomendada para llegar a 10/10:** Opción A.

**Verificación (Opción A):**
- Long-press en home Android → "Transitly" aparece en lista de widgets.
- Añadir widget → muestra próxima salida real.

**Esfuerzo:** L (opción A) / S (opción B) · **Riesgo:** 🟡 · **Tipo:** feat / debt

---

### F4.7 · SLO real con SLI instrumentados

**Acción:**
1. Define las queries SLI en Sentry (Discover) o Grafana:
   - SLO-2 (latencia auth): p95 de transaction `auth.signIn` < 800ms
   - SLO-4 (Edge success): success rate de `http.server` en edge functions > 99%
   - SLO-5 (p95 map): p95 de `map.initial_render` < 1500ms
   - SLO-6 (push delivery): success rate de `push.send` > 95%
2. Guarda las queries en `docs/slo/queries.md`.
3. Configura alertas Sentry → Slack o email con thresholds.

**Verificación:**
- Dashboard Grafana o Sentry muestra los 4 SLIs en tiempo real.
- Alertas configuradas (test: provocar error → alerta llega).

**Esfuerzo:** M · **Riesgo:** 🟢 · **Tipo:** ops

---

### F4.8 · tool/contrast_check.dart como pre-commit

**Acción:**
Añade a `lefthook.yml`:
```yaml
pre-commit:
  commands:
    contrast-check:
      glob: "lib/core/theme/*.dart"
      run: dart run tool/contrast_check.dart > docs/CONTRAST_MATRIX.md && git add docs/CONTRAST_MATRIX.md
```

**Verificación:**
- Cambia `transit_colors.dart` → commit → `CONTRAST_MATRIX.md` regenerado automáticamente.

**Esfuerzo:** S · **Riesgo:** 🟢 · **Tipo:** ops

---

### F4.9 · Verificación final Fase 4

```bash
# Sentry
curl https://sentry.io/api/0/projects/transitly/transitly/events/ # ≥6 transactions/hour
# PostHog
curl https://app.posthog.com/api/projects/.../events/ # ≥17 distinct event names
# SLI
# manual: verificar dashboards
flutter test
flutter analyze
```

**Estado posterior:** TFG 9.5/10 · Producción 8.5/10 · Media 8.6/10

---

## FASE 5 — PERFORMANCE + ESCALABILIDAD (≈1 semana)

### F5.1 · Clustering markers en mapa

**Acción:**
```bash
flutter pub add flutter_map_marker_cluster
```

En `lib/features/map/transit_map.dart:220-221`:
```dart
MarkerClusterLayerWidget(
  options: MarkerClusterLayerOptions(
    maxClusterRadius: 60,
    size: const Size(40, 40),
    markers: markers,
    builder: (context, cluster) => Container(
      decoration: BoxDecoration(
        color: c.accent,
        shape: BoxShape.circle,
      ),
      child: Center(child: Text('${cluster.length}', style: TextStyle(color: c.textHi))),
    ),
  ),
)
```

**Verificación:**
- Con 500 markers, FPS ≥55 en zoom medio.
- `flutter drive --target=test_driver/map_perf_test.dart --profile`.

**Esfuerzo:** M · **Riesgo:** 🟡 · **Tipo:** req

---

### F5.2 · MapController dispose

**Archivo:** `lib/features/home/tabs/map_tab.dart:35-45`

**Acción:**
```dart
class _MapTabState extends State<MapTab> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _sheetController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
```

**Verificación:**
- Tests con `leak_tracker_flutter_testing`: 0 leaks.

**Esfuerzo:** S · **Riesgo:** 🟢 · **Tipo:** fix

---

### F5.3 · autoDispose sweep

**Acción:**
Convertir los providers identificados como long-lived sin justificación a `.autoDispose`:
- `mapDataCacheProvider` → `mapDataCacheProvider = Provider.autoDispose(...)` (`lib/features/map/map_data_cache.dart:36`)
- Repositorios que crean `RealtimeChannelManager` → `.autoDispose` o `ref.onDispose(() => channel.close())`

**Verificación:**
- `Grep -c ".autoDispose\|autoDispose\." lib/` ⇒ ≥25 hits (antes 9).

**Esfuerzo:** M · **Riesgo:** 🟡 · **Tipo:** fix

---

### F5.4 · LRU FMTC

**Archivo:** `lib/features/appearance/widgets/storage_section.dart`

**Acción:**
```dart
final store = FMTCStore('transitly_tiles');
await store.manage.create();
await store.manage.setMaxLength(500); // máx 500 MB
store.stats.realTimeWatch.listen((stats) {
  if (stats.size > 480 * 1024 * 1024) {
    store.manage.removeOldestTiles(100);
  }
});
```

**Verificación:**
- Tamaño tiles ≤500 MB tras uso extensivo.

**Esfuerzo:** M · **Riesgo:** 🟡 · **Tipo:** fix

---

### F5.5 · Helper repository factory

**Estado (2026-05-23):** PENDIENTE. No implementado. Aceptable para TFG (la duplicación es cosmética); recomendado post-defensa.

**Archivo nuevo:** `lib/data/_shared/repository_factory.dart`

**Acción:**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Provider<T> repositoryWithSessionFallback<T>({
  required T Function() mock,
  required T Function(SupabaseClient client) remote,
  String? name,
}) {
  return Provider<T>((ref) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return mock();
    return remote(Supabase.instance.client);
  }, name: name);
}
```

Aplicar en los 12 providers:
```dart
// ANTES (route_repository_provider.dart:114-128)
final routeRepositoryProvider = Provider<RouteRepository>((ref) {
  final session = Supabase.instance.client.auth.currentSession;
  if (session == null) return RouteMockRepository(ref.watch(mockDataServiceProvider));
  return RouteRemoteRepository(ref.watch(supabaseClientProvider));
});

// DESPUÉS
final routeRepositoryProvider = repositoryWithSessionFallback<RouteRepository>(
  mock: () => RouteMockRepository(...),
  remote: (client) => RouteRemoteRepository(client),
  name: 'route',
);
```

**Verificación:**
- `Grep -c "session == null" lib/data/*/_repository_provider.dart` baja de ~12 a 0.

**Esfuerzo:** M · **Riesgo:** 🟢 · **Tipo:** debt

---

### F5.6 · Descomponer 5 screens >450 LoC

**Cada uno:**

1. `region_download_sheet.dart` (508):
   - Extraer `_BoundsPicker` widget (~150 líneas) a `widgets/bounds_picker.dart`
   - Extraer `_DownloadProgress` (~80 líneas) a `widgets/download_progress.dart`
   - Extraer `_StorageEstimate` (~50 líneas) a `widgets/storage_estimate.dart`
   - Screen final ≤200 líneas.

2-5. Similar para `driver_dashboard_screen`, `my_contributions_screen`, `reputation_screen`, `offline_regions_screen`.

**Verificación:**
- `wc -l lib/features/*/*screen*.dart` → ninguno >300 líneas.

**Esfuerzo:** L · **Riesgo:** 🟡 · **Tipo:** debt

---

### F5.7 · flutter_secure_storage para sesión Supabase

**Acción:**
```bash
flutter pub add flutter_secure_storage
```

Crea `lib/data/auth/secure_local_storage.dart`:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureLocalStorage extends LocalStorage {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  @override
  Future<bool> hasAccessToken() async => (await _storage.read(key: 'sb-session')) != null;
  @override
  Future<String?> accessToken() => _storage.read(key: 'sb-session');
  @override
  Future<void> persistSession(String s) => _storage.write(key: 'sb-session', value: s);
  @override
  Future<void> removePersistedSession() => _storage.delete(key: 'sb-session');
  @override
  Future<void> initialize() async {}
}
```

En `main.dart`:
```dart
await Supabase.initialize(
  url: Env.supabaseUrl,
  anonKey: Env.supabaseAnonKey,
  authOptions: const FlutterAuthClientOptions(
    localStorage: SecureLocalStorage(),
  ),
);
```

**Verificación:**
- `adb backup` y luego `dd if=backup.ab | head | strings` → no aparece "refresh_token".

**Esfuerzo:** M · **Riesgo:** 🟡 · **Tipo:** fix

---

### F5.8 · HiveAesCipher para boxes sensibles

**Archivo:** `lib/data/cache/hive_init.dart`

**Acción:**
```dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<void> bootstrap() async {
  await Hive.initFlutter();

  // Obtener/generar clave de cifrado desde Keystore/Keychain
  const storage = FlutterSecureStorage();
  String? key = await storage.read(key: 'hive_aes_key');
  if (key == null) {
    final newKey = Hive.generateSecureKey();
    await storage.write(key: 'hive_aes_key', value: base64Encode(newKey));
    key = base64Encode(newKey);
  }
  final cipher = HiveAesCipher(base64Decode(key));

  // Boxes con datos personales → cifradas
  await Hive.openBox('authSessionMeta', encryptionCipher: cipher);
  await Hive.openBox('userPreferences', encryptionCipher: cipher);
  await Hive.openBox('pendingActions', encryptionCipher: cipher);

  // Boxes con datos públicos → sin cifrar (rendimiento)
  await Hive.openBox('routes');
  await Hive.openBox('stops');
  // ... resto
}
```

**Verificación:**
- `strings ~/.../hive/authSessionMeta.hive | head` → no muestra texto plano.

**Esfuerzo:** M · **Riesgo:** 🟡 · **Tipo:** fix

---

### F5.9 · Eliminar accesos directos a Supabase desde widgets

**Acción:**
1. `lib/features/route_detail/widgets/route_share_sheet.dart:78-94` — mover lógica a `lib/data/route_share/route_share_repository.dart` (nuevo).
2. `lib/features/route_detail/widgets/route_officialize_modal.dart:68` — mover a `lib/data/route_officialize/route_officialize_repository.dart` (nuevo).

**Verificación:**
- `Grep "client.from\|Supabase.instance" lib/features/` ⇒ 0 hits (todo desde repositorios).

**Esfuerzo:** M · **Riesgo:** 🟢 · **Tipo:** debt

---

### F5.10 · Region download bbox real + FMTC verdadero

**Archivo:** `lib/features/offline/widgets/region_download_sheet.dart`

**Acción:**
1. Sustituir bbox hardcoded por `MapPicker` (nuevo widget) que permita dibujar rectángulo en mapa.
2. Conectar a FMTC real:
   ```dart
   final store = FMTCStore(regionName);
   await store.manage.create();
   final region = RectangleRegion(LatLngBounds(LatLng(bounds.south, bounds.west), LatLng(bounds.north, bounds.east)));
   await store.download.startForeground(
     region: region.toDownloadable(
       minZoom: 12, maxZoom: 16,
       options: TileLayer(urlTemplate: '...'),
     ),
   ).listen((progress) {
     setState(() => _downloadProgress = progress.percentageProgress / 100);
   });
   ```

**Verificación:**
- Descargar región → cache FMTC ≥10 MB tiles reales.
- Activar avión + abrir mapa en la zona descargada → tiles visibles.

**Esfuerzo:** L · **Riesgo:** 🟡 · **Tipo:** fix

---

### F5.11 · Sustituir '_current_' literal

**Archivos:**
- `lib/features/offline/offline_regions_screen.dart:114`
- `lib/shared/providers/theme_notifier.dart:367`

**Acción:**
```dart
// ANTES
final uid = '_current_';

// DESPUÉS
final uid = Supabase.instance.client.auth.currentUser?.id;
if (uid == null) {
  // mostrar empty state "necesitas iniciar sesión"
  return;
}
```

**Verificación:**
- `Grep "'_current_'" lib/` ⇒ 0 hits.

**Esfuerzo:** XS · **Riesgo:** 🟢 · **Tipo:** fix

---

### F5.12 · Verificación final Fase 5

```bash
flutter build apk --release --split-per-abi --analyze-size
# Cada APK <35 MB
flutter test
flutter drive --target=integration_test/perf_map_test.dart --profile
```

**Estado posterior:** TFG 9.5/10 · Producción 9.5/10 · Media 9.2/10

---

## FASE 6 — POLISH HASTA 10/10 (≈1 semana)

### F6.1 · Integration tests reales

**Estado (2026-05-23):** PENDIENTE. Carpeta `integration_test/` no existe. Aceptable para defensa TFG (la rúbrica no exige integration tests).

**Acción:**
1. `flutter pub add --dev integration_test`
2. Crear `integration_test/happy_paths_test.dart`:
   ```dart
   void main() {
     IntegrationTestWidgetsFlutterBinding.ensureInitialized();
     testWidgets('signup → login → search → favorite', (tester) async {
       app.main();
       await tester.pumpAndSettle();
       // signup flow...
     });
     testWidgets('report incident from stop', (tester) async { ... });
     testWidgets('change theme to dark', (tester) async { ... });
   }
   ```
3. CI: añadir job que ejecuta integration_test en emulador Android.

**Verificación:**
- `flutter test integration_test/` verde con 3 tests.

**Esfuerzo:** L · **Riesgo:** 🟡 · **Tipo:** req

---

### F6.2 · Tests capa remote (12 dominios)

**Acción:**
Para cada uno de los 12 dominios (route, stop, operator, incident, ...), crear `test/data/<domain>/remote/<domain>_remote_repository_test.dart`:
```dart
class _MockSupabaseClient extends Mock implements SupabaseClient {}
class _MockPostgrestQueryBuilder extends Mock implements PostgrestQueryBuilder {}

void main() {
  late RouteRemoteRepository repo;
  late _MockSupabaseClient client;

  setUp(() {
    client = _MockSupabaseClient();
    repo = RouteRemoteRepository(client);
  });

  test('byId returns parsed route on success', () async {
    // arrange con when(...).thenAnswer(...)
    // act + assert
  });
  test('byId throws RepositoryException on network error', () async { ... });
}
```

**Verificación:**
- Cobertura de `lib/data/*/remote/*.dart` ≥80%.

**Esfuerzo:** L · **Riesgo:** 🟢 · **Tipo:** req

---

### F6.3 · Subir cobertura global a 60%

**Acción:**
1. Identifica archivos con 0% cobertura desde `coverage/lcov.info`.
2. Prioriza por LOC × uso:
   - `lib/features/map/transit_map.dart` (88 líneas, alto uso) → tests widget
   - `lib/features/driver/route_editor/*` (~600 líneas) → tests unit con `EditorController` mock
   - `lib/features/appearance/widgets/*` (~400 líneas) → tests widget
   - `lib/features/operator_admin/*` → tests con session mock
3. Objetivo: 24,77% → 60%+ (4000 líneas adicionales cubiertas).

**Verificación:**
- `awk` sobre `lcov.info` ⇒ ≥60%.
- CI coverage gate: actualizar de 24% a 60%.

**Esfuerzo:** XL · **Riesgo:** 🟢 · **Tipo:** req

---

### F6.4 · Pasada manual WCAG AA con TalkBack/VoiceOver

**Acción:**
1. Dispositivo Android con TalkBack activado: navegar las 27 pantallas y reportar:
   - ¿Cada elemento tiene label leído correcto?
   - ¿Orden de foco es lógico?
   - ¿Botones son accionables con doble tap?
   - ¿Imágenes decorativas son skipped (no anunciadas)?
2. Dispositivo iOS con VoiceOver: idem.
3. Documentar en `docs/A11Y_MANUAL_TEST_2026_06.md` con screenshots y veredicto por pantalla.

**Verificación:**
- 27/27 pantallas con veredicto "AA pass".

**Esfuerzo:** L · **Riesgo:** 🟢 · **Tipo:** doc + req

---

### F6.5 · dartdoc en GitHub Pages

**Acción:**
1. Crea `.github/workflows/dartdoc.yml`:
   ```yaml
   name: dartdoc
   on:
     push:
       branches: [main]
   jobs:
     deploy:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4
         - uses: subosito/flutter-action@v2
         - run: flutter pub get
         - run: dart doc .
         - uses: peaceiris/actions-gh-pages@v3
           with:
             github_token: ${{ secrets.GITHUB_TOKEN }}
             publish_dir: ./doc/api
   ```
2. Habilita GitHub Pages en repo settings.

**Verificación:**
- `https://<user>.github.io/<repo>/` muestra dartdoc navegable.

**Esfuerzo:** S · **Riesgo:** 🟢 · **Tipo:** doc

---

### F6.6 · INFLESZ regenerable con script

**Acción:**
Crea `tool/inflesz_check.dart` que:
1. Lee `lib/l10n/app_es.arb`.
2. Para cada string, calcula Flesch-Szigriszt: `INFLESZ = 206.835 - 62.3 * (sílabas/palabras) - palabras/frases`.
3. Genera `docs/INFLESZ_AUDIT.md` con tabla string → INFLESZ → categoría.

**Verificación:**
- Cifras INFLESZ reproducibles desde script.

**Esfuerzo:** M · **Riesgo:** 🟢 · **Tipo:** doc

---

### F6.7 · leak_tracker_flutter_testing tests

**Acción:**
```bash
flutter pub add --dev leak_tracker_flutter_testing
```

Para cada uno de los 16 controllers/streams:
```dart
testWidgets('MapTab no leaks', (tester) async {
  await tester.runAsync(() async {
    final tracker = LeakTracker();
    await tester.pumpWidget(const MapTab());
    await tester.pumpWidget(Container());  // dispose
    expect(tracker.collectedLeaks, isEmpty);
  });
});
```

**Verificación:**
- 16 tests verdes.

**Esfuerzo:** L · **Riesgo:** 🟡 · **Tipo:** req

---

### F6.8 · SAST nightly con OWASP ZAP

**Acción:**
Añade a `.github/workflows/`:
```yaml
name: nightly-security
on:
  schedule:
    - cron: '0 3 * * *'
jobs:
  zap:
    runs-on: ubuntu-latest
    steps:
      - uses: zaproxy/action-baseline@v0.10.0
        with:
          target: 'https://transitly.app'
```

**Verificación:**
- Cron job ejecuta a las 03:00 UTC.

**Esfuerzo:** S · **Riesgo:** 🟢 · **Tipo:** ops

---

### F6.9 · Migration a very_good_analysis

**Acción:**
```bash
flutter pub add --dev very_good_analysis:^6.0.0
flutter pub remove flutter_lints
```

Edita `analysis_options.yaml`:
```yaml
include: package:very_good_analysis/analysis_options.yaml
analyzer:
  exclude:
    - '**/*.g.dart'
    - '**/*.freezed.dart'
    - 'lib/l10n/generated/**'
```

Esperar ~300-500 issues nuevos al principio; arreglar progresivamente.

**Verificación:**
- `flutter analyze` 0 issues con `very_good_analysis`.

**Esfuerzo:** L · **Riesgo:** 🟡 · **Tipo:** debt

---

### F6.10 · Pen test pasivo OWASP Mobile Top 10

**Acción:**
Checklist sobre la app real:
- M1 Credential storage: `flutter_secure_storage` ✓ (F5.7)
- M2 Supply chain: `pubspec.lock` commit, dependabot
- M3 Auth: verificar deeplinks no permiten bypass (F0.8 + tests)
- M4 Input validation: sanitizar feedback/incident comments (escape HTML)
- M5 Insecure comms: HTTPS forzado (ya OK)
- M6 Privacy: F2.6 + F2.7 + F2.10
- M7 Code quality: very_good_analysis (F6.9)
- M8 Code tampering: --obfuscate + split-debug-info (ya OK)
- M9 Insecure storage: HiveAesCipher (F5.8)
- M10 Crypto: ningún SHA1/MD5

**Verificación:**
- Doc `docs/SECURITY_AUDIT_2026_06.md` con cada item revisado.

**Esfuerzo:** L · **Riesgo:** 🟢 · **Tipo:** doc

---

### F6.11 · Performance budget en CI

**Acción:**
Añade step en `.github/workflows/ci.yml`:
```yaml
- name: APK size budget
  run: |
    SIZE=$(stat -c%s build/app/outputs/flutter-apk/app-arm64-v8a-release.apk)
    BUDGET=36700160  # 35 MB
    if [ "$SIZE" -gt "$BUDGET" ]; then
      echo "::error::APK size $SIZE exceeds budget $BUDGET"
      exit 1
    fi
```

**Verificación:**
- CI falla si APK arm64 >35 MB.

**Esfuerzo:** S · **Riesgo:** 🟢 · **Tipo:** ops

---

### F6.12 · Reauditoría final

**Acción:**
1. Re-ejecutar `tool/verify_state.sh`.
2. Re-ejecutar el AUDIT con sub-agentes (o auditoría manual).
3. Verificar scorecard: 8 áreas a 9-10/10.
4. Eliminar todo `// TODO`, `// FIXME`, `// HACK` residual.
5. Actualizar `docs/00_MAESTRO.md` con scorecard final 10/10.
6. Generar release notes para v1.0.0.
7. Tag `v1.0.0`.

**Criterio:**
- Scorecard medio ≥9.5/10.
- Cero items "estantería" residuales.
- Documentación 100% sincronizada con código (`verify_state.sh` sin drift).
- 60%+ cobertura.
- Tests integration verdes.
- Pasada A11Y manual aprobada.
- Push end-to-end funcional.
- AAB firmado pasa `jarsigner -verify`.
- 0 advisors Supabase security.

**Estado final:** TFG 10/10 · Producción 10/10 · **Media 10/10**

---

## B. ANEXOS

### Anexo A — Comandos de verificación por fase

```bash
# F0 (Pre-defensa)
flutter analyze && flutter test && ./tool/verify_state.sh

# F1 (Hardening TFG)
./tool/verify_state.sh && ./tool/check_no_hardcoded.sh && dart run tool/contrast_check.dart && flutter analyze && flutter test

# F2 (SQL + Backend)
flutter test && deno test supabase/functions/*/test.ts
# MCP:
# mcp__supabase__list_tables, list_migrations, get_advisors --security, list_edge_functions

# F3 (Push + Release)
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
jarsigner -verify -verbose build/app/outputs/bundle/release/app-release.aab

# F4 (Observabilidad)
flutter test && curl <sentry api> && curl <posthog api>

# F5 (Performance)
flutter build apk --release --split-per-abi
flutter drive --target=integration_test/perf_map_test.dart --profile

# F6 (Polish)
flutter test integration_test/ && flutter test --coverage && awk ... lcov.info
```

### Anexo B — Mapeo finding auditoría → paso

| Finding del AUDIT | Paso(s) v2 |
|-------------------|------------|
| Drift documental tests (175/201/245/292/304) | F1.1 |
| Cobertura 27% vs 24,77% real | F0.4, F0.5, F6.3 |
| `00_MAESTRO.md` no es fuente única | F0.4, F0.5, F1.10 |
| Migración 014_audit_log corrupta | F2.1 |
| Migración 015_privacy_consents conflicto | F2.2 |
| Backend Supabase pausado | F2.4 |
| 0 publishable keys | F2.4 |
| 0 edge functions desplegadas | F2.5 |
| WCAG AA no defendible (textLo, contrast) | F1.3 |
| 0 semanticLabels | F1.4 |
| Goldens falsos | F1.8 |
| Edge function tests falsos | F2.9 |
| Sentry spans no implementados | F4.1 |
| CI AAB sin keystore | F3.8, F3.9 |
| Bug onPressed: () {} en route_detail | F0.1 |
| Búsqueda fake | F0.7 |
| Ana Martín hardcoded | F0.2 |
| ETA fake en active_route | F0.2 |
| Freshness fake en route_detail_header | F0.2 |
| UUID cero en operator_admin | F0.2 (parcial), F5.11 |
| Push 100% desconectado | F3.1-F3.7 |
| Home widgets vaporware | F4.6 |
| Age verification fake | F2.6 |
| Right to be forgotten manual | F2.7 |
| purge_old_* ausentes | F2.8 |
| Onboarding sin persistencia | F0.9 |
| Debug showcase accesible release | F0.8 |
| Terms y Privacy onTap vacío | F3.10 |
| flutter_secure_storage ausente | F5.7, F5.8 |
| Bundle 73 MiB sin ABI splits | F3.11 |
| Mapa sin clustering | F5.1 |
| MapController no dispose | F5.2 |
| Markers no const | F5.1 (implica) |
| 5 screens >450 LoC | F5.6 |
| 24 setState post-await sin mounted | F1.5 |
| ADRs 003/004 desincronizados | F1.2 |
| migration_rollback.md fake | F0.3 |
| firebase_setup.dart referencia | F0.3 |
| CONTRAST_MATRIX colores fake | F1.3 |
| LEAK_TRACKER paquete ausente | F6.7 |
| POSTHOG_EVENTS 17 sin invocación | F4.4 |
| AppLogger noop en release | F4.5 |
| beforeSend solo IP | F4.3 |
| Semgrep no en CI | F1.7 |
| Helper repository duplicado 12× | F5.5 |
| Acceso Supabase desde widgets | F5.9 |
| Mock getNextDepartures ignora stopId | (no priorizado — fix incremental en F0/F1) |
| Filtros mapa decorativos | (no priorizado — fix incremental) |
| 9 falsos cierres mega plan | reconciliar en F1.1 |

### Anexo C — Dependencias añadidas

`pubspec.yaml` diff esperado tras todas las fases:
```yaml
dependencies:
  flutter_secure_storage: ^9.2.2     # F5.7
  flutter_map_marker_cluster: ^1.3.4 # F5.1
  flutter_markdown: ^0.7.4           # F3.10
  webview_flutter: ^4.10.0           # F3.10 (alternativa)

dev_dependencies:
  integration_test:                  # F6.1
    sdk: flutter
  leak_tracker_flutter_testing: ^3.0.0 # F6.7
  very_good_analysis: ^6.0.0         # F6.9
  # Eliminar: flutter_lints (F6.9)
  # Eliminar: home_widget (si opción B en F4.6)
```

### Anexo D — Scripts nuevos en `tool/`

| Script | Función | Fase |
|--------|---------|------|
| `verify_state.sh` | Regenera bloque "Estado verificado" de 00_MAESTRO | F0.4 |
| `sync_docs.sh` | Sincroniza cifras en docs (opcional) | F1.1 |
| `check_no_hardcoded.sh` | Falla si hay strings ES hardcoded | F1.6 |
| `contrast_check.dart` | Regenera CONTRAST_MATRIX.md | F1.3 |
| `inflesz_check.dart` | Mide Flesch-Szigriszt de strings ARB | F6.6 |

### Anexo E — Reglas transversales obligatorias

1. **Nada se considera "cerrado" sin grep verificable** en `lib/`, `supabase/` o `test/`.
2. **Las cifras del bloque "Estado verificado" se regeneran con script** — nunca a mano.
3. **Pre-commit hook lefthook** valida que `00_MAESTRO.md` y `CONTRAST_MATRIX.md` están sincronizados.
4. **Cada paso es PR-able y reversible** (commit atómico, mensaje conventional commits).
5. **Tests verdes y analyze 0** son criterio obligatorio para mergear cualquier PR.
6. **Conventional commits** + auto-release-notes via `release-please`.

---

## C. RIESGOS Y MITIGACIONES

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|:-:|:-:|------------|
| Migraciones SQL rompen backend con datos | Media | Alto | Validar en proyecto staging antes; F2.4 con dump previo |
| Keystore Android perdido | Baja | Catastrófico | Guardar en password manager + cloud backup encriptado |
| Tests integration flaky en CI | Alta | Medio | Marcar como `flaky` con retry; usar emulador específico (Pixel 6 API 34) |
| very_good_analysis introduce ~500 issues | Alta | Bajo | Aplicar gradualmente, fase F6.9 al final |
| Sentry quota free agotada | Media | Bajo | Configurar sample rate 0.1-0.2, plan team si crece |
| FCM push delivery flaky en Android 12+ | Media | Medio | Documentar excepciones device-specific (Xiaomi, Huawei sin GMS) |
| Drift documental vuelve | Alta | Medio | Lefthook pre-commit + F1.10 |
| Tribunal pulsa botón roto en demo | Media | Alto | F0.1 + F0.7 + simulacro de defensa |
| Edge function timeout en pg_cron | Media | Bajo | Implementar idempotencia + retry |

---

## D. CRITERIOS DE ÉXITO POR FASE

| Fase | Criterio "fase completa" | Verificación |
|------|--------------------------|--------------|
| F0 | TFG defendible sin sorpresas obvias | Demo simulada 30 min sin fakes detectados |
| F1 | Documentación 100% sincronizada con código | `tool/verify_state.sh` + `check_no_hardcoded.sh` sin drift |
| F2 | Backend Supabase production-ready | MCP advisors security=0, edge functions=4 |
| F3 | Push notifications end-to-end funcional | E2E test foreground/background/killed |
| F4 | Observabilidad real con SLOs medibles | Dashboards Sentry/Grafana con SLI vivos |
| F5 | Mapa con 500 markers a 60fps + APK <35 MB | `flutter drive --profile` confirma |
| F6 | Scorecard 10/10 reauditado | Auditoría independiente confirma 8 áreas a 9-10 |

---

## E. HISTORIAL Y FIRMA

| Fecha | Versión | Cambios |
|-------|---------|---------|
| 2026-05-18 | v1 | Plan original tras revisión independiente (`docs/historico/PLAN_ACCION_REMEDIACION_v1.md`) |
| 2026-05-22 | **v2 (este)** | Reescrito tras auditoría deep-dive `AUDIT_2026_05_22.md`. Estructura por fases con detalle ejecutable. |

**Anclaje:** `master @ 1c77f1f` · **Auditor:** Claude (orquestación 13 sub-agentes) · **Próxima reauditoría:** tras completar F6.
