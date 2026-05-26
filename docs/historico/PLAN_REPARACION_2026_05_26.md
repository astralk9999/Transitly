# Plan de despacho paralelo — Reparación Transitly (nexto-stop-v2)

> **Formato:** este plan reparte 16 errores reportados entre 8 agentes en 3 olas paralelas. Cada agente recibe un brief autónomo (no comparte contexto con los demás). Las olas están diseñadas para evitar conflictos de archivos: dentro de una misma ola, ningún agente toca el mismo fichero que otro agente de esa ola.

**Fecha del plan:** 2026-05-26
**Autor:** Claude Code (Opus 4.7)
**Estado:** aprobado, pendiente de ejecución.

---

## Cómo usar este plan

### Quién es quién

- **Coordinador** = el agente principal que lanza este plan (tú o Claude Code en sesión nueva).
- **A1..A8** = sub-agentes despachados con el subagent type `general-purpose` (o `claude` si está disponible) en modo **foreground** dentro de una sola wave, en paralelo.
- Cada sub-agente recibe **solo** su brief (la sección `### A<N>` correspondiente) más el bloque `Contexto global del proyecto` pegado al inicio. **No** comparte el resto del documento ni el contexto de la conversación del coordinador.

### Receta de despacho paso a paso

1. **Antes de Wave 1**, el coordinador:
   - Verifica que `git status` está limpio y la rama es `master` (o crea una rama `fix/reparacion-app` para todo el trabajo).
   - Ejecuta `flutter analyze` y `flutter test` para tener un baseline; guarda el resultado.
   - Asegura que `flutter pub get` corre sin error.

2. **Wave 1** — despachar A1, A2, A3, A4, A5 **en paralelo** (una sola respuesta del coordinador con 5 tool calls `Agent` simultáneos). Modelo recomendado: `sonnet` (suficiente para cada brief, más barato y rápido). Si A5 (el más cargado) se queda largo, considerar `opus` solo para él.
   - El coordinador espera a que las 5 vuelvan.
   - Lee los 5 reportes finales.
   - Resuelve conflictos triviales en `.arb` y en `route_card.dart` (A4 y A5 tocan zonas distintas del mismo archivo).
   - Ejecuta `flutter analyze && flutter test` y deja un commit limpio si quedaron cambios sueltos.

3. **Wave 2** — despachar A6 y A7 en paralelo. Como `home_tab.dart` lo toca A6 y A7 deja un widget HomeSearchBar pendiente de anclar, el coordinador hace el anclaje manualmente tras recibir los dos reportes.
   - Ejecuta `flutter analyze && flutter test`.

4. **Wave 3** — despachar A8 individualmente.
   - Ejecuta `flutter analyze && flutter test`.

5. **Wave 4 — coordinador final**:
   - `flutter gen-l10n` para regenerar localizaciones con todas las claves añadidas.
   - `flutter analyze && flutter test` final.
   - Smoke test manual (lista detallada en Wave 4 más abajo).
   - Build APK release si el usuario lo pide explícitamente: `flutter build apk --release`.

### Si una tarea falla

- **Compila pero falla un test específico** → el coordinador inspecciona el test, decide si era un edge case real o si el agente lo rompió. Si rompió, despachar un mini-agente correctivo con el brief original + el test failure.
- **No compila** → no avanzar a la siguiente wave. Hacer rollback de los cambios del agente que rompió, repetir con un brief más estricto.
- **Conflicto de archivo entre dos agentes de la misma wave** → el plan está diseñado para que no haya, pero si pasa, el coordinador hace el merge manual y deja registro en su commit.

### Comando de invocación de cada agente (plantilla)

```
Agent({
  subagent_type: "general-purpose",
  description: "<3-5 palabras describiendo la tarea>",
  prompt: <pegar el bloque "### A<N>" completo>
})
```

Despachar varios a la vez = un solo mensaje del coordinador con N bloques `Agent(...)` en paralelo.

### Cómo verificar tras cada wave

```bash
flutter analyze                  # 0 warnings esperado
flutter test                     # 100% verde
flutter run -d <device-id>       # smoke visual manual
```

### Reglas para el coordinador

- **No tocar código de Dart en Wave 4** salvo para resolver conflictos y anclar HomeSearchBar.
- **No saltarse el smoke test final**: el plan está diseñado contra una baseline mock; si algo se ve mal, registrarlo en `docs/historico/INFORME_REPARACION_<FECHA>.md`.
- **No pedir push al remoto** salvo que el usuario lo solicite.

---

## Contexto global del proyecto (incluir en TODOS los briefs)

```
PROYECTO: Transitly (nexto-stop-v2)
DESCRIPCIÓN: App Flutter de transporte público para Jerez (operador COMUJESA, 19
  líneas, 598 paradas geocodificadas reales). Demo académica con datos mock desde
  assets/mock/comujesa_data.json. Sin GTFS-Realtime real, con Supabase opcional
  para auth/repos.
STACK: Flutter 3.9.2+, Riverpod 2.6.1, go_router 17.2.3, flutter_map 7.0.2,
  nfc_manager 3.5.0, supabase_flutter 2.8.0, hive 2.2.3, geolocator 13.0.0.
DIRECTORIO: C:\Users\k\Desktop\all\clase\nexto-stop-v2
RAMA: master

REGLAS OBLIGATORIAS (NO NEGOCIABLES):
1. NUNCA crear valores inline de color, spacing, typography, animation. Usar
   siempre los tokens existentes:
     - lib/core/theme/transit_colors.dart  → TransitColorScheme
     - lib/core/theme/transit_typography.dart → TransitTypography
     - lib/core/theme/transit_spacing.dart → TransitSpacing
     - lib/core/theme/transit_animations.dart → TransitAnimations
2. Reusar widgets compartidos en lib/shared/widgets/ (Pressable, StaggerList,
   GlassCard, TransitButton, RouteCard, StopListItem, StatusBadge, etc.).
3. Nada de Color(0xFF...), SizedBox(height: N), TextStyle(...), Duration(...)
   sueltos fuera de lib/core/theme/.
4. Tras cualquier cambio: `flutter analyze` debe quedar en 0 warnings.
5. Commits en español con prefijo convencional (feat/fix/refactor/chore).
6. NO ejecutar `flutter build apk` ni `git push` salvo que el usuario lo pida.

TESTS:
- `flutter test` para todo el suite
- `flutter test test/features/<feature>/` para uno concreto
```

---

## Mapa de waves

```
WAVE 1 (5 agentes en paralelo, sin solape de archivos)
├── A1  Iconos y splash sin recorte                 [F11]
├── A2  NFC offline-first + Supabase sync            [F9]
├── A3  Rediseño campana notificaciones              [F10]
├── A4  Theming claro/oscuro + accesibilidad total   [F7+F8+route_card refactor de color]
└── A5  Mapa funcional + sheet ajustado              [F1+F2: centro usuario, FAB, flechas, filtros, chips, "Líneas", padding bottom, RouteCard resize]

WAVE 2 (2 agentes en paralelo; depende de Wave 1)
├── A6  Home configurable + Mis paradas              [F6]
└── A7  Buscador unificado + opción "Mi ubicación"   [F3+F4]

WAVE 3 (1 agente; depende de Wave 2)
└── A8  Route planner A→B con transbordos             [F5]

WAVE 4 (coordinador, NO un agente más)
└── Verificación integral, regen l10n, smoke test, build release opcional.
```

### Tabla de solape de archivos por agente

| Agente | Archivos clave que modifica |
|--------|------------------------------|
| A1 | `pubspec.yaml`, `assets/branding/*` |
| A2 | `lib/data/nfc/*` (NUEVO repo), `lib/shared/providers/nfc_provider.dart`, `lib/main.dart`, migración Supabase remota |
| A3 | `lib/features/notifications/widgets/notification_bell.dart` (NUEVO), `lib/features/home/home_shell.dart` |
| A4 | `lib/shared/providers/theme_notifier.dart`, `lib/core/theme/transit_colors.dart`, `lib/core/theme/transit_animations.dart`, `lib/core/theme/high_contrast_theme.dart`, `lib/features/appearance/**`, `lib/features/profile/accessibility_settings_screen.dart`, `lib/app.dart`, `lib/shared/widgets/route_card.dart` (solo refactor de color, sin tocar tamaños), `lib/l10n/*.arb` (añade claves al final) |
| A5 | `lib/features/home/tabs/map_tab.dart`, `lib/features/map/widgets/map_controls.dart`, `lib/features/map/layers/route_direction_arrows.dart` (NUEVO), `lib/features/map/transit_map.dart`, `lib/shared/widgets/route_card.dart` (solo el badge de código L15-EP, sin tocar colores), `lib/l10n/*.arb` (añade claves al final) |
| A6 | `lib/features/home/tabs/home_tab.dart`, `lib/shared/providers/user_favorites_provider.dart` (extender), `lib/shared/providers/home_habitual_config_provider.dart` (NUEVO), `lib/features/home/widgets/habitual_config_sheet.dart` (NUEVO), `lib/features/map/sheets/stop_info_sheet.dart` |
| A7 | `lib/shared/widgets/route_search_bar.dart`, `lib/features/home/tabs/search_tab.dart`, `lib/features/home/widgets/home_search_bar.dart` (NUEVO), `lib/core/router/app_router.dart` |
| A8 | `lib/features/route_planner/*` (NUEVO), `lib/core/router/app_router.dart`, `lib/data/mock/mock_data_service.dart` (lectura) |

**Conflicto controlado A4/A5 en `route_card.dart`:** A4 toca SOLO el `Container` (l. 60-67) reemplazando `Colors.white.withValues(...)` por tokens. A5 toca SOLO el subContainer del código (l. 74-92) cambiando `width: 60` por constraints adaptables. Ambos commitean por separado. Si en la integración hay merge conflict, se resuelve trivialmente.

**Conflicto controlado A4/A5 en `lib/l10n/*.arb`:** ambos añaden claves nuevas. Regla: añadir SIEMPRE al final del JSON, antes del cierre `}`. La regeneración (`flutter gen-l10n`) la hace WAVE 4.

**Conflicto controlado A7/A8 en `app_router.dart`:** A7 añade ruta `/search/places`. A8 añade ruta `/route-plan`. Ambos añaden al final del listado de rutas. Merge trivial. Si Wave 3 (A8) ya empieza después de A7, no hay conflicto temporal.

---

## WAVE 1 — Briefs (despachar en paralelo)

### A1 — Iconos de app y splash sin recorte

```text
ROL: Engineer Flutter de branding/assets.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global" de arriba>

PROBLEMA REPORTADO POR EL USUARIO:
"El icono de la app y de entrada no se ven bien y están cortados."

ANÁLISIS PREVIO (estado actual confirmado leyendo el repo):
- pubspec.yaml líneas 65-73 configura flutter_launcher_icons con
  adaptive_icon_foreground_inset: 16. Para Android adaptive icons la safe zone
  es ~33% del ancho; 16 es insuficiente y el logo aparece recortado en algunos
  launchers que aplican máscaras circulares.
- assets/branding/transitly_logo_white.png se usa tanto para legacy como adaptive.
- NO existe configuración flutter_native_splash en pubspec.yaml; el splash actual
  es la pantalla por defecto.
- Último commit relevante: b499265 "proper app icon setup. Adaptive foreground:
  white logo on transparent with 280px padding (no edge clipping)". Pero el inset
  del pubspec sigue siendo 16, contradice el mensaje.

OBJETIVO:
1. Eliminar el recorte del icono en launchers con máscara circular y oval.
2. Configurar un splash nativo coherente con la identidad (#08081A + logo).

ARCHIVOS QUE PUEDES TOCAR:
- pubspec.yaml (sección flutter_launcher_icons y nueva sección flutter_native_splash)
- assets/branding/ (puedes añadir transitly_logo_white_padded.png si lo necesitas)
- android/app/src/main/res/ (regenerado por flutter_launcher_icons)
- ios/Runner/Assets.xcassets/ (regenerado por flutter_launcher_icons si ios:true)

PASOS:
1. Lee el tamaño actual de assets/branding/transitly_logo_white.png.
2. Si el logo no tiene padding interno suficiente, genera una versión padded:
   - usa un script Dart o ImageMagick para añadir 25% de margen transparente
     alrededor; o crea manualmente transitly_logo_white_padded.png.
3. Actualiza pubspec.yaml:
   flutter_launcher_icons:
     android: "ic_launcher"
     ios: true
     image_path: "assets/branding/transitly_logo_white_padded.png"
     adaptive_icon_background: "#08081A"
     adaptive_icon_foreground: "assets/branding/transitly_logo_white_padded.png"
     adaptive_icon_foreground_inset: 0   # ya está padded internamente
     min_sdk_android: 21
     remove_alpha_ios: true
4. Añade flutter_native_splash en pubspec.yaml:
   dev_dependencies:
     flutter_native_splash: ^2.4.0
   flutter_native_splash:
     color: "#08081A"
     image: assets/branding/transitly_logo_white.png
     android_12:
       icon_background_color: "#08081A"
       image: assets/branding/transitly_logo_white.png
     fullscreen: false
5. Ejecuta:
   flutter pub get
   dart run flutter_launcher_icons
   dart run flutter_native_splash:create
6. Verifica visualmente que los nuevos archivos en android/app/src/main/res/mipmap-*
   muestran el logo SIN recorte (abrir un par de PNG, ej. mipmap-xxxhdpi).

CONSTRAINTS:
- NO toques ningún archivo de Dart.
- NO ejecutes `flutter build apk`.
- Si flutter_native_splash falla porque el .png tiene alpha, fuérzalo
  con remove_alpha_ios:true y/o usa la propia herramienta para resolver.

VERIFICACIÓN:
- `flutter analyze` (debe seguir limpio).
- Listar android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png
  y confirmar que existe.
- Abrir ese PNG y verificar que el logo se ve completo dentro del cuadro.

COMMIT al final:
fix(branding): launcher icons sin recorte + splash nativo

REPORTE FINAL (en tu respuesta de cierre):
- Tamaño original del logo y tamaño del padded.
- Comando ejecutado y output relevante.
- Lista de archivos regenerados en android/ e ios/.
- Cualquier desviación del plan.
```

---

### A2 — Saldo NFC: offline-first con sync a Supabase

```text
ROL: Engineer Flutter de capa de datos + Supabase.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global" de arriba>

PROBLEMA REPORTADO POR EL USUARIO:
"Quiero que el saldo escaneado se guarde en la cache si no hay internet y que
si lo hay se guarde en la base de datos."

DECISIÓN TOMADA CON EL USUARIO:
Supabase si está autenticado + Hive local fallback, con cola de sync que
reintenta al volver el internet.

ANÁLISIS PREVIO:
- lib/data/nfc/nfc_card_service.dart (291 líneas): lee Mifare Classic sector 0
  y 9, bloque 37 = saldo, bloque 0 = card ID. Reintentos backoff exponencial.
- lib/shared/providers/nfc_provider.dart (111 líneas): NfcScanNotifier mantiene
  scanHistory en RAM (máx 10), se pierde al cerrar la app.
- lib/features/home/tabs/card_tab.dart muestra el resultado y un histórico.
- lib/main.dart inicializa Hive y Supabase (verifícalo, está en el código).
- supabase_flutter ^2.8.0 ya está en pubspec.yaml.
- connectivity_plus ^6.1.4 ya está en pubspec.yaml.

OBJETIVO:
1. Crear NfcBalanceRepository que persiste TODOS los escaneos en Hive (siempre)
   y sincroniza a Supabase cuando hay sesión autenticada + internet.
2. Mantener cola de pendientes; reintentar al volver online.
3. Hacer que el histórico sobreviva al cierre de la app.

ARCHIVOS QUE PUEDES TOCAR:
- lib/data/nfc/nfc_balance_repository.dart (NUEVO)
- lib/shared/providers/nfc_provider.dart (cambiar a usar el repo)
- lib/main.dart (abrir Hive box 'nfc_scans')
- lib/features/home/tabs/card_tab.dart (solo si el contrato cambia; idealmente no)
- test/data/nfc/nfc_balance_repository_test.dart (NUEVO)

MIGRACIÓN SUPABASE (aplicar con mcp__supabase__apply_migration tras list_tables):
  create table if not exists nfc_scans (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    card_id text not null,
    balance numeric(10,2) not null,
    scanned_at timestamptz not null,
    created_at timestamptz default now(),
    unique(user_id, card_id, scanned_at)
  );
  create index nfc_scans_user_id_idx on nfc_scans(user_id);
  alter table nfc_scans enable row level security;
  create policy "users read own scans" on nfc_scans for select using (auth.uid() = user_id);
  create policy "users insert own scans" on nfc_scans for insert with check (auth.uid() = user_id);

PASOS:
1. Verifica primero con mcp__supabase__list_tables que la tabla no existe ya
   con esquema distinto. Si existe, AJUSTA la migración para que sea idempotente.
2. Aplica migración con mcp__supabase__apply_migration.
3. En lib/main.dart, dentro de la inicialización Hive, añade:
     await Hive.openBox('nfc_scans');
   (sin sobreescribir otras boxes que ya se abran).
4. Crea lib/data/nfc/nfc_balance_repository.dart con la API descrita en
   "ESQUEMA DEL REPO" más abajo.
5. Refactoriza NfcScanNotifier en lib/shared/providers/nfc_provider.dart:
   - En vez de mantener scanHistory en RAM, llama
     ref.read(nfcBalanceRepositoryProvider).saveScan(result) al éxito.
   - El estado scanHistory se calcula con repo.getHistory() (List<NfcCardResult>).
   - Suscríbete a connectivityProvider (ya existe) y cuando vuelva online llama
     repo.syncPending().
6. Añade test unitario que verifique:
   - saveScan guarda en Hive aunque Supabase falle.
   - syncPending marca como synced las entradas que se subieron OK.
   - Usar mocktail para mockear SupabaseClient y una Box in-memory.

ESQUEMA DEL REPO (Dart):
  class NfcBalanceRepository {
    NfcBalanceRepository(this._supabase, this._hive);
    final SupabaseClient _supabase;
    final Box<dynamic> _hive;

    Future<void> saveScan(NfcCardResult scan) async { ... }
    Future<void> syncPending() async { ... }
    List<NfcCardResult> getHistory() { ... }
    int get pendingCount { ... }
  }

  final nfcBalanceRepositoryProvider = Provider((ref) =>
    NfcBalanceRepository(Supabase.instance.client, Hive.box('nfc_scans')));

CONSTRAINTS:
- NO toques nfc_card_service.dart (la lógica de hardware NFC) salvo que la API
  haya cambiado y haga falta.
- NO añadas dependencias nuevas.
- Respeta el formato de NfcCardResult ya existente.

VERIFICACIÓN:
- `flutter analyze`
- `flutter test test/data/nfc/`
- Comprobar mcp__supabase__list_tables que aparezca nfc_scans con las
  columnas esperadas.

COMMIT al final:
feat(nfc): saldo offline-first con sync a Supabase

REPORTE FINAL:
- Output de la migración Supabase.
- Tests añadidos y resultado.
- Cualquier dependencia inesperada con el resto del código.
```

---

### A3 — Rediseño visual de la campana de notificaciones

```text
ROL: Engineer Flutter de UI/UX.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global" de arriba>

PROBLEMA REPORTADO POR EL USUARIO:
"El botón de notificaciones no me gusta como está quiero cambiarlo."

DECISIÓN TOMADA CON EL USUARIO: rediseño visual completo.

ANÁLISIS PREVIO:
- lib/features/home/home_shell.dart contiene `_NotificationBell` privado en
  líneas 217-281.
- Usa Icons.notifications_active si hay no leídas, Icons.notifications_outlined
  si no, con Badge rojo (count capped a 99+).
- Provider unreadCountProvider ya existe en lib/shared/providers/ (no recrearlo).
- Pantalla destino: /notifications.

OBJETIVO:
Diseñar un widget reutilizable, accesible y visualmente coherente con el resto
del design system (neon/glass, IBM Plex Mono).

ARCHIVOS QUE PUEDES TOCAR:
- lib/features/notifications/widgets/notification_bell.dart (NUEVO)
- lib/features/home/home_shell.dart (eliminar _NotificationBell privado y usar
  el nuevo widget)

ESPECIFICACIÓN VISUAL:
- Botón circular 44x44 (cumple WCAG touch target).
- Fondo: c.bgRaised con borde 0.5px c.border. Si unreadCount > 0, borde sube a
  1.5px y color = c.accent.
- Icono central: Icons.notifications_outlined, color c.textMid en estado idle,
  c.accent si hay no leídas. Tamaño 20.
- Badge: pequeña esfera 8x8 esquina superior derecha, color c.accent, con
  BoxShadow(blurRadius: 8, color: accent.withValues(alpha: 0.5)) para efecto
  neon. NO mostrar número en el badge salvo que unreadCount >= 1 y count != null
  → en ese caso badge se convierte en pill 16x10 con número (max "99+" con
  TransitTypography.bodySmall(c.textHi)).
- Si unreadCount aumentó desde la última vez (compara con valor previo en el
  state), animar el widget con un Tween RotationTransition de -0.05 a 0.05 a
  -0.05 a 0 en 600 ms (3 oscilaciones); luego idle. RESPETA reduceMotion (lee
  themeNotifierProvider.reduceMotion → si true, no animes).
- Semantics label: "Notificaciones, $unreadCount sin leer" (localiza con
  AppLocalizations si añades clave) o usa l10n existente notificationsBellSemantics
  si ya existe — busca antes de crear.

USA SIEMPRE TOKENS:
- Colores → TransitColorScheme
- Tipografía → TransitTypography
- Animación → TransitAnimations (busca duración apropiada; si la mejor opción
  es Duration(milliseconds: 600), añádela como token TransitAnimations.shake
  en lib/core/theme/transit_animations.dart en vez de inline).

INTEGRACIÓN EN HOME_SHELL:
- Reemplaza ambas instancias del _NotificationBell privado (mobile y desktop)
  por NotificationBell(unreadCount: count, onTap: () => context.push('/notifications')).
- Borra la clase _NotificationBell privada.

CONSTRAINTS:
- NO toques la pantalla de notificaciones, solo el botón/campana.
- NO toques themeNotifier ni transit_colors salvo para añadir el token de
  animación si lo decides.

VERIFICACIÓN:
- `flutter analyze`
- Smoke visual: ejecuta `flutter run` (Windows desktop o Android) y observa
  que la campana en el home tiene el aspecto descrito. Si no puedes ejecutar
  el dispositivo, al menos verifica que compila.
- Test widget en test/features/notifications/widgets/notification_bell_test.dart
  que monte el widget con unreadCount 0 y 3 y verifique color del borde.

COMMIT al final:
refactor(notif): rediseño visual de campana de notificaciones

REPORTE FINAL:
- Cambios concretos al estilo.
- Si añadiste algún token en transit_animations, justifícalo.
- Confirmación de que las dos instancias en home_shell se actualizaron.
```

---

### A4 — Theming claro/oscuro real + accesibilidad funcional + árabe

```text
ROL: Engineer Flutter senior, especialista en design system, theming y a11y.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global" de arriba>

PROBLEMAS REPORTADOS POR EL USUARIO (varios, todos relacionados con theming/a11y):
- "Lo de cambiar el fondo y apariencia no hace nada junto con la personalización."
- "El modo claro no va." (al activar, no cambia nada visualmente)
- "En las funciones de accesibilidad ninguna hace nada y falta el árabe como
  opción además de que el de alto contraste no hace nada."

DECISIONES TOMADAS CON EL USUARIO:
- Modo claro: actualmente "no cambia nada visualmente"; arreglar a fondo.
- Árabe ya existe como locale soportada (lib/l10n/app_ar.arb), pero hay que
  asegurarse de que aparezca en el selector y la app cambie a RTL.
- Alto contraste y reduce motion deben tener efecto observable.

ANÁLISIS PREVIO (estado actual confirmado):
- lib/app.dart línea 25 ya conecta `themeMode = ref.watch(themeModeProvider)`.
- lib/app.dart líneas 31-32 llama `themeNotifier.buildTheme(Brightness.light)`
  y `buildTheme(Brightness.dark)`.
- lib/shared/providers/theme_notifier.dart contiene buildTheme(Brightness) en
  ~línea 239-249. Debes verificar si realmente devuelve un ThemeData con
  TransitLightColors cuando se le pasa Brightness.light. Sospecha: el método
  usa la paleta del notifier (que sigue dark) en vez de la light.
- lib/core/theme/transit_colors.dart tiene TransitLightColors (línea 65+) y
  TransitDarkColors. TransitColorScheme.of(isDark) elige la correcta SOLO
  basado en isDark = Theme.brightness == dark.
- lib/shared/widgets/route_card.dart líneas 60-67 tiene Colors.white.withValues(
  alpha:0.10) hardcoded — eso ignora el tema claro. Hay más casos similares.
- lib/features/appearance/widgets/accessibility_section.dart líneas 101-108:
  el switch reduceMotion guarda el bool pero NO se aplica a las animaciones.
- lib/core/theme/high_contrast_theme.dart actualmente solo engrosa bordes; no
  cambia paleta ni opacidades; el usuario no percibe efecto.
- AppLocalizations.supportedLocales ya incluye Locale('ar'), Locale('es'),
  Locale('en').

OBJETIVO:
1. Cuando el usuario cambia a modo claro en BrightnessSection, TODA la app
   cambia (no solo el mapa).
2. Cuando activa "Reducir movimiento", las animaciones de la app desaparecen.
3. Cuando activa "Alto contraste", la UI cambia perceptiblemente.
4. El selector de idioma muestra árabe; al elegirlo, la UI rota a RTL.
5. La pantalla de Apariencia/Personalización refleja los cambios en vivo.

ARCHIVOS QUE PUEDES TOCAR:
- lib/shared/providers/theme_notifier.dart
- lib/shared/providers/theme_provider.dart (si necesario)
- lib/core/theme/transit_colors.dart (verificar paletas light coherentes)
- lib/core/theme/high_contrast_theme.dart (rediseño)
- lib/core/theme/transit_animations.dart (helper para respeto de reduceMotion)
- lib/features/appearance/appearance_screen.dart (sin tocar layout principal)
- lib/features/appearance/widgets/accessibility_section.dart
- lib/features/appearance/widgets/brightness_section.dart
- lib/features/profile/accessibility_settings_screen.dart (asegurar árabe en
  selector)
- lib/app.dart (conexión final)
- lib/shared/widgets/route_card.dart  ←  SOLO el Container externo (l. 60-67)
  reemplazando los `Colors.white.withValues(alpha: 0.10)` y `0.15` por tokens.
  NO toques el subContainer del código de línea (l. 74-92) — ese es propiedad
  del agente A5.
- lib/l10n/app_es.arb, app_en.arb, app_ar.arb (añadir SIEMPRE claves al final
  del JSON, justo antes del cierre `}`)

LISTA DE TAREAS CONCRETAS:

T1. buildTheme realmente cambia con Brightness
   - Abre theme_notifier.dart.
   - Verifica que buildTheme(Brightness b) usa:
       final scheme = b == Brightness.dark ? TransitDarkColors() : TransitLightColors();
   - El ThemeData resultante debe tener colorScheme.brightness == b y
     scaffoldBackgroundColor == scheme.bgRoot.
   - Si highContrast == true, aplica HighContrastTheme.apply(base, scheme).

T2. Eliminar hardcodes en route_card.dart
   - En líneas 60-67, reemplaza:
       color: isDark ? Colors.white.withValues(alpha: 0.10) : c.bgSurface
     por:
       color: c.bgRaised
     Y el border:
       color: c.border
   - Verifica que TransitLightColors.bgRaised y border existen y son coherentes.
   - Si no existen valores light apropiados, AÑÁDELOS a transit_colors.dart con
     colores razonables (consulta valores existentes del dark y haz los light
     más claros). Documenta los valores elegidos.

T3. Audit y limpieza de hardcodes en widgets clave
   - Ejecuta búsqueda: rg "Colors\.white\.withValues" lib/  y  rg "Color\(0xFF" lib/
   - Lista todos los hits FUERA de lib/core/theme/.
   - Por cada hit, sustituye por el token equivalente. Si el caso es trivial
     y aislado, hazlo. Si requiere cambio profundo en un archivo de otro
     agente (especialmente map_tab.dart o home_tab.dart), DOCUMENTA el hit
     en tu reporte para que el coordinador lo arregle posteriormente — NO
     entres en archivos de otros agentes en esta ola.

T4. reduceMotion conectado de verdad
   - Opción A (la más simple, recomendada): en lib/app.dart builder, envuelve
     en MediaQuery con disableAnimations = themeNotifier.reduceMotion:
       final mq = MediaQuery.of(context);
       child: MediaQuery(
         data: mq.copyWith(
           disableAnimations: themeNotifier.reduceMotion || mq.disableAnimations,
           textScaler: TextScaler.linear(combined),
         ),
         child: result,
       )
   - Opción B: en transit_animations.dart añade helper que lea el provider.
     Si vas por B, refactoriza los usos de AnimatedSwitcher / AnimationController
     en widgets clave para que respeten el flag.
   - Recomendación: usa A.

T5. Alto contraste con efecto perceptible
   - Reescribe HighContrastTheme.apply:
       - Reemplaza scheme.bgRaised por colores 100% opacos.
       - Border default → 2 px en lugar de 0.5.
       - Texto textHi → blanco puro en dark / negro puro en light.
       - Glass opacity sube de 0.05 a 0.20.
   - Aplícalo dentro de buildTheme cuando highContrast == true (T1).

T6. Árabe en selector y RTL
   - En lib/features/profile/accessibility_settings_screen.dart (LanguageSection
     ~líneas 316-372), asegúrate de que se itera sobre
     AppLocalizations.supportedLocales y se renderiza una opción para árabe con
     etiqueta "العربية".
   - En lib/features/appearance/* si hay otro selector de idioma, idem.
   - Verifica que MaterialApp respeta el Locale automáticamente para RTL
     (Flutter lo hace si usas `Locale('ar')`); no necesitas envoltorio
     Directionality manual.
   - Si necesitas etiquetas localizadas nuevas (ej. "Idioma" en árabe), añade
     las claves en app_es.arb, app_en.arb y app_ar.arb. SIEMPRE al final del
     JSON.

T7. AccessibilitySection conectado realmente
   - En appearance/widgets/accessibility_section.dart, confirma que:
     - el dropdown ColorBlindMode → ya funciona (matriz aplicada en app.dart).
     - reduceMotion switch → ahora funciona gracias a T4.
     - highContrast switch → ahora funciona gracias a T1+T5.
   - Si encuentras incongruencias (ej. switch que escribe en un provider que
     nadie lee), corrígelo.

CONSTRAINTS DUROS:
- NO toques los archivos del agente A5: lib/features/home/tabs/map_tab.dart,
  lib/features/map/widgets/map_controls.dart, lib/features/map/transit_map.dart,
  lib/features/map/layers/route_direction_arrows.dart.
- En route_card.dart, NO toques el sub-Container del código de ruta (líneas
  ~74-92, el badge "L1"/"L15-EP"). Ese es del agente A5.
- En .arb, añade tus claves SIEMPRE al final del JSON, antes del `}` cierre.
  No regeneres `flutter gen-l10n` — eso lo hace Wave 4.

VERIFICACIÓN:
- `flutter analyze`
- `flutter test` (debería seguir verde; añade test si introduces lógica nueva
  no trivial).
- Smoke manual: arranca la app, ve a Apariencia, cambia a Claro → Mira la
  pantalla de home: debe cambiar también, no solo el mapa.
- Activa "Reducir movimiento" → al cambiar de tab no hay slide.
- Activa "Alto contraste" → fondos sólidos, bordes 2px, textos 100% contraste.
- Cambia idioma a "العربية" → la app rota a RTL, AppBars y listas se alinean
  a la derecha, textos en árabe (verifica al menos 5 cadenas distintas).

COMMIT al final:
fix(theme): modo claro aplica app-wide + a11y real + árabe en selector

REPORTE FINAL:
- Cambios concretos en buildTheme (snippet).
- Lista de hardcodes encontrados fuera de tu scope, con archivo:línea (para
  que el coordinador los pase a otros agentes o resuelva en Wave 4).
- Confirmación de cada T1-T7.
- Claves de .arb añadidas y sus valores en es/en/ar.
```

---

### A5 — Mapa: centro usuario, FAB, flechas direccionales, filtros, dropdown "Líneas", sheet sin recortes

```text
ROL: Engineer Flutter senior, especialista en flutter_map y UX de mapas.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global" de arriba>

PROBLEMAS REPORTADOS POR EL USUARIO (todos del mapa):
- "No hay botón para que te lleve a tu ubicación y el punto de entrada
  siempre es Jerez quiero que el mapa aparezcas tu en el centro y que ya te
  puedas mover."
- "Las líneas de buses no indican en qué dirección van."
- "Los filtros de mapas dejan mucho que desear y no funcionan."
- "En el mapa el desplegable de líneas urbanas no debería salir líneas
  urbanas sino algo como líneas (la app cubre todo tipo de líneas)."
- "El menú donde están las líneas se corta por la parte inferior del nav bar
  y si el tipo de línea por ejemplo l15-ep al ser largo se desestructura y
  se ve mal."

DECISIÓN TOMADA CON EL USUARIO: flechas direccionales sobre los polylines del
mapa.

ANÁLISIS PREVIO (confirmado leyendo el repo):
- lib/features/home/tabs/map_tab.dart línea 144: _requestLocationPermission()
  se llama en initState pero el mapa NUNCA se centra automáticamente en la
  ubicación. La línea 173 lee userLocation pero solo para pintar el marcador.
- MapConfig.defaultCenter = LatLng(36.6850, -6.1261) (centro de Jerez), zoom 13.
- El FAB onCenter (línea 223-230) ya funciona, pero solo se ve si la pantalla
  abre con stream activo (depende de tiempos).
- map_tab.dart línea 383: literal 'LÍNEAS URBANAS' hardcoded. Necesita l10n key.
- map_tab.dart líneas 437-442: chips de tipo solo incluyen [null, urban,
  interurban, metropolitan]. Faltan longDistance, special, school, onDemand
  (ver ServiceType en lib/shared/models/enums.dart).
- map_tab.dart línea 48-51: _filteredRoutes solo aplica _serviceTypeFilter
  local; NO lee mapFilterControllerProvider. Por eso el filter sheet
  (showOfficial, onlyAccessible, onlyFavorites, nextMinutes) no tiene efecto.
- map_tab.dart línea 308: padding bottom del ListView es 24, pero HomeBottomNav
  mide 56 → la última card queda oculta. Confirmar la altura del nav (existe
  como static const en HomeBottomNav, búscalo y úsalo).
- route_polylines.dart NO dibuja flechas direccionales. Hay que añadir capa.
- lib/shared/widgets/route_card.dart líneas 74-92: width fijo 60 del badge
  del código. Códigos largos como "L15-EP" se desestructuran.

OBJETIVO:
1. Centro inicial del mapa = ubicación del usuario (con timeout 4s); fallback
   a Jerez si no hay GPS.
2. FAB "ir a mi ubicación" robusto, funciona aunque el stream todavía no haya
   emitido (pide pos current con timeout 10s).
3. Etiqueta "Líneas" en vez de "LÍNEAS URBANAS" (vía l10n).
4. Chips de tipo cubren todos los ServiceType.
5. Filtros del map_filter_sheet (showOfficial, showCommunity, onlyAccessible,
   onlyFavorites, nextMinutes) realmente afectan al listado y a los polylines.
6. Flechas direccionales sobre los polylines (zoom >= 14).
7. Listado de líneas del sheet ya no se corta por el navbar.
8. RouteCard adaptable a códigos largos como "L15-EP" o "M101-Nocturno".

ARCHIVOS QUE PUEDES TOCAR (exclusivos en esta ola):
- lib/features/home/tabs/map_tab.dart
- lib/features/map/widgets/map_controls.dart
- lib/features/map/transit_map.dart
- lib/features/map/layers/route_direction_arrows.dart (NUEVO)
- lib/shared/widgets/route_card.dart   ←  SOLO el sub-Container del código de
  ruta (líneas ~74-92, el badge "L1"/"L15-EP"). El Container externo (l. 60-67)
  es propiedad del agente A4 — NO lo toques.
- lib/l10n/app_es.arb, app_en.arb, app_ar.arb (añadir clave mapLinesSectionTitle
  al final del JSON)

LISTA DE TAREAS CONCRETAS:

T1. Centro inicial = usuario
   - En map_tab.dart _MapTabState, añade un bool _didInitialCenter = false.
   - En initState, tras _requestLocationPermission(), espera al primer fix con
     timeout: ref.read(userLocationStreamProvider.future).timeout(Duration(seconds: 4))
     y si llega antes, _mapController.move(loc, 14); _didInitialCenter = true.
   - Si timeout, dejar el mapa en defaultCenter sin auto-mover.
   - NO auto-centres después de _didInitialCenter para no fastidiar al usuario.

T2. FAB "mi ubicación" robusto
   - En MapControls.onCenter ya hace move; si valueOrNull es null, intenta
     LocationService.getCurrent() con timeout 10s y luego mueve.
   - Muestra spinner pequeño sobre el FAB durante la espera (parámetro
     loading: bool en MapControls).
   - Si Geolocator.checkPermission == denied, llama Geolocator.requestPermission().
     Si deniedForever, muestra SnackBar con acción "Ajustes" llamando
     Geolocator.openLocationSettings().

T3. Etiqueta "Líneas"
   - En map_tab.dart línea 383, reemplaza el literal por:
       AppLocalizations.of(context).mapLinesSectionTitle
   - Añade la clave en los 3 .arb (al final):
       "mapLinesSectionTitle": "Líneas"     (es)
       "mapLinesSectionTitle": "Lines"      (en)
       "mapLinesSectionTitle": "خطوط"       (ar)
   - NO ejecutes flutter gen-l10n; Wave 4 lo hace.

T4. Chips de tipo completos
   - En map_tab.dart _buildServiceTypeFilter (l. 437-442), reemplaza por:
       final filterTypes = <ServiceType?>[null, ...ServiceType.values];
   - Cambia el Wrap a runSpacing: 6 para que quepa en dos filas si es necesario.
   - Cada chip muestra type?.label ?? 'Todas'.

T5. Filtros del map_filter_sheet conectados
   - En map_tab.dart _filteredRoutes, añade lectura del provider:
       final f = ref.watch(mapFilterControllerProvider);
   - Filtra por:
       - !f.showOfficial → excluir routes con status official
       - !f.showCommunity → excluir routes con status community o proposed
       - f.onlyAccessible → solo routes con al menos 1 stop con isAccessible
         (usar mockData.getStopsForRoute(routeId))
       - f.onlyFavorites → cruzar con ref.watch(userFavoritesProvider).lines
       - f.nextMinutes > 0 → solo routes con próxima salida dentro de N min
         (usar mockData.getNextDepartures(routeId, '', 1).first.scheduled).
   - El resultado debe propagarse a:
       - El ListView del DraggableScrollableSheet (ya lo hace con filteredRoutes).
       - TransitMap.routes (para que route_polylines.dart pinte sólo las
         filtradas — el código ya respeta la lista, basta con pasarle la
         versión filtrada).

T6. Flechas direccionales
   - Crea lib/features/map/layers/route_direction_arrows.dart:
       class RouteDirectionArrows {
         static List<Marker> build({
           required Map<String, Map<int, List<LatLng>>> routePathsLod,
           required int zoom,
           required Color color,
           int minZoom = 14,
         }) { ... }
       }
   - Para cada ruta visible (zoom >= 14), recorre el polyline a LOD más alto
     y cada ~400m coloca un Marker centrado en el punto, ángulo:
         angle = atan2(b.lat - a.lat, (b.lng - a.lng) * cos(a.lat * pi / 180))
   - El Marker contiene Transform.rotate(angle: -angle + pi/2, child:
     Icon(Icons.arrow_upward, size: 14, color: color)).
   - Usa latlong2 Distance().as(LengthUnit.Meter, a, b) para acumular metros.
   - Limita máx 50 flechas por viewport para no degradar FPS.
   - Inserta la capa en transit_map.dart DESPUÉS de los polylines y ANTES
     de los markers de paradas/buses (en MarkerLayer separado).
   - Usa c.accent.withValues(alpha:0.7) como color por defecto.

T7. Padding bottom del sheet
   - En map_tab.dart línea 308, cambia:
       padding: const EdgeInsets.fromLTRB(16, 0, 16, 24)
     por:
       padding: EdgeInsets.fromLTRB(
         16, 0, 16,
         24 + 56 /* HomeBottomNav.height */ + MediaQuery.of(context).padding.bottom,
       )
   - Si HomeBottomNav expone una constante (static const double height = 56),
     impórtala y úsala en lugar de literal.

T8. RouteCard badge adaptable
   - En route_card.dart líneas 74-92, reemplaza `width: 60` por:
       constraints: const BoxConstraints(minWidth: 60, maxWidth: 96),
   - Envuelve el Text(route.code) en:
       FittedBox(fit: BoxFit.scaleDown, child: Text(route.code, ...))
   - Asegura maxLines: 1, overflow: TextOverflow.fade en el Text.
   - Padding interno del Container del código: EdgeInsets.symmetric(
       horizontal: 8, vertical: 10) en lugar del actual.
   - NO toques los `Colors.white.withValues(...)` del Container externo
     (líneas 60-67) — eso es del agente A4.

CONSTRAINTS DUROS:
- NO toques: theme_notifier.dart, transit_colors.dart, high_contrast_theme.dart,
  appearance/**, accessibility_settings_screen.dart, app.dart, home_shell.dart,
  notification_bell.dart, route_search_bar.dart, search_tab.dart, home_tab.dart,
  app_router.dart, route_planner/**.
- En route_card.dart, NO toques el Container externo (líneas 60-67) ni los
  hardcodes de color. Es jurisdicción del agente A4.
- En .arb, añade SOLO mapLinesSectionTitle. No regeneres l10n.

VERIFICACIÓN:
- `flutter analyze`
- `flutter test test/features/map/`  (si hay tests; si no, añade un widget
  test que monte map_tab con userLocation mock y verifique que el controller
  llama move).
- Smoke manual: arranca la app, abre el mapa.
  - Con GPS encendido: en < 4s el mapa centra en tu ubicación.
  - Pulsa el FAB de ubicación → confirma que mueve a tu pos.
  - El header del sheet dice "Líneas".
  - Hay 8 chips de tipo (Todas + 7 ServiceType), en dos filas.
  - Activa "Solo favoritas" en map_filter_sheet → la lista se reduce.
  - A zoom 15+ se ven pequeñas flechas a lo largo de los polylines.
  - Expande el sheet al máximo → la última card queda visible sobre el navbar.
  - Crea un RouteModel mock con code 'L15-EP' o 'M101-Nocturno' → renderiza
    sin truncar.

COMMIT al final:
feat(map): centro usuario, FAB, flechas direccionales, filtros aplicados, "Líneas"
fix(map): padding bottom del sheet y badge adaptable en RouteCard

(haz commits separados si lo prefieres — F1 y F2 son cambios distintos)

REPORTE FINAL:
- Confirmación de cada T1-T8.
- Si HomeBottomNav.height no es static const, lo añadiste o lo dejaste como
  literal.
- Resultado del smoke manual.
- Cualquier sospecha de regresión en zoom-out (flechas no deben saturar).
```

---

## WAVE 2 — Briefs (despachar tras integración de Wave 1)

### A6 — Home configurable + Mis paradas favoritas

```text
ROL: Engineer Flutter senior, especialista en Riverpod y home screens.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global" de arriba>

PROBLEMAS REPORTADOS POR EL USUARIO:
- "En el menu de inicio en lo de tu proximo bus quiero que me deje elegir
  una linea o parada en vez de tener un preset."
- "Paradas cerca de mi funcione realmete y que te indique la distancia de la
  parada."
- "Mis lineas sean aquellas que esten en favoritos o etc y que se añadan
  algo como mis paradas que sean paradas en favoritos y que salgan en cuanto
  pasa el siguiente bus o algo asi."

DECISIONES TOMADAS CON EL USUARIO:
- Próximo bus configurable: botón "Configurar" → modal con selector línea +
  parada.
- Paradas cerca sin GPS: pedir manualmente una parada de referencia.
- Mis paradas: botón estrella en StopInfoSheet para añadir/quitar.

ANÁLISIS PREVIO:
- lib/features/home/tabs/home_tab.dart líneas 25-26 tienen _jerezCenter
  hardcoded → "paradas cerca" siempre usa Jerez ignorando GPS.
- líneas 69-80 calculan habitualFav = favorites.first (preset oculto).
- "Mis líneas" usa mockData.favorites en vez de userFavoritesProvider.lines
  (los favoritos persistidos del usuario).
- NO existe "Mis paradas".
- lib/shared/providers/user_favorites_provider.dart gestiona Set<String>
  lines en Hive box 'userFavorites'. Falta extender con stops.
- StopInfoSheet (lib/features/map/sheets/stop_info_sheet.dart) muestra info
  de una parada al pulsar marker — no tiene botón estrella.

DEPENDENCIAS:
- Asume que Wave 1 (A5) ya añadió el provider userLocationStreamProvider
  utilizable y que map_tab ya centra al usuario.
- Asume que Wave 1 (A4) ya hizo que reduceMotion y light/dark funcionen.

ARCHIVOS QUE PUEDES TOCAR:
- lib/features/home/tabs/home_tab.dart
- lib/shared/providers/user_favorites_provider.dart (extender, NO romper API)
- lib/shared/providers/home_habitual_config_provider.dart (NUEVO)
- lib/shared/providers/home_reference_stop_provider.dart (NUEVO)
- lib/features/home/widgets/habitual_config_sheet.dart (NUEVO)
- lib/features/home/widgets/reference_stop_picker_sheet.dart (NUEVO)
- lib/features/map/sheets/stop_info_sheet.dart (añadir botón estrella)
- test/shared/providers/user_favorites_provider_test.dart (extender)

LISTA DE TAREAS CONCRETAS:

T1. Provider de configuración del viaje habitual
   - Crea HomeHabitualConfig con campos routeId, stopId.
   - HomeHabitualConfigNotifier extiende StateNotifier<HomeHabitualConfig>.
   - Persiste en Hive box 'home_habitual_config' con claves 'routeId', 'stopId'.
   - Métodos: save(routeId, stopId), clear(), get isConfigured.
   - Provider: homeHabitualConfigProvider.

T2. Provider de parada de referencia (fallback sin GPS)
   - HomeReferenceStopNotifier guarda String? stopId en Hive box
     'home_reference_stop'.
   - Métodos: setStop(id), clear().

T3. Sheet de configuración del viaje habitual
   - showHabitualConfigSheet(context, ref): BottomSheet con:
     - DropdownButtonFormField<RouteModel> con todas las routes (mock).
     - Al elegir, DropdownButtonFormField<StopModel> con
       mockData.getStopsForRoute(route.id).
     - Botón TransitButton "Guardar" llama
       ref.read(homeHabitualConfigProvider.notifier).save(routeId, stopId).
   - Usa siempre GlassCard, tokens, TransitTypography.

T4. Sheet de selección de parada de referencia
   - showReferenceStopPickerSheet(context, ref): BottomSheet con TextField
     de búsqueda + ListView filtrado de mockData.stops, al pulsar guarda el id.

T5. home_tab.dart — "Tu próximo bus" configurable
   - Elimina líneas 69-80 que calculan habitual desde favorites.first.
   - Sustituye por:
       final cfg = ref.watch(homeHabitualConfigProvider);
       if (!cfg.isConfigured) {
         return _buildConfigureHabitualCTA(c, () => showHabitualConfigSheet(...));
       }
       final habitualRoute = mockData.getRouteById(cfg.routeId!);
       final habitualStop = mockData.stops.firstWhereOrNull((s) => s.id == cfg.stopId!);
   - CTA: GlassCard con icono Icons.tune, texto l10n.homeConfigureHabitual,
     botón TransitButton "Configurar".

T6. home_tab.dart — "Paradas cerca de mí" con GPS + fallback manual
   - En líneas 82-83, sustituye _jerezCenter por:
       final loc = ref.watch(userLocationStreamProvider).valueOrNull;
       final refStop = ref.watch(homeReferenceStopProvider);
       final center = loc ??
           (refStop != null ? LatLng(refStop.lat, refStop.lng) : null);
       if (center == null) {
         return _buildPickReferenceCTA(c, () => showReferenceStopPickerSheet(...));
       }
   - Para cada nearbyStop, calcula:
       final dist = const Distance().as(LengthUnit.Meter,
           center, LatLng(stop.lat, stop.lng));
   - Usa StopListItem con subtitle: l10n.homeNearbyDistance("${dist.toInt()} m")
     (añade clave en .arb si no existe).
   - Importa `import 'package:latlong2/latlong.dart';` si falta.

T7. home_tab.dart — "Mis líneas" usa favoritos reales
   - En líneas 177-211, cambia la fuente de:
       favorites = mockData.favorites
     a:
       final favIds = ref.watch(userFavoritesProvider).lines;
       final favs = favIds.map((id) => mockData.getRouteById(id)).whereType<RouteModel>().toList();
   - Si favs.isEmpty, muestra empty state con CTA "Marca una línea como
     favorita".

T8. Extender userFavoritesProvider con paradas
   - En lib/shared/providers/user_favorites_provider.dart, añade al state:
       Set<String> stops;
   - Métodos addStop(id), removeStop(id), toggleStop(id), isStopFavorite(id).
   - Persistencia en la misma box 'userFavorites' con clave 'stops'.
   - MANTÉN la API existente para 'lines' intacta para no romper otros agentes.

T9. Sección "Mis paradas" en home
   - Debajo de "Mis líneas" en home_tab.dart, añade una sección nueva con
     título l10n.homeMyStops (añade clave .arb).
   - Para cada stopId en userFavoritesProvider.stops:
     - Resuelve StopModel.
     - Muestra StopListItem con:
       - title: stop.name
       - subtitle: l10n.homeNextBus("$minutes min")  o "Sin próximas salidas"
         usando mockData.getNextDeparturesForStop(stopId, 1).first si existe.
   - Si vacía, empty state "Marca paradas como favoritas desde el mapa".

T10. Botón estrella en StopInfoSheet
    - En lib/features/map/sheets/stop_info_sheet.dart, añade un IconButton en
      la cabecera del sheet:
        final isFav = ref.watch(userFavoritesProvider.select(
            (s) => s.stops.contains(stop.id)));
        IconButton(
          icon: Icon(isFav ? Icons.star : Icons.star_border, color: c.accent),
          tooltip: l10n.actionToggleStopFavorite,
          onPressed: () => ref.read(userFavoritesProvider.notifier).toggleStop(stop.id),
        )
    - Asegúrate de que el StopInfoSheet es ConsumerWidget; si no, conviértelo.

CONSTRAINTS DUROS:
- NO toques app_router.dart (es del agente A7).
- NO toques map_tab.dart, route_card.dart, theme files, ni archivos de Wave 1.
- NO toques los archivos de A7/A8.

VERIFICACIÓN:
- `flutter analyze`
- `flutter test test/shared/providers/user_favorites_provider_test.dart`
- Smoke manual:
  - Fresh install (clear app data): home muestra CTA "Configura tu viaje
    habitual" + CTA "Elige una parada de referencia".
  - Configura → la card de próximo bus aparece y muestra próxima salida.
  - Con GPS apagado: paradas cerca usa la parada de referencia.
  - Con GPS encendido: paradas cerca usa la ubicación real; distancia en m.
  - Marca una parada como favorita en su sheet → aparece en "Mis paradas"
    con su próximo bus.

COMMITS sugeridos (separados):
- feat(home): configurable habitual trip (CTA + sheet)
- feat(home): real distance and reference stop fallback for nearby
- feat(home): favoritos lines + new stops section with bell

REPORTE FINAL:
- Confirma cada T1-T10.
- API de userFavoritesProvider antes y después (mantener compat).
- Claves .arb añadidas.
```

---

### A7 — Buscador unificado + opción "Mi ubicación" como origen

```text
ROL: Engineer Flutter senior, especialista en formularios y autocomplete.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global" de arriba>

PROBLEMAS REPORTADOS POR EL USUARIO:
- "El buscador de rutas no es funcional." (este brief es la parte de UX +
  ubicación como origen; el cálculo A→B real lo hará Wave 3 / agente A8)
- "En el buscador de rutas quiero que puedas poner tu ubicación como una opción."
- "En lo de zona principal quiero que se puedan buscar sitios."

DECISIONES TOMADAS CON EL USUARIO:
- Buscador unificado en home: paradas + líneas + lugares (POI vía Nominatim).
- Opción "Mi ubicación" como origen en el RouteSearchBar.

ANÁLISIS PREVIO:
- lib/features/home/tabs/search_tab.dart actualmente muestra RouteSearchBar +
  EmptyState (UI placeholder). onSearch solo hace setState(_hasSearched=true).
- lib/shared/widgets/route_search_bar.dart es StatefulWidget con dos TextField
  ("Desde..." y "Hasta...") con autocomplete sobre stops. No tiene noción de
  "mi ubicación".
- lib/features/map/widgets/map_search_sheet.dart YA implementa búsqueda
  unificada de rutas+paradas+lugares (Nominatim con bbox Jerez). Solo se
  accede desde el botón lupa del mapa.
- lib/core/router/app_router.dart ya tiene rutas básicas. Añadir /search/places
  y dejar lista para /route-plan (de A8).

DEPENDENCIAS:
- Asume que Wave 1 (A5) hizo que userLocationStreamProvider funcione para
  obtener pos del usuario.
- Asume que Wave 2 (A6) NO toca home_tab.dart después de ti — eso es problema
  de orden temporal: A6 y A7 ambos modifican home_tab.dart. Solución: A6
  termina y commitea antes de que A7 empiece. Si por flujo eso no sucede,
  el coordinador hace rebase manual.

  → POR SI ACASO, A7 NO TOCA home_tab.dart directamente. Añade un nuevo
    widget HomeSearchBar y lo incluye desde un PUNTO DE ANCLAJE en la
    AppBar del home_shell — no en home_tab.dart. Si A6 modificó la AppBar
    del home_shell, A7 hace su edit ahí. Coordinar.

ARCHIVOS QUE PUEDES TOCAR:
- lib/shared/widgets/route_search_bar.dart
- lib/features/home/tabs/search_tab.dart
- lib/features/home/widgets/home_search_bar.dart (NUEVO)
- lib/core/router/app_router.dart  ← añade ruta /search/places al FINAL del
  listado (A8 también añadirá una al final — coordinación: deja una línea de
  separación al cierre).

LISTA DE TAREAS CONCRETAS:

T1. RouteSearchBar como ConsumerStatefulWidget con "Mi ubicación"
   - Convierte de StatefulWidget a ConsumerStatefulWidget.
   - Añade estado bool _useMyLocation = false.
   - Encima del campo "Desde...", añade un Pressable con icono
     Icons.my_location y texto AppLocalizations.useMyLocation (clave nueva).
   - onTap:
       if (!_useMyLocation) {
         setState(() {
           _useMyLocation = true;
           _fromController.text = '';
         });
       }
   - Cuando _useMyLocation == true, el TextField "Desde..." se muestra como
     read-only con valor "📍 ${l10n.myLocation}". Si el usuario hace tap o
     escribe, _useMyLocation = false.
   - Si Geolocator.checkPermission() == denied/deniedForever, deshabilita el
     chip con tooltip "Activa la ubicación" (busca clave existente).
   - Cambia la firma del callback:
       final VoidCallback? onSearch;
       final void Function(StopModel? origin, StopModel? destination, bool useMyLocation)? onSearchWith;
     (mantén compat con onSearch para no romper otros consumidores).

T2. SearchTab dispara navegación al planner
   - En search_tab.dart, sustituye el callback `_hasSearched = true` por:
       onSearchWith: (origin, dest, useMyLoc) {
         if ((!useMyLoc && origin == null) || dest == null) return;
         context.push('/route-plan', extra: {
           'fromStopId': origin?.id,
           'toStopId': dest.id,
           'useMyLocation': useMyLoc,
         });
       }
   - Deja un EmptyState bonito si _hasSearched aún no ocurre (igual que
     ahora).

T3. HomeSearchBar como ancla para "buscar sitios" en home
   - Crea lib/features/home/widgets/home_search_bar.dart:
       class HomeSearchBar extends StatelessWidget {
         const HomeSearchBar({super.key});
         @override Widget build(context) {
           return Pressable(
             onTap: () => context.push('/search/places'),
             child: GlassCard(
               padding: ...,
               child: Row(children: [
                 Icon(Icons.search, color: c.textMid),
                 SizedBox(width: 12),
                 Text(l10n.homeSearchPlacesHint, ...),
               ]),
             ),
           );
         }
       }
   - El widget NO se inserta directamente en home_tab.dart (A6 territory).
     En su lugar, lo dejarás listo y documentado en tu reporte como "anclar
     en home_tab.dart en Wave 4". Eso aísla el conflicto.
     ALTERNATIVA: si A6 ya terminó y commiteó, puedes hacer un pequeño edit
     en home_tab.dart insertándolo al inicio del CustomScrollView. Coordina
     con el coordinador.

T4. /search/places en app_router
   - Añade al FINAL del listado de rutas en lib/core/router/app_router.dart:
       GoRoute(
         path: '/search/places',
         builder: (ctx, st) => const PlaceSearchScreen(),
       ),
   - Crea lib/features/home/screens/place_search_screen.dart (NUEVO, scope
     pequeño) que reutiliza la lógica de map_search_sheet.dart:
       - Header con TextField autofocus + Icon(Icons.search).
       - Lee `mapSearchResultsProvider` (ya existe) y muestra:
           - section "Líneas"
           - section "Paradas"
           - section "Lugares"
       - onTap de resultado:
           - tipo route: context.push('/route/${result.routeId}')
           - tipo stop o place: context.go('/home/mapa', extra: result.latLng)
             y dejar que map_tab.dart centre el mapa allí.
       - Pop al elegir.
   - Importante: el archivo place_search_screen.dart está dentro de tu scope,
     no del agente A6. Justifica si reutilizas widgets de map_search_sheet
     (no romper su API).

T5. Claves .arb
   - Añade SIEMPRE al final de cada arb:
       "useMyLocation": "Usar mi ubicación" / "Use my location" / "استخدم موقعي"
       "myLocation": "Mi ubicación" / "My location" / "موقعي"
       "homeSearchPlacesHint": "Buscar paradas, líneas o lugares..." / etc.
   - NO regeneres l10n; Wave 4 lo hace.

CONSTRAINTS DUROS:
- NO toques home_tab.dart salvo coordinación con A6 (ver T3).
- NO toques map_search_sheet.dart (si necesitas su lógica, extráela a una
  función helper compartida en lib/features/map/widgets/ o duplícala
  superficialmente).
- NO toques nada de Wave 1.

VERIFICACIÓN:
- `flutter analyze`
- Smoke: en pestaña Search, pulsa "Usar mi ubicación" → el campo "Desde"
  cambia de aspecto. Pulsa de nuevo o escribe → vuelve.
- Pulsa "Buscar ruta" sin destino → no navega.
- Con origen + destino, navega a /route-plan (que A8 implementará).
- En home, el HomeSearchBar (cuando se ancle) abre /search/places y permite
  buscar.

COMMIT al final:
feat(search): mi ubicación como origen + buscador unificado de lugares

REPORTE FINAL:
- Confirma T1-T5.
- Indica si pudiste anclar el HomeSearchBar en home_tab.dart o si quedó
  pendiente para Wave 4.
- Claves .arb añadidas.
```

---

## WAVE 3 — Brief (despachar tras Wave 2)

### A8 — Route planner A→B heurístico con transbordos

```text
ROL: Engineer Flutter senior con experiencia en algoritmos de transporte.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global" de arriba>

PROBLEMA REPORTADO POR EL USUARIO:
"El buscador de rutas no es funcional."

DECISIÓN TOMADA CON EL USUARIO: planificador A→B completo.
Implementación heurística: rutas directas + 1 transbordo, ordenadas por
tiempo estimado.

NOTA: la memoria del proyecto desaconseja un route planner real, pero el
usuario lo pidió explícitamente. Su instrucción prevalece. La implementación
es heurística sobre mock data, no Dijkstra completo.

DEPENDENCIAS DE WAVE 2:
- A7 ya dejó la ruta /route-plan disparada desde SearchTab con extra:
  { fromStopId, toStopId, useMyLocation }.

ARCHIVOS QUE PUEDES TOCAR:
- lib/features/route_planner/route_plan_models.dart (NUEVO)
- lib/features/route_planner/route_planner_service.dart (NUEVO)
- lib/features/route_planner/route_planner_provider.dart (NUEVO)
- lib/features/route_planner/route_plan_results_screen.dart (NUEVO)
- lib/features/route_planner/widgets/route_plan_card.dart (NUEVO)
- lib/core/router/app_router.dart  ← añade ruta /route-plan al final.
- test/features/route_planner/route_planner_service_test.dart (NUEVO)

LISTA DE TAREAS CONCRETAS:

T1. Modelos
   class RoutePlanLeg {
     final RouteModel route;
     final StopModel boardStop;
     final StopModel alightStop;
     final int stopsBetween;
     final int estimatedMinutes;
   }

   class RoutePlanResult {
     final List<RoutePlanLeg> legs;
     final int totalMinutes;
     final int totalStops;
     int get transfers => legs.length - 1;
   }

T2. Servicio (sobre MockDataService)
   class RoutePlannerService {
     RoutePlannerService(this._mock);
     final MockDataService _mock;

     List<RoutePlanResult> plan({
       required StopModel from,
       required StopModel to,
       int maxTransfers = 1,
     }) {
       // 1. Para cada ruta que sirve `from`, comprobar si sirve también `to`
       //    con orden de paradas válido (iFrom < iTo). Devolver leg directo.
       // 2. Si maxTransfers >= 1, para cada parada intermedia X en la ruta r1
       //    que pasa por `from`, comprobar si existe r2 que pasa por X y luego
       //    por `to`. Devolver dos legs.
       // 3. Sort by totalMinutes; cap a 5.
     }
   }

   final routePlannerServiceProvider = Provider((ref) =>
       RoutePlannerService(ref.watch(mockDataServiceProvider)));

T3. Provider de resultados (FutureProvider.family)
   final routePlanResultsProvider = FutureProvider.family<
       List<RoutePlanResult>, ({StopModel from, StopModel to})>((ref, args) async {
     return ref.read(routePlannerServiceProvider).plan(from: args.from, to: args.to);
   });

T4. RoutePlanResultsScreen
   - Recibe fromStopId, toStopId, useMyLocation (de extra del router).
   - Si useMyLocation, calcula stop más cercano al usuario:
       final loc = ref.watch(userLocationStreamProvider).valueOrNull;
       if (loc == null) → muestra estado "Activa ubicación"
       else → from = mockData.getNearbyStops(loc.latitude, loc.longitude, 1).first
   - Resuelve to = mockData.stops.firstWhere(id == toStopId).
   - Muestra resultados via routePlanResultsProvider.
   - Estado loading: ShimmerSkeleton.routeCard ×3.
   - Estado vacío: EmptyState con CTA "Probar otras paradas".

T5. RoutePlanCard
   - Para cada result, GlassCard con:
     - Header: "$totalMinutes min · $transfers transbordo(s)"
     - Por cada leg, una row con:
       - Badge del código de línea (reusa estilo de RouteCard si está
         publicado como widget; si no, replica el visual con tokens).
       - Texto: "${leg.boardStop.name} → ${leg.alightStop.name}"
       - Subtitle: "${leg.stopsBetween} paradas · ${leg.estimatedMinutes} min"
     - Si hay transbordo, mostrar entre legs un row con
       Icon(Icons.swap_horiz) + "Cambia en ${leg.alightStop.name}"
     - onTap: ?? (puede navegar al detalle de la primera línea, o quedar
       pasivo).

T6. Ruta /route-plan en app_router
   - Añade al FINAL del listado:
       GoRoute(
         path: '/route-plan',
         builder: (ctx, st) {
           final extra = st.extra as Map<String, dynamic>;
           return RoutePlanResultsScreen(
             fromStopId: extra['fromStopId'] as String?,
             toStopId: extra['toStopId'] as String,
             useMyLocation: extra['useMyLocation'] as bool? ?? false,
           );
         },
       ),

T7. Tests unitarios
   - Caso A: from y to en la misma ruta (orden correcto) → 1 resultado directo.
   - Caso B: from y to en rutas distintas con parada de transbordo común →
     1 resultado con 1 transbordo.
   - Caso C: from y to sin rutas que conecten → lista vacía.
   - Caso D: from y to mismo stop → lista vacía o resultado de 0 min (a tu
     criterio, justifica).
   - Mock MockDataService con datos sintéticos pequeños.

CONSTRAINTS DUROS:
- NO toques data/mock/mock_data_service.dart salvo para añadir un método
  pequeño si lo necesitas (ej. getRoutesServingStop(stopId)). Si lo añades,
  ponlo al final del archivo y documéntalo.
- NO toques route_search_bar.dart, search_tab.dart, home_tab.dart.
- NO toques theme files.

VERIFICACIÓN:
- `flutter analyze`
- `flutter test test/features/route_planner/`
- E2E manual: pestaña Search, elegir dos paradas reales del mock, "Buscar
  ruta" → ver lista de RoutePlanCards ordenadas por tiempo.

COMMIT al final:
feat(planner): planificador A→B heurístico con transbordos sobre mock

REPORTE FINAL:
- Confirma T1-T7.
- Justificación de la heurística (no es Dijkstra).
- Casos de test cubiertos.
- Si añadiste métodos a MockDataService, lístalos.
```

---

## WAVE 4 — Coordinador (NO un agente)

Cuando A1-A8 hayan terminado y reportado, el coordinador (tú, modelo principal)
ejecuta:

1. **Regeneración de l10n**
   ```bash
   flutter gen-l10n
   ```
   Verifica que `lib/l10n/generated/app_localizations_*.dart` se regeneren con
   todas las claves añadidas por A4/A5/A7.

2. **Resolución de conflictos pendientes**
   - Si A4 reportó hardcodes de color FUERA de su scope, los aplicas tú aquí.
   - Si A7 dejó HomeSearchBar pendiente de anclar en home_tab.dart, lo
     anclas (insertando en CustomScrollView entre el SliverPadding inicial y
     "Tu próximo bus").
   - Conflictos de merge triviales en `.arb` y `app_router.dart` se resuelven
     manualmente.

3. **Verificación integral**
   ```bash
   flutter analyze
   flutter test
   ```
   Ambos deben quedar en verde.

4. **Smoke test sobre dispositivo (manual del usuario)**
   - Permitir GPS → el mapa centra en mi ubicación al abrir.
   - Pulsar FAB ubicación → mueve a mi pos.
   - Cambiar tema a Claro → toda la app cambia.
   - Cambiar idioma a Árabe → UI rota a RTL y textos en árabe.
   - Activar Reducir movimiento → no hay animaciones de transición.
   - Activar Alto contraste → bordes 2px, fondos sólidos, texto máx contraste.
   - En Search, escribir 2 paradas + buscar → resultados A→B.
   - Marcar una parada como favorita → aparece en "Mis paradas" del home.
   - Escanear NFC offline (modo avión) → guarda local. Salir/entrar app → sigue.
   - Activar wifi → la entrada NFC se marca como sincronizada (badge desaparece).
   - En el mapa, abrir filtros y activar "Solo favoritas" → la lista de líneas
     se reduce.
   - Sheet de mapa expandido al máximo → la última card visible sobre el navbar.
   - A zoom 15 → flechas direccionales en los polylines.
   - Header del sheet dice "Líneas" (no "Líneas urbanas").
   - Códigos `L15-EP` o `M101-Nocturno` se ven completos en RouteCard.

5. **Build release (opcional, sólo si el usuario lo pide)**
   ```bash
   flutter build apk --release
   ```

---

## Resumen de cobertura de errores

| # | Error del usuario | Agente |
|---|--------------------|--------|
| 1 | Icono y pantalla de entrada cortados | A1 |
| 2 | Buscador de rutas no funcional | A7 (UI + mi ubicación) + A8 (algoritmo) |
| 3 | Cambiar fondo/apariencia/personalización no hace nada | A4 |
| 4 | Sin botón "mi ubicación", mapa no centra en usuario | A5 |
| 5 | Menú de líneas se corta por navbar; códigos largos desestructurados | A5 |
| 6 | Buscador de rutas: opción "mi ubicación" | A7 |
| 7 | Zona principal: buscar sitios | A7 (HomeSearchBar) |
| 8 | Botón notificaciones: cambio visual | A3 |
| 9 | Líneas no indican dirección | A5 (flechas direccionales) |
| 10 | Filtros del mapa no funcionan | A5 |
| 11 | Modo claro no va | A4 |
| 12 | Accesibilidad no hace nada; falta árabe; alto contraste no aplica | A4 |
| 13 | Saldo escaneado: cache offline + BD online | A2 |
| 14 | Home: próximo bus configurable; paradas cerca real con distancia; mis líneas favoritas; mis paradas | A6 |
| 15 | Desplegable "líneas urbanas" → "líneas" | A5 |

(Total 15 errores; el usuario los redactó como un único bloque pero son
~16 puntos independientes — coincide con la cobertura.)

---

## Riesgos y notas

- **A5 toca 5 archivos clave** del mapa; es el agente con más carga. Si tarda,
  el coordinador puede subdividirlo en A5a (centro/FAB/dropdown/chips) y A5b
  (flechas + filtros + sheet padding + RouteCard badge) tras Wave 1 cancelando
  los demás agentes — pero NO recomendado, la coordinación entre archivos
  superpuestos es complicada.
- **A4 puede encontrar hardcodes que afectan a archivos de otros agentes**.
  Si los encuentra, los documenta sin tocarlos; Wave 4 los arregla.
- **A8 depende de la decisión "planner A→B completo"**. Si el usuario
  reconsidera (el proyecto es académico), saltar Wave 3 y dejar SearchTab
  mostrando solo "rutas que pasan por ambas paradas" (variante simple
  implementable en A7 sin un agente nuevo).
- **`flutter gen-l10n`** falla si dos agentes añaden la misma clave con
  cuerpos distintos. Convención: usar prefijos por scope (`map`, `home`,
  `planner`) para evitar colisiones.
- **Supabase migration de A2**: si el proyecto ya tiene tabla `nfc_scans`
  con esquema distinto, A2 debe pedir confirmación antes de aplicar destructive
  changes.
