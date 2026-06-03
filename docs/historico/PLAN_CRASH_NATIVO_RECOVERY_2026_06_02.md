# Plan de acción — Crash nativo silencioso al cambiar accesibilidad (recovery boot)

**Fecha:** 2026-06-02
**Autor:** Claude Code (Opus 4.7)
**Estado:** propuesto, **CRÍTICO**
**Continuación de:** `PLAN_8_BUGS_LOGS_2026_06_02.md` (las defensas Dart se implementaron en commit `e9787ef` pero **NO bastan**)
**Goal:** Eliminar la posibilidad de que la app quede brickeada tras cambios de accesibilidad. Si crashea, debe recuperarse SOLA al siguiente arranque sin que el usuario tenga que borrar datos del sistema.
**Arquitectura:** Boot canary + modo recovery + Sentry nativo. Atacamos el crash desde 3 ángulos porque las defensas Dart actuales no lo capturan.
**Stack:** Flutter 3.9.2 + Riverpod + Hive + Sentry + Android nativo.

---

## 1. Diagnóstico del problema actual

### Lo que la otra IA implementó (correcto pero insuficiente)

Verificado en código actual `lib/shared/providers/theme_notifier.dart:465-510`:
- ✅ `_loadGuestPrefs()` envuelto en try/catch.
- ✅ `_safeDouble`, `_safeString`, `_safeBool` validan tipos primitivos.
- ✅ Si carga falla → `_resetToDefaults()` + `_guestBox.delete('prefs')`.
- ✅ `init()` para auth prefs también con try/catch.
- ✅ Validación NaN/Infinity en `app.dart` antes del `TextScaler`.
- ✅ `HighContrastTheme.apply` envuelto en try/catch.
- ✅ `_fallback()` revertido a null cuando no hay dislexia (evita TextStyle assertion crash).

### Por qué siguen los crashes (causa raíz REAL)

El usuario reporta:
> "La única solución que ha funcionado ha sido borrar caché de la app y sus datos para que se arregla. El crash no es detectado por el terminal y provoca que no se pueda acceder a la app."

Esto significa:
1. **El crash NO es de Dart** — un crash de Dart sería capturado por el `runZonedGuarded` que envuelve `runApp`, generaría stack trace en logcat y Sentry lo recogería.
2. **El crash es del ENGINE nativo** — Skia/Impeller (Vulkan), font subsystem o shader. Cuando el engine crashea, el proceso muere antes de loggear.
3. **El crash es persistente** porque las prefs tóxicas se guardaron ANTES del crash. Al reabrir, `_loadGuestPrefs` carga las mismas prefs OK (porque son números/strings válidos), pero al RENDERIZAR el primer frame con esa combinación, el engine crashea de nuevo.
4. **El try/catch no lo captura** porque el crash ocurre en C++ del engine, no en Dart.

### Hipótesis de qué combinación crashea

Lo más probable de las opciones:
- **Vulkan/Impeller + ColorFilter.matrix complejo** (color blind) sobre un background shader (smoke.frag) con `BlendMode` raro → crash de Vulkan.
- **OpenDyslexic OTF + textScale > 2.0 + peso w600 sintetizado** → font subsystem se queda sin memoria o stack overflow al construir el shape de glifos.
- **MediaQuery.disableAnimations + AnimatedSwitcher con shader child** → race condition en el engine.
- **ColorFilter.matrix con valores NaN si AccessibilityMatrix.forMode devuelve algo malformado** → Skia crash al pintar.

Para identificar la combinación exacta hace falta un **log persistente que sobreviva al crash**, y para evitar el brick hace falta un **boot canary**.

---

## 2. Plan de tareas

### Tarea A — Boot canary persistente (1 h) ⭐ CRÍTICA

**Goal:** detectar al arrancar si el último intento de "aplicar settings" terminó en crash, y si es así, revertir esos settings a defaults ANTES de aplicarlos.

#### A.1 — Flag en SharedPreferences (no Hive)
Usar **SharedPreferences** en lugar de Hive porque:
- Es más simple para flags atómicos.
- No depende del subsystem Hive que también podría estar afectado por la corrupción.
- Es síncrono (`getString` con cache), ideal para boot.

**Archivos:**
- New: `lib/core/utils/boot_canary.dart`

**API propuesta:**
```dart
class BootCanary {
  static const _kLastBootStatus = 'boot.lastStatus';
  static const _kPendingSensitiveChange = 'boot.pendingSensitive';
  static const _kCrashStreak = 'boot.crashStreak';

  /// Llamar PRIMERO en main(). Antes que cualquier `runApp`.
  static Future<BootCanaryState> startBoot() async {
    final prefs = await SharedPreferences.getInstance();
    final lastStatus = prefs.getString(_kLastBootStatus);
    final pendingChange = prefs.getString(_kPendingSensitiveChange);
    final crashStreak = prefs.getInt(_kCrashStreak) ?? 0;
    // Marcar "BOOTING" — si llegamos a `markStable` se sustituirá por "STABLE".
    // Si no, próximo boot verá "BOOTING" y sabrá que crasheamos.
    await prefs.setString(_kLastBootStatus, 'BOOTING');
    return BootCanaryState(
      lastStatusWas: lastStatus,           // STABLE | BOOTING | null
      pendingChange: pendingChange,        // qué setting estábamos aplicando
      crashStreak: crashStreak,            // consecutivos
    );
  }

  /// Llamar al rendererse el primer frame OK (en `WidgetsBinding.addPostFrameCallback`).
  static Future<void> markStable() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastBootStatus, 'STABLE');
    await prefs.setInt(_kCrashStreak, 0);
    await prefs.remove(_kPendingSensitiveChange);
  }

  /// Marcar que vamos a aplicar un setting potencialmente tóxico
  /// (dislexia, alto contraste, fontScale > 1.5, colorBlind, shader bg).
  static Future<void> markPendingSensitive(String change) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPendingSensitiveChange, change);
  }

  static Future<void> incrementCrashStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final n = (prefs.getInt(_kCrashStreak) ?? 0) + 1;
    await prefs.setInt(_kCrashStreak, n);
  }
}

class BootCanaryState {
  final String? lastStatusWas;
  final String? pendingChange;
  final int crashStreak;
  BootCanaryState({...});

  bool get crashed => lastStatusWas == 'BOOTING';
  bool get inRecoveryMode => crashStreak >= 2;
}
```

#### A.2 — Wire-up en main.dart
**Archivos:**
- Modify: `lib/main.dart` antes de `runApp`

**Steps:**
- [ ] Al inicio de `main()`, después de `WidgetsFlutterBinding.ensureInitialized()`:
```dart
final canary = await BootCanary.startBoot();
if (canary.crashed) {
  AppLogger.warn('BootCanary', 'previous boot crashed, pending=${canary.pendingChange} streak=${canary.crashStreak}');
  await BootCanary.incrementCrashStreak();
  // Si el último intento crasheó al aplicar un setting sensible, revertirlo.
  if (canary.pendingChange != null) {
    await _revertSensitiveSetting(canary.pendingChange!);
  }
  // Si 2+ crashes consecutivos, ENTRAR EN MODO RECOVERY: defaults completos.
  if (canary.crashStreak >= 2) {
    await _enterRecoveryMode();
  }
}
```
- [ ] `_revertSensitiveSetting(change)` lee el guest box y resetea el campo concreto a default:
```dart
Future<void> _revertSensitiveSetting(String change) async {
  final box = await Hive.openBox('guest_prefs');
  final data = Map<String, dynamic>.from(box.get('prefs') ?? {});
  switch (change) {
    case 'dyslexiaFontEnabled': data['dyslexiaFontEnabled'] = false; break;
    case 'highContrast': data['highContrast'] = false; break;
    case 'fontScale': data['fontScale'] = 1.0; break;
    case 'colorBlindMode': data['colorBlindMode'] = 'none'; break;
    case 'backgroundId': data['backgroundId'] = 'shaders/smoke.frag'; break;
  }
  await box.put('prefs', data);
}
```
- [ ] `_enterRecoveryMode()` borra el `prefs` entero del guest box.
- [ ] Tras `runApp(...)`, en el root widget, en `addPostFrameCallback` del primer build:
```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  BootCanary.markStable();
});
```

#### A.3 — Wire-up en theme_notifier setters
**Archivos:**
- Modify: `lib/shared/providers/theme_notifier.dart` setters de campos sensibles

**Steps:**
- [ ] En cada setter sensible, marcar el pending ANTES de notify:
```dart
set dyslexiaFontEnabled(bool v) {
  if (_dyslexiaFontEnabled == v) return;
  BootCanary.markPendingSensitive('dyslexiaFontEnabled'); // ← NUEVO
  _dyslexiaFontEnabled = v;
  notifyListeners();
  unawaited(_persist());
}
```
- [ ] Igual para `highContrast`, `fontScale`, `colorBlindMode`, `backgroundId`.

---

### Tarea B — Sentry crashlytics activo desde el primer boot (30 min)

**Goal:** capturar el crash nativo en logs remotos para diagnosticar la combinación exacta.

**Archivos:**
- Modify: `lib/main.dart` Sentry init

**Steps:**
- [ ] Auditar `SentrySetup.init` para confirmar:
  - `attachStacktrace: true`
  - `attachScreenshot: true` (para ver qué se intentaba renderizar)
  - `nativeCrashHandling: enabled` (default en SDK 8+, confirmar)
- [ ] Forzar Sentry activo INDEPENDIENTE de consent en boot inicial:
```dart
await SentrySetup.init(
  dsn: sentryDsn,
  enabled: true, // ← forzar hasta que el primer frame quede estable
  beforeSend: (event) {
    // Si crashStreak > 0, etiquetar como recovery event
    return event;
  },
);
```
- [ ] Después del `markStable()` y de verificar consent, ya respetar el toggle del usuario.
- [ ] Añadir breadcrumbs en los setters sensibles:
```dart
Sentry.addBreadcrumb(Breadcrumb(
  category: 'a11y.toggle',
  message: 'dyslexiaFontEnabled=$v',
  level: SentryLevel.info,
));
```

---

### Tarea C — Modo Recovery UI accesible (1.5 h)

**Goal:** si el canary detecta 2 crashes consecutivos, mostrar una pantalla **antes** de cargar la app completa que permita al usuario:
- Ver qué se intentó cambiar (`pendingChange`).
- Restaurar todo a defaults.
- Reportar el problema.
- Continuar sin recovery (a su riesgo).

#### C.1 — Provider de estado canary
**Archivos:**
- New: `lib/shared/providers/boot_canary_provider.dart`

```dart
final bootCanaryStateProvider = StateProvider<BootCanaryState?>((ref) => null);
```

#### C.2 — RecoveryScreen
**Archivos:**
- New: `lib/features/recovery/recovery_screen.dart`

```dart
class RecoveryScreen extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bootCanaryStateProvider);
    // Layout MUY simple, SIN fuentes custom, SIN shaders:
    // - Color blanco/negro puros
    // - Material default DM Sans (no OpenDyslexic, no IBM Plex)
    // - Sin BackgroundWrapper
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber, size: 64, color: Colors.orange),
                SizedBox(height: 16),
                Text('Hubo un problema al iniciar Transitly',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Detectamos que la app no se inició correctamente las últimas veces. '
                  'Posiblemente debido al cambio: ${state?.pendingChange ?? "desconocido"}',
                  textAlign: TextAlign.center),
                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => _restoreDefaults(context, ref),
                  child: Text('Restaurar configuración por defecto'),
                ),
                TextButton(
                  onPressed: () => _continueAnyway(context, ref),
                  child: Text('Continuar sin cambios'),
                ),
                TextButton(
                  onPressed: () => _reportProblem(context),
                  child: Text('Reportar el problema'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

#### C.3 — Wire-up
**Archivos:**
- Modify: `lib/main.dart` decidir TransitlyApp vs RecoveryScreen

**Steps:**
- [ ] Si `canary.inRecoveryMode == true`:
```dart
runApp(ProviderScope(
  overrides: [bootCanaryStateProvider.overrideWith((ref) => canary)],
  child: const RecoveryScreen(),
));
return;
```
- [ ] Si no, app normal.

---

### Tarea D — Persistencia segura de prefs (15 min)

**Goal:** una preferencia tóxica nunca se persiste si la app no ha llegado a renderizar bien con ella.

**Archivos:**
- Modify: `lib/shared/providers/theme_notifier.dart` métodos `_persist`

**Steps:**
- [ ] Cambiar el patrón actual `notifyListeners(); unawaited(_persist())` por:
```dart
set dyslexiaFontEnabled(bool v) {
  if (_dyslexiaFontEnabled == v) return;
  // 1. Marcar el cambio pendiente en el canary
  BootCanary.markPendingSensitive('dyslexiaFontEnabled');
  // 2. Aplicar en memoria + notificar
  _dyslexiaFontEnabled = v;
  notifyListeners();
  // 3. NO persistir todavía. Persistimos solo cuando markStable se llame
  //    tras el siguiente frame (ver A.2). Si crash → la pref NO queda en disco.
}
```
- [ ] En `BootCanary.markStable()`, después de marcar estable, llamar a `themeNotifier._persistAllNow()` (nuevo método) que sí escribe a Hive.
- [ ] Resultado: si activas dislexia y crashea ANTES del primer frame → al reabrir SharedPreferences canary detecta crash + Hive todavía tiene el valor viejo → app arranca con dislexia OFF. **No requiere clear data.**

---

### Tarea E — Test de combinaciones a11y (30 min)

**Goal:** identificar QUÉ combinaciones concretas crashean para poder evitarlas o avisar.

#### E.1 — Test de integración manual
**Steps:**
- [ ] Build APK debug + instalar + `adb logcat | tee crash_log.txt`.
- [ ] Activar configuraciones sensibles UNA A UNA, persistencia segura activa (Tarea D):
  1. Solo dislexia ON
  2. Solo alto contraste ON
  3. Solo fontScale 2.5
  4. Solo color blind protanopia
  5. Dislexia + alto contraste
  6. Dislexia + fontScale 2.5
  7. Dislexia + alto contraste + fontScale 2.5
  8. Dislexia + alto contraste + fontScale 2.5 + color blind protanopia
- [ ] Anotar cuál combinación crashea. Sentry debería capturarlo si E.1 lo dispara antes del markStable.

#### E.2 — Fix preventivo según el resultado
**Steps:**
- [ ] Si la dislexia + textScale > 2.0 crashea → limitar `fontScale.clamp(0.8, 2.0)` cuando dislexia está activa.
- [ ] Si el `ColorFilter.matrix` sobre shader background crashea → desactivar shader bg cuando color blind != none.
- [ ] Si la fuente OpenDyslexic con peso w600 crashea → forzar weights solo w400/w700 en `_activeFontFamily('OpenDyslexic')`.

---

### Tarea F — Documentación para el usuario (15 min)

**Goal:** si el recovery se activa, el usuario sabe qué hacer.

**Archivos:**
- New: `docs/RECOVERY_GUIDE.md`

**Contenido:**
- Qué es el modo recovery (pantalla blanca con triángulo amarillo).
- Por qué se activa (la app no pudo iniciar 2 veces seguidas).
- Cómo funciona "Restaurar configuración por defecto".
- Cómo reportar el problema (botón abre form con logs adjuntos).
- Cómo desactivar manualmente: `adb shell pm clear com.transitly.transitly` como último recurso.

---

## 3. Archivos modificados (resumen)

### Dart nuevos
- `lib/core/utils/boot_canary.dart`
- `lib/shared/providers/boot_canary_provider.dart`
- `lib/features/recovery/recovery_screen.dart`

### Dart modificados
- `lib/main.dart` (canary start + recovery routing + markStable)
- `lib/shared/providers/theme_notifier.dart` (markPendingSensitive en setters + persist diferido)

### Sin tocar
- Wizard crear ruta, widgets, auth.

### Docs
- `docs/RECOVERY_GUIDE.md`

---

## 4. Estimación de tiempo

| Tarea | Tiempo | Prioridad |
|-------|--------|-----------|
| A — Boot canary | 1 h | **CRÍTICA** |
| B — Sentry nativo | 30 min | Alta (diagnóstico) |
| C — Recovery UI | 1.5 h | **CRÍTICA** |
| D — Persistencia diferida | 15 min | Alta |
| E — Test combinaciones a11y | 30 min | Media |
| F — Doc recovery | 15 min | Baja |
| Build + smoke en dispositivo | 30 min | — |
| **Total** | **~4.5 h** | 1 sesión larga |

---

## 5. Orden de ejecución

1. **A + D** (~1.25 h): boot canary y persistencia diferida juntas. Esto es el corazón del fix.
2. **B** (30 min): Sentry forzado en boot, para capturar el siguiente crash si ocurre.
3. **C** (1.5 h): recovery UI para que el usuario no tenga que borrar datos.
4. **E** (30 min): identificar qué combinaciones crashean para fix preventivo.
5. **F** (15 min): doc final.

---

## 6. Decisiones tomadas

| # | Decisión | Justificación |
|---|----------|---------------|
| D1 | SharedPreferences (no Hive) para el canary | Hive puede ser parte de la corrupción; SharedPreferences es más robusta para flags atómicos |
| D2 | 2 crashes consecutivos = recovery mode | 1 puede ser puntual; 2 confirma persistencia |
| D3 | Recovery UI con `MaterialApp` propio sin BackgroundWrapper ni fuentes custom | Si el crash es del subsystem de fuentes/shaders, el recovery NO debe usarlos |
| D4 | Persistencia diferida: aplicar en memoria + notifyListeners, persistir solo en markStable | Garantiza que un crash antes del primer frame NO escribe pref tóxica |
| D5 | Sentry FORZADO ON al inicio hasta markStable | Sin esto el crash nativo no se reporta, no podemos diagnosticar |
| D6 | Revert por setting concreto (no clear total) | Preserva los otros settings que sí funcionaban |

---

## 7. Riesgos

- **R1: Marcar pendingChange por cada setter inunda SharedPreferences.** Mitigación: solo settings ya identificados como sensibles (dislexia, contraste, fontScale, colorBlind, background).
- **R2: El primer frame puede ser "OK" pero crashear al navegar a otra pantalla.** Mitigación: el canary marca stable tras 5s de uso (no solo primer frame), via `Timer(Duration(seconds: 5))`.
- **R3: Sentry forzado ON puede violar GDPR pre-consent.** Mitigación: enviar solo `crash` events, no telemetría. Activación temporal explícita en la pantalla de recovery con texto "los crashes se envían anónimamente para diagnóstico".
- **R4: Recovery UI puede crashear también si Material/Flutter engine está dañado.** Mitigación: layout MUY simple, fuentes system, sin lógica compleja.
- **R5: Persistencia diferida puede perder cambios si el usuario cierra la app rápido.** Mitigación: persistir tras 2s de estabilidad además de en markStable.

---

## 8. Criterios de aceptación

1. Activar dislexia + cambiar fontScale al max + alto contraste + color blind:
   - Si NO crashea: app funciona y configuración persiste.
   - Si crashea: al reabrir, la app arranca **automáticamente** con esos settings revertidos. NO requiere clear data.
2. 2 crashes consecutivos → recovery screen visible.
3. En recovery screen, "Restaurar configuración por defecto" funciona y luego abre la app normal.
4. Sentry registra al menos 1 evento "Native crash" con tag `pendingChange=dyslexiaFontEnabled` (u otro).
5. Pruebas E.1: documentar qué combinación crashea.
6. CLAR data por el usuario YA NO es necesario para recuperar la app.

---

## 9. Por qué este plan funciona donde el anterior falló

| Anterior (commit `e9787ef`) | Este plan |
|-------------------------|-----------|
| try/catch en Dart | + canary en SharedPreferences que sobrevive a crashes nativos |
| `_safeDouble`/`_safeBool` validan TIPOS | + revierten SETTINGS específicos si se sospecha de ellos |
| Persistencia inmediata `unawaited(_persist())` | Persistencia DIFERIDA tras primer frame estable |
| Sin Recovery UI | Recovery UI con MaterialApp standalone |
| Sentry on/off según consent | Sentry FORZADO al boot para capturar crashes nativos |
| Sin doc para el usuario | RECOVERY_GUIDE.md |

---

## 10. Próximos pasos

Cuando apruebes:
- **"arranca todo en orden"** → 4.5 h en 1 sesión (recomendado).
- **"arranca A+D primero"** (1.25 h) → solo el canary + persistencia diferida, los crashes ya no brickean la app. El resto (recovery UI, Sentry, tests) en otra sesión.
- **"arranca solo A"** (1 h) → fix mínimo viable: detecta crash y revierte setting. Sin UI bonita.

Recomendado **"arranca todo en orden"** porque el bug es bloqueante y la combinación de A+B+C+D es la única defensa robusta.

---

## Changelog

- **2026-06-02** — Plan creado tras confirmar que las defensas Dart de la otra IA (commit `e9787ef`) NO bastan porque el crash es **nativo del engine** (no de Dart). Diagnóstico: try/catch no captura crashes de Skia/Vulkan/font subsystem. Solución: boot canary + persistencia diferida + recovery UI + Sentry nativo.
