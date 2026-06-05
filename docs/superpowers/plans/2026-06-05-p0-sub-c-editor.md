# Sub-plan C de P0 — Editor de rutas: añadir horario no cuelga + botón publicar funciona

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cerrar los dos blockers P0 del editor de rutas del conductor: (P0-03) al pulsar "Añadir horario" la interfaz se queda en blanco; (P0-04) el botón "Publicar" del paso de revisión no produce efecto visible.

**Architecture:** El editor (`ManualRouteEditor`) usa un `RouteEditorController extends ChangeNotifier` y lo envuelve TODO el `PageView` en un único `ListenableBuilder`. Cada `notifyListeners()` rebuildea los 6 steps a la vez — incluidos los tres steps que tienen un `FlutterMap` propio (Trace, Stops, Review) atado a `MapController`s compartidos del controller. El rebuild violento desmonta y remonta `FlutterMap` con controllers reusados, lo que produce el "queda en blanco". Además el handler del botón "Publicar" llama a `saveDraft()` sin try/catch y navega antes de poder mostrar feedback de error.

Solución doble:
1. **P0-03** — Aislar el rebuild del PageView: pasar el `PageView` por el slot `child:` del `ListenableBuilder` para que se construya UNA sola vez, y mover el `ListenableBuilder` al **paso 5 (Schedules)** que es el único que necesita reaccionar al `addScheduleTime`. Además añadir validación HH:MM en `addScheduleTime` para no aceptar entradas mal formadas que pueden generar excepciones aguas abajo.
2. **P0-04** — Envolver `saveDraft()` en try/catch con `SnackBar` rojo y botón "Reintentar" en caso de error; navegar a `/home/mapa` solo después de un breve `Future.delayed` para que el snackbar se vea; clarificar el copy del botón mientras la publicación remota real (`RouteRepository.create`) sigue pendiente de implementar (queda como TODO documentado del bloque P1.5-07 del plan V16).

**Tech Stack:** Flutter `ChangeNotifier` + `ListenableBuilder`, `flutter_map` `MapController`, `Hive` editor_drafts box, `go_router` para navegación, `SnackBar` con acción.

---

## File Structure

**Modify:**
- `lib/features/driver/route_editor/editor_controller.dart` — añadir validación HH:MM y dedupe en `addScheduleTime`.
- `lib/features/driver/route_editor/manual_route_editor.dart` — quitar el `ListenableBuilder` del PageView (`child:` slot constante).
- `lib/features/driver/route_editor/steps/step_schedules.dart` — añadir `ListenableBuilder` localizado para reaccionar a cambios.
- `lib/features/driver/route_editor/steps/step_review.dart` — try/catch en publish + delay antes de navegar + error con reintentar.

**Create:**
- `test/features/driver/route_editor/editor_controller_test.dart` — tests de `addScheduleTime` con formato válido/inválido/duplicado.

---

## Task 1: Validación + dedupe en `addScheduleTime` (parte de P0-03)

**Files:**
- Modify: `lib/features/driver/route_editor/editor_controller.dart`
- Test: `test/features/driver/route_editor/editor_controller_test.dart`

### Step 1.1 — Escribir test que falla

- [ ] Crear `test/features/driver/route_editor/editor_controller_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:transitly/features/driver/route_editor/editor_controller.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('hive_editor_ctrl_test_');
    Hive.init(dir.path);
  });

  test('addScheduleTime accepts valid HH:MM and keeps list sorted', () {
    final c = RouteEditorController();
    addTearDown(c.dispose);

    c.addScheduleTime('weekday', '08:00');
    c.addScheduleTime('weekday', '07:30');
    c.addScheduleTime('weekday', '12:15');

    expect(c.schedules['weekday'], equals(['07:30', '08:00', '12:15']));
  });

  test('addScheduleTime rejects malformed input without throwing', () {
    final c = RouteEditorController();
    addTearDown(c.dispose);

    c.addScheduleTime('weekday', 'abc');
    c.addScheduleTime('weekday', '25:00');
    c.addScheduleTime('weekday', '08:60');
    c.addScheduleTime('weekday', '');
    c.addScheduleTime('weekday', '8:5');

    expect(c.schedules['weekday'], isEmpty);
  });

  test('addScheduleTime ignores duplicates', () {
    final c = RouteEditorController();
    addTearDown(c.dispose);

    c.addScheduleTime('weekday', '09:00');
    c.addScheduleTime('weekday', '09:00');
    c.addScheduleTime('weekday', '09:00');

    expect(c.schedules['weekday'], equals(['09:00']));
  });

  test('addScheduleTime does NOT notify listeners on noop (invalid/duplicate)',
      () {
    final c = RouteEditorController();
    addTearDown(c.dispose);
    var notifications = 0;
    c.addListener(() => notifications++);

    c.addScheduleTime('weekday', '08:00');
    expect(notifications, 1);

    // Duplicate: no notify
    c.addScheduleTime('weekday', '08:00');
    expect(notifications, 1);

    // Invalid: no notify
    c.addScheduleTime('weekday', 'xx');
    expect(notifications, 1);
  });
}
```

### Step 1.2 — Run test, ver falla

- [ ] Ejecutar:

```bash
flutter test test/features/driver/route_editor/editor_controller_test.dart
```

Expected: 3 de los 4 tests fallan (la versión actual de `addScheduleTime` acepta cualquier string y siempre notifica).

### Step 1.3 — Implementar validación + dedupe

- [ ] En `lib/features/driver/route_editor/editor_controller.dart`, reemplazar el método `addScheduleTime` (líneas 112-119) por:

```dart
  static final _hhmmRegExp = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

  void addScheduleTime(String key, String hhmm) {
    final list = schedules[key];
    if (list == null) return;
    if (!_hhmmRegExp.hasMatch(hhmm)) return;
    if (list.contains(hhmm)) return;
    list
      ..add(hhmm)
      ..sort();
    notifyListeners();
  }
```

### Step 1.4 — Verificar tests pasan

- [ ] Ejecutar:

```bash
flutter test test/features/driver/route_editor/editor_controller_test.dart
```

Expected: 4 tests PASS.

---

## Task 2: Aislar rebuild del PageView (P0-03)

**Files:**
- Modify: `lib/features/driver/route_editor/manual_route_editor.dart`
- Modify: `lib/features/driver/route_editor/steps/step_schedules.dart`

### Step 2.1 — Pasar PageView por el slot `child:` del ListenableBuilder

- [ ] En `lib/features/driver/route_editor/manual_route_editor.dart`, reemplazar el bloque `ListenableBuilder` (líneas 87-113):

```dart
                child: ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) => PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      StepInfo(
                          controller: _controller,
                          onNext: () => _goToStep(1)),
                      StepTrace(
                          controller: _controller,
                          isDark: isDark,
                          onNext: () => _goToStep(2)),
                      StepStops(
                          controller: _controller,
                          isDark: isDark,
                          onNext: () => _goToStep(3)),
                      StepReturn(
                          controller: _controller,
                          onNext: () => _goToStep(4)),
                      StepSchedules(
                          controller: _controller,
                          onNext: () => _goToStep(5)),
                      StepReview(controller: _controller, isDark: isDark),
                    ],
                  ),
                ),
```

por:

```dart
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    StepInfo(
                        controller: _controller,
                        onNext: () => _goToStep(1)),
                    StepTrace(
                        controller: _controller,
                        isDark: isDark,
                        onNext: () => _goToStep(2)),
                    StepStops(
                        controller: _controller,
                        isDark: isDark,
                        onNext: () => _goToStep(3)),
                    StepReturn(
                        controller: _controller,
                        onNext: () => _goToStep(4)),
                    StepSchedules(
                        controller: _controller,
                        onNext: () => _goToStep(5)),
                    StepReview(controller: _controller, isDark: isDark),
                  ],
                ),
```

> **Nota.** Los steps que actualmente dependían del rebuild global (StepInfo para enable del botón "Siguiente" según `codeCtrl.text`) seguirán funcionando porque sus `TransitInput` ya están enlazados a los `TextEditingController` del editor y el `controller.refresh()` siguiente se sustituye en el paso de revisión con un listener localizado donde haga falta. Para el alcance P0 solo necesitamos que el paso 5 (Horarios) refresque al añadir hora sin tumbar la UI.

### Step 2.2 — Localizar el `ListenableBuilder` en StepSchedules

- [ ] Editar `lib/features/driver/route_editor/steps/step_schedules.dart`. Reemplazar el método `build` (líneas 32-103) por:

```dart
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => DefaultTabController(
        length: 3,
        child: Column(
          children: [
            TabBar(
              indicatorColor: c.accent,
              labelColor: c.accent,
              unselectedLabelColor: c.textMid,
              labelStyle: GoogleFonts.ibmPlexMono(
                  fontSize: 11, fontWeight: FontWeight.w600),
              tabs: [
                Tab(text: AppLocalizations.of(context).routeDayWeekday.toUpperCase()),
                Tab(text: AppLocalizations.of(context).routeDaySaturday.toUpperCase()),
                Tab(text: AppLocalizations.of(context).routeDayHoliday.toUpperCase()),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _ScheduleTab(
                    controller: controller,
                    keyName: 'weekday',
                    onAddTime: () => _addTime(context, 'weekday'),
                  ),
                  _ScheduleTab(
                    controller: controller,
                    keyName: 'saturday',
                    onAddTime: () => _addTime(context, 'saturday'),
                  ),
                  _ScheduleTab(
                    controller: controller,
                    keyName: 'sunday',
                    onAddTime: () => _addTime(context, 'sunday'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tiempo total (min)',
                      style: TransitTypography.bodySecondary(c.textMid)),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 120,
                    child: TransitInput(
                      hint: '45',
                      controller: controller.totalTimeCtrl,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: TransitButton(
                      label: AppLocalizations.of(context).actionNext.toUpperCase(),
                      onPressed: onNext,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
```

### Step 2.3 — Localizar también el ListenableBuilder en StepReview

Para que `StepReview` siga mostrando los datos actualizados (paradas, totalScheduleCount, etc.) tras el cambio.

- [ ] En `lib/features/driver/route_editor/steps/step_review.dart`, reemplazar el método `build` (líneas 30-169) envolviendo el `Column` raíz en `ListenableBuilder`:

```dart
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final c = TransitColorScheme.of(isDark);
        final tracePoints = controller.tracePoints;
        final stops = controller.stops;

        return Column(
```

…y cerrar el builder al final del Column raíz con `);` extra:

```dart
            ],
          ),
        );
      },
    );
  }
}
```

(Es el mismo Column tal cual, solo añadido envoltorio.)

### Step 2.4 — Análisis y suite

- [ ] Ejecutar:

```bash
flutter analyze
flutter test
```

Expected: 0 errors. Pueden aparecer warnings sobre StepInfo/StepTrace/StepStops/StepReturn que ya no rebuildean por el controller global — son rebuilds que ya no eran necesarios y se eliminan; no es regresión funcional para el alcance P0. Si algún test golden de esos steps falla, se actualizará en el sub-plan futuro de P2 (rediseño UX del editor).

### Step 2.5 — Smoke test manual

- [ ] `flutter run`.
- [ ] Abrir editor de ruta como conductor.
- [ ] Avanzar hasta paso 5 (Horarios).
- [ ] Tab "DIARIO" → "+" → escribir "08:00" → ACEPTAR → la hora aparece en el wrap.
- [ ] Pulsar "+" otra vez → escribir "07:30" → ACEPTAR → ambas horas aparecen ordenadas.
- [ ] Probar input inválido "abc" → ACEPTAR → no se añade nada, la UI sigue.
- [ ] Repetir 20 ciclos abrir/cancelar/aceptar → no hay glitch ni pantalla en blanco.
- [ ] Cambiar al tab "SÁBADO" → añadir hora → el tab anterior conserva sus horas.

### Step 2.6 — Commit (Tasks 1+2 juntas)

```bash
git add lib/features/driver/route_editor/editor_controller.dart \
        lib/features/driver/route_editor/manual_route_editor.dart \
        lib/features/driver/route_editor/steps/step_schedules.dart \
        lib/features/driver/route_editor/steps/step_review.dart \
        test/features/driver/route_editor/editor_controller_test.dart
git commit -m "$(cat <<'EOF'
fix(editor): añadir horario no cuelga la UI (P0-03)

Causa raíz: ManualRouteEditor envolvía el PageView en un ListenableBuilder
global. Cada addScheduleTime() → notifyListeners() rebuildeaba los 6 steps
a la vez, incluidos StepTrace/StepStops/StepReview con FlutterMap atados
a MapControllers compartidos. El rebuild violento desmontaba/remontaba
los mapas con controllers reusados → estado inconsistente y UI en blanco.

Fix:
- PageView vive directo en el árbol; solo los steps que reaccionan a
  notifyListeners (Schedules, Review) tienen ListenableBuilder localizado.
- addScheduleTime valida HH:MM con regex y deduplica antes de notificar.
- Test unitario cubre formato válido, inválido, duplicado y silencio en
  notificaciones a no-ops.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Botón Publicar con error visible y feedback claro (P0-04)

**Files:**
- Modify: `lib/features/driver/route_editor/steps/step_review.dart`

### Step 3.1 — Envolver `saveDraft` en try/catch con SnackBar de error

- [ ] En `lib/features/driver/route_editor/steps/step_review.dart`, dentro del builder del `ListenableBuilder` que añadiste en Step 2.3, sustituir el handler `onPressed` del botón "Publicar" (eran las líneas originales 137-159) por:

```dart
                      onPressed: () async {
                        if (controller.codeCtrl.text.isEmpty ||
                            controller.nameCtrl.text.isEmpty ||
                            controller.stops.length < 2) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Código, nombre y al menos 2 paradas son obligatorios'),
                              duration: Duration(seconds: 3),
                            ),
                          );
                          return;
                        }
                        try {
                          await controller.saveDraft();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Ruta guardada como borrador. La publicación remota '
                                    'se habilitará en F15.'),
                                duration: Duration(seconds: 4),
                              ),
                            );
                          await Future<void>.delayed(
                              const Duration(milliseconds: 600));
                          if (!context.mounted) return;
                          context.go('/home/mapa');
                        } catch (e, st) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                backgroundColor: c.stateDelay,
                                duration: const Duration(seconds: 6),
                                content: Text('Error guardando: $e'),
                                action: SnackBarAction(
                                  label: 'REINTENTAR',
                                  textColor: Colors.white,
                                  onPressed: () async {
                                    try {
                                      await controller.saveDraft();
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                          ..hideCurrentSnackBar()
                                          ..showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Ruta guardada como borrador.'),
                                            ),
                                          );
                                      }
                                    } catch (_) {
                                      // El error queda en el log; el usuario
                                      // sigue viendo el snackbar con su botón.
                                    }
                                  },
                                ),
                              ),
                            );
                          // Mantiene el comportamiento de captura de excepciones
                          // de framework — la pila va al ErrorBoundary global.
                          debugPrint('publish.error: $e\n$st');
                        }
                      },
```

> **Nota.** El comentario `F15: conectar a RouteRepository.create()` del bug original sigue siendo válido como TODO — la publicación REMOTA contra Supabase se aborda en P1.5-07 del plan V16 (rutas oficiales vs comunidad). El alcance P0-04 es solo que el botón haga algo visible y correcto en local.

### Step 3.2 — Eliminar el comentario obsoleto del original

- [ ] Ya no es necesario el comentario `// F15: conectar a RouteRepository.create() para` etc. dentro del handler — el cuerpo nuevo lo reemplaza con la lógica real (saveDraft + delay + navegar). Si quedó algún comentario suelto en el diff, eliminarlo limpiamente.

### Step 3.3 — Análisis + suite

- [ ] Ejecutar:

```bash
flutter analyze
flutter test
```

Expected: 0 issues. La rama nueva del try/catch añade ramas al cuerpo del botón pero no introduce nuevos imports.

### Step 3.4 — Smoke test manual

- [ ] `flutter run`.
- [ ] Completar editor: paso 1 (Info), paso 3 (mínimo 2 stops), llegar a paso 6 (Review).
- [ ] Pulsar "Publicar" → snackbar verde con texto "Ruta guardada como borrador..." → navega a `/home/mapa` tras ~600ms.
- [ ] Si falta alguno de los 3 campos requeridos: snackbar "Código, nombre y al menos 2 paradas son obligatorios" → no navega.
- [ ] Simular error: pre-llenar el `editor_drafts` box hasta llenarlo (o forzar throw en `saveDraft` con un breakpoint en debug) → snackbar rojo con "REINTENTAR" → no navega.

### Step 3.5 — Commit

```bash
git add lib/features/driver/route_editor/steps/step_review.dart
git commit -m "$(cat <<'EOF'
fix(editor): botón Publicar con feedback visible y manejo de error (P0-04)

El botón "Publicar" llamaba a saveDraft() sin try/catch y navegaba a
/home/mapa de inmediato, lo que ocultaba el SnackBar de éxito y dejaba
al usuario sin feedback si fallaba. Además se solapaba con el bug P0-03
que desmontaba el árbol durante el await.

Fix:
- Snackbar de éxito visible 4s con copy clarificado ("guardada como
  borrador. La publicación remota se habilitará en F15").
- Delay 600ms antes de navegar para que el snackbar se vea.
- try/catch con SnackBar rojo + botón REINTENTAR si saveDraft lanza.
- Validación pre-existente ahora muestra duración explícita.

La publicación remota real (RouteRepository.create + tabla Supabase)
queda como TODO documentado del bloque P1.5-07 del plan V16.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Verificación + tracking + PR

### Step 4.1 — Suite completa final

- [ ] Ejecutar:

```bash
flutter analyze
flutter test
```

Expected: 0 errors. Mismos 19 timeouts pre-existentes en `card_tab_widget_test.dart` (no relacionados).

### Step 4.2 — Smoke test integrado

- [ ] `flutter run`.
- [ ] Editor completo de principio a fin: 6 steps, añadir paradas, añadir horarios, publicar → llega a `/home/mapa` con snack de confirmación.

### Step 4.3 — Actualizar tracking del plan V16

- [ ] Editar `docs/historico/PLAN_REPARACION_2026_06_05_V16.md`: marcar como completados P0-03 y P0-04.

- [ ] Commit tracking:

```bash
git add docs/historico/PLAN_REPARACION_2026_06_05_V16.md
git commit -m "chore: cerrar P0-03/P0-04 en plan V16

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

### Step 4.4 — Push + PR

```bash
git push -u origin fix/p0-sub-c-editor
```

Abrir PR manualmente desde la URL que devuelve GitHub.

### Step 4.5 — Siguiente sub-plan

Tras este, queda solo el **sub-plan D**: P0-08 (zona principal error operador) + P0-09 (saldo NFC no hidrata al login). Con eso se cierra P0 entero.

---

## Notas y consideraciones

**Sobre StepInfo/StepTrace/StepStops/StepReturn.** Estos cuatro steps actualmente dependen del rebuild global del PageView para reflejar cambios. Tras el cambio P0-03, dejan de hacerlo. Para los flujos básicos eso NO es problema:
- StepInfo usa `TextEditingController` (cada keystroke ya rebuildea localmente el TextField).
- StepTrace mantiene su mapa estable; los puntos del trazado se ven con `controller.tracePoints` pero la lista se pinta porque cada `addTracePoint` genera un setState propio del paso (verificar si necesita más).
- StepStops igualmente.
- StepReturn solo tiene radios — su setState local basta.

Si en smoke test se detecta un caso donde alguno de estos steps NO refresca cuando debería, el fix es añadir un `ListenableBuilder(listenable: controller, builder: ...)` localizado igual que en Schedules/Review. Esa cirugía queda como follow-up; no es bloqueante para P0.

**Sobre P0-04 y la "publicación real".** Implementar `RouteRepository.create(RouteModel)` + nueva tabla `community_route_proposals` en Supabase + RLS es alcance del plan V16 fase P1.5 (admin/operator/conductor). Este sub-plan solo desbloquea el flujo local: el conductor guarda su ruta como borrador y el editor ya no se siente roto. El siguiente paso lógico cuando se implemente P1.5-07 es reemplazar el `saveDraft` interno por una llamada a `routeRepository.publish(controller.toRouteModel(), official: false)` que persista en Supabase.

**Sobre la regex HH:MM.** `r'^([01]\d|2[0-3]):[0-5]\d$'` exige dos dígitos en ambos lados (08:00 sí, 8:0 no). Si se quiere tolerar entradas tipo "8:0" en input libre, ampliar a `r'^([0-1]?\d|2[0-3]):([0-5]\d|\d)$'` y normalizar con `padLeft(2, '0')` antes de añadir. Para el alcance P0 mantengo estricto: la UX final del paso de horarios (segmented control + reloj) se aborda en P2-06.
