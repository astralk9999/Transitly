# 04 — Desarrollo e Implementación

**Proyecto:** Transitly
**Repositorio:** nexto-stop-v2 (`master @ b908f3c`)
**Pila tecnológica principal:** Flutter 3.x · Dart 3 · Riverpod 2.6 · GoRouter 17 · Freezed 3 · Supabase (PostgreSQL + Auth + Edge Functions) · Hive 2.2 con cifrado AES en cajas sensibles · Firebase Messaging 16 · Sentry 8 · PostHog 5 · `flutter_secure_storage` · `very_good_analysis` · `leak_tracker_flutter_testing`
**Indicadores verificados a 23/05/2026:** 616 *tests* pasando, 14 migraciones SQL consecutivas, 27 *features*, 4 Edge Functions desplegadas, 5 ADRs, 6 *runbooks*, 171/190 ítems del plan mega cerrados (90,0 %), 19 bloqueadores externos documentados, 628 claves ARB (español, inglés y árabe), 4 *jobs* de CI en verde, *scorecard* TFG 8,9/10 y producción 6,0/10

---

## 1. Metodología real aplicada

La metodología que ha guiado la construcción del producto se asienta
sobre tres pilares: un enfoque **feature-first**, una variante de
**Scrum solo** con sprints semanales y un compromiso estricto con la
**trazabilidad** mediante *Conventional Commits* y CI bloqueante.

### 1.1. Feature-first y sprints semanales

El árbol `lib/features/` agrupa 27 *features* autocontenidas, cada una
con su pantalla, sus *providers* Riverpod y, cuando procede, sus
*widgets* internos. Las dependencias entre *features* se modelan a
través de la capa `lib/data/`, lo que evita acoplamientos transversales
y permite que cada sprint semanal se dedique a una o dos *features*
nuevas, una integración o una fase de pulido. La planificación de cada
sprint se realiza los lunes y el cierre el domingo, con verificación
explícita (analyze, test, CI verde) antes de pasar al siguiente.

### 1.2. *Conventional Commits* y *release-please*

Todos los *commits* siguen el estándar *Conventional Commits*. Los
prefijos en uso son `feat`, `fix`, `docs`, `test`, `chore`, `refactor`,
`perf`, `ci`, `build` y `revert`. Esta disciplina permite a
*release-please* generar automáticamente el `CHANGELOG.md` y proponer
versiones SemVer. Los mensajes están redactados en imperativo y
describen el "porqué" cuando no es obvio.

### 1.3. *Code review* propia mediante PRs auto-revisión

El proyecto es individual, pero todo cambio de cierto calado se
introduce mediante *pull request*. La auto-revisión tiene un propósito
auditable: forzar que CI ejecute las verificaciones automáticas
(analyze, test, build-web, build-android, gitleaks, semgrep) antes de
incorporar el cambio a `master`. Esa disciplina ha permitido detectar
regresiones y mantener los 4 *jobs* en verde de forma sostenida.

### 1.4. Asistencia de IA documentada

El proyecto ha utilizado asistencia de IA para redacción, generación
inicial de *boilerplate* y revisión cruzada. La declaración es
explícita y se hace por integridad académica. Cada *commit* lleva la
huella del autor, los *prompts* relevantes están archivados y el
contenido se revisa, atribuye y firma como propio.

---

## 2. Arquitectura implementada

Las decisiones de fondo están registradas en cinco **Architecture
Decision Records (ADR)**:

| ADR | Decisión | Motivo principal |
|-----|----------|------------------|
| 001 | Riverpod 2.6 como gestor de estado | Tipado fuerte, sin código generado obligatorio, *autoDispose* y `.family` idóneos para una app de movilidad con sesiones cortas |
| 002 | Freezed 3 para *value objects* | Inmutabilidad, igualdad estructural y `copyWith` sin *boilerplate* |
| 003 | Hive 2.2 para almacenamiento local | Velocidad, soporte de cifrado AES vía `HiveAesCipher`, ausencia de SQL en cliente |
| 004 | Supabase como *backend* | PostgreSQL con RLS nativo, Auth integrada, Edge Functions en Deno, *free tier* viable |
| 005 | Feature-first como organización | Escala mejor que *layer-first* cuando el equipo es pequeño y las *features* son verticales |

### 2.1. Capas

```text
lib/
  main.dart            Bootstrap secuencial
  app.dart             MaterialApp.router + tema + locale
  core/                Tokens, router, utils, theme
  data/                Repositorios + cache + sync (12 dominios)
  features/            Feature-first (27 features)
  l10n/                ARB + generated (es, en, ar) — 628 claves
  shared/              Modelos, providers y widgets reutilizables
```

### 2.2. Patrón canónico de repositorio con SWR

Cada dominio sigue el patrón **domain / local / remote / mock**:

```text
lib/data/<entity>/
  domain/<entity>_repository.dart       interfaz abstracta
  remote/<entity>_remote_repository.dart cliente Supabase
  local/<entity>_local_repository.dart   Hive
  local/<entity>_mock_repository.dart    modo invitado
  <entity>_repository_provider.dart     Riverpod SWR + selector
```

De los 12 dominios cableados, **4 funcionan sin SWR** por motivos
documentados: `auth` (la sesión la gestiona el SDK de Supabase),
`analytics`, `privacy_consent` y `nfc` (no requieren cache porque su
estado lo manda el dispositivo o el cliente *backend* en tiempo
constante).

### 2.3. Riverpod y *autoDispose*

Riverpod 2.6 expone `Provider`, `FutureProvider`, `StreamProvider`,
`StateProvider` y `NotifierProvider`. Los providers que mantienen
suscripciones (canales *realtime*, *streams* de notificaciones) usan
`autoDispose` para cerrar recursos cuando ningún consumidor está
escuchando. Los providers parametrizables emplean `.family` para
evitar instanciaciones duplicadas.

### 2.4. Navegación con GoRouter 17

GoRouter aporta navegación tipada, soporte declarativo de *deeplinks*
y *shell routes* para el chasis principal (rail/bottom según anchura).
Los *guards* de autenticación viven en `redirect_guards.dart` y
consultan el rol REAL del perfil en Supabase, no un estado mutable
local.

---

## 3. Integración de bases de datos

### 3.1. Supabase (PostgreSQL)

El *backend* descansa en una instancia Supabase con PostgreSQL como
motor relacional. La política RLS es **DENY-by-default**: ninguna
tabla con datos sensibles concede acceso sin una *policy* explícita.
La seguridad se apoya en dos helpers `SECURITY DEFINER`,
`is_admin(uuid)` e `is_moderator_or_admin(uuid)`, con `search_path`
fijado para evitar suplantación. Cada *policy* lleva su `COMMENT ON
POLICY` con el caso de uso que la justifica, y existe una **separación
estricta entre `service_role` y `anon`** para evitar escaladas.

| Indicador | Valor |
|-----------|-------|
| Migraciones SQL versionadas | 14 consecutivas (001 a 013 y 016) |
| Tablas en `public` | 16 |
| Helpers `SECURITY DEFINER` | 2 (`is_admin`, `is_moderator_or_admin`) |
| Política por defecto | DENY-by-default |
| Separación de claves | service_role frente a anon |

### 3.2. Hive local

Hive 2.2 actúa como **cache offline-first**. En total se utilizan 16
*boxes*, de las cuales tres almacenan información sensible y se cifran
con `HiveAesCipher`:

| Box | Cifrado | Contenido |
|-----|:------:|-----------|
| `authSessionMeta` | Sí (AES) | Metadatos de sesión auth |
| `userPreferences` | Sí (AES) | Preferencias personales |
| `pendingActions` | Sí (AES) | Cola offline de acciones del usuario |
| `routes`, `stops`, `schedules`, ... | No | Datos públicos del operador (rendimiento prioritario) |

La clave de cifrado se conserva en `flutter_secure_storage` y nunca
abandona el dispositivo.

---

## 4. Integración multimedia

| Recurso | Tecnología | Notas |
|---------|------------|-------|
| Caché de *tiles* del mapa | `flutter_map_tile_caching` v10 | Política LRU con evicción configurable; mapa usable sin conexión |
| Tipografías empaquetadas | DM Sans (variable) + IBM Plex Mono en tres pesos (400, 500, 700) | *Assets* locales para evitar dependencias en red y descargas remotas |
| Logotipo y marca | PNG en `assets/branding/` | Distribuido junto al APK |
| *Shaders* | GLSL custom (`shaders/smoke.frag`) | Fondos animados sin coste de imagen |

La estrategia general es **empaquetar todo lo que se pueda** para que
la app arranque y funcione sin red, salvo la consulta al *backend* y
las descargas opcionales de *tiles* nuevos.

---

## 5. Integración de interfaces

### 5.1. Sistema de diseño propio

El sistema reside íntegramente en `core/theme/` y se compone de cuatro
fuentes únicas de verdad:

- `transit_colors`: paleta semántica (no colores crudos).
- `transit_typography`: escalas tipográficas.
- `transit_spacing`: rejilla de 4 puntos.
- `transit_animations`: duraciones y curvas reutilizables.

Está prohibido duplicar *tokens*; los *widgets* compartidos los
consumen y nunca los re-implementan.

### 5.2. Tema accesible

El tema incorpora ocho matrices de **simulación de daltonismo**
(deuteranopia, protanopia, tritanopia, acromatopsia y variantes
parciales), un modo de **alto contraste** y un escalado tipográfico
compuesto: se respeta el factor del sistema operativo mediante
`MediaQuery.textScalerOf` y se *clampa* internamente entre 0,8 y 2,5
para evitar que la interfaz se rompa con valores extremos. Los
*widgets* compartidos están auditados con *tests* de semántica.

### 5.3. *Responsive scaffold*

El chasis principal adapta su patrón de navegación al ancho de la
pantalla: *bottom navigation bar* en móviles, *navigation rail* en
tabletas y escritorio. La decisión es declarativa según *breakpoints*
publicados en `core/theme/`.

### 5.4. Localización

`flutter_localizations` con tres locales activos (español como
fuente, inglés y árabe). El recuento actual es de **628 claves ARB**
mantenidas con paridad estricta. La dirección RTL está soportada para
árabe.

---

## 6. Integración de servicios externos

### 6.1. Edge Functions Deno

Hay **cuatro Edge Functions desplegadas** en Supabase, todas escritas
en Deno y con `verify_jwt` habilitado cuando la naturaleza del *endpoint*
lo permite:

| Función | Propósito | Notas |
|---------|-----------|-------|
| `send_notification` | Envío *push* a través de FCM HTTP v1 | OAuth JWT firmado en Deno; *fail-closed* si falla la persistencia |
| `import_gtfs` | Importación de feeds GTFS | Anti-SSRF: resolución DNS estricta, redirecciones manuales, rangos privados bloqueados |
| `delete_user` | Borrado total (Art. 17 GDPR) | Limpia perfil, datos derivados y referencias |
| `purge_old_data` | Minimización (Art. 5 GDPR) y purga de datos antiguos | Ejecutada por `cron`; idempotente |

### 6.2. Firebase Messaging

`firebase_messaging` 16 gestiona los *tokens* del dispositivo y la
recepción de mensajes. En Android se declara el canal
`transitly_push` en el manifiesto. En iOS se preparan los
*entitlements* de APNs y los `UIBackgroundModes` necesarios. Los
*deeplinks* incluidos en el *payload* se consumen tanto en
*foreground* como en *background* y en estado *killed* mediante la
política recomendada por el SDK.

### 6.3. Observabilidad: Sentry y PostHog

**Sentry 8** instrumenta **seis transacciones** representativas:

1. `auth.signIn`
2. `auth.refresh`
3. `map.initial_render`
4. `nfc.read`
5. `network.fetch_routes`
6. `push.send`

El *hook* `beforeSend` *scrubba* sistemáticamente datos personales
identificables: correos electrónicos, *tokens* `Bearer`, *query
parameters* sensibles y cabeceras `Authorization`.

**PostHog 5** registra **17 eventos** funcionales (entre ellos
`signup_completed`, `route_viewed`, `incident_reported` y los
correspondientes a las pantallas críticas). El *autocapture* está
**desactivado** por defecto y el opt-out es la posición inicial; toda
captura requiere consentimiento explícito (*consent-gated*).

### 6.4. Almacenamiento seguro

`flutter_secure_storage` conserva las claves AES de Hive y los *tokens*
ofuscados que requieran persistir entre arranques.

---

## 7. Pruebas técnicas

La suite actual cuenta con **616 *tests* pasando**. Esta cifra se
verifica en el `commit` de cabecera (`master @ b908f3c`). El
desglose aproximado por categoría es el siguiente:

| Categoría | Cantidad aproximada | Foco |
|-----------|:-------------------:|------|
| Unitarios | ≈ 340 | Modelos Freezed, *helpers*, *providers* Riverpod, *theme*, utilidades |
| Widget    | ≈ 220 | Componentes compartidos, pantallas críticas, semántica |
| Integración | 3 *happy paths* en `integration_test/` | Registro/inicio, búsqueda, reporte de incidencia |
| Repositorios remotos | 12 dominios | `SupabaseClient` mockeado |
| Leak tracking | Transversal | `leak_tracker_flutter_testing` para controladores y *streams* |

**Visual goldens**: los ocho *widgets* compartidos y dos brillos
(claro/oscuro) cuentan actualmente con *rendering tests*; la evolución
hacia *goldens* pixel-perfect está planificada y registrada como
evolución, no como deuda crítica.

`mocktail` cubre la inyección de mocks sin generación de código. Para
pruebas con tiempos se utiliza `fake_async`. La regla `avoid_print`
está activa en `lib/`; solo `AppLogger` produce salida.

---

## 8. Pruebas funcionales

### 8.1. Accesibilidad manual

Está prevista para la semana 10 una pasada manual de **accesibilidad
con TalkBack (Android) y VoiceOver (iOS)**. El procedimiento, las
incidencias y el resultado quedan registrados en
`docs/A11Y_MANUAL_TEST_2026_06.md`. La pasada cubre orden de foco,
etiquetas semánticas, contraste y operación con una sola mano.

### 8.2. *Push* extremo a extremo

Se realiza una prueba E2E del flujo *push* cubriendo los tres estados
del proceso receptor (*foreground*, *background* y *killed*) y el
seguimiento del *deeplink* incluido en el *payload*. La verificación se
hace en un dispositivo físico Android porque los emuladores no
emulan fielmente la entrega FCM en *killed*.

### 8.3. Sesión con usuarios reales

En la semana 10 se ejecuta una sesión con **cinco usuarios reales** de
los perfiles definidos en el documento 03, seguida de un cuestionario
**SUS (System Usability Scale)**. Los resultados se incorporan al
documento 05 (Evaluación y documentación) con análisis cuantitativo
y cualitativo.

---

## 9. Documentación del código y del proyecto

### 9.1. `dartdoc` y publicación

La API pública se documenta con `dartdoc`. El sitio resultante se
publica en **GitHub Pages**, lo que permite consultar la
documentación generada sin clonar el repositorio.

### 9.2. Documentos vivos

| Documento | Propósito |
|-----------|-----------|
| `README.md` raíz | Visión general, badges de CI, *codecov*, licencia y versión |
| `AGENTS.md` | Guía para agentes de IA colaboradores; recoge reglas de arquitectura no negociables |
| `CHANGELOG.md` | Generado por `release-please` a partir de los *Conventional Commits* |
| `docs/00_MAESTRO.md` | Cuadro de mando central del proyecto |
| `docs/adr/` | Cinco ADRs (Riverpod, Freezed, Hive, Supabase, feature-first) |
| `docs/runbooks/` | Seis *runbooks* operativos (despliegue, rotación de claves, recuperación de Supabase, *keystore* Android, *push* en producción, GDPR) |
| `docs/tfg/` | Memoria académica (ocho documentos) |
| Resto de `docs/` | Más de 70 documentos técnicos (arquitectura, escalabilidad, accesibilidad, seguridad, *performance budget*, etc.) |

### 9.3. Estilo de comentarios

Como regla general, el código no se comenta. Los identificadores
expresan el "qué". Solo se comenta el "porqué" no obvio: invariantes
ocultos, *workarounds* con referencia al *bug* o decisiones
contraintuitivas que ahorrarían horas a una persona que lea el código
por primera vez.

---

## 10. CI/CD

### 10.1. *Jobs* actualmente en verde

GitHub Actions ejecuta los siguientes *jobs* en cada *push* y *pull
request* contra `master`:

1. **Flutter Analyze**: `flutter analyze` con cero *issues* obligatorio.
2. **Flutter Test**: `flutter test --coverage` con umbral mínimo de
   cobertura y *upload* a Codecov.
3. **Build Web (release)**: compilación en *release* validando que el
   código de la rama compila para plataforma web.
4. **Build Android APK**: compilación *release* con `--split-per-abi`,
   `--obfuscate` y `--split-debug-info`; firma con claves de *debug*
   en CI (la firma con *keystore* real ocurre en *release*
   manualmente). Incluye verificación de **presupuesto de tamaño**
   por ABI.
5. **Gitleaks**: escaneo de *secrets* con configuración `.gitleaks.toml`.
6. **Semgrep**: SAST con reglas en `.semgrep/rules.yaml`.

Los cuatro *jobs* principales (analyze, test, build-web, build-android)
están **en verde de forma sostenida**. Gitleaks actúa como
**bloqueante**: cualquier *secret* detectado impide el *merge*.

### 10.2. Evolución prevista

Está planificado añadir un *job* dedicado a *tests* de Edge
Functions, alcanzando un total de siete *jobs*. Esa evolución no
condiciona la entrega académica y forma parte del plan mega
refinamiento.

### 10.3. *Hooks* locales con lefthook

El proyecto utiliza **lefthook** para ejecutar verificaciones antes de
cada *commit* y antes de cada *push*. Los *hooks* incluyen:

- `flutter analyze` (cero *issues*).
- `dart format --set-exit-if-changed`.
- *Check* de coherencia del estado del repositorio (`verify-state`).
- Gitleaks local antes de *push*.

### 10.4. Releases

Los *releases* siguen versión SemVer mediante etiqueta Git que dispara
`release-please`. El *workflow* genera automáticamente el *release* en
GitHub a partir del `CHANGELOG.md`.

---

## 11. Decisiones técnicas relevantes

Las cinco decisiones de mayor calado están explicadas en sus ADRs y se
resumen aquí porque condicionan el resto del desarrollo:

**ADR 001 — Riverpod 2.6 como gestor de estado.** Se valoraron Bloc y
Provider clásico. Riverpod gana por dos motivos: tipado fuerte sin
código generado obligatorio y soporte de `autoDispose` y `.family`,
ideales para una app con pantallas que aparecen y desaparecen y con
*streams* en tiempo real.

**ADR 002 — Freezed 3 para inmutabilidad.** El coste de añadir un
generador se compensa por la ausencia de errores comunes con
`copyWith` manuales, igualdad estructural correcta y patrones de
*sealed classes* para *states*.

**ADR 003 — Hive 2.2 con `HiveAesCipher`.** Hive ofrece persistencia
local muy rápida sin SQL embebido, suficiente para una app móvil con
datasets modestos. El cifrado AES nativo permite cubrir las tres
*boxes* sensibles sin librerías adicionales.

**ADR 004 — Supabase como *backend*.** Combina PostgreSQL con RLS
nativo (justo lo que requiere un proyecto con datos personales bajo
GDPR), Auth integrada, Edge Functions en Deno y un *free tier*
viable para un TFG.

**ADR 005 — Feature-first.** La organización por *features*
verticales escala mejor que la organización por capas cuando el
equipo es pequeño y cada *feature* tiene su pantalla, su *provider*
y, eventualmente, sus *widgets* internos.

---

## 12. Resumen ejecutivo

El producto entregado es **funcional, verificable y trazable**. Cada
*commit* atraviesa `flutter analyze` con cero *issues*, los 616
*tests* y siete *jobs* de CI sostenidamente en verde. El *backend*
descansa sobre PostgreSQL con RLS DENY-by-default y catorce
migraciones versionadas; el cliente cifra los datos sensibles con
AES en tres *boxes* de Hive y nunca expone *secrets* al repositorio
gracias a Gitleaks. La observabilidad cubre seis transacciones y 17
eventos funcionales con *scrubbing* sistemático de PII y *consent
gating* por defecto. Las decisiones de arquitectura están documentadas
en cinco ADRs y las operaciones críticas en seis *runbooks*. La
asistencia de IA queda declarada con transparencia. El siguiente
documento, `05_evaluacion_documentacion.md`, presenta los
procedimientos de evaluación, los resultados de la sesión con
usuarios reales y los indicadores finales del proyecto.
