# Revisión independiente integral — Transitly (`nexto-stop-v2`)

> **Óptica:** TFG académico, lente de tribunal, criterio profesional.
> **Fecha:** 2026-05-17 (2.ª pasada, *post* commit `5077099`).
> **Rama / commit auditado:** `master` @ `5077099`
> *("fix(review): resolve all P0/P1 issues from independent code review")*.
> **Método:** auditoría escéptica con verificación de **hechos duros
> ejecutados** (`flutter analyze`, `flutter test`, cobertura calculada sobre
> `lcov.info`, `git show` de los fixes, parseo de ARB por clave) + auditoría de
> calidad del propio commit de remediación.
> **Nota de versión:** este documento **sustituye** al estado anterior. Hubo
> dos rondas de remediación: `f53d822` (P0/P1/P2 doc+seguridad) y `5077099`
> (P0/P1 de calidad de código). La revisión refleja el código **tras ambas**.

---

## 1. Hechos duros verificados (ejecutados en `master @ 5077099`)

| Verificación | Resultado real | Estado anterior | Δ |
|---|---|---|:--:|
| `flutter analyze` | **0 issues** ("No issues found", 19,4 s) | 6 info | ✅ **Mejora real** |
| `flutter test` | **148 / 148 passing** (suite completa, exit 0) | 143 | ✅ +5 |
| Cobertura de líneas | **24,74 %** (LH=3860 / LF=15605) | 23,22 % | ✅ +1,52 pp |
| i18n ES/EN | **343 / 343 claves**, 0 diferencias | 278/278 | ✅ +65, sincronizado |
| Auth en capa correcta | `lib/data/auth/` con imports íntegros | en `features/` | ✅ Corregido |

**Conclusión:** el commit `5077099` es **trabajo legítimo y verificable**, no
cosmético. Lint a cero, +5 tests, cobertura al alza, i18n ampliado y
sincronizado, y la violación de capas de `auth` corregida. La afirmación
"resolve **all** P0/P1" es, no obstante, **exagerada**: C1 e I2 quedaron
incompletos (ver §3).

---

## 2. Remediaciones que SÍ se sostienen (verificadas)

- **C3 — Reubicación de `auth` a `lib/data/auth/`: SÓLIDA.** Rename puro;
  **todas** las referencias actualizadas (12 ficheros: `auth_provider.dart:4-5`,
  `app_router.dart:7`, `privacy_consent_provider.dart:6`, `privacy_screen.dart:10`,
  etc.); 0 imports rotos; no viola `data/` no-depende-de `features/`
  (`auth_repository_supabase.dart` solo importa `supabase_flutter` + `core/`).
- **C2 — 13 `catch (_)` → `AppLogger`: SÓLIDA.** 0 cuerpos `catch{}` vacíos en
  `lib/`; los 13 usan `AppLogger.warn(tag, mensaje-contextual, e)` real, no
  genérico (`firebase_setup.dart`, `theme_notifier.dart:425`, las 6 pantallas
  auth, etc.).
- **M1 — Lint a 0: SÓLIDA.** Verificado por ejecución. Fix real de
  `prefer_const_constructors` en `route_officialize_modal.dart`. *(Matiz: se
  coló un `import 'dart:async';` redundante en `manager_inbox_screen.dart:1`
  que el ruleset no detecta porque `unnecessary_import` no está activo.)*
- **I1 — Descomposición: SÓLIDA, sin regresión.** `appearance_screen.dart`
  1242→**78 L** (orquestador limpio + 8 widgets cohesivos),
  `manager_inbox_screen.dart` 818→**305 L** + 6 widgets. Extracción fiel, sin
  código muerto en los screens. *(Deuda heredada, no nueva: los widgets
  extraídos mantienen `GoogleFonts` inline / `Color(0xFF…)` que ya existían;
  `inbox_action_sheets.dart` 347 L supera la guía de ~300 L de AGENTS.md:116.)*
- **Ronda previa `f53d822` (revalidada):** README honesto, project-ref fuera de
  `015` (git), CORS allowlist, validación de invocador en tiempo constante,
  `search_path` en SECURITY DEFINER, consent-gating en arranque, 6 stubs
  implementados, `offline_banner` con plural ICU.

---

## 3. Remediaciones PARCIALES o exageradas

- **C1 — "55 strings auth a l10n": PARCIAL.** ARB sincronizados (343/343), UI
  estática migrada, pero quedan **4 strings ES de error visibles al usuario**:
  `signin_screen.dart:50` `'Error al iniciar sesión'`, `:53` `'Error de
  conexión'`, `signup_screen.dart:53` `'Error al registrarse'`, `:56` `'Error
  de conexión'` (se asignan a `_error` y se pintan). No es 55/55.
- **I2 — "+5 tests auth": SUPERFICIAL.** De los 5 nuevos en
  `test/features/auth/auth_screen_test.dart`, **4 son smoke triviales**
  (`expect(find.text(...))`); solo 1 verifica comportamiento real. Ninguno
  cubre `auth_repository_supabase.dart` — irónico, siendo el fichero
  protagonista de C3. Sin tests de submit-OK ni de validación de formulario.
- **Guard de rol `/operator-admin`:** añadido pero sigue derivando del modelo
  mock (ver C2 estructural).

---

## 4. Puntuación global: **7.5 / 10**

> *Notable técnico, en trayectoria de mejora demostrada. Las dos rondas de
> remediación elevaron higiene (lint 0), mantenibilidad (descomposición real),
> capas (auth corregido), honestidad documental e i18n. La nota sube de 7.0 a
> 7.5. El techo en 7.5 (no 8+) lo fijan tres lastres **que ninguna ronda
> tocó**: (a) la funcionalidad central "tiempo real" (F13) **no existe**; (b)
> cobertura 24,7 % con auth y la capa `remote` a 0 %; (c) deuda estructural
> viva (doble modelo de usuario, código muerto `web_entry/`, tokens
> incumplidos en la capa compartida, GDPR sin revocación efectiva).*

### Desglose por dimensión

| Dimensión | Nota | Δ | Comentario |
|---|---:|:--:|---|
| Arquitectura y código | **7.5** | +0.5 | Auth recolocado, screens descompuestos. Sigue: `web_entry/` muerto, 0 `autoDispose`, 7 modelos manuales. |
| Calidad de implementación | **7.0** | +0.5 | Lint 0, catch logueados. DS aún incumplido en `shared/widgets/` (7 con `GoogleFonts` inline). |
| Backend / seguridad | **7.0** | = | RLS default-deny coherente, `search_path` fijado. Restan SSRF incompleto y rate-limit con fuga. |
| Privacidad / GDPR | **7.0** | = | Opt-out real verificado. Baja por revocación sin efecto hasta reiniciar y `deleteAccount` roto. |
| Pruebas | **5.0** | +0.5 | 148 reales, `bus_estimator` ejemplar; pero auth + 7 repos `remote` siguen a **0 %**; ~40 % smoke. |
| CI | **4.5** | = | Sin coverage gate, sin `dart format`, sin build release, Flutter 3.32.x vs Dart `^3.9.2`. |
| Documentación / coherencia | **7.5** | = | README honesto y verificable; commits trazables. Resta F26 abierto. |
| Accesibilidad | **6.5** | = | Esfuerzo real; "AA parcial" defendible, "AA" pleno no. |
| Rendimiento | **6.5** | = | `smoke_background` cuidado; falta `RepaintBoundary` en `features/`. |
| Integridad académica | **8.0** | = | Asistencia IA declarada; trazabilidad por fases y por commits de review. |

---

## 5. Hallazgos vivos por severidad (NO resueltos por ninguna ronda)

### 🔴 Crítico — el techo real de la nota

**C1-EST. Realtime (F13) inexistente.** 0 de 12 repos `remote/` tienen
`stream()` funcional: `stop_remote_repository.dart:59-63`,
`route_remote_repository.dart:47-50`, `bus_location_remote_repository.dart:34-37`
son `yield await <snapshot>;` + comentario "F13 conectará…". El "bus en tiempo
real" es simulación mock. El README lo declara (`README.md:22-24`) → riesgo
documental bajo, pero funcionalmente "lo que da nombre al proyecto no se
demuestra".

**C2-EST. Doble modelo de usuario.** `currentUserProvider`
(`user_provider.dart:8-22`) deriva de `mockData.users` filtrado por
`isDriverModeProvider` (StateProvider mutable); el guard del router
(`app_router.dart:107-108`) usa ese mock, desconectado de
`AuthRepositorySupabase`. Control de rol frágil; la seguridad real es solo RLS
server-side.

### 🟠 Alto

- **S1. Anti-SSRF incompleto en `import_gtfs`** — valida hostname textual antes
  de DNS y `redirect:"follow"`: vulnerable a DNS rebinding / 302 a IP interna /
  IPv6 privado. Mitigado por requerir token admin.
- **S2. Rate-limit de `send_notification` evadible** — conteo no atómico
  (TOCTOU), sigue enviando push si el INSERT falla, es por destinatario.
- **T1. Capa de datos de producción a 0 % de tests** — `auth_repository_supabase`
  (que C3 acaba de mover) y los 7 repos `remote/` sin un solo test; wizard
  `route_editor/steps/*` a 0 %.
- **U1. Tokens incumplidos en la capa compartida** — 7 widgets de
  `lib/shared/widgets/` re-implementan `GoogleFonts.*`/colores literales
  (`route_card.dart:89-94,107-111,150-154`, `empty_state.dart:49-52`, etc.).
  Contradice AGENTS.md:114 ("tokens no se duplican"). La descomposición I1
  propagó este patrón a los nuevos widgets en vez de saldarlo.

### 🟡 Medio

- **A1. Código muerto `lib/web_entry/`** — `admin_main.dart`/`editor_main.dart`/
  `map_main.dart` byte-idénticos, sin referencias; contradice la narrativa
  "Flutter Web islands".
- **A2. 0 `autoDispose` en 56 providers.**
- **A3. 7 modelos manuales fuera de freezed** (`achievement_model.dart`, …).
- **P1-GDPR. Revocación de consentimiento sin efecto hasta reiniciar** —
  `privacy_screen.dart:49-54` solo persiste en BD; 0 llamadas a
  `Posthog().disable()`; PostHog sigue activo tras revocar en la misma sesión.
  Defecto de cumplimiento real.
- **P2-GDPR. `deleteAccount()` roto** — `auth_repository_supabase.dart` usa
  `auth.admin.deleteUser` (requiere `service_role`); falla con anon key.
- **SEC1. PAT de Supabase real en `.mcp.json`** (gitignored, no en git —
  correcto) con **alcance de cuenta**. **Rotarlo**: queda expuesto en disco y
  herramientas; más sensible que el `ANON_KEY`.
- **SEC2. `.env` empaquetado como asset** (`pubspec.yaml:102`) — extraíble del
  APK. Riesgo bajo hoy (solo `ANON_KEY` público) pero anti-patrón; mover a
  `--dart-define` antes de añadir cualquier clave con coste.
- **CI1. Pipeline incompleto** — sin coverage gate, sin `dart format
  --set-exit-if-changed`, sin build de release, Flutter 3.32.x vs Dart `^3.9.2`.
- **C1-resid. 4 strings ES de error en pantallas auth** (ver §3).
- **U2. "WCAG AA" defendible solo como "parcial"** — mapa sin `Semantics`,
  Semantics en ES hardcodeado, `Pressable` sin suelo 48 dp, `textScaler` pisa
  el del SO.

### 🔵 Bajo

- **B1.** `import 'dart:async';` muerto colado en `manager_inbox_screen.dart:1`
  (no detectado: `unnecessary_import` desactivado).
- **B2.** Ruido `[WARN] supabase ... must initialize` durante `flutter test`.
- **B3.** ~26–42 `Color(0x…)` y ~264–338 `EdgeInsets.*` literales en `lib/`.
- **B4.** Imports relativos profundos sin alias `package:`.
- **B5.** ~~README dice "275 keys / 16 migrations"; real **343 claves / 13
  ficheros**~~ → **RESUELTO**: README actualizado a 343 claves / 13 migraciones
  y referencia a `lib/web_entry/` eliminada.
- **B6.** `inbox_action_sheets.dart` 347 L > guía ~300 L (AGENTS.md:116).

---

## 6. Plan priorizado (estado vivo)

**P0 — antes de la defensa (horas):**
- ⚠️ **PENDIENTE (acción externa, no automatizable):** rotar el PAT de
  `.mcp.json` (SEC1) desde el dashboard de Supabase.
- ✅ **HECHO:** migrados los 4 strings ES de error residuales a l10n
  (`signin_screen`/`signup_screen` → `authSignInError`/`authSignUpError`/
  `authErrorConnection`, claves ya existentes) (C1-resid).
- ✅ **HECHO:** README actualizado a 343 claves / 13 migraciones (B5).
- ✅ **HECHO:** `lib/web_entry/` (código muerto, 3 ficheros idénticos sin
  referencias) eliminado; referencia en README quitada (A1).
- ⏳ **Discurso de defensa (no es código):** presentar F13 como "arquitectura
  preparada, integración = trabajo futuro"; demostrar el Realtime real de
  notificaciones.

**P1 — calidad/seguridad (días):**
- Endurecer `import_gtfs` (resolver IP final + `redirect:"manual"`) (S1) y
  rate-limit atómico en `send_notification` (S2).
- GDPR: `Posthog().disable()` + invalidar `analyticsServiceProvider` al revocar;
  eliminar/reubicar `deleteAccount()` (P1/P2-GDPR).
- Unificar modelo de usuario mock↔Supabase (C2-EST).
- CI: coverage gate + `dart format` + build release + alinear Flutter/Dart.
- Tests reales de `auth_repository_supabase` (cierra el gap irónico de C3/I2).

**P2 — deuda (semanas):**
- Tests de los 7 repos `remote/` (T1); migrar tokens empezando por
  `shared/widgets/` (U1); cerrar F26; 7 modelos a freezed (A3); `autoDispose`
  (A2); Semantics vía l10n + suelo 48 dp en `Pressable` (U2).

---

## 7. Veredicto

El proyecto **ha mejorado de forma medible y honesta** entre rondas: lint 0
(verificado), 148 tests verdes (+5), cobertura 24,7 % (+1,5 pp), `auth`
recolocado con integridad de imports, screens descompuestos sin regresión, i18n
ampliado y sincronizado (343/343). El commit `5077099` es trabajo real; su
único pecado es el rótulo "**all** P0/P1" cuando C1 (4 strings) e I2 (4/5 tests
smoke, sin cubrir el repo Supabase) quedaron a medias.

La nota sube a **7.5/10**. No llega a 8+ porque las tres barreras de fondo
siguen intactas y **no son redactables, hay que implementarlas**: la
funcionalidad "tiempo real" que titula el proyecto no existe (F13, 0/12 repos),
la capa de datos de producción está a 0 % de tests, y persiste deuda
estructural (doble modelo de usuario, `web_entry/` muerto, tokens incumplidos
en la capa canónica, GDPR sin revocación efectiva). Para el tribunal: la
honestidad documental ya conseguida convierte F13 y la cobertura en decisiones
de alcance defendibles; el mayor riesgo restante no es el código, es no
anticipar esas dos preguntas.
