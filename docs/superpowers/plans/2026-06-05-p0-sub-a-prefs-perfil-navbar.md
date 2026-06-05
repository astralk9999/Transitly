# Sub-plan A de P0 — Prefs persistentes + Perfil con datos auth + Navbar hitbox

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cerrar tres blockers P0 del plan V16: (P0-05) la elección oscuro/claro se pierde al cerrar la app; (P0-06) el perfil del usuario logueado muestra "?" en vez de su nombre y foto; (P0-07) la zona táctil del botón perfil en el navbar inferior es minúscula.

**Architecture:** El bug de persistencia es muy localizado: `themeModeProvider` (un `StateProvider` puro en `lib/shared/providers/theme_provider.dart:4`) nunca se persistió, mientras que el resto de ajustes ya viven en `ThemeNotifier` con su Hive `guest_theme_prefs` box. La solución es mover `themeMode` al `ThemeNotifier` para que herede el mismo path de persistencia. El bug del perfil es leer correctamente `user_metadata` de Supabase Auth con cascada de claves (`full_name` → `name` → `display_name`) y mostrar `Image.network(avatar_url)` con fallback a iniciales. El bug del navbar es ampliar el SizedBox del tab item a `width: double.infinity` + altura 64 para cumplir WCAG 2.5.5.

**Tech Stack:** Flutter 3.9.2+, Riverpod 2.6.1, Hive 2.2.3, Supabase Auth (Google Sign-In + email/password), Material widgets (`GestureDetector`, `Image.network`, `CircleAvatar`).

---

## File Structure

**Modify:**
- `lib/shared/providers/theme_notifier.dart` — añadir field `_themeMode`, getter/setter, persistencia.
- `lib/shared/providers/theme_provider.dart` — refactor `themeModeProvider` a derivado del notifier.
- `lib/features/home/widgets/profile_appearance_section.dart` — usar el setter del notifier.
- `lib/features/home/widgets/profile_header_card.dart` — cascada `full_name`/`name`/`display_name` y `Image.network(avatar_url)`.
- `lib/features/home/widgets/home_bottom_nav.dart` — `width: double.infinity` en SizedBox + altura 64.

**Create:**
- `lib/shared/widgets/user_avatar.dart` — widget reutilizable: avatar con foto + fallback iniciales.
- `test/shared/providers/theme_notifier_mode_persistence_test.dart` — test de persistencia de `themeMode`.
- `test/shared/widgets/user_avatar_test.dart` — test del widget.

---

## Task 1: Persistir `themeMode` en `ThemeNotifier` (P0-05)

**Files:**
- Modify: `lib/shared/providers/theme_notifier.dart`
- Modify: `lib/shared/providers/theme_provider.dart`
- Modify: `lib/features/home/widgets/profile_appearance_section.dart`
- Test: `test/shared/providers/theme_notifier_mode_persistence_test.dart`

### Step 1.1 — Escribir el test que falla

- [ ] Crear `test/shared/providers/theme_notifier_mode_persistence_test.dart` con este contenido:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:transitly/shared/providers/theme_notifier.dart';

import '../../data/shared_test_repositories.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Hive en memoria para tests.
    final dir = await Directory.systemTemp.createTemp('hive_themeMode_test_');
    Hive.init(dir.path);
  });

  setUp(() async {
    // Asegurar box limpio entre tests.
    if (await Hive.boxExists('guest_theme_prefs')) {
      await Hive.deleteBoxFromDisk('guest_theme_prefs');
    }
  });

  test('themeMode defaults to system on first launch', () {
    final notifier = ThemeNotifier(prefsRepo: mockUserPreferencesRepo());
    expect(notifier.themeMode, ThemeMode.system);
  });

  test('themeMode setter persists to guest box', () async {
    final notifier = ThemeNotifier(prefsRepo: mockUserPreferencesRepo());
    await notifier.loadGuest();
    notifier.themeMode = ThemeMode.light;
    // Wait microtasks for unawaited _persist.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(notifier.themeMode, ThemeMode.light);

    // Reabrir simulando arranque en frío.
    final notifier2 = ThemeNotifier(prefsRepo: mockUserPreferencesRepo());
    await notifier2.loadGuest();
    expect(notifier2.themeMode, ThemeMode.light);
  });

  test('themeMode dark survives full round-trip', () async {
    final n1 = ThemeNotifier(prefsRepo: mockUserPreferencesRepo());
    await n1.loadGuest();
    n1.themeMode = ThemeMode.dark;
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final n2 = ThemeNotifier(prefsRepo: mockUserPreferencesRepo());
    await n2.loadGuest();
    expect(n2.themeMode, ThemeMode.dark);
  });
}
```

> Nota: el import de `dart:io` para `Directory` falta — añadirlo arriba: `import 'dart:io';`.

### Step 1.2 — Ejecutar el test, ver que falla

- [ ] Ejecutar:

```bash
flutter test test/shared/providers/theme_notifier_mode_persistence_test.dart
```

Expected: 3 tests fail con `NoSuchMethodError: Class 'ThemeNotifier' has no instance getter 'themeMode'`.

### Step 1.3 — Añadir field, getter y setter en `ThemeNotifier`

- [ ] Editar `lib/shared/providers/theme_notifier.dart`. Tras la línea 44 (`String _mapStyle = 'streets';`) añadir:

```dart
  ThemeMode _themeMode = ThemeMode.system;
```

- [ ] Tras la línea 76 (`String get mapStyle => _mapStyle;`) añadir el getter:

```dart
  ThemeMode get themeMode => _themeMode;
```

- [ ] Tras la línea 250 (final del setter `mapStyle`) añadir el setter:

```dart
  set themeMode(ThemeMode value) {
    if (_themeMode == value) return;
    _themeMode = value;
    notifyListeners();
    unawaited(_persist());
  }
```

### Step 1.4 — Persistir `themeMode` en `_persist`

- [ ] En `lib/shared/providers/theme_notifier.dart`, dentro de `_persist()` (líneas 538-580), localizar el mapa que va a `_guestBox!.put('prefs', ...)` (línea 555) y añadir:

```dart
        'themeMode': _themeMode.name,
```

Justo después de `'mapStyle': _mapStyle,` (línea 566).

- [ ] En `toPreferences(String userId)` (líneas 429-451), no añadir nada: las preferencias en Supabase no llevan `themeMode` porque es **solo local** (decisión V16). El usuario lo eligió así (Hive local).

### Step 1.5 — Hidratar `themeMode` desde el guest box

- [ ] En `lib/shared/providers/theme_notifier.dart`, dentro de `_loadGuestPrefs()` (líneas 492-536), localizar el bloque `if (data != null)` (línea 497) y añadir:

```dart
        _themeMode = _parseThemeMode(data['themeMode'] as String?);
```

Justo después de `_mapStyle = _safeString(data['mapStyle'], 'streets');` (línea 508).

- [ ] Añadir el parser tras `_parseColorBlindMode` (líneas 582-588):

```dart
  ThemeMode _parseThemeMode(String? value) {
    if (value == null) return ThemeMode.system;
    return ThemeMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ThemeMode.system,
    );
  }
```

- [ ] En `_resetToDefaults()` (líneas 629-642) añadir tras `_mapStyle = 'streets';`:

```dart
    _themeMode = ThemeMode.system;
```

### Step 1.6 — Ejecutar el test, ver que pasa

- [ ] Ejecutar:

```bash
flutter test test/shared/providers/theme_notifier_mode_persistence_test.dart
```

Expected: 3 tests PASS.

### Step 1.7 — Refactor `themeModeProvider` a derivado del notifier

- [ ] Reemplazar el contenido de `lib/shared/providers/theme_provider.dart` (línea 4 actual) por:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_notifier.dart';

/// Lee el themeMode del ThemeNotifier (que persiste en Hive).
///
/// Para cambiarlo, NO uses `.notifier.state =` — usa
/// `ref.read(themeNotifierProvider).themeMode = value`.
final themeModeProvider = Provider<ThemeMode>((ref) {
  final notifier = ref.watch(themeNotifierProvider);
  return notifier.themeMode;
});
```

### Step 1.8 — Actualizar `profile_appearance_section.dart` al nuevo API

- [ ] En `lib/features/home/widgets/profile_appearance_section.dart`, líneas 55-62, cambiar:

```dart
              Switch.adaptive(
                value: isDark,
                activeTrackColor: c.accent,
                onChanged: (v) {
                  ref.read(themeModeProvider.notifier).state =
                      v ? ThemeMode.dark : ThemeMode.light;
                },
              ),
```

por:

```dart
              Switch.adaptive(
                value: isDark,
                activeTrackColor: c.accent,
                onChanged: (v) {
                  ref.read(themeNotifierProvider).themeMode =
                      v ? ThemeMode.dark : ThemeMode.light;
                },
              ),
```

- [ ] Añadir el import si no está:

```dart
import '../../../shared/providers/theme_notifier.dart';
```

### Step 1.9 — Buscar otros usos del antiguo `.notifier.state =` para themeMode

- [ ] Ejecutar:

```bash
flutter analyze
```

Expected: posiblemente errores en archivos que hacían `ref.read(themeModeProvider.notifier).state = ...`. Corregirlos cambiando por `ref.read(themeNotifierProvider).themeMode = ...`.

- [ ] Buscar manualmente con Grep:

```bash
# Desde la raíz del repo:
grep -rn "themeModeProvider.notifier" lib/ test/
```

Para cada ocurrencia, sustituir el patrón anterior por el nuevo.

### Step 1.10 — Ejecutar la suite completa

- [ ] Ejecutar:

```bash
flutter test
flutter analyze
```

Expected: 0 issues, todos los tests pasan.

### Step 1.11 — Smoke test manual

- [ ] `flutter run -d <android-device>` o web.
- [ ] Entrar en perfil → Apariencia → cambiar a modo claro.
- [ ] Cerrar la app del todo (no solo background).
- [ ] Reabrir → debería arrancar en modo claro.
- [ ] Repetir con modo oscuro.
- [ ] Repetir cambiando paleta + fuente + alto contraste a la vez: todo persiste.

### Step 1.12 — Commit

- [ ] Ejecutar:

```bash
git add lib/shared/providers/theme_notifier.dart lib/shared/providers/theme_provider.dart lib/features/home/widgets/profile_appearance_section.dart test/shared/providers/theme_notifier_mode_persistence_test.dart
git commit -m "$(cat <<'EOF'
fix(theme): persistir themeMode en ThemeNotifier (P0-05)

themeModeProvider era un StateProvider sin persistencia, por lo que al
reabrir la app siempre arrancaba en ThemeMode.dark. Ahora el themeMode
vive en ThemeNotifier junto al resto de preferencias UI y persiste en
el guest_theme_prefs box de Hive.

- Añade getter/setter themeMode en ThemeNotifier
- Persiste en _persist() y hidrata en _loadGuestPrefs()
- Refactoriza themeModeProvider a derivado del notifier
- Actualiza profile_appearance_section al nuevo API
- Test de round-trip cubre cierre y reapertura simulados

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Mostrar nombre + foto reales en el header del perfil (P0-06)

**Files:**
- Create: `lib/shared/widgets/user_avatar.dart`
- Modify: `lib/features/home/widgets/profile_header_card.dart`
- Test: `test/shared/widgets/user_avatar_test.dart`

### Step 2.1 — Crear el widget `UserAvatar` con fallback robusto

- [ ] Crear `lib/shared/widgets/user_avatar.dart` con:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Avatar reutilizable: si hay [photoUrl] válida muestra la imagen;
/// si falla o no hay URL muestra las iniciales de [name] sobre [accent].
///
/// Tamaño en logical pixels. Por defecto 48x48 para listas/cabeceras.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.size = 48,
    required this.accent,
  });

  final String name;
  final String? photoUrl;
  final double size;
  final Color accent;

  String _initials() {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initialsLabel = Center(
      child: Text(
        _initials(),
        style: GoogleFonts.ibmPlexMono(
          fontSize: size * 0.375,
          fontWeight: FontWeight.w600,
          color: accent,
        ),
      ),
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(
          color: accent.withValues(alpha: 0.25),
          width: 0.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: (photoUrl != null && photoUrl!.isNotEmpty)
          ? Image.network(
              photoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => initialsLabel,
              loadingBuilder: (_, child, progress) =>
                  progress == null ? child : initialsLabel,
            )
          : initialsLabel,
    );
  }
}
```

### Step 2.2 — Test del widget

- [ ] Crear `test/shared/widgets/user_avatar_test.dart` con:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/shared/widgets/user_avatar.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(body: Center(child: child)),
      );

  testWidgets('UserAvatar shows two-letter initials for full name',
      (tester) async {
    await tester.pumpWidget(wrap(
      const UserAvatar(name: 'Itziar Uruburu', accent: Colors.purple),
    ));
    expect(find.text('IU'), findsOneWidget);
  });

  testWidgets('UserAvatar shows single initial for one-word name',
      (tester) async {
    await tester.pumpWidget(wrap(
      const UserAvatar(name: 'Itziar', accent: Colors.purple),
    ));
    expect(find.text('I'), findsOneWidget);
  });

  testWidgets('UserAvatar shows ? for empty name', (tester) async {
    await tester.pumpWidget(wrap(
      const UserAvatar(name: '', accent: Colors.purple),
    ));
    expect(find.text('?'), findsOneWidget);
  });

  testWidgets('UserAvatar falls back to initials when photoUrl is null',
      (tester) async {
    await tester.pumpWidget(wrap(
      const UserAvatar(name: 'Test User', accent: Colors.purple),
    ));
    expect(find.byType(Image), findsNothing);
    expect(find.text('TU'), findsOneWidget);
  });
}
```

### Step 2.3 — Ejecutar test, ver pasa

- [ ] Ejecutar:

```bash
flutter test test/shared/widgets/user_avatar_test.dart
```

Expected: 4 tests PASS.

### Step 2.4 — Actualizar `ProfileHeaderCard` para usar `UserAvatar` y cascada de metadata

- [ ] Editar `lib/features/home/widgets/profile_header_card.dart`. Reemplazar el método `build` completo (líneas 31-169) por:

```dart
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    final authState = ref.watch(authStateProvider).valueOrNull;
    final authUser = authState is AuthAuthenticated ? authState.user : null;

    if (authUser == null) {
      final l10n = AppLocalizations.of(context);
      return GlassCard(
        blur: 20,
        fillOpacity: 0.06,
        borderRadius: 16,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            UserAvatar(
              name: '',
              accent: c.accent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.profileGuestLabel,
                    style: TransitTypography.sectionLabel(c.accent),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.profileGuestCta,
                    style: TransitTypography.bodySecondary(c.textMid),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/sign-in'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: c.accent.withValues(alpha: 0.4), width: 0.5),
                ),
                child: Text(
                  l10n.profileGuestSignIn,
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: c.accent,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final metadata = authUser.userMetadata ?? const <String, dynamic>{};
    final displayName = (metadata['full_name'] as String?) ??
        (metadata['name'] as String?) ??
        (metadata['display_name'] as String?) ??
        authUser.email?.split('@').first ??
        user.name;
    final displayEmail = authUser.email ?? user.email;
    final photoUrl = (metadata['avatar_url'] as String?) ??
        (metadata['picture'] as String?);

    return GlassCard(
      blur: 20,
      fillOpacity: 0.06,
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          UserAvatar(
            name: displayName,
            photoUrl: photoUrl,
            accent: c.accent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: c.textHi,
                  ),
                ),
                Text(
                  displayEmail,
                  style: TransitTypography.bodySecondary(c.textMid),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/profile/reputation'),
            child: ReputationBadge(user.reputationLevel,
                score: user.reputationScore),
          ),
        ],
      ),
    );
  }
```

- [ ] Añadir el import al inicio del archivo:

```dart
import '../../../shared/widgets/user_avatar.dart';
```

- [ ] Eliminar el método `_initials` (líneas 20-29) — ya no se usa, ahora vive en `UserAvatar`.

### Step 2.5 — Ejecutar tests + análisis

- [ ] Ejecutar:

```bash
flutter analyze
flutter test
```

Expected: 0 issues, todos los tests pasan.

### Step 2.6 — Smoke test manual (Google Sign-In)

- [ ] `flutter run`.
- [ ] Sign-out si hay sesión activa.
- [ ] Login con Google.
- [ ] Ir a Perfil → debe verse foto y nombre real de Google.

### Step 2.7 — Smoke test manual (email/password)

- [ ] Sign-out.
- [ ] Login con email/password (cuenta sin foto).
- [ ] Ir a Perfil → debe verse iniciales basadas en `email.split('@').first` o el nombre del metadata si está.

### Step 2.8 — Commit

- [ ] Ejecutar:

```bash
git add lib/shared/widgets/user_avatar.dart lib/features/home/widgets/profile_header_card.dart test/shared/widgets/user_avatar_test.dart
git commit -m "$(cat <<'EOF'
fix(profile): nombre y avatar reales en header del perfil (P0-06)

ProfileHeaderCard solo leía user_metadata['display_name'] que Google
Sign-In no rellena, cayendo al fallback ? y mostrando "?" como iniciales.
Ahora hay cascada full_name → name → display_name → email-split → mock.

- Nuevo widget UserAvatar reutilizable con Image.network + fallback
  a iniciales sobre color de paleta
- Cascada de metadata robusta
- Tests del widget cubren iniciales una-letra, dos-letras y vacío

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Ampliar hitbox del navbar inferior (P0-07)

**Files:**
- Modify: `lib/features/home/widgets/home_bottom_nav.dart`

### Step 3.1 — Cambiar SizedBox a ocupar todo el ancho del Expanded

- [ ] Editar `lib/features/home/widgets/home_bottom_nav.dart`, líneas 85-127. Reemplazar el bloque:

```dart
                        child: SizedBox(
                          height: 56,
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 4),
                              AnimatedOpacity(
                                duration: const Duration(
                                    milliseconds: 200),
                                opacity: isActive ? 1.0 : 0.35,
                                child: Icon(
                                  isActive ? tab.activeIcon : tab.icon,
                                  size: 21,
                                  color: isActive ? c.accent : c.textHi,
                                ),
                              ),
                              const SizedBox(height: 3),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(
                                    milliseconds: 200),
                                style: GoogleFonts.ibmPlexMono(
                                  fontSize: 9,
                                  fontWeight: isActive
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isActive
                                      ? c.accent
                                      : c.textHi.withValues(alpha: 0.35),
                                  letterSpacing: 0.5,
                                ),
                                child: Text(tab.label),
                              ),
                            ],
                          ),
                        ),
```

por:

```dart
                        child: SizedBox(
                          width: double.infinity,
                          height: 64,
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 4),
                              AnimatedOpacity(
                                duration: const Duration(
                                    milliseconds: 200),
                                opacity: isActive ? 1.0 : 0.35,
                                child: Icon(
                                  isActive ? tab.activeIcon : tab.icon,
                                  size: 21,
                                  color: isActive ? c.accent : c.textHi,
                                ),
                              ),
                              const SizedBox(height: 3),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(
                                    milliseconds: 200),
                                style: GoogleFonts.ibmPlexMono(
                                  fontSize: 9,
                                  fontWeight: isActive
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isActive
                                      ? c.accent
                                      : c.textHi.withValues(alpha: 0.35),
                                  letterSpacing: 0.5,
                                ),
                                child: Text(tab.label),
                              ),
                            ],
                          ),
                        ),
```

Cambios concretos:
1. `width: double.infinity` — fuerza que el hitbox ocupe todo el ancho del `Expanded`.
2. `height: 64` (antes 56) — cumple WCAG 2.5.5 target size con margen.

### Step 3.2 — Actualizar la constante `height` y el contenedor exterior

- [ ] En la misma línea ~20 (`static const double height = 56;`) cambiar a:

```dart
  /// Altura interna del nav bar (sin contar safe area inferior).
  /// La usan los sheets/dialogs para no quedar tapados.
  /// 64 dp cumple WCAG 2.5.5 (target size) con margen.
  static const double height = 64;
```

- [ ] En la línea ~46 (`height: 56,` del SizedBox externo del LayoutBuilder), cambiar a:

```dart
        child: SizedBox(
          height: 64,
```

### Step 3.3 — Ajustar pillLeft si rompe la animación del indicador

- [ ] En `home_bottom_nav.dart` línea 50:

```dart
              final pillLeft = tabWidth * currentIndex + (tabWidth - 28) / 2;
```

La animación del pill horizontal no cambia con la altura, así que no se toca.

- [ ] Verificar que el `top: 4` del `AnimatedPositioned` (línea 57) sigue luciendo bien con la nueva altura 64; si la "pill" queda demasiado pegada al borde superior, cambiar a `top: 6`. Decisión visual a tomar tras smoke test.

### Step 3.4 — Ejecutar tests + análisis

- [ ] Ejecutar:

```bash
flutter analyze
flutter test
```

Expected: 0 issues. Si algún golden o widget test depende de la altura 56, actualizarlo a 64.

### Step 3.5 — Smoke test manual

- [ ] `flutter run -d <android-device>`.
- [ ] En portrait, pulsar **el borde superior** de cada pestaña (no el icono). Debe cambiar de pestaña.
- [ ] Pulsar **el borde derecho** de la última pestaña (perfil) — debe abrir el perfil.
- [ ] Mantener pulsado y arrastrar — no debe activar nada (es tap, no swipe).
- [ ] Rotar a landscape — debería renderizar `HomeSideNav` (no este componente). Si el navbar inferior se muestra en landscape, ese bug es de P2.5 (responsive) y queda fuera de este plan.

### Step 3.6 — Commit

- [ ] Ejecutar:

```bash
git add lib/features/home/widgets/home_bottom_nav.dart
git commit -m "$(cat <<'EOF'
fix(nav): ampliar hitbox del bottom nav a todo el ancho del tab (P0-07)

El SizedBox dentro del GestureDetector no declaraba width, por lo que
aunque el GestureDetector tenía HitTestBehavior.opaque, en algunos
escenarios el hitbox efectivo se limitaba al icono+label. Ahora:

- width: double.infinity en el SizedBox del tab
- altura 56 → 64 (WCAG 2.5.5 target size mínimo 48 + margen)
- height constant actualizada para que sheets/dialogs queden bien

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Verificación final del sub-plan

### Step 4.1 — Suite completa + análisis

- [ ] Ejecutar:

```bash
flutter analyze
flutter test
```

Expected: 0 issues, todos los tests pasan (los nuevos + todos los previos).

### Step 4.2 — Smoke test integrado

- [ ] `flutter run`.
- [ ] Login con Google → header del perfil muestra foto y nombre ✓ (P0-06).
- [ ] Toca cualquier zona de la pestaña Perfil del navbar (no solo icono) → abre perfil ✓ (P0-07).
- [ ] Cambia a modo claro → cierra app completamente → reabre → arranca en modo claro ✓ (P0-05).

### Step 4.3 — Actualizar tracking

- [ ] Editar `docs/historico/PLAN_REPARACION_2026_06_05_V16.md`: marcar como completados:
  - Ítem P0-05 (todos los CA tachados).
  - Ítem P0-06 (todos los CA tachados).
  - Ítem P0-07 (todos los CA tachados).

- [ ] Commit del tracking:

```bash
git add docs/historico/PLAN_REPARACION_2026_06_05_V16.md
git commit -m "chore: cerrar P0-05/P0-06/P0-07 en plan V16

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

### Step 4.4 — Siguiente sub-plan

Tras este sub-plan, los siguientes bloques de P0 son:

1. **Sub-plan B (Mapa)** — P0-01 (líneas invisibles) + P0-02 (deja de cargar).
2. **Sub-plan C (Editor crashes)** — P0-03 (add horario cuelga) + P0-04 (publicar no va).
3. **Sub-plan D (Zona + NFC)** — P0-08 (zona principal error) + P0-09 (saldo no hidrata).

Cada uno requerirá su propio plan de implementación creado vía
writing-plans skill.

---

## Notas y consideraciones

**Sobre la decisión de "Hive solo, no Supabase".** El usuario eligió en
la planificación V16 que las preferencias UI son local-only. Eso afecta
a esta tarea: no se añade `themeMode` al modelo `UserPreferences` ni al
schema Supabase. Si en el futuro se decide sincronizar entre
dispositivos, se hará en una feature aparte.

**Sobre el método `loadFromPreferences`.** Tiene sentido seguir
hidratando paleta/fondo/dislexia desde Supabase cuando el usuario está
logueado (eso permite "viajar" parte de la preferencia), pero `themeMode`
permanece **siempre local**, sobreviviendo a logout/login. Esto es
coherente con el comportamiento de Material You en iOS/Android.

**Sobre el `width: double.infinity` del SizedBox.** Sin él, en algunos
dispositivos (Samsung con gesture navigation, displays con notch
inferior), el `Expanded` puede dar un ancho efectivo menor al `tabWidth`
calculado, y el SizedBox sin width explícito puede shrink-wrap al
contenido. La declaración explícita garantiza el comportamiento.

**Sobre los emojis y comentarios en código.** No se introducen
emojis ni comentarios decorativos en el código modificado. Solo los
comentarios existentes que aportan el "porqué" (los del `flex_color_picker`,
`flutter_native_splash`, etc.) se mantienen.
