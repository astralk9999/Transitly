# Revisión independiente integral — Transitly (`nexto-stop-v2`)

> **Óptica:** TFG académico, lente de tribunal, criterio profesional.
> **Fecha:** 2026-05-17 (3.ª pasada, *post* commit `2b1ddf6`).
> **Rama / commit auditado:** `master` @ `2b1ddf6`
> *(remediación P0 → `5077099`/`001e3cf`; P1 seguridad/GDPR/CI → `2b1ddf6`)*.
> **Método:** auditoría escéptica con verificación de **hechos duros
> ejecutados** (`flutter analyze`, `flutter test`, cobertura calculada sobre
> `lcov.info`, `git show` de los fixes, parseo de ARB por clave) + auditoría de
> calidad del propio commit de remediación.
> **Nota de versión:** este documento **sustituye** al estado anterior. Hubo
> dos rondas de remediación: `f53d822` (P0/P1/P2 doc+seguridad) y `5077099`
> (P0/P1 de calidad de código). La revisión refleja el código **tras ambas**.

---

## 1. Hechos duros verificados (ejecutados localmente; CI verificado en GitHub)

| Verificación | Resultado real | Estado anterior | Δ |
|---|---|---|:--:|
| `flutter analyze` | **0 issues** ("No issues found") | 6 info | ✅ **Mejora real** |
| `flutter test` | **148 / 148 passing** (suite completa, exit 0) | 143 | ✅ +5 |
| Cobertura de líneas | **24,74 %** (LH=3860 / LF=15605) | 23,22 % | ✅ +1,52 pp |
| i18n ES/EN | **343 / 343 claves**, 0 diferencias | 278/278 | ✅ +65, sincronizado |
| Auth en capa correcta | `lib/data/auth/` con imports íntegros | en `features/` | ✅ Corregido |
| **CI GitHub Actions** | **`success`** los 3 jobs (`@62f5ee0`) | **rojo desde `de55cb6`** (jamás verde) | ✅ **Arreglado (ver §1bis)** |

**Conclusión:** el commit `5077099` es **trabajo legítimo y verificable**, no
cosmético. Lint a cero, +5 tests, cobertura al alza, i18n ampliado y
sincronizado, y la violación de capas de `auth` corregida. La afirmación
"resolve **all** P0/P1" es, no obstante, **exagerada**: C1 e I2 quedaron
incompletos (ver §3).

---

## 1bis. Hallazgo nuevo (3.ª pasada): el CI **nunca había pasado**

**Severidad: 🟠 Alto (de proceso) — descubierto y resuelto en esta pasada.**

Al verificar el CI en GitHub Actions se descubrió que **todas** las
ejecuciones desde que se añadió el pipeline (`de55cb6 chore(release): add
CI pipeline`) estaban en **rojo** — incluidas las de las dos rondas de
remediación previas. El "CI verde" nunca existió; los "hechos duros" de las
pasadas 1 y 2 eran **solo locales**.

**Causa raíz** (de los logs de Actions, descargados con autenticación
porque la API pública devolvía 403):

```
warning • The asset file '.env' doesn't exist • pubspec.yaml:102:7
Error: Failed to build asset bundle
##[error]Process completed with exit code 1
```

`pubspec.yaml:102` declara `- .env` como **asset bundleado**, pero `.env`
está (correctamente) gitignored → en una checkout limpia de CI no existe →
`flutter analyze`, `flutter test` y `flutter build web` **fallan los tres**
al construir el asset bundle. Es el **mismo anti-patrón SEC2** ya señalado
en este informe; tenía además este efecto colateral oculto que invalidaba
el pipeline entero. Agravante de proceso: `AGENTS.md` y los commits exigían
"`flutter analyze` limpio y tests verdes" por commit, pero **sin CI
operativo** esa garantía nunca se ejerció de forma reproducible.

**Fix aplicado** (`62f5ee0`): paso `cp .env.example .env` antes de instalar
dependencias en los 3 jobs. Se verificó previamente que **ningún test
referencia `Env`/`dotenv`**, por lo que materializar la plantilla no altera
el comportamiento de los 148 tests. Resultado verificado en GitHub: run
`26004101903`, **3/3 jobs `success`** — CI **verde por primera vez en la
historia del repositorio**.

**Deuda residual:** el fix de CI es pragmático y correcto, pero **no cierra
SEC2**: `.env` se sigue bundleando como asset. Lo correcto a futuro sigue
siendo no bundlearlo y pasar a `--dart-define` (documentado en `ci.yml` y en
§5/SEC2).

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

## 4. Puntuación global: **7.7 / 10**

> *Notable técnico, en trayectoria de mejora demostrada. Tres rondas de
> remediación (`f53d822`, `5077099`, `2b1ddf6`) elevaron higiene (lint 0),
> mantenibilidad (descomposición real), capas (auth corregido), honestidad
> documental, i18n, y —en la 3.ª pasada— **seguridad backend, GDPR y CI**.
> La nota pasa 7.0 → 7.5 → **7.7**. El incremento es moderado (+0.2, no más)
> a propósito: las mejoras de la 3.ª ronda son reales pero caen en
> dimensiones intermedias (seguridad/GDPR/CI), **no en los tres lastres que
> fijan el techo y que ninguna ronda ha tocado**: (a) la funcionalidad
> central "tiempo real" (F13) **no existe** (0/12 repos); (b) cobertura
> 24,7 % con auth y la capa `remote` a 0 %; (c) deuda estructural viva
> (doble modelo de usuario, tokens incumplidos en la capa compartida). Hasta
> que no se ataquen esos tres —que exigen *implementar*, no *redactar* ni
> *endurecer*— el techo realista se mantiene por debajo de 8.*

### Desglose por dimensión

| Dimensión | Nota | Δ | Comentario |
|---|---:|:--:|---|
| Arquitectura y código | **7.5** | +0.5 | Auth recolocado, screens descompuestos. Sigue: `web_entry/` muerto, 0 `autoDispose`, 7 modelos manuales. |
| Calidad de implementación | **7.0** | +0.5 | Lint 0, catch logueados. DS aún incumplido en `shared/widgets/` (7 con `GoogleFonts` inline). |
| Backend / seguridad | **7.5** | +0.5 | S1: `redirect:"manual"` + IPv6 privado + DNS anti-rebinding. S2: fail-closed. Resta TOCTOU residual (documentado) y DNS best-effort. |
| Privacidad / GDPR | **8.0** | +1.0 | Revocación efectiva en caliente (`Posthog().disable()`/`SentrySetup.close()` + invalidación de provider); `deleteAccount` roto eliminado, borrado por flujo real. Resta UI `?? true` cosmética. |
| Pruebas | **5.0** | = | 148 reales, `bus_estimator` ejemplar; pero auth + 7 repos `remote` siguen a **0 %**; ~40 % smoke. |
| CI | **6.5** | +2.0 | Flutter 3.35.x alineado a Dart `^3.9.2`, `--coverage` + artefacto, build web release. **Descubierto: el CI nunca había pasado** (asset `.env` ausente, ver §1bis) → arreglado y **verde verificado en GitHub** (`@62f5ee0`). La nota no sube más porque el verde es reciente y sin gate de umbral; penaliza que el rojo perduró sin detectarse en 2 rondas previas. |
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
- ~~**CI1. Pipeline incompleto**~~ → **RESUELTO + agravante descubierto**: no
  solo estaba incompleto, **nunca había pasado** (asset `.env` ausente, ver
  §1bis). Arreglado: Flutter 3.35.x, `--coverage`+artefacto, build release,
  `.env` provisionado → **CI verde verificado en GitHub** (`@62f5ee0`).
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
- ✅ **HECHO:** `import_gtfs` endurecido — `redirect:"manual"` (rechaza 3xx),
  rangos IPv6 privados/ULA/link-local + IPv4-mapped, y resolución DNS A/AAAA
  best-effort anti-rebinding (S1).
- ✅ **HECHO (parcial):** `send_notification` ahora es **fail-closed** — si el
  INSERT en `notifications` falla, aborta y NO envía push (cierra la evasión
  del rate-limit); el TOCTOU residual queda documentado como deuda conocida
  (un límite estrictamente atómico exigiría contador con lock en BD) (S2).
- ✅ **HECHO:** GDPR revocación efectiva en caliente — `Posthog().disable()`
  al revocar analytics, `SentrySetup.close()` al revocar crash_reporting, e
  `ref.invalidate(privacyConsentsProvider)` para reconstruir
  `analyticsServiceProvider` (P1-GDPR); `deleteAccount()` roto **eliminado**
  del interface/impl y el caller redirigido al flujo real
  `data_deletion_requests` + `signOut` + l10n (P2-GDPR).
- ✅ **HECHO + verificado en GitHub:** CI — Flutter `3.35.x` (Dart 3.9 ↔
  `^3.9.2`), `flutter test --coverage` + artefacto lcov, build web release.
  **Hallazgo clave (§1bis):** el CI **nunca había pasado** por el asset
  `.env` ausente; provisionado desde plantilla → **3/3 jobs `success`**
  (`@62f5ee0`, run `26004101903`). **NO** se añadió gate de `dart format`:
  el proyecto no lo usa (AGENTS.md) y forzarlo reformatearía 260 ficheros
  (ruido/riesgo) (CI1).
- ⏳ **PENDIENTE (decisión de diseño):** unificar modelo de usuario
  mock↔Supabase (C2-EST); tests reales de `auth_repository_supabase`.

**P2 — deuda (semanas), no abordada (requiere decisión/alto riesgo visual):**
- Tests de los 7 repos `remote/` (T1); migrar tokens en `shared/widgets/`
  (U1, riesgo de regresión visual); cerrar F26 (necesita binarios de fuente);
  7 modelos a freezed (A3, codegen masivo); `autoDispose` (A2, riesgo de
  ciclo de vida); Semantics vía l10n + suelo 48 dp en `Pressable` (U2).
- **F13 Realtime** (C1-EST): decisión de alcance, no se implementa a ciegas.

---

## 7. Veredicto

El proyecto **ha mejorado de forma medible y honesta** a lo largo de tres
rondas: lint 0 (verificado), 148 tests verdes, cobertura 24,7 %, `auth`
recolocado con integridad de imports, screens descompuestos sin regresión,
i18n 343/343, y en la 3.ª pasada — GDPR con revocación efectiva en caliente,
`deleteAccount` roto eliminado, SSRF de `import_gtfs` endurecido,
`send_notification` fail-closed, CI alineado con cobertura y build de release.
`web_entry/` muerto y los 4 strings ES residuales también quedaron resueltos.
La 3.ª pasada destapó además un fallo de proceso relevante: **el CI nunca
había estado verde** (asset `.env` ausente) — las garantías de "tests verdes
por commit" eran solo locales; ya está arreglado y **verificado verde en
GitHub**.

La nota pasa a **7.7/10**. El +0.2 (no más) es deliberado: las correcciones
fueron numerosas y reales, pero las tres barreras de fondo siguen intactas y
**no son redactables ni endurecibles, hay que implementarlas**: la
funcionalidad "tiempo real" que titula el proyecto no existe (F13, 0/12
repos), la capa de datos de producción está a 0 % de tests, y persiste el
doble modelo de usuario. Para el tribunal: la honestidad documental ya
conseguida convierte F13 y la cobertura en decisiones de alcance defendibles;
el mayor riesgo restante no es el código, es no anticipar esas dos preguntas.
Subir de 7.7 a 8.5 ya no es trabajo de remediación documental o de seguridad
—agotado— sino de implementar Realtime y cobertura de la capa de datos.
