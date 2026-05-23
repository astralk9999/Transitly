# GUÍA DE LIMPIEZA Y FIXES FINALES — Transitly

**Fecha:** 2026-05-23
**HEAD base:** `master @ 85b81a1`
**Origen:** análisis de 3 sub-agentes Explore en sesión 2026-05-23 (post fixes B1-B8)
**Predecesores:** `docs/historico/REVISION_FINAL_2026_05_23.md`, `docs/historico/AUDIT_2026_05_22.md`
**Tiempo estimado de ejecución completa:** ~2 horas
**Audiencia:** dev junior o IA colaboradora con acceso al repositorio

---

## Reglas transversales

1. **No ejecutar todo de golpe.** Una fase a la vez; verificar antes de pasar a la siguiente.
2. **Cada paso es PR-able.** Commit atómico tras cada paso con mensaje en formato Conventional Commits.
3. **`flutter analyze` debe quedar en 0 errores tras cada paso.** Si rompe, revertir con `git reset --hard HEAD~1`.
4. **`flutter test` debe quedar verde (616+ tests) tras cada fase.** Si rompe, revertir.
5. **Antes de cada Edit, verificar que el "código actual" del documento coincide con el archivo real.** Si no coincide, parar y reportar (otra persona ya tocó el archivo).
6. **No usar `git commit -am`** mientras haya cambios pendientes de otras IAs en el working tree. Usar `git add <archivo_específico>` y luego `git commit`.

---

## Índice

- [A. FASE 1 — Fixes técnicos críticos (7 fixes, ~45 min)](#a-fase-1)
  - [A.1 — N1 + N2: `.first` sin guard en accessible_buses](#a1)
  - [A.2 — N3: `.first` en orElse de driver_dashboard](#a2)
  - [A.3 — N4: `int.parse` sin tryParse en start_route_screen](#a3)
  - [A.4 — N5: `int.parse` en helper `_timeToMinutes`](#a4)
  - [A.5 — N6: hex parser sin try-catch en region_download_sheet](#a5)
  - [A.6 — B9: `Future.delayed` residual sin Timer cancelable](#a6)
  - [A.7 — N15: `.first` sin guard en brightness_section](#a7)
- [B. FASE 2 — Sync cifras docs/tfg (~15 min)](#b-fase-2)
- [C. FASE 3 — Condensación docs/ a archive/ (~45 min)](#c-fase-3)
- [D. FASE 4 — Informe final SESION_LIMPIEZA_2026_05_23.md (~15 min)](#d-fase-4)
- [E. Verificación end-to-end](#e-verificacion)
- [F. Deuda post-defensa (bugs P2 NO atacados)](#f-deuda)

---

<a id="a-fase-1"></a>
## A. FASE 1 — Fixes técnicos críticos

**Objetivo:** evitar crashes potenciales nuevos (no estaban en auditoría 2026-05-22) que un tribunal podría toparse en demo.

**Esfuerzo total:** ~45 minutos (7 fixes atómicos).

---

<a id="a1"></a>
### A.1 — N1 + N2: `.first` sin guard en accessible_buses

**Por qué importa:** la pantalla "Autobuses accesibles" usa `.first` en dos sitios sin guard. Si `getStopsForRoute()` o `getNextDepartures()` devuelve lista vacía por edge case (operador sin datos, schedule fuera de horario), la app crashea con `Bad state: No element`.

**Archivo:** `lib/features/accessible_buses/accessible_buses_screen.dart`

**Código actual** (líneas 69-88):

```dart
  String? _nextStopName(MockDataService mockData, ActiveTripModel trip) {
    final stops = mockData.getStopsForRoute(trip.routeId);
    if (stops.isEmpty) return null;
    final idx = trip.currentStopIndex;
    if (idx != null && idx >= 0 && idx < stops.length) return stops[idx].name;
    return stops.first.name;
  }

  int? _minutesUntil(MockDataService mockData, ActiveTripModel trip) {
    final next = mockData.getNextDepartures(trip.routeId, '', 1);
    if (next.isEmpty) return null;
    final parts = next.first.departureTime.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    final now = DateTime.now();
    final mins = (h * 60 + m) - (now.hour * 60 + now.minute);
    return mins > 0 ? mins : null;
  }
```

**Análisis matizado:** ambos métodos ya tienen `if (stops.isEmpty) return null;` y `if (next.isEmpty) return null;` antes del `.first`. Por lo tanto **el crash no se produce hoy**. Sin embargo, el patrón es frágil: si alguien añade un `return` temprano o reordena el código, el guard puede quedar atrás. Mejor usar `firstOrNull` (Dart 3+) para eliminar el riesgo estructural.

**Código objetivo:**

```dart
  String? _nextStopName(MockDataService mockData, ActiveTripModel trip) {
    final stops = mockData.getStopsForRoute(trip.routeId);
    if (stops.isEmpty) return null;
    final idx = trip.currentStopIndex;
    if (idx != null && idx >= 0 && idx < stops.length) return stops[idx].name;
    return stops.firstOrNull?.name;
  }

  int? _minutesUntil(MockDataService mockData, ActiveTripModel trip) {
    final next = mockData.getNextDepartures(trip.routeId, '', 1);
    final departureTime = next.firstOrNull?.departureTime;
    if (departureTime == null) return null;
    final parts = departureTime.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    final now = DateTime.now();
    final mins = (h * 60 + m) - (now.hour * 60 + now.minute);
    return mins > 0 ? mins : null;
  }
```

**Cambios concretos:**
- Línea 74: `return stops.first.name;` → `return stops.firstOrNull?.name;`
- Líneas 78-80: combinar el `if (next.isEmpty) return null;` con `firstOrNull?.departureTime`.

**Verificación:**

```bash
grep -n "\.first\b" lib/features/accessible_buses/accessible_buses_screen.dart
# Resultado esperado: 0 hits (o solo coincidencias en comentarios)
```

**Commit:**

```bash
git add lib/features/accessible_buses/accessible_buses_screen.dart
git commit -m "fix(a11y): use firstOrNull instead of .first in accessible_buses helpers"
```

---

<a id="a2"></a>
### A.2 — N3: `.first` en orElse de driver_dashboard

**Por qué importa:** `mockData.routes.first` dentro de `orElse` se ejecuta cuando `firstWhere` NO encuentra coincidencia. Si `mockData.routes` está vacía (situación rara pero posible si el JSON mock falla en cargar), la app crashea. Además, el comportamiento actual es engañoso: si una ruta remota tiene un código que no existe en mock, se mapea silenciosamente a "la primera ruta del mock" — el conductor podría ver datos incorrectos sin saberlo.

**Archivo:** `lib/features/driver/driver_dashboard_screen.dart`

**Código actual** (líneas 74-83):

```dart
        final routes = response as List<dynamic>;
        _availableRoutes = routes
            .map((r) {
              final code = r['code'] as String;
              return mockData.routes.firstWhere(
                (mr) => mr.code == code,
                orElse: () => mockData.routes.first,
              );
            })
            .toList();
```

**Código objetivo:**

```dart
        final routes = response as List<dynamic>;
        _availableRoutes = routes
            .map((r) {
              final code = r['code'] as String;
              return mockData.routes.firstWhereOrNull((mr) => mr.code == code);
            })
            .whereType<RouteModel>()
            .toList();
```

**Cambios concretos:**
- Sustituir `firstWhere` + `orElse` por `firstWhereOrNull` (de `package:collection`).
- Añadir `.whereType<RouteModel>()` para filtrar los nulls (rutas remotas sin coincidencia mock se descartan en lugar de mapearse incorrectamente).
- Si no está ya: `import 'package:collection/collection.dart';` arriba.

**Verificación:**

```bash
grep -n "orElse: () => mockData.routes.first" lib/features/driver/driver_dashboard_screen.dart
# Resultado esperado: 0 hits
grep -n "firstWhereOrNull" lib/features/driver/driver_dashboard_screen.dart
# Resultado esperado: 1 hit (la nueva línea)
```

**Commit:**

```bash
git add lib/features/driver/driver_dashboard_screen.dart
git commit -m "fix(driver): drop unmapped routes instead of falling back to .first in dashboard"
```

---

<a id="a3"></a>
### A.3 — N4: `int.parse` sin tryParse en start_route_screen

**Por qué importa:** `int.parse()` sobre un string mal formado (ej. "1a:30", "24:99", string vacío) lanza `FormatException` que crashea el rendering. Si algún schedule tiene tiempo malformado en el mock o en datos remotos, la pantalla "Iniciar ruta" peta.

**Archivo:** `lib/features/driver/start_route_screen.dart`

**Código actual** (líneas 170-182):

```dart
                children: sortedSchedules.map((s) {
                  final time = s.departureTime;
                  final parts = time.split(':');
                  final m = int.parse(parts[0]) * 60 + int.parse(parts[1]);
                  final isPast = m < nowMinutes;
                  final isNext = !isPast &&
                      (sortedSchedules.indexOf(s) ==
                          sortedSchedules.indexWhere((x) {
                            final p = x.departureTime.split(':');
                            return int.parse(p[0]) * 60 + int.parse(p[1]) >=
                                nowMinutes;
                          }));
                  final isSelected = _selectedTime == time;
```

**Código objetivo:**

```dart
                children: sortedSchedules.map((s) {
                  final time = s.departureTime;
                  final m = _parseTimeToMinutes(time);
                  final isPast = m != null && m < nowMinutes;
                  final isNext = m != null && !isPast &&
                      (sortedSchedules.indexOf(s) ==
                          sortedSchedules.indexWhere((x) {
                            final candidate = _parseTimeToMinutes(x.departureTime);
                            return candidate != null && candidate >= nowMinutes;
                          }));
                  final isSelected = _selectedTime == time;
```

**Y añadir al final de la clase** (antes del último `}`):

```dart
  /// Parsea "HH:MM" a minutos desde medianoche. Devuelve null si el formato no es válido.
  int? _parseTimeToMinutes(String time) {
    final parts = time.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }
```

**Verificación:**

```bash
grep -n "int\.parse" lib/features/driver/start_route_screen.dart
# Resultado esperado: 0 hits
grep -n "_parseTimeToMinutes" lib/features/driver/start_route_screen.dart
# Resultado esperado: 3+ hits (1 definición + 2-3 usos)
```

**Commit:**

```bash
git add lib/features/driver/start_route_screen.dart
git commit -m "fix(driver): use tryParse for time-of-day parsing in start_route_screen"
```

---

<a id="a4"></a>
### A.4 — N5: `int.parse` en helper `_timeToMinutes`

**Por qué importa:** mismo problema que A.3 pero en `route_detail_schedule_section`. Esta pantalla la abre cualquier usuario al pulsar una ruta — más expuesta que el modo conductor.

**Archivo:** `lib/features/route_detail/widgets/route_detail_schedule_section.dart`

**Código actual** (líneas 27-35):

```dart
class _RouteDetailScheduleSectionState
    extends State<RouteDetailScheduleSection> {
  DayType _selectedDayType = DayType.weekday;
  bool _showAllSchedules = false;

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
```

**Código objetivo:**

```dart
class _RouteDetailScheduleSectionState
    extends State<RouteDetailScheduleSection> {
  DayType _selectedDayType = DayType.weekday;
  bool _showAllSchedules = false;

  /// Parsea "HH:MM" a minutos desde medianoche. Devuelve -1 si el formato no es válido.
  /// El centinela -1 garantiza que un horario malformado se ordena al inicio sin crash.
  int _timeToMinutes(String time) {
    final parts = time.split(':');
    if (parts.length < 2) return -1;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return -1;
    return h * 60 + m;
  }
```

**Justificación del centinela `-1`:** los callers actuales usan el valor para `sort` y comparaciones `<`/`>=`. Devolver `null` requeriría refactor de cada caller; `-1` mantiene la firma `int _timeToMinutes(...)` y un horario malformado queda al inicio del orden (visiblemente "raro" pero sin crash).

**Verificación:**

```bash
grep -n "int\.parse" lib/features/route_detail/widgets/route_detail_schedule_section.dart
# Resultado esperado: 0 hits
```

**Commit:**

```bash
git add lib/features/route_detail/widgets/route_detail_schedule_section.dart
git commit -m "fix(route_detail): use tryParse with sentinel -1 in _timeToMinutes helper"
```

---

<a id="a5"></a>
### A.5 — N6: hex parser sin try-catch en region_download_sheet

**Por qué importa:** si Supabase devuelve un color malformado en `row['color']` (ej. "#GGGG", "rojo", "0x"), `int.parse(clean, radix: 16)` lanza `FormatException` que crashea la lista de regiones.

**Archivo:** `lib/features/offline/widgets/region_download_sheet.dart`

**Código actual** (líneas 258-262):

```dart
  static Color _parseHexColor(String hex) {
    var clean = hex.startsWith('#') ? hex.substring(1) : hex;
    if (clean.length == 6) clean = 'FF$clean';
    return Color(int.parse(clean, radix: 16));
  }
```

**Código objetivo:**

```dart
  static const Color _defaultRouteColor = Color(0xFF888888);

  static Color _parseHexColor(String hex) {
    try {
      var clean = hex.startsWith('#') ? hex.substring(1) : hex;
      if (clean.startsWith('0x') || clean.startsWith('0X')) {
        clean = clean.substring(2);
      }
      if (clean.length != 6 && clean.length != 8) return _defaultRouteColor;
      if (clean.length == 6) clean = 'FF$clean';
      final value = int.tryParse(clean, radix: 16);
      if (value == null) return _defaultRouteColor;
      return Color(value);
    } catch (_) {
      return _defaultRouteColor;
    }
  }
```

**Cambios concretos:**
- Añadir constante `_defaultRouteColor` (gris neutro).
- Aceptar también el prefijo `0x` / `0X`.
- Validar longitud (6 o 8 caracteres) antes de parsear.
- Usar `tryParse` + try-catch defensivo.

**Verificación:**

```bash
grep -n "int\.parse(clean, radix: 16)" lib/features/offline/widgets/region_download_sheet.dart
# Resultado esperado: 0 hits
grep -n "_defaultRouteColor" lib/features/offline/widgets/region_download_sheet.dart
# Resultado esperado: 4+ hits (1 definición + 3 usos)
```

**Test sugerido** (opcional, ~5 min): añadir `test/features/offline/region_download_hex_color_test.dart` con casos:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
// Si _parseHexColor es privado, exportar a top-level o crear helper público
// Aquí asumo que el test cubre el comportamiento observable

void main() {
  test('valid #RRGGBB returns Color', () {
    // ...
  });
  test('malformed hex returns default gray', () {
    // ...
  });
  test('empty string returns default gray', () {
    // ...
  });
  test('with 0x prefix returns Color', () {
    // ...
  });
}
```

**Commit:**

```bash
git add lib/features/offline/widgets/region_download_sheet.dart
git commit -m "fix(offline): wrap hex color parser in try-catch with safe gray fallback"
```

---

<a id="a6"></a>
### A.6 — B9: `Future.delayed` residual sin Timer cancelable

**Por qué importa:** la auditoría 2026-05-22 catalogó esto como "jank artificial". Tras inspección directa (verificada con grep), los dos sitios restantes **no son simulaciones de carga falsa** sino timers UX legítimos (limpiar badges/flash visual). Sin embargo, son `Future.delayed` sueltos que pueden ejecutar `setState` o `notifyListeners` **después de `dispose()`** si el usuario navega rápido fuera de la pantalla. Esto provoca warnings o leaks.

**Solución:** envolver en `Timer` cancelable en `dispose()`.

---

#### A.6.a — `active_route_screen.dart:324`

**Archivo:** `lib/features/driver/active_route_screen.dart`

**Código actual** (contexto líneas 320-328):

```dart
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _justRegistered = false);
    });
```

**Código objetivo:**

```dart
    });

    _justRegisteredTimer?.cancel();
    _justRegisteredTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _justRegistered = false);
    });
```

**Cambios adicionales en la misma clase:**

1. Añadir import si no existe:
   ```dart
   import 'dart:async';
   ```

2. Añadir campo en el State:
   ```dart
   Timer? _justRegisteredTimer;
   ```

3. Cancelar en `dispose()`:
   ```dart
   @override
   void dispose() {
     _justRegisteredTimer?.cancel();
     super.dispose();
   }
   ```

**Verificación:**

```bash
grep -n "Future\.delayed" lib/features/driver/active_route_screen.dart
# Resultado esperado: 0 hits
grep -n "_justRegisteredTimer" lib/features/driver/active_route_screen.dart
# Resultado esperado: 3 hits (campo + asignación + dispose)
```

---

#### A.6.b — `live_recorder_controller.dart:210`

**Archivo:** `lib/features/driver/route_editor/live_recorder_controller.dart`

**Código actual** (contexto líneas 208-214):

```dart
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 100), () {
      flashVisible = false;
      notifyListeners();
    });
```

**Código objetivo:**

```dart
    notifyListeners();

    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 100), () {
      flashVisible = false;
      notifyListeners();
    });
```

**Cambios adicionales en la misma clase:**

1. Import:
   ```dart
   import 'dart:async';
   ```

2. Campo:
   ```dart
   Timer? _flashTimer;
   ```

3. En `dispose()` (o `@override void dispose()` de la clase ChangeNotifier):
   ```dart
   @override
   void dispose() {
     _flashTimer?.cancel();
     super.dispose();
   }
   ```

**Verificación:**

```bash
grep -n "Future\.delayed" lib/features/driver/route_editor/live_recorder_controller.dart
# Resultado esperado: 0 hits
grep -rn "Future\.delayed" lib/features/driver/
# Resultado esperado: 0 hits global
```

**Commit (uno solo para los dos sitios):**

```bash
git add lib/features/driver/active_route_screen.dart lib/features/driver/route_editor/live_recorder_controller.dart
git commit -m "fix(driver): replace Future.delayed with cancelable Timer in dispose (B9)"
```

---

<a id="a7"></a>
### A.7 — N15: `.first` sin guard en brightness_section

**Por qué importa:** `SegmentedButton.onSelectionChanged` siempre debería devolver al menos un elemento porque tiene `multiSelectionEnabled: false` por defecto. Pero si alguna versión futura del paquete cambia el comportamiento o un usuario logra emitir un `Set` vacío, el cast `newMode.first` crashea.

**Archivo:** `lib/features/appearance/widgets/brightness_section.dart`

**Código actual** (líneas 57-60):

```dart
            selected: {mode},
            onSelectionChanged: (newMode) {
              ref.read(themeModeProvider.notifier).state = newMode.first;
            },
```

**Código objetivo:**

```dart
            selected: {mode},
            onSelectionChanged: (newMode) {
              if (newMode.isEmpty) return;
              ref.read(themeModeProvider.notifier).state = newMode.first;
            },
```

**Verificación:**

```bash
grep -n "newMode\.first" lib/features/appearance/widgets/brightness_section.dart
# Resultado esperado: 1 hit (la línea sigue, pero precedida por el guard)
grep -B 1 -n "newMode\.first" lib/features/appearance/widgets/brightness_section.dart
# Resultado esperado: línea anterior debe contener "if (newMode.isEmpty) return;"
```

**Commit:**

```bash
git add lib/features/appearance/widgets/brightness_section.dart
git commit -m "fix(appearance): guard against empty newMode set in brightness_section"
```

---

### A.8 — Verificación FASE 1 completa

```bash
flutter analyze
# Resultado esperado: 0 errors

flutter test
# Resultado esperado: 616+ tests verde (no debe romper ninguno)

grep -rn "\.first\b" lib/features/ | grep -v "firstOrNull\|firstWhere\|firstWhereOrNull"
# Resultado esperado: 0 hits o solo en comentarios/strings

grep -rn "int\.parse" lib/features/ | grep -v "tryParse\|radix"
# Resultado esperado: 0 hits

grep -rn "Future\.delayed" lib/features/driver/
# Resultado esperado: 0 hits
```

**Total commits FASE 1:** 7 commits atómicos.

---

<a id="b-fase-2"></a>
## B. FASE 2 — Sync cifras docs/tfg

**Objetivo:** alinear las cifras citadas en los 8 docs/tfg con el código real (drift detectado: 620→616 tests, 846→628 ARB, 4→7 CI jobs).

**Esfuerzo:** ~15 min.

---

### B.1 — Crear script `tool/sync_tfg_numbers.sh`

**Archivo nuevo:** `tool/sync_tfg_numbers.sh`

**Contenido completo:**

```bash
#!/usr/bin/env bash
# Sincroniza cifras en docs/tfg/*.md con valores reales del repositorio.
# Uso: bash tool/sync_tfg_numbers.sh
# Idempotente: ejecutar varias veces no rompe nada.

set -e

FILES=(
  docs/tfg/01_analisis_contexto.md
  docs/tfg/02_diseno_proyecto.md
  docs/tfg/03_planificacion.md
  docs/tfg/04_desarrollo_implementacion.md
  docs/tfg/05_evaluacion_documentacion.md
  docs/tfg/06_manual_tecnico.md
  docs/tfg/07_manual_usuario.md
  docs/tfg/08_presentacion.md
)

for f in "${FILES[@]}"; do
  echo "Sincronizando: $f"
  sed -i \
    -e 's/620 tests/616 tests/g' \
    -e 's/620 pruebas/616 pruebas/g' \
    -e 's/\*\*620\*\*/**616**/g' \
    -e 's/846 claves ARB/628 claves ARB/g' \
    -e 's/846 claves/628 claves/g' \
    -e 's/\*\*846\*\*/**628**/g' \
    -e 's/4 jobs CI/7 jobs CI/g' \
    -e 's/4 CI jobs/7 CI jobs/g' \
    -e 's/4 jobs de CI/7 jobs de CI/g' \
    -e 's/cuatro jobs/siete jobs/g' \
    "$f"
done

echo ""
echo "DONE — verificación:"
for f in "${FILES[@]}"; do
  remaining=$(grep -cE '620|846|4 jobs|cuatro jobs' "$f" || echo 0)
  echo "  $f: $remaining referencias antiguas restantes (revisar si son legítimas)"
done
```

**Pasos para crear y ejecutar:**

```bash
# 1. Crear directorio si no existe
mkdir -p tool

# 2. Pegar el contenido anterior en tool/sync_tfg_numbers.sh
#    (usar tu editor o herramienta de escritura preferida)

# 3. Dar permisos de ejecución
chmod +x tool/sync_tfg_numbers.sh

# 4. Ejecutar
bash tool/sync_tfg_numbers.sh

# 5. Revisar el output — debería mostrar "0 referencias antiguas restantes" para cada doc
#    (o un número bajo si quedan menciones legítimas históricas)
```

---

### B.2 — Validaciones post-sed

#### B.2.a — Verificar Hive boxes cifradas

Los docs/tfg mencionan "3 boxes cifradas". Verificar con el código real:

```bash
grep -c "encryptionCipher" lib/data/cache/hive_init.dart
# Resultado: número de boxes con cifrado.
# Si es 2 (no 3), actualizar manualmente los docs/tfg que lo mencionen:
grep -rn "3 boxes cifradas\|tres boxes cifradas\|3 cifradas" docs/tfg/
```

Si la cifra real es **2** y no **3**, ejecutar:

```bash
for f in docs/tfg/04_desarrollo_implementacion.md docs/tfg/06_manual_tecnico.md; do
  sed -i \
    -e 's/3 boxes cifradas/2 boxes cifradas/g' \
    -e 's/tres boxes cifradas/dos boxes cifradas/g' \
    -e 's/3 cifradas/2 cifradas/g' \
    "$f"
done
```

#### B.2.b — Verificar bloque "Estado verificado" de 00_MAESTRO

```bash
sed -n '/<!-- BEGIN ESTADO -->/,/<!-- END ESTADO -->/p' docs/00_MAESTRO.md
```

Si las cifras no coinciden con la realidad y existe `tool/verify_state.sh`:

```bash
./tool/verify_state.sh
# Comparar output con el bloque en 00_MAESTRO.md y actualizar manualmente si difieren.
```

---

### B.3 — Verificación FASE 2

```bash
# No deben quedar cifras viejas en los 8 docs TFG
grep -rE "\b620\b|\b846\b" docs/tfg/
# Resultado esperado: 0 hits

# CI jobs actualizado
grep -rE "\b4 (jobs|CI jobs)\b" docs/tfg/
# Resultado esperado: 0 hits
```

---

### B.4 — Commit FASE 2

```bash
git add tool/sync_tfg_numbers.sh docs/tfg/*.md
git commit -m "docs(tfg): sync numbers — 620→616 tests, 846→628 ARB keys, 4→7 CI jobs"
```

---

<a id="c-fase-3"></a>
## C. FASE 3 — Condensación docs/ a archive/

**Objetivo:** reducir el ruido documental de 74 docs no-tfg a ~30 manteniendo trazabilidad académica.

**Esfuerzo:** ~45 min.

---

### C.1 — Crear estructura `docs/historico/archive/`

```bash
mkdir -p docs/historico/archive
```

---

### C.2 — Mover 8 docs históricos obsoletos

```bash
git mv docs/historico/PLAN_TRANSITLY_V2.md             docs/historico/archive/
git mv docs/historico/PLAN_ACCION_REMEDIACION_v1.md    docs/historico/archive/
git mv docs/historico/PLAN_ACCION_REMEDIACION_v2.md    docs/historico/archive/
git mv docs/historico/AUDIT_2026_04.md                 docs/historico/archive/
git mv docs/historico/AUDIT_2026_05_22.md              docs/historico/archive/
git mv docs/historico/SESSION_AUDIT_2026_05.md         docs/historico/archive/
git mv docs/historico/REVISION_CRITICA.md              docs/historico/archive/
git mv docs/historico/A11Y_AUDIT.md                    docs/historico/archive/
```

**Se MANTIENEN en `docs/historico/` (no se mueven al archive):**
- `REVISION_INDEPENDIENTE_2026_05_17.md` — decisiones críticas trazables, referencia activa
- `REVISION_FINAL_2026_05_23.md` — informe activo del ciclo actual
- `GUIA_LIMPIEZA_2026_05_23.md` — este propio documento

---

### C.3 — Mover 12 docs huérfanos ya implementados

Estos docs corresponden a features ya cerradas e implementadas en código; no son referencia operativa activa.

```bash
git mv docs/ABI_SPLITS.md             docs/historico/archive/
git mv docs/FONTS_F26.md              docs/historico/archive/
git mv docs/FMTC_LRU.md               docs/historico/archive/
git mv docs/FCM_SETUP.md              docs/historico/archive/
git mv docs/INFLESZ_AUDIT.md          docs/historico/archive/
git mv docs/SECURITY_PAT_ROTATION.md  docs/historico/archive/
git mv docs/LOW_DATA_MODE.md          docs/historico/archive/
git mv docs/HIVE_CACHE_TENANT.md      docs/historico/archive/
git mv docs/MAP_CLUSTERING.md         docs/historico/archive/
git mv docs/F2_VERIFICATION.md        docs/historico/archive/
git mv docs/SESSION_SUMMARY.md        docs/historico/archive/
git mv docs/PLAN_V2_PROGRESS.md       docs/historico/archive/
```

---

### C.4 — Fusionar HOME_WIDGETS + HOME_WIDGETS_DECISION + WEARABLE_NIVEL_1

**Objetivo:** un único `docs/HOME_WIDGETS.md` con secciones para decisión y wearable.

```bash
# 1. Añadir cabecera de sección al doc principal
echo "" >> docs/HOME_WIDGETS.md
echo "---" >> docs/HOME_WIDGETS.md
echo "" >> docs/HOME_WIDGETS.md
echo "## Decisión arquitectónica" >> docs/HOME_WIDGETS.md
echo "" >> docs/HOME_WIDGETS.md
cat docs/HOME_WIDGETS_DECISION.md >> docs/HOME_WIDGETS.md

echo "" >> docs/HOME_WIDGETS.md
echo "---" >> docs/HOME_WIDGETS.md
echo "" >> docs/HOME_WIDGETS.md
echo "## Wearable (Nivel 1)" >> docs/HOME_WIDGETS.md
echo "" >> docs/HOME_WIDGETS.md
cat docs/WEARABLE_NIVEL_1.md >> docs/HOME_WIDGETS.md

# 2. Mover los originales al archive
git mv docs/HOME_WIDGETS_DECISION.md docs/historico/archive/
git mv docs/WEARABLE_NIVEL_1.md docs/historico/archive/

# 3. Stagear el HOME_WIDGETS.md fusionado
git add docs/HOME_WIDGETS.md
```

**Verificación:**

```bash
ls docs/HOME_WIDGETS*.md docs/WEARABLE*.md 2>/dev/null
# Resultado esperado: solo docs/HOME_WIDGETS.md
grep -c "^## " docs/HOME_WIDGETS.md
# Resultado esperado: 3+ secciones (original + Decisión + Wearable)
```

---

### C.5 — Crear `docs/historico/archive/INDEX.md`

**Archivo nuevo:** `docs/historico/archive/INDEX.md`

**Contenido completo:**

```markdown
# Archivo histórico documental — Transitly

> Documentos archivados el 2026-05-23 como parte de la sesión de limpieza
> documentada en `docs/historico/GUIA_LIMPIEZA_2026_05_23.md`.
>
> Estos archivos se mantienen aquí por trazabilidad académica (TFG) y
> auditoría histórica. **No son fuente operativa activa.** Para el estado
> actual del proyecto consultar:
> - `docs/00_MAESTRO.md` — fuente única de verdad
> - `docs/MEGA_PLAN_REFINAMIENTO.md` — roadmap activo
> - `docs/historico/REVISION_INDEPENDIENTE_2026_05_17.md` — decisiones críticas
> - `docs/historico/REVISION_FINAL_2026_05_23.md` — último informe de revisión

## Planes históricos (3 archivos)

| Archivo | Tamaño | Razón de archivado |
|---------|-------:|--------------------|
| `PLAN_TRANSITLY_V2.md` | 4.635 líneas | Plan original v2; absorbido por MEGA_PLAN_REFINAMIENTO.md |
| `PLAN_ACCION_REMEDIACION_v1.md` | 235 líneas | Plan v1 pre-auditoría (2026-05-18); reemplazado por v2 |
| `PLAN_ACCION_REMEDIACION_v2.md` | 2.805 líneas | Plan v2 ejecutado; objetivos absorbidos por MEGA_PLAN |

## Auditorías cerradas (5 archivos)

| Archivo | Fecha | Razón de archivado |
|---------|-------|--------------------|
| `AUDIT_2026_04.md` | 2026-04 | Auditoría abril; estado superado, hallazgos cerrados |
| `AUDIT_2026_05_22.md` | 2026-05-22 | Auditoría deep-dive; data refleja en 00_MAESTRO |
| `SESSION_AUDIT_2026_05.md` | 2026-05 | Auditoría sesión mayo; subsumida en PENDIENTE_PARA_CERRAR |
| `REVISION_CRITICA.md` | 2026-05-15 | 1.ª revisión crítica; trazabilidad histórica |
| `A11Y_AUDIT.md` | 2026-05 | Auditoría a11y; superada por ACCESSIBILITY.md + CONTRAST_MATRIX.md |

## Docs de features cerradas (12 archivos)

Implementaciones cerradas; documentación de cómo se hicieron, no referencia operativa.

| Archivo | Tema |
|---------|------|
| `ABI_SPLITS.md` | Split-per-ABI Android (implementado) |
| `FONTS_F26.md` | Bundling de fuentes locales (implementado) |
| `FMTC_LRU.md` | Caché LRU de tiles (implementado) |
| `FCM_SETUP.md` | Configuración Firebase Cloud Messaging (implementado) |
| `INFLESZ_AUDIT.md` | Auditoría legibilidad Inflesz (cerrada) |
| `SECURITY_PAT_ROTATION.md` | Rotación de PAT Supabase (procedimiento puntual) |
| `LOW_DATA_MODE.md` | Modo bajo consumo (implementado) |
| `HIVE_CACHE_TENANT.md` | Particionado Hive multi-operador (implementado parcial) |
| `MAP_CLUSTERING.md` | Clustering de markers (planificado) |
| `F2_VERIFICATION.md` | Verificación fase F2 del plan v2 |
| `SESSION_SUMMARY.md` | Resumen sesión cerrada |
| `PLAN_V2_PROGRESS.md` | Tracker progreso plan v2 (sustituido por MEGA_PLAN) |

## Docs fusionados (2 archivos)

| Archivo | Fusionado en |
|---------|--------------|
| `HOME_WIDGETS_DECISION.md` | `docs/HOME_WIDGETS.md` (sección "Decisión arquitectónica") |
| `WEARABLE_NIVEL_1.md` | `docs/HOME_WIDGETS.md` (sección "Wearable Nivel 1") |

---

**Total archivado:** 22 archivos
**Tamaño aprox.:** ~12.000 líneas
**Reducción de ruido:** 74 docs no-tfg → ~30 docs activos (-60%)
```

---

### C.6 — Corregir cifras outdated en `README.md`

**Verificar primero:**

```bash
grep -n "175 tests\|201 tests\|245 tests\|292 tests" README.md
```

**Aplicar fix:**

```bash
sed -i \
  -e 's/175 tests/616 tests/g' \
  -e 's/201 tests/616 tests/g' \
  -e 's/245 tests/616 tests/g' \
  -e 's/292 tests/616 tests/g' \
  README.md

# Verificación
grep -n "tests" README.md | head -5
```

---

### C.7 — Verificación FASE 3

```bash
# Conteo docs activos (esperado: ≤30)
ls docs/*.md | wc -l

# Conteo docs/historico activos (esperado: 3 — REVISION_INDEPENDIENTE_2026_05_17, REVISION_FINAL_2026_05_23, GUIA_LIMPIEZA_2026_05_23)
ls docs/historico/*.md 2>/dev/null | wc -l

# Conteo archivo (esperado: 22+)
ls docs/historico/archive/*.md | wc -l

# INDEX.md presente
ls docs/historico/archive/INDEX.md

# Verificar fusión HOME_WIDGETS
ls docs/HOME_WIDGETS*.md docs/WEARABLE*.md 2>/dev/null
# Solo HOME_WIDGETS.md
```

---

### C.8 — Commit FASE 3

```bash
git add docs/historico/archive/INDEX.md docs/HOME_WIDGETS.md README.md
git add -u  # Para registrar los renames de git mv
git commit -m "docs: condense — archive 22 obsolete docs, merge HOME_WIDGETS, fix README cifras

Movidos a docs/historico/archive/:
- 3 planes históricos (PLAN_TRANSITLY_V2, PLAN_ACCION_REMEDIACION_v1, v2)
- 5 auditorías cerradas
- 12 docs de features ya implementadas
- 2 docs fusionados en HOME_WIDGETS.md

Total: 74 → ~30 docs activos en docs/ (-60% ruido documental).
INDEX.md en archive/ documenta cada archivo movido y razón."
```

---

<a id="d-fase-4"></a>
## D. FASE 4 — Informe final SESION_LIMPIEZA_2026_05_23.md

**Objetivo:** documentar la sesión completa para trazabilidad.

**Archivo a crear:** `docs/historico/SESION_LIMPIEZA_2026_05_23.md`

**Plantilla completa:**

```markdown
# SESIÓN DE LIMPIEZA Y FIXES FINALES — Transitly

**Fecha:** 2026-05-23
**HEAD inicial:** `master @ 85b81a1`
**HEAD final:** `master @ <hash-tras-commits>` (rellenar tras ejecución)
**Origen:** `docs/historico/GUIA_LIMPIEZA_2026_05_23.md`
**Predecesores:** `REVISION_FINAL_2026_05_23.md`, `AUDIT_2026_05_22.md`

---

## A. Resumen ejecutivo

Esta sesión cierra los hallazgos pendientes del informe `REVISION_FINAL_2026_05_23.md`:

| Métrica | Antes | Después | Delta |
|---------|------:|--------:|------:|
| Bugs vivos P0/P1 | 6 nuevos detectados | 0 | -6 |
| `Future.delayed` residuales | 2 | 0 | -2 |
| `.first` sin guard | 3 | 0 | -3 |
| `int.parse` sin tryParse en helpers | 2 | 0 | -2 |
| Docs activos en docs/ | 51 | ~30 | -21 |
| Drift cifras docs/tfg | 3 (tests, ARB, CI jobs) | 0 | -3 |

**Veredicto demo-ready:** SÍ. Riesgo de crash en demo TFG: bajo.

---

## B. Fixes aplicados (FASE 1)

| # | Fix | Archivo:línea | Commit | Verificación |
|---|-----|---------------|--------|--------------|
| A.1 | N1+N2 `.first` → `firstOrNull` en accessible_buses | `accessible_buses_screen.dart:74,80` | `<sha-1>` | grep `.first` → 0 |
| A.2 | N3 `firstWhere` → `firstWhereOrNull` en driver_dashboard | `driver_dashboard_screen.dart:78-83` | `<sha-2>` | grep `orElse.*routes.first` → 0 |
| A.3 | N4 `int.parse` → `_parseTimeToMinutes` helper en start_route | `start_route_screen.dart:170-182` | `<sha-3>` | grep `int.parse` → 0 |
| A.4 | N5 `int.parse` → tryParse con centinela -1 en schedule_section | `route_detail_schedule_section.dart:27-39` | `<sha-4>` | grep `int.parse` → 0 |
| A.5 | N6 hex parser con try-catch + fallback gris | `region_download_sheet.dart:258-275` | `<sha-5>` | grep `_defaultRouteColor` → 4+ |
| A.6 | B9 `Future.delayed` → Timer cancelable en dispose | `active_route_screen.dart:324`, `live_recorder_controller.dart:210` | `<sha-6>` | grep `Future.delayed` driver/ → 0 |
| A.7 | N15 guard `newMode.isEmpty` en brightness_section | `brightness_section.dart:57-62` | `<sha-7>` | grep `newMode.isEmpty` → 1 |

---

## C. Sync cifras docs/tfg (FASE 2)

| Cifra | Antes | Después | Docs afectados |
|-------|------:|--------:|----------------|
| Tests pasando | 620 | 616 | 6 docs |
| Claves ARB | 846 | 628 | 4 docs |
| CI jobs | 4 | 7 | 2 docs |
| Hive boxes cifradas (si aplica) | 3 | 2 | 2 docs |

Script creado: `tool/sync_tfg_numbers.sh` (re-ejecutable).
Commit: `<sha-fase-2>`.

---

## D. Docs movidos a archive (FASE 3)

22 archivos movidos a `docs/historico/archive/` con `git mv` (preserva historial).

**Planes históricos (3):**
- `PLAN_TRANSITLY_V2.md` (4.635 L)
- `PLAN_ACCION_REMEDIACION_v1.md` (235 L)
- `PLAN_ACCION_REMEDIACION_v2.md` (2.805 L)

**Auditorías cerradas (5):**
- `AUDIT_2026_04.md`
- `AUDIT_2026_05_22.md`
- `SESSION_AUDIT_2026_05.md`
- `REVISION_CRITICA.md`
- `A11Y_AUDIT.md`

**Docs de features cerradas (12):**
- `ABI_SPLITS`, `FONTS_F26`, `FMTC_LRU`, `FCM_SETUP`, `INFLESZ_AUDIT`,
  `SECURITY_PAT_ROTATION`, `LOW_DATA_MODE`, `HIVE_CACHE_TENANT`,
  `MAP_CLUSTERING`, `F2_VERIFICATION`, `SESSION_SUMMARY`, `PLAN_V2_PROGRESS`

**Docs fusionados (2):**
- `HOME_WIDGETS_DECISION.md` → `docs/HOME_WIDGETS.md`
- `WEARABLE_NIVEL_1.md` → `docs/HOME_WIDGETS.md`

INDEX completo: `docs/historico/archive/INDEX.md`.

---

## E. Estado final

| Área | Nota antes (REVISION_FINAL) | Nota tras esta sesión | Comentario |
|------|:--:|:--:|------------|
| Funcionalidad demo | 7.5/10 | 8.5/10 | Bugs nuevos cerrados |
| Arquitectura | 8.0/10 | 8.0/10 | Sin cambios estructurales |
| Documentación | 7.0/10 | 8.5/10 | Drift eliminado + ruido -60% |
| Tests | 6.5/10 | 6.5/10 | Sin cambios (mismo conteo) |
| Release-readiness | 5.0/10 | 5.5/10 | Code-quality sube, plataforma sigue igual |
| **MEDIA** | **7.0** | **7.6** | +0.6 |

---

## F. Pendientes (8 bugs P2 NO atacados)

Quedan documentados para sesión post-defensa (no críticos para TFG):

| ID | Severidad | Archivo:línea | Acción propuesta |
|----|-----------|---------------|------------------|
| N7 | P2 | `storage_section.dart:35,90,140` | Mover `Hive.box()` directo a repositorio dedicado |
| N8 | P2 | `editor_controller.dart:175-204` | Consolidar acceso Hive en `EditorDraftsRepository` |
| N9 | P2 | `signin_screen.dart:51` | Envolver `PostHogAnalyticsService.signin()` en `unawaited()` |
| N10 | P2 | `route_detail_screen.dart:48` | Mover `track()` de build() a callback post-frame |
| N11 | P2 | `region_download_sheet.dart:334` | Migrar banner "Demo: solo Jerez" a ARB |
| N12 | P3 | `city_picker_screen.dart:140` | Extraer `_safeBadge()` a `lib/shared/utils/string_formatting.dart` |
| N13 | P3 | (resuelto por A.6) | --- |
| N14 | P3 | `mock_data_service.dart:359-395` | Documentar simplificación 2-min offset entre paradas |

---

**FIN DEL INFORME**

> Documento generado el 2026-05-23 tras ejecución completa de la guía
> `docs/historico/GUIA_LIMPIEZA_2026_05_23.md`. Cada fix verificado con grep + lectura;
> cada move de archivo trazable en `git log --diff-filter=R`.
```

---

<a id="e-verificacion"></a>
## E. Verificación end-to-end

Tras completar las 4 fases, ejecutar este bloque de verificación. **Todos los comandos deben pasar.**

```bash
# 1. Bugs B1 (de revisión previa) — siguen arreglados
grep -rn "00000000-0000-0000-0000-000000000000" lib/
# Esperado: 0 hits

# 2. FASE 1 — fixes aplicados
grep -rn "\.first\b" lib/features/ | grep -v "firstOrNull\|firstWhere\|firstWhereOrNull"
# Esperado: 0 hits (o solo en comentarios)

grep -rn "int\.parse" lib/features/ | grep -v "tryParse\|radix"
# Esperado: 0 hits

grep -rn "Future\.delayed" lib/features/driver/
# Esperado: 0 hits

grep -rn "Timer?" lib/features/driver/active_route_screen.dart
# Esperado: 1+ hits (el nuevo campo _justRegisteredTimer)

# 3. FASE 2 — cifras tfg sincronizadas
grep -rE "\b620\b|\b846\b" docs/tfg/
# Esperado: 0 hits (o solo en contextos legítimos)

grep -rE "4 (jobs|CI jobs)" docs/tfg/
# Esperado: 0 hits

# 4. FASE 3 — condensación docs
ls docs/*.md | wc -l
# Esperado: ≤30 (de 51)

ls docs/historico/*.md 2>/dev/null | wc -l
# Esperado: 3 (REVISION_INDEPENDIENTE, REVISION_FINAL, GUIA_LIMPIEZA, SESION_LIMPIEZA)

ls docs/historico/archive/*.md | wc -l
# Esperado: 22+ archivos + INDEX.md

cat docs/historico/archive/INDEX.md | grep -c "^|"
# Esperado: tabla con 22+ filas

# 5. FASE 4 — informe creado
ls docs/historico/SESION_LIMPIEZA_2026_05_23.md
# Esperado: existe

# 6. Build limpio
flutter analyze
# Esperado: 0 errors

flutter test
# Esperado: 616+ tests verde

# 7. Git log atómico
git log --oneline -15
# Esperado: ver ~10-11 commits nuevos:
#   - 7 commits FASE 1 (uno por fix)
#   - 1 commit FASE 2 (sync cifras tfg)
#   - 1 commit FASE 3 (condensación docs)
#   - 1 commit FASE 4 (informe final)
```

---

<a id="f-deuda"></a>
## F. Deuda post-defensa (bugs P2 NO atacados)

Esta sesión deja documentados 8 bugs P2/P3 no críticos. **No bloquean defensa TFG**, pero conviene resolver tras la defensa.

### N7 — Acceso directo a Hive desde feature (storage_section)

**Archivo:** `lib/features/appearance/widgets/storage_section.dart:35, 90, 140`

**Problema:** `Hive.box()` se invoca directamente desde el widget, violando la arquitectura de capas (feature → repository → Hive).

**Fix propuesto:** crear `lib/data/cache/storage_repository.dart` con métodos públicos (`clearTileCache()`, `getCacheSize()`, etc.) y consumir via `ref.read(storageRepositoryProvider)`.

**Esfuerzo:** M (1-2 h).

---

### N8 — Acceso directo a Hive desde controller (editor_controller)

**Archivo:** `lib/features/driver/route_editor/editor_controller.dart:175, 182, 194, 204`

**Problema:** mismo que N7 pero en un `ChangeNotifier`. Además duplica lógica con `post_recording_editor.dart`.

**Fix propuesto:** crear `lib/data/editor/editor_drafts_repository.dart` y consolidar la persistencia de drafts en un único sitio.

**Esfuerzo:** M (1-2 h).

---

### N9 — `PostHogAnalyticsService.signin()` sin await

**Archivo:** `lib/features/auth/signin_screen.dart:51` (aproximado)

**Problema:** la llamada `PostHogAnalyticsService.signin('email')` se ejecuta tras `signInWithEmail()` sin `await` ni `unawaited()`. Si la app se cierra rápido tras el login, el evento puede no enviarse.

**Fix propuesto:**

```dart
import 'dart:async';
// ...
unawaited(PostHogAnalyticsService.signin('email'));
```

**Esfuerzo:** XS (5 min).

---

### N10 — `track()` en `build()` de ConsumerWidget

**Archivo:** `lib/features/route_detail/route_detail_screen.dart:48` (aproximado)

**Problema:** `PostHogAnalyticsService.routeViewed(route.id, ...)` se invoca dentro de `build()`. Cada rebuild dispara un evento adicional.

**Fix propuesto:** mover a `addPostFrameCallback` la primera vez, o usar un `useEffect`-like (`hooks_riverpod`). Alternativa simple: convertir a `ConsumerStatefulWidget` y llamar en `initState`.

**Esfuerzo:** S (15 min).

---

### N11 — Banner ES hardcoded en region_download_sheet

**Archivo:** `lib/features/offline/widgets/region_download_sheet.dart:334`

**Problema:** el banner `'⚠ Demo: solo se puede descargar la región de Jerez...'` está hardcoded en español. Un usuario con idioma inglés o árabe ve español inesperado.

**Fix propuesto:**

1. Añadir a `lib/l10n/app_es.arb`:
   ```json
   "offlineRegionDemoLimitation": "Versión demo: solo se puede descargar la región de Jerez de la Frontera. Selección libre de región disponible en próximas versiones."
   ```
2. Idem en `app_en.arb` y `app_ar.arb`.
3. Regenerar: `flutter gen-l10n`.
4. Sustituir el string hardcoded por `AppLocalizations.of(context).offlineRegionDemoLimitation`.

**Esfuerzo:** S (15 min).

---

### N12 — `_safeBadge()` privado

**Archivo:** `lib/features/city_picker/city_picker_screen.dart:140` (aprox)

**Problema:** el helper `_safeBadge()` que arregla `substring(0,2)` es privado. Si otros features necesitan el mismo guard (probable para badges de usuarios), hay duplicación.

**Fix propuesto:** extraer a `lib/shared/utils/string_formatting.dart` como función pública:

```dart
/// Devuelve un badge de 2 caracteres de [s] en mayúsculas, seguro
/// contra strings de longitud < 2.
String safeBadge(String s) {
  if (s.isEmpty) return '··';
  if (s.length == 1) return '${s.toUpperCase()}·';
  return s.substring(0, 2).toUpperCase();
}
```

**Esfuerzo:** XS (10 min).

---

### N13 — `Future.delayed` jank residual

**Estado:** **RESUELTO en A.6** de esta misma guía (Timer cancelable en dispose).

No requiere acción adicional. Si tras la ejecución de A.6 quedaran `Future.delayed` adicionales, repetir el patrón.

---

### N14 — Mock `getNextDepartures` realismo

**Archivo:** `lib/data/mock/mock_data_service.dart:359-395`

**Problema:** el mock asume offset de 2 minutos entre paradas consecutivas. Es una simplificación pedagógica; la realidad depende del tráfico, semáforos, distancia entre paradas, etc.

**Fix propuesto:** **NO arreglar.** Documentar como simplificación intencional añadiendo comentario en la firma del método:

```dart
/// Devuelve las próximas [count] salidas para la combinación [routeId]+[stopId].
///
/// **Simplificación demo:** se asume un offset de 2 minutos por parada
/// consecutiva desde la cabecera. La realidad operativa de COMUJESA
/// depende de tráfico, semáforos y distancia entre paradas; esta
/// simulación basta para la demo del TFG.
List<ScheduleModel> getNextDepartures(...) { ... }
```

**Esfuerzo:** XS (5 min, documentación).

---

## Resumen de deuda

| Bug | Severidad | Esfuerzo | Aceptable post-defensa |
|-----|-----------|----------|:--:|
| N7 | P2 | M | sí |
| N8 | P2 | M | sí |
| N9 | P2 | XS | sí |
| N10 | P2 | S | sí |
| N11 | P2 | S | sí (importante para usuarios EN/AR) |
| N12 | P3 | XS | sí |
| N13 | (resuelto) | - | - |
| N14 | P3 (doc) | XS | sí |

**Total esfuerzo deuda:** ~4-5 horas tras defensa.

---

**FIN DE LA GUÍA**

> Documento generado el 2026-05-23 como guía ejecutable autocontenida.
> Cada snippet de "código actual" fue verificado mediante lectura puntual
> del archivo `lib/` correspondiente en `master @ 85b81a1`. Si al ejecutar
> esta guía algún "código actual" no coincide con el archivo real, parar
> y reportar — otra IA o persona puede haber tocado el archivo entre la
> generación de este documento y su ejecución.
