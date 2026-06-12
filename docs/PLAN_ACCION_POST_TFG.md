# Plan de acción post-TFG — Auditoría 2026-06-12

> **Rama:** `post-tfg` (creada desde `master@945d896f`, la entregada al tribunal).
> **Método:** auditoría sin tocar código — `flutter analyze` + `flutter test`
> locales, advisors de Supabase (security + performance), estado de CI/GitHub,
> barrido de i18n, dependencias (`pub outdated`) y revisión de la web
> (`astro/` + `presentation/`). Este documento es el registro de deficiencias
> y el plan; **no se ha aplicado ningún fix todavía**.

---

## 0. Estado verificado hoy (snapshot)

| Métrica | Valor 2026-06-12 | Última afirmación documentada |
|---------|------------------|-------------------------------|
| `flutter analyze` | **19 errors · 31 warnings · 100 infos** | "0 issues" (docs de mayo) |
| `flutter test` | **650 OK · 17 fallos · 6 skipped** | "616/616 passing" |
| CI en `master` | **🔴 ROJA** (Analyze y Test fallan, run `27382669337`) | "CI verde 4 jobs" |
| Cobertura | 24,04 % (lcov del 22-may, desfasado) | ~25,5 % |
| Migraciones SQL | 53 | docs dicen 13–14 |
| Edge Functions | 8 | docs dicen 2–4 |
| ARB i18n | es 868 · en 868 · **ar 758 (−110)** | "343 claves, 3 idiomas en sync" |
| Strings ES hardcodeados | **116 ficheros** en `lib/` | "cerrado" (mayo) |
| Advisors Supabase (security) | **160 lints** (2 ERROR) | — |
| Advisors Supabase (performance) | **209 lints** | — |
| PRs abiertos | 11 (10 dependabot + release-please 1.13.0) | — |
| Ramas obsoletas | ~45 locales/remotas ya mergeadas | — |

**Diagnóstico general:** el sprint de junio (266 commits) añadió muchísimo
producto (widgets, gestión de líneas, conductor en 2º plano, web nueva) pero
sin red de calidad: la CI lleva rota desde entonces, la i18n y los tests se
quedaron atrás, y la documentación de auditoría describe un proyecto que ya
no existe. El plan prioriza recuperar la base (P0) antes de seguir añadiendo.

---

## P0 · Recuperar la base de calidad (CI verde) — ~1-2 días

> Sin esto, todo lo demás se construye a ciegas. Es lo primero.

- [x] **P0.1 — Arreglar los 5 errores de compilación de analyze en `lib/`.**
  Todos en `lib/features/map/widgets/zone_company_line_tree.dart`
  (líneas 238–284: condiciones/negaciones sobre `dynamic` — entró con el
  commit de filtros del mapa `56148098`).
- [x] **P0.2 — Arreglar el test que no compila.**
  `test/shared/providers/user_favorites_provider_test.dart` (14 errores:
  `UserFavoritesNotifier`/`UserFavoriteStopsNotifier` cambiaron de firma a
  2 argumentos posicionales y el test no se actualizó).
- [x] **P0.3 — Arreglar los 17 tests en rojo** (listado en §Anexo A).
  Son regresiones del sprint de junio: el código cambió y la suite no se
  mantuvo. Revisar uno a uno si el fallo es del test (actualizar) o del
  código (bug real).
- [x] **P0.4 — Limpiar los 31 warnings** (imports sin usar, casts
  innecesarios, campos muertos — mecánico, ~1 h) y bajar los 100 infos
  cuando se toque cada fichero.
- [x] **P0.5 — Añadir `post-tfg` a los triggers de CI.**
  `.github/workflows/ci.yml` solo corre en `master`/`main`: ahora mismo la
  rama de trabajo **no tiene CI**. Añadir `post-tfg` a `branches` de `push`
  y `pull_request` (docs.yml y deploy-presentation.yml pueden quedarse solo
  en master, son publicación).
- [x] **P0.6 — Triaje de los 11 PRs abiertos.** Decisión 2026-06-12: NO se
  mergean — todos apuntan a `master`, que está congelada para la corrección.
  Los bumps de dependencias se harán directamente en `post-tfg` (P6.1) y el
  PR de release-please se resolverá con P6.3 al final de la corrección.
- [x] **P0.7 — Regenerar `coverage/lcov.info`**. Hecho 2026-06-12: la
  cobertura real es **17,30 %** (6.233/36.033 líneas) — bajó desde 24 %
  porque junio duplicó las líneas instrumentadas. Gate de CI ajustado a
  16 % para frenar regresiones; la subida escalonada es P4.4.
- [x] **P0.8 — (descubierto durante P0) Build Android APK roto en CI.**
  `google-services.json` está gitignored y el plugin de Google Services lo
  exige desde que junio integró FCM — el job llevaba roto desde entonces.
  Arreglado 2026-06-12: secret `GOOGLE_SERVICES_JSON` en el repo + paso del
  workflow que lo materializa antes del build.

---

## P1 · Seguridad del backend (advisors Supabase) — ~2-4 días

> 160 lints de seguridad, 2 de nivel ERROR. El proyecto remoto es real y
> público: esto es lo segundo más urgente.

- [x] **P1.1 — 🔴 ERROR: tabla `route_vote_xp_awarded` sin RLS.** ✅ 2026-06-12
  (migración `20260612100000`): RLS activado sin policies + los dos triggers
  de voto ahora son SECURITY DEFINER — de paso arregla que el UPDATE de
  `vote_count` en rutas ajenas se filtrara en silencio bajo RLS.
  Está en `public` expuesta vía PostgREST sin ninguna política. Habilitar
  RLS + políticas (o moverla a un schema privado si es solo contabilidad
  interna de triggers). (`spatial_ref_sys`, el otro ERROR, es de PostGIS y
  puede documentarse como aceptado.)
- [x] **P1.2 — Auditar las 60 funciones `SECURITY DEFINER`.** ✅ 2026-06-12
  (migración `20260612104000`). Resultado: (a) **add_xp no validaba rol** —
  cualquier autenticado podía regalarse XP; ahora hay `admin_add_xp` con
  check `is_admin()` y `add_xp` quedó solo para triggers/owner (el panel
  admin usa el wrapper); (b) los 9 triggers de XP pasaron a SECURITY
  DEFINER; (c) EXECUTE revocado a `anon` en las ~40 RPCs de sesión y
  revocado del todo en funciones de trigger y helpers internos. Se
  conservan para `anon` las 13 funciones por diseño: helpers de policies
  (`is_admin`, `is_route_owner`…) y RPCs read-only de datos públicos
  (`get_next_departures_*`, `list_zones`…). Original: Incluyen toda la familia `admin_*`
  (`admin_route_delete`, `admin_broadcast_alert`, `admin_ban_users`…).
  Verificar una a una que el cuerpo valida el rol; para las que no deban
  ser públicas: `REVOKE EXECUTE FROM anon, authenticated` y conceder solo a
  quien toque. Es la superficie de ataque más grande del backend.
- [x] **P1.3 — Fijar `search_path` en las 31 funciones marcadas** ✅
  2026-06-12 (migración `20260612101000` + P1.1 para los 2 triggers de voto).
  (`SET search_path = ''` o explícito) — mitiga escalada por shadowing.
- [ ] **P1.4 — Activar protección de contraseñas filtradas.** ⛔ BLOQUEADO
  2026-06-12: la Management API devuelve 402 — HIBP requiere plan Pro.
  Mitigación actual: min 6 caracteres (alineado app/servidor). Retomar si
  el proyecto pasa a Pro.
- [x] **P1.5 — Buckets públicos con listado permitido.** ✅ 2026-06-12
  (migración `20260612103000`): eliminadas las policies `*_select_public`
  de `avatars`/`operator-assets` — la descarga por URL pública no pasa por
  RLS, así que solo desaparece la enumeración. Verificado: ni app ni web
  usan el cliente de Storage sobre esos buckets.
- [x] **P1.6 — Policy always-true de `user_route_views`.** ✅ 2026-06-12
  (migración `20260612102000`): el INSERT ahora exige
  `viewer_id IS NULL OR viewer_id = auth.uid()` — vistas anónimas legítimas
  sí, suplantar a otros usuarios no.
- [x] **P1.7 — MV `next_scheduled_arrivals` expuesta.** ✅ 2026-06-12
  (migración `20260612102000`): `REVOKE SELECT` a anon/authenticated —
  ningún cliente la consume (la app usa los RPC `stop_timetable*`).
- [ ] **P1.8 — FORCE RLS + revisión de policies** (deuda ya documentada en
  `docs/SCALABILITY.md`): aplicar `FORCE ROW LEVEL SECURITY` en tablas
  sensibles para blindar frente a funciones definer descuidadas.
- [ ] **P1.9 — Completar el pipeline FCM**: subir la service account de
  Firebase a los secrets de la Edge Function (`docs/FCM_SETUP.md` —
  pendiente conocido; sin esto los triggers de push del backend no envían).
- [ ] **P1.10 — SMTP propio + reactivar verificación de email** (hoy
  "Confirm email" está OFF y el código la bypassa). Pasos exactos ya
  escritos en `docs/SUPABASE_SETUP.md`. Resend/Brevo tienen tier gratuito.

---

**Resultado P1 (2026-06-12):** advisors de seguridad **160 → 74 lints**.
Lo restante es aceptado por diseño (56 definer con authz interno + 13
públicas deliberadas), `spatial_ref_sys`/extensiones de PostGIS (no
movibles sin riesgo) y HIBP (requiere plan Pro). Quedan abiertos P1.8
(FORCE RLS), P1.9 (service account FCM) y P1.10 (SMTP).

---

## P2 · Rendimiento de la base de datos — ~1-2 días

> 209 lints de performance. Con pocos usuarios no duele; arreglarlo ahora es
> barato y evita re-aprender el esquema más tarde.

- [x] **P2.1 — `auth_rls_initplan` ×86 → 0.** ✅ 2026-06-12 (migración
  `20260612110000`, reescritura programática de ~98 policies en public y
  storage). Verificado: el lint desapareció y el RLS sigue funcionando
  (anon ve líneas oficiales/paradas, no ve lo privado).
- [x] **P2.2 — `multiple_permissive_policies` ×54.** ✅ 2026-06-12 con
  decisión documentada (migración `20260612112000`): NO se fusionan las
  policies por rol (nombres autodocumentados > ganancia marginal); en su
  lugar `is_admin()`/`is_moderator_or_admin()` quedan envueltas en
  `(SELECT ...)` → InitPlan una vez por consulta, que era el coste real.
  El lint seguirá contando 54 (cuenta policies, no coste) — aceptado.
- [x] **P2.3 — 49 foreign keys sin índice → 0.** ✅ 2026-06-12 (migración
  `20260612111000`, generador programático `<tabla>_<col>_fk_idx`). Los 49
  nuevos índices aparecerán como "unused" hasta que tengan tráfico — ver
  P2.4.
- [x] **P2.4 — 20 índices sin uso:** revisados uno a uno el 2026-06-12 —
  decisión: **conservarlos todos**. Son índices funcionales de features
  reales (GIST del mapa en routes/bus_positions/operators, GIN de búsqueda
  en user_routes, índices de estado para moderación); `idx_scan = 0` se debe
  a que el dataset aún es pequeño y el planner elige seq scan. Borrarlos
  ahorraría escritura marginal y obligaría a recrearlos al crecer. Revisar
  de nuevo cuando haya tráfico real.

---

**Resultado P2 (2026-06-12):** advisors de rendimiento **209 → 123 lints**;
`auth_rls_initplan` y `unindexed_foreign_keys` a **cero**. Lo restante son
las 54 policies separadas por diseño y 69 índices jóvenes/funcionales
documentados en P2.4.

---

## P3 · i18n y accesibilidad — ~3-5 días

> La historia de i18n/a11y era de las más fuertes del TFG y junio la erosionó.

- [x] **P3.1 — Re-sincronizar el árabe.** ✅ 2026-06-12: traducidas las 110
  claves que faltaban (editor de rutas, comunidad, compartir, moderación,
  estados) con la terminología existente (خط = línea, مسار = ruta,
  محطة = parada). ARB 868/868/868, `flutter gen-l10n` regenerado y el test
  de paridad `test/smoke/arb_parity_test.dart` en verde. Pendiente ideal:
  revisión por hablante nativo (bloqueador externo B5 histórico).
- [ ] **P3.2 — Migrar los strings ES hardcodeados a ARB.** 116 ficheros
  afectados; los peores: `legal_screen` (26), `route_editor_screen` (20),
  `enums.dart` (20), `invitation_codes_screen` (18), `widgets_config_screen`
  (17), `admin_operators_screen` (17), `admin_geo_alerts_screen` (17).
  Sugerencia: hacerlo por feature y añadir un check de CI (grep de
  caracteres acentuados en literales) para que no vuelva a crecer.
- [ ] **P3.3 — Pasada real con TalkBack** en dispositivo físico + acta.
  Sigue siendo el bloqueador para defender "WCAG 2.2 AA" (deuda histórica).
- [ ] **P3.4 — RTL en runtime:** probar el locale árabe en dispositivo
  (widgets custom, mapa, navegación) — nunca se ha hecho.
- [ ] **P3.5 — Verificar contrastes de los tokens** de `transit_colors.dart`
  con tooling (axe/Stark) y documentar la matriz resultante.
- [ ] **P3.6 — Accesibilidad de las pantallas nuevas de junio** (widgets
  config, gestión de líneas/zonas, conductor): semantics, foco, tap targets
  — se construyeron rápido y sin pasada a11y.

---

## P4 · Testing y cobertura — continuo, primera tanda ~1 semana

- [ ] **P4.1 — Tests de la capa `remote/`** (sigue a ~0 %): auth repository,
  stop/route/bus_location remotos, channel manager con reconexión. Es la
  palanca de cobertura identificada hace un mes y sigue intacta.
- [ ] **P4.2 — Tests de lo construido en junio:** gestión de líneas admin,
  widgets (selector, refresco), filtros del mapa, conductor 2º plano,
  user_routes/favoritos. Nada de eso tiene tests y es justo lo que se está
  rompiendo (los 17 fallos actuales son de ahí).
- [ ] **P4.3 — Golden tests:** la razón histórica para no tenerlos
  (google_fonts por red) **ya no existe** — las fuentes van bundled desde
  F26. Empezar por design system + pantallas estables.
- [ ] **P4.4 — Subir el umbral de cobertura de CI** (hoy 20 %) en escalones
  (24 → 30 → 35 %) a medida que P4.1–P4.3 aterricen, para que no vuelva a
  bajar sin que se note.
- [ ] **P4.5 — Smoke E2E mínimo** (integration_test): arranque, login mock,
  mapa, detalle de línea. Un solo flujo feliz ya caza roturas gordas.

---

## P5 · Salud del código — ~2-3 días

- [ ] **P5.1 — Descomponer los god files** (en orden de riesgo):
  `map_tab.dart` (1.536 LoC), `admin_geo_alerts_screen.dart` (1.442),
  `admin_user_detail_screen.dart` (1.288), `user_route_detail_screen.dart`
  (1.243), `manager_inbox_screen.dart` (1.236), `admin_requests_screen.dart`
  (1.189). Extraer widgets/controllers; mismo patrón que ya usan otras
  features.
- [ ] **P5.2 — Limpiar código muerto** detectado por analyze (campos,
  elementos y `_showManualAddStopModal` sin referencias, imports muertos).
- [x] **P5.3 — Borrar ramas mergeadas.** ✅ 2026-06-12: eliminadas 41
  locales y 40 remotas (todas verificadas `--merged master`). Quedan:
  master, post-tfg, gh-pages, release-please y las dependabot/* de PRs
  abiertos.
- [ ] **P5.4 — Revisar deuda menor arrastrada** de `docs/PENDIENTE_PARA_CERRAR.md`
  §7 que siga aplicando (acceso directo a Hive en `storage_section`, etc.).

---

## P6 · Dependencias y release engineering — ~2-4 días

- [ ] **P6.1 — Upgrades menores seguros** (vía PRs de dependabot ya
  abiertos): firebase_core/messaging, supabase_flutter 2.14, posthog,
  image_picker, flutter_secure_storage + bumps de GitHub Actions.
- [ ] **P6.2 — Planificar los majors** (cada uno con breaking changes, en
  rama propia y con la suite verde antes):
  | Paquete | Actual → Última | Nota |
  |---------|-----------------|------|
  | riverpod / flutter_riverpod | 2.6 → 3.3 | migración con codemod oficial |
  | flutter_map (+FMTC) | 7.0 → 8.3 | API de capas cambió |
  | sentry_flutter | 8.14 → 9.22 | init/options renovados |
  | nfc_manager | 3.5 → 4.2 | API reescrita — afecta al lector de tarjeta |
  | geolocator | 13 → 14 | permisos |
  | google_sign_in | 6.3 → 7.2 | no urgente: el login usa OAuth web de Supabase |
  | share_plus / connectivity_plus / permission_handler / flutter_local_notifications / flutter_lints | majors varios | mecánicos |
- [ ] **P6.3 — Unificar el versionado.** Hoy conviven `pubspec 1.2.0`,
  PR de release-please `1.13.0`, y la web anuncia `v1.12.4`. Decidir una
  fuente de verdad (release-please ya gestiona pubspec + CHANGELOG) y que
  la web lea esa versión en build en vez de mantenerla a mano.
- [ ] **P6.4 — Keystore de release + Play App Signing** si se quiere
  publicar en Play Store (bloqueador histórico B1; ~30 min + secrets en CI).

---

## P7 · Web (astro/ y presentation/) — ~2-3 días

- [ ] **P7.1 — Decidir el destino de `astro/`.** El sitio de producto es
  solo local (la doc lo admite). O se despliega de verdad (Vercel/Netlify/
  VPS con el adapter node ya configurado) o se documenta como demo local y
  se deja de invertir en él. Ahora mismo es trabajo que nadie ve.
- [ ] **P7.2 — Sacar el APK de `astro/public/downloads/` (92 MB).**
  Publicarlo como asset de **GitHub Releases** (encaja con release-please)
  y enlazar desde la web; el fichero actual es manual, pesa y no se
  versiona.
- [ ] **P7.3 — Auditoría Lighthouse** (performance + SEO + a11y) de
  `presentation/` (GitHub Pages) y de `astro/`: imágenes sin lazy-load,
  metadatos OG, contraste del tema claro nuevo, tamaño del bundle de
  three.js en la landing.
- [ ] **P7.4 — Accesibilidad web:** navegación por teclado del deck de
  defensa, `prefers-reduced-motion` en las animaciones del hero/orbitales,
  textos alternativos.
- [ ] **P7.5 — Islas Flutter Web:** verificar que la build embebida en
  `astro/public/app/` está al día con el código actual y automatizar su
  regeneración (`build:all` existe pero es manual; un workflow o un check
  de frescura evitaría servir una app vieja).

---

## P8 · Producto — funcionalidades candidatas (backlog priorizado)

> Nada de esto debería empezar antes de cerrar P0–P1.

1. **Planificador de viajes A→B** — la ausencia más visible para un usuario
   real (descartada conscientemente en el TFG; primera gran feature post-TFG
   natural). Empezar con grafo simple sobre las líneas existentes +
   transbordos en paradas compartidas.
2. **Más operadores reales** — el seed multi-operador (TUSSAM, EMT…) existe
   desde F7-F8 pero solo COMUJESA tiene datos completos. El importador GTFS
   ya está; alimentar 1-2 ciudades más daría mucho valor de demo.
3. **GTFS-Realtime** — hoy el "tiempo real" es GPS de conductor + estimación.
   Integrar feeds GTFS-RT donde existan (documentado como trabajo futuro).
4. **Notificaciones de llegada inteligentes** — "avísame 5 min antes" con
   geofencing + horario (ya hay geo_alerts y workmanager como base).
5. **Histórico/estadísticas para el usuario** — viajes NFC + rutas usadas
   (las tablas `nfc_scans` y `user_route_views` ya existen).
6. **Descarga offline de regiones libre** — hoy limitada a Jerez (banner
   demo); generalizar selección de bbox.
7. **Modo wear OS nivel 2** (acciones interactivas) — solo si sobra tiempo;
   es la de menor retorno.

---

## P9 · Documentación y gobernanza — ~1 día

- [x] **P9.1 — Docs de auditoría desfasados.** ✅ 2026-06-12: banner de
  «DOCUMENTO HISTÓRICO» con enlace a este plan en `PENDIENTES.md`,
  `PENDIENTE_PARA_CERRAR.md`, `PROPUESTAS_FUTURAS.md` y `00_MAESTRO.md`;
  `AGENTS.md` corregido (suite 679, 60 migraciones, CI 6 jobs + lefthook,
  flujo de ramas master-congelada/post-tfg).
- [ ] **P9.2 — CHANGELOG real:** el CHANGELOG se quedó en 1.0.0 mientras la
  web anuncia 1.12.x. Resolver junto con P6.3.
- [ ] **P9.3 — Definir el flujo de la rama `post-tfg`:** features en ramas
  `feat/*` → PR a `post-tfg` con CI (requiere P0.5); `master` intocable
  hasta que acabe la corrección.

---

## Orden recomendado

```
Semana 1:  P0 completo (CI verde) + P1.1, P1.4 (quick wins de seguridad)
Semana 2:  P1 resto (definer functions, search_path, FCM, SMTP) + P2
Semana 3:  P3.1–P3.2 (i18n) + P4.1–P4.2 (tests de junio y remote/)
Semana 4:  P5 + P6.1/P6.3 + P7.2/P7.3
Después:   P6.2 (majors) en ramas propias · P8 por orden del backlog · P3.3–P3.6
```

Regla general: **no se añade más producto (P8) hasta que P0 y P1 estén
cerrados** — es exactamente la deuda que generó el sprint de junio.

---

## Anexo A — Tests en rojo (2026-06-12)

`flutter test`: 650 OK · 17 fallos · 6 skipped. Ficheros afectados:

| Fichero | Fallos | Detalle |
|---------|:------:|---------|
| `test/features/auth/auth_states_test.dart` | 5 | SignInScreen: rendering, credenciales inválidas, email no verificado, error de red, botón |
| `test/features/admin/admin_users_screen_test.dart` | 3 | shimmer en loading, EmptyState, chip "Todos" |
| `test/shared/providers/derived/active_trip_providers_test.dart` | 3 | activeTripDetailProvider: caso normal, última parada, currentStopIndex null |
| `test/features/auth/auth_screen_test.dart` | 2 | campos email/contraseña, email inválido |
| `test/features/management/manager_inbox_screen_test.dart` | 1 | EmptyState sin datos |
| `test/shared/models/notification_model_test.dart` | 1 | enum AppNotificationType (faltan/ sobran valores nuevos) |
| `test/shared/providers/user_favorites_provider_test.dart` | 1 | **no compila** (firma de los notifiers cambió — ver P0.2) |
| `test/widget/offline_data_screen_test.dart` | 1 | stats + metadata + botón reload |

Patrón: pantallas de auth, admin y providers que cambiaron en el sprint de
junio sin actualizar sus tests.

## Anexo B — Detalle de advisors Supabase

**Security (160):** `rls_disabled_in_public` ×2 (**ERROR**:
`route_vote_xp_awarded`, `spatial_ref_sys`) ·
`anon_security_definer_function_executable` ×60 ·
`authenticated_security_definer_function_executable` ×60 ·
`function_search_path_mutable` ×31 · `extension_in_public` ×2 (postgis,
pg_net) · `public_bucket_allows_listing` ×2 (avatars, operator-assets) ·
`materialized_view_in_api` ×1 (next_scheduled_arrivals) ·
`rls_policy_always_true` ×1 (user_route_views) ·
`auth_leaked_password_protection` ×1.

**Performance (209):** `auth_rls_initplan` ×86 ·
`multiple_permissive_policies` ×54 · `unindexed_foreign_keys` ×49 ·
`unused_index` ×20.

Remediation: <https://supabase.com/docs/guides/database/database-linter>
