# 05 — Seguimiento, Evaluación y Documentación

**Proyecto:** Transitly (nexto-stop-v2)
**Rama / HEAD original:** `master @ b908f3c`
**Fecha de cierre del anchor original:** 2026-05-23
**Rama / HEAD actualizado:** `master @ 5231f4c` (2026-06-04, +94 commits)
**Release pública distribuida:** v1.11.0 — https://github.com/astralk9999/Transitly/releases/tag/v1.11.0
**Ciclo formativo:** DAM (Desarrollo de Aplicaciónes Multiplataforma)
**Autoria:** Itziar Uruburu Elizalde (autoria individual; asistencia IA documentada).

---

## 1. Procedimientos de control y seguimiento aplicados

El proyecto se ha desarrollado a lo largo de once semanas (01/04/2026 a 16/06/2026) y la disciplina de control se ha apoyado en una idea rectora: la documentación solo cuenta si es **verificable contra el código**. Toda cifra públicada en la memoria del TFG se genera o se contrasta con un script reproducible, y los cierres documentales se aceptan únicamente cuando existe un commit que los respalde.

### 1.1. Integración continua

Se mantiene un pipeline en GitHub Actions (`.github/workflows/ci.yml`) con cuatro trabajos principales ejecutados en cada push y en cada pull request hacia `master`:

1. **Flutter Analyze** — ejecuta `flutter analyze` con el preset `very_good_analysis`. Toda incidencia de tipo error, warning o info bloquea el avance.
2. **Flutter Test** — ejecuta `flutter test --coverage`, sube `coverage/lcov.info` como artefacto, válida el umbral global (24 %) y comprueba budgets por módulo.
3. **Build Web (release)** — compila el target web para detectar regresiones de tree-shaking, tipos y l10n.
4. **Build Android APK / AAB** — construye el APK release con `--split-per-abi`, `--obfuscate` y `--split-debug-info`, válida el budget de tamano (80 MB por ABI) y firma el AAB para verificar el flujo de release completo.

A los cuatro trabajos principales se anaden dos jobs de seguridad (Gitleaks y Semgrep) que actuan como complemento defensivo. Cuando el pipeline esta rojo, no se avanza en plan ni en documentación: la regla es **CI verde antes de cerrar nada**.

### 1.2. Hooks locales (lefthook)

El control en la máquina del desarrollador se ha automatizado con `lefthook`. Las reglas activas son:

- **pre-commit:** `flutter analyze`, `dart format --set-exit-if-changed` y `tool/verify_state.sh`. Garantiza que los datos públicados en `docs/00_MAESTRO.md` (número de tests, migraciónes, features, ARB keys) coinciden con la realidad antes de aceptar el commit.
- **pre-push:** `flutter test` y `flutter analyze`. Evita públicar a remoto un estado que la CI tumbaria.

### 1.3. Auditorias independientes periodicas

Durante el ciclo se han ejecutado tres auditorias formales que actuan como contrapeso al sesgo de autor:

- **2026-04-15:** auditoria inicial sobre el alcance y la arquitectura base.
- **2026-05-17:** auditoria intermedia, documentada en `docs/historico/REVISION_INDEPENDIENTE_2026_05_17.md`, focalizada en deuda de capa de datos y observabilidad.
- **2026-05-22:** auditoria deep-dive con trece sub-agentes en paralelo, archivada en `docs/historico/AUDIT_2026_05_22.md`. Cubrio accesibilidad, RLS, contraste, observabilidad, dependencias, build Android y backend, y produjo la base del plan de remediacion v2.

### 1.4. Code review y plan vivo

Al tratarse de autoria individual, el code review se ha realizado mediante **self-review estructurado sobre pull requests internas**: cada cambio significativo se prepara como rama, se revisa contra los criterios de aceptacion del mega plan y se fusiona solo si los hooks pasan. El plan vivo (`docs/MEGA_PLAN_REFINAMIENTO.md`) clasifica cada ítem en P0-P3 y se actualiza tras cada cierre real.

El documento maestro (`docs/00_MAESTRO.md`) actua como fuente única de verdad: sus cifras se autogeneran con `tool/verify_state.sh`, que cuenta tests, migraciónes, features, ARB keys y commits, y deja constancia del HEAD. Cualquier discrepancia entre lo afirmado y lo medido bloquea el cierre del cambio.

### 1.5. Plan de remediacion v2

Cuando la auditoria del 22 de mayo identifico desviaciones críticas, se redacto un plan de remediacion estructurado (`docs/historico/PLAN_ACCION_REMEDIACION_v2.md`) en seis fases ejecutadas en paralelo: capa de datos, observabilidad, accesibilidad, build Android, backend Supabase y documentación. Cada fase tiene criterios de aceptacion explicitos (grep verificable, commits asociados, tests anadidos) y un responsable IA por fase con supervisión humana.

---

## 2. Registro de incidencias

Las incidencias significativas detectadas durante el desarrollo se han registrado con fecha, descripcion, categoria, severidad y resolucion. Se listan a continuación las doce más representativas; el registro completo, junto con los SHA exactos de los commits que las cierran, vive en el historial de Git y en `docs/historico/`.

| Fecha | Descripcion | Categoria | Severidad | Resolucion |
|-------|-------------|-----------|-----------|------------|
| 2026-04-22 | El APK release no compilaba: `workmanager` arrastraba la antigua v1 embedding incompatible con Flutter 3.x. | Build | Alta | Eliminacion del plugin de `pubspec.yaml` y rebajada de funcionalidad a un `Timer` controlado por `WidgetsBindingObserver`. |
| 2026-04-29 | Drift entre cifras de tests en cinco documentos (175 / 201 / 245 / 292 / 304). | Documental | Media | Creación de `tool/verify_state.sh` y consumo único en `00_MAESTRO.md`. |
| 2026-05-04 | La migración `014_audit_log.sql` duplicaba la tabla introducida en `001_init.sql` con un esquema incompatible. | Backend | Crítica | Renumeracion a `016_data_exports.sql` y conservacion de la auditoria como ampliacion (`011_audit_log_extras.sql`). |
| 2026-05-08 | Bug funcional `onPressed: () {}` en `route_detail_screen.dart` (línea 181) impedia marcar la ruta como favorita. | Funciónal | Alta | Cableado a `userFavoritesProvider` y test unitario que cubre el callback. |
| 2026-05-12 | El color `textLo` fallaba el contraste WCAG AA: 2,2:1 en tema oscuro y 3,1:1 en tema claro. | Accesibilidad | Alta | Aumento de luminancia + script regenerable `dart run tool/contrast_check.dart` integrado en `verify_state.sh`. |
| 2026-05-15 | El proyecto Supabase quedo pausado por inactividad del plan gratuito. | Infraestructura | Media | Reactivacion manual del proyecto y rotacion de la `publishable key` documentada. |
| 2026-05-18 | El scaffold de `integration_test` estaba roto: el paquete no figuraba en `pubspec.yaml`. | Test | Media | Incorporacion de la dependencia y tres pruebas felices (boot, login mock, navegación principal). |
| 2026-05-20 | TalkBack no leia el `_NotificationBell` de la pantalla `home`. | Accesibilidad | Alta | Envolver el icono en `TransitIconButton` con `Semantics(label: ...)` localizado en ES/EN/AR. |
| 2026-05-21 | Cero spans en Sentry pese a que `docs/SENTRY_SPANS.md` describia seis transacciones objetivo. | Observabilidad | Alta | Instrumentacion de las seis transacciones (arranque, mapa, busqueda, login, escaneo NFC, sincronizacion). |
| 2026-05-21 | Cero eventos en PostHog pese a documentarse diecisiete en `docs/POSTHOG_EVENTS.md`. | Observabilidad | Alta | Cableado de los diecisiete eventos en las features correspondientes y test que comprueba el mock client. |
| 2026-05-22 | `AppLogger` quedaba como noop en release, lo que hacia perder los breadcrumbs de Sentry. | Observabilidad | Media | Movimiento de `addBreadcrumb` fuera del bloque `kDebugMode` y test asociado. |
| 2026-05-23 | Factoria de repositorios duplicada en doce providers (código casi identico). | Deuda técnica | Media | Helper `repositoryWithSessionFallback` reutilizable y refactor coordinado de los doce providers. |

El conjunto de incidencias se encuentra cerrado al cierre del anchor (HEAD `b908f3c`), salvo los diecinueve bloqueadores externos enumerados en `docs/EXTERNAL_BLOCKERS.md`, que dependen de servicios o decisiónes fuera del alcance individual (alta en Play Console, certificado Apple, alta de COMUJESA como entidad colaboradora, etc.).

---

## 3. Cambios y mejoras documentados

La evolucion de Transitly se materializa en un historial de commits trazables con la convencion `feat:`, `fix:`, `refactor:`, `test:` y `docs:`. La tabla siguiente resume los grandes bloques de mejora; los SHA exactos pueden consultarse en `git log` y en `CHANGELOG.md`.

| Bloque | Naturaleza | Descripcion | Cobertura tests antes / después |
|--------|------------|-------------|---------------------------------|
| Estabilizacion del build Android | Fix | Eliminacion de `workmanager`, paso a Kotlin DSL puro, signing condicional, ABI splits, `--obfuscate`. | 304 → 314 |
| Saneamiento de migraciónes SQL | Fix | Renumeracion y consolidacion en catorce migraciónes consecutivas con RLS default-deny. | 314 → 334 |
| Refactor de modelos a `@freezed` | Refactor | Veintisiete modelos inmutables con `copyWith`, `==`, `hashCode` y serializacion `json_serializable`. | 334 → 376 |
| Cierre de PRO-A11Y completo | Feat | Contraste regenerable, `textScaler` correcto, semántica localizada en ES/EN/AR, foco visible, tap targets 48 dp. | 376 → 500 |
| Cierre de PRO-Rel (release readiness) | Feat | Pipeline de release con AAB firmado, budget de APK, debug-info archivado, splits ABI. | 500 → 480 (regresion controlada y recuperacion) |
| Observabilidad real | Feat | Seis spans Sentry, diecisiete eventos PostHog, breadcrumbs en release, consent-gating efectivo. | 500 → 523 |
| Capa de datos con repositorio canonico | Refactor | Doce repositorios con domain/remote/local/mock/provider y SWR; helper de fallback de sesión. | 523 → 570 |
| Cierre de PRO-Ops y EXTERNAL_BLOCKERS | Docs + feat | Runbooks operativos, error budget policy, documentación de bloqueadores externos. | 570 → 616 |

El detalle completo (commits + PRs internas) puede consultarse en `git log --oneline` desde el commit raiz hasta `b908f3c`, junto con los archivos `docs/MEGA_PLAN_REFINAMIENTO.md` y `docs/historico/AUDIT_2026_05_22.md`.

---

## 4. Feedback de usuarios

### 4.1. Sesión de validacion (semana 10)

El plan académico contempla una sesión de validacion en la semana 10 del cronograma (prevista para el 04/06/2026) con **cinco usuarios** de perfiles diversos: pasajero senior con baja experiencia digital, pasajero joven habituado a apps de transporte, usuario con visión reducida que utiliza lector de pantalla, conductor en activo y administrador municipal.

### 4.2. Tareas guiadas

Cada participante completa, en orden, las siguientes tareas, observadas por el autor sin intervenir:

1. Crear una cuenta nueva con email y contrasena.
2. Consultar la línea L1 y revisar la siguiente parada.
3. Reportar una incidencia ficticia desde el detalle de la ruta.
4. Cambiar el idioma de la aplicación a ingles y verificar el cambio.
5. Descargar una región offline (Centro de Jerez) y validar la persistencia.
6. Leer una tarjeta NFC simulada para comprobar saldo (mock controlado).

### 4.3. Instrumento de medicion

La medicion principal es el **System Usability Scale (SUS)** clasico, con sus diez ítems en escala Likert de cinco puntos. El objetivo del proyecto es alcanzar una puntuacion media SUS ≥ 75 (umbral de "good" en la escala interpretativa de Bangor, Kortum y Miller). De forma complementaria se registra el tiempo de finalizacion por tarea, los errores observables y las preguntas verbales emitidas por el participante.

### 4.4. Hallazgos preliminares y acciones

A partir de los pilotos internos (autora, dos revisores académicos y un conductor voluntario), los hallazgos cualitativos que ya han generado cambio en código son:

- **Positivo:** claridad de los iconos del bottom navigation, paleta accesible para daltonismo (probada con simulador de Coblis), funcionamiento offline en ausencia de cobertura.
- **A mejorar:** latencia inicial al cargar el mapa con muchas paradas (mitigada con clustering basado en zoom); nomenclatura arabe imprecisa en algunos campos (corregida tras revisión lingueistica de los 628 strings ARB); peso del APK (mitigado con `--split-per-abi` y `--obfuscate`).

La sesión formal con los cinco usuarios externos producira un anexo en `docs/historico/SUS_2026_06_04.md` con los datos en bruto anonimizados y el calculo agregado.

---

## 5. Metricas finales auditadas

Las cifras siguientes son las verificadas en el anchor `master @ b908f3c` mediante `tool/verify_state.sh` y se públican como contrato del cierre del TFG:

| Metrica | Valor | Comentario |
|---------|-------|------------|
| Tests automáticos en verde | **619** | Cobertura distribuida entre widgets, modelos, accesibilidad, utilidades y data layer. |
| Mega plan | **171 / 190 (90,0 %)** | Los diecinueve ítems restantes son bloqueadores externos enumerados en `docs/EXTERNAL_BLOCKERS.md`. |
| Cobertura global de tests | **24-30 %** | Buena en componentes UI y modelos, débil en capa `data/remote` (deuda reconocida y priorizada en P2-4). |
| Migraciones SQL aplicadas | **14** consecutivas | Schema completo con RLS default-deny y funciones helper. |
| Edge Functions desplegadas | **4** | `delete_user`, `import_gtfs`, `purge_old_data`, `send_notification`. |
| Jobs CI en verde | **4 / 4** | Analyze, Test, Build Web, Build Android (más dos jobs auxiliares Gitleaks y Semgrep). |
| ADRs vivos | **5** | Riverpod, Freezed, Hive, Supabase, Feature-first. |
| Runbooks operativos | **6** | Disaster recovery, error budget, migration rollback, push down, Sentry spike, Supabase down. |
| Documentos vivos | **73+** | En `docs/` (incluye `tfg/`, `runbooks/`, `adr/`, `historico/`). |
| Claves ARB | **628** en ES, EN y AR | Cobertura completa de la UI (incluye RTL). |
| Scorecard interno | **TFG 8,9 / 10 — Produccion 6,0 / 10** | Diferenciacion explicita entre madurez académica y madurez productiva. |

---

## 6. Plan de elaboracion de manuales

La documentación entregable se ha estructurado en cuatro frentes complementarios:

1. **Manual técnico (`docs/tfg/06_manual_tecnico.md`).** Cubre requisitos, instalación, configuración avanzada, estructura del repositorio, despliegue de backend Supabase, configuración de CI/CD, mantenimiento rutinario, runbooks resumidos y resolucion de problemas habituales. Es el documento de referencia para cualquier desarrollador que herede el proyecto.
2. **Manual de usuario (`docs/tfg/07_manual_usuario.md`).** Cubre el uso de la aplicación desde la perspectiva del pasajero, conductor y administrador. Incluye capturas, flujos paso a paso y consejos de accesibilidad.
3. **Runbooks operativos (`docs/runbooks/`).** Seis documentos operativos pensados para incidentes reales en producción: recuperacion ante desastre, política de error budget, rollback de migraciónes, caida de push, picos en Sentry y caida de Supabase. Cada runbook sigue la estructura sintoma / diagnostico / contencion / resolucion / postmortem.
4. **Documentación de API (`dartdoc` públicada en GitHub Pages).** Generada automáticamente a partir de los comentarios `///` del código Dart y desplegada en cada release.

---

## 7. Conclusiones de evaluación y lecciónes aprendidas

El proceso de evaluación arroja cinco lecciónes que conviene fijar como aprendizaje del proyecto:

1. **La documentación tratada como contrato verificable evita el drift.** Mientras las cifras se copiaron a mano entre documentos, aparecieron cinco valores distintos del número de tests. Una vez consumidas todas desde `verify_state.sh`, el drift desaparecio.
2. **Una auditoria independiente con trece sub-agentes en paralelo detecta lo que la auto-revisión nunca encuentra.** La pasada del 22 de mayo localizo deuda crítica (observabilidad inexistente, contraste fallido, factoria duplicada) que la auto-revisión habia normalizado.
3. **La asistencia IA como colaboradora exige gobernanza.** Sin un anchor canonico, sin `grep` verificable y sin la regla de "no inventar cifras", la asistencia IA tiende a producir documentos coherentes pero falsos. Con esas tres reglas, su contribucion es trazable y defendible.
4. **Un plan v2 dividido en seis fases con criterios de aceptacion explicitos permite progreso medible.** Cada fase del plan de remediacion tenia criterios de aceptacion expresables como un `grep` o un test, lo que permitio coordinar trabajos en paralelo sin perder el control.
5. **El cierre real (commit + grep) y el cierre documental son distintos; solo el primero cuenta.** Esta disciplina ha sido el principal factor diferenciador entre lo declarado y lo entregable.

El proyecto cumple los objetivos académicos definidos en la fase de planificación y deja, al cierre del anchor, un sistema documentado, auditado y verificable, con un plan público para llevarlo desde "TFG aprobado" hasta "producto en producción".

---

## Adenda — Evolución entre 23/05 y 04/06 de 2026

Tras el cierre del anchor original `b908f3c`, se ejecutaron 94 commits adicionales agrupados en cinco oleadas de estabilización post-MVP. Los hechos más relevantes para esta sección de evaluación son los siguientes:

**Cierre de un crash bloqueante identificado en pruebas de usuario.** Durante las sesiones de prueba con dispositivos físicos del 24-27 de mayo se detectó que la combinación simultánea de varias opciones de accesibilidad (dislexia + alto contraste + escala de texto máxima) provocaba un crash nativo del engine de Flutter no capturable por `try/catch` en Dart. La aplicación quedaba inutilizable y la única recuperación era `adb shell pm clear`. La mitigación implementada (BootCanary + persistencia diferida de preferencias + RecoveryScreen) elimina el riesgo: la app detecta el crash al siguiente arranque, revierte la última preferencia tóxica y, tras dos crashes consecutivos, muestra una pantalla de recovery con `MaterialApp` propio sin shaders ni fuentes custom. El indicador "número de crashes que requieren clear data" pasa de no-cero a cero en los criterios de aceptación operativos.

**Resolución de un error PostgreSQL 42P17 detectado en el flujo post-login.** La carga de "Mis contribuciones" en el perfil fallaba con `PostgrestException: infinite recursion detected in policy for relation route_shares`. Auditadas las políticas RLS de las tres tablas involucradas (`route_shares`, `routes`, `user_routes`), se identificó un ciclo cerrado entre `route_shares_select_owner` y `routes_select_visible`. Se desplegó la migración SQL `fix_route_shares_rls_recursion` que introduce la función `public.is_route_owner(uuid)` con `SECURITY DEFINER` para romper la recursión. Verificación: consulta `SELECT count(*) FROM route_shares` ejecuta sin error tras el deploy. Aumenta en uno el contador de migraciones SQL aplicadas (a 15 totales).

**Release pública v1.11.0 con APK como Release Asset en GitHub.** Hasta la fecha del anchor original, las versiones del APK se versionaban en el directorio `presentation/public/` del repositorio para servirlas desde GitHub Pages. Esta práctica generaba dos problemas: (a) GitHub avisaba (>50 MB) y rechazaría (>100 MB) en versiones futuras; (b) cada APK histórico inflaba el `.git/` indefinidamente. La solución implementada elimina los 9 APKs históricos del `HEAD` (~792 MB liberados), añade `*.apk` a `.gitignore` raíz, y publica el APK v1.11.0 como asset del release oficial. La presentación web enlaza ahora a `releases/latest`, URL estable que apunta siempre a la última versión publicada.

**Bypass documentado de verificación de email.** Como deuda explícita por la imposibilidad de configurar SMTP propio dentro del cronograma del TFG, se bypaseó la verificación de email obligatoria de Supabase. El listener emite `AuthAuthenticated` sin esperar a `emailConfirmedAt`, y `signUpWithEmail` realiza un auto-login defensivo si la configuración del dashboard fuerza la creación de usuarios sin sesión activa. La infraestructura para reactivar verificación (`EmailVerifyPendingScreen`, ruta `/verify-email`) queda intacta y documentada en `docs/SUPABASE_SETUP.md`.

**Logs `warn` y `error` activos en builds de release.** Para diagnosticar el bug del flujo Google Sign-In (descrito en `04_desarrollo_implementacion.md` §11.2) fue necesario eliminar el guard `kDebugMode` en los métodos `warn` y `error` de `AppLogger`. Esta decisión permite observabilidad en producción de errores reales sin inflar `logcat` con ruido (los niveles `debug`, `info` y `perf` siguen siendo debug-only). Refuerza el objetivo no funcional de observabilidad.

Los indicadores cuantitativos del anchor original permanecen vigentes y se complementan con: **release v1.11.0 publicada y descargable**, **migraciones SQL: 14 → 15**, **+94 commits**, **+5 documentos técnicos** en `docs/historico/` (planes de acción de las cinco oleadas), **0 crashes bloqueantes que requieran clear data** tras la mitigación, y **3 widgets configurables vía perfil** con preview en vivo.
