# Revisión crítica integral — Transitly (nexto-stop-v2)

> **Óptica de evaluación:** TFG académico (lente de tribunal).
> **Fecha:** 2026-05-15.
> **Método:** exploración paralela del código + verificación directa de las
> afirmaciones más graves. Varias incidencias detectadas en una primera pasada
> resultaron **falsas o exageradas** y se corrigen explícitamente abajo: en una
> revisión profesional la precisión prima sobre el efecto.

---

## Hechos verificados (correcciones a hallazgos preliminares)

| Afirmación preliminar | Veredicto tras verificación |
|---|---|
| "`.env` con claves reales commiteado" (Crítico) | **FALSO.** `.env` está gitignored, **no** rastreado y **no** aparece en el historial (`git log --all -- .env` vacío). La `SUPABASE_ANON_KEY` es por diseño pública (protegida por RLS). Riesgo real: **Bajo**. |
| "El sistema multiagente IA no está documentado → falta de transparencia" (integridad) | **FALSO.** Declarado en `docs/tfg/03_planificacion.md:76`, `04_desarrollo_implementacion.md:16`, `05_evaluacion_documentacion.md:17-23`. Sí es transparente. Matiz real: el **README** lo omite. |
| "`flutter analyze` → 0 issues" (README:28) | **FALSO en README.** Real: **6 issues** `info` (4× `prefer_const_constructors`, 1× `prefer_conditional_assignment`, 1× `no_leading_underscores`). Menor, pero contradice la doc. |
| "56 / 56 passing" (README:28,75) | **Desactualizado solo en README.** El runner reporta **137** tests verdes; `multiagent/state/project.json` (137) era correcto. La cifra "56" del README era la única obsoleta. |
| "Project-ref de producción hardcodeada" | **CONFIRMADO.** `supabase/migrations/015_push_triggers.sql:85` fija `https://mmzahxtiaurkgtmtehxk.supabase.co/...`. |
| "FORCE RLS deshabilitado" | **CONFIRMADO y documentado como decisión de diseño** (`002_rls.sql:18`). `service_role` bypassa RLS. |
| `coverage/lcov.info` | Medición 2026-05-15: **23,4 %** (3 512/15 018) — muy por debajo del "~45 %" reclamado. Re-medido 2026-05-17 tras P1/P2: **23,2 %** (3 580/15 424, **143** tests); bajó levemente porque las 6 pantallas implementadas añaden LOC sin cubrir. `coverage/` está gitignored. |

> **Nota P0 (2026-05-15):** aplicados — README reescrito, `pubspec.yaml` y
> claims de accesibilidad alineados ("AA parcial"), `docs/tfg/05` y
> `docs/tfg/02/08` con cifras reales (al 15-may: 23,4 %, 137 tests, 6 info;
> reconciliadas el 17-may, ver nota de repaso al final).
>
> **Nota P1 (2026-05-15):** aplicados — (1) logging `AppLogger` en todos los
> `catch (_) {}` silenciosos (main, appearance, privacy, map_filter);
> (2) Realtime F13 documentado como pendiente en `06_manual_tecnico`/`02`
> (Realtime activo solo en notificaciones); (3) guard de rol del router
> extendido a `/operator-admin` + comentario aclarando que el límite real es
> RLS server-side (unificación mock↔Supabase queda como deuda P2);
> (4) Edge Functions endurecidas (CORS por allowlist, anti-SSRF en
> `import_gtfs`, validación de invocador/`user_id` + rate-limit en
> `send_notification`, project-ref hardcodeada eliminada de `015`);
> (5) las 6 pantallas stub implementadas con datos mock y widgets del design
> system.
>
> **Nota P2 (2026-05-15):** aplicados — (1) `test/hive_temp/` añadido a
> `.gitignore`; (2) consent-gating real: PostHog arranca con
> `optOut=true` + sin autocapture y `analyticsServiceProvider` es
> default-deny (solo con consentimiento explícito), Sentry no se inicializa
> para invitados ni si falla la lectura de consentimiento; (3) tests reales
> de `bus_estimator` (6 casos, módulo crítico antes sin cobertura);
> (4) migración targeted de colores a tokens (signin dividers,
> region_download bg) — el resto eran colores raw intencionales
> (palette editor, debug, swatches de estilos de mapa, scrims), documentado;
> (5) **i18n: la afirmación "~60 %" era falsa** (recuento por líneas); ES/EN
> están completos (275/275). Corregido en docs y enrutados por l10n los
> strings inline de `offline_banner` (con plural ICU es/en); (6) F26:
> *seam* `_fontsBundled` en `main.dart` + guía exacta en `docs/FONTS_F26.md`
> (no se commitean binarios `.ttf`; queda como deuda acotada y documentada).
>
> Verificación P2: `flutter analyze` 0 errores / 6 info preexistentes;
> `flutter test` **143/143** verdes. P0+P1+P2 cerrados.
>
> **Nota repaso (2026-05-17):** repaso crítico del propio trabajo. Hallazgos
> y correcciones: (1) **deriva doc↔código autoinfligida** — P2 subió los
> tests de 137 a 143 y cambió la cobertura, pero README/`tfg/05`/este
> informe seguían citando 137 y 23,4 %. Re-medido y reconciliado en todos
> los sitios: **143 tests, 23,2 %** (3 580/15 424); (2) **footgun
> introducido por P1** — las Edge Functions endurecidas exigen
> `functions_url`/`ALLOWED_ORIGINS` o las push degradan en silencio; ahora
> documentado en `supabase/README.md`. Verificado además, por lógica (no
> solo compilación): `Posthog().enable()` revierte `optOut`,
> `notifications.created_at` existe e indexado (rate-limit correcto), l10n
> es/en generado y consumido OK.

---

# Informe crítico

## Puntuación global: **7.0 / 10**

*Aprobable con reservas: notable a nivel técnico, lastrado por documentación
incoherente y un alcance publicitado que no es del todo demostrable en la build
entregada.*

### Desglose por dimensión

| Dimensión | Nota | Comentario |
|---|---:|---|
| Arquitectura y diseño de código | 8.0 | Capas limpias (domain/local/mock/remote), Riverpod + freezed + go_router coherentes. Penaliza la triplicación y la capa `remote` parcialmente sin conectar (Realtime F13). |
| Calidad de implementación | 7.0 | Design system sólido pero con valores hardcodeados dispersos; `catch(_){}` silenciosos; `!` force-unwrap en zonas sensibles. |
| Backend / seguridad | 6.5 | RLS extensa (102 políticas) pero sin FORCE RLS, Edge Functions sin rate-limit/validación de `user_id`, CORS `*`, ref de prod hardcodeada. |
| Privacidad / GDPR | 6.0 | Hay consent gating, pero el orden de init de Sentry/PostHog respecto al consentimiento debe demostrarse; fuentes Google en runtime. |
| Pruebas | 4.5 | 143 tests para 49 K LOC; cobertura real medida **23,2 %**. `bus_estimator` ya cubierto (P2); `offline_sync_service` y los repos remote siguen sin tests reales. |
| Documentación / coherencia | 5.5 | `docs/tfg` razonablemente rigurosos y honestos (declaran la IA y los gaps WCAG), **pero el README contradice el código** (backend, tests, analyze, fases). |
| Accesibilidad | 6.5 | Esfuerzo real (Semantics, alto contraste, daltonismo, dislexia, textScaler). El reclamo "WCAG 2.1 AA" no está verificado con lector de pantalla → debe ser "AA parcial / en progreso". |
| Integridad académica | 8.0 | La asistencia multiagente **sí** se declara en la memoria. Buena trazabilidad por commits/fases. Recomendable reforzar la sección de autoría/responsabilidad. |

---

## Hallazgos por severidad

### 🔴 Crítico — resolver antes de la defensa

1. **README engañoso vs. realidad del código.** `README.md:9-10,117-119` afirma
   "no backend, no auth, no push — all local mock data", pero el repo integra
   Supabase (`lib/data/supabase/`, 16 migraciones, auth real en
   `lib/features/auth/auth_repository_supabase.dart`), FCM y telemetría. En un
   TFG, una descripción arquitectónica falsa en el documento de entrada es el
   riesgo más serio. **Acción:** reescribir el README para reflejar el stack real
   (o explicar de forma explícita el modo "mock-only" como una de dos rutas).

2. **Métricas falsas/incoherentes en la documentación.**
   - `README.md:28` "`flutter analyze` → 0 issues" → real **6**.
   - `README.md:28,75` "56/56" → real **137** (`project.json` ya era correcto).
   - `docs/tfg/05` reclamaba ~45 % de cobertura; medición real **23,2 %**
     (23,4 % el 15-may; re-medido el 17-may tras P1/P2).
   **Acción:** regenerar `flutter analyze` / `flutter test --coverage` y citar
   cifras reales en README y `docs/tfg/05`.

3. **Alcance prometido no demostrable.** `pubspec.yaml:2` promete "multioperador
   para toda España, GTFS-Realtime, WCAG 2.1 AA, panel admin/moderación". En la
   build local solo hay datos de COMUJESA (`assets/mock/`), Realtime (F13) **no
   está implementado** (los `watch()` de los repos `remote` solo emiten snapshot
   + refresh manual, con comentarios "F13 conectará…"), y los otros 9 operadores
   dependen de un Supabase no incluido. **Acción:** alinear la descripción con lo
   realmente demostrable, o marcar lo no demostrado como "trabajo futuro".

### 🟠 Alto

4. **Realtime (F13) sin implementar** en `lib/data/*/remote/*_repository.dart`
   (p. ej. `stop_remote_repository.dart`, `route_remote_repository.dart`): la
   funcionalidad central "tiempo real" es en realidad refresco manual. Es la
   mayor brecha funcional frente al título del proyecto.

5. **Doble modelo de usuario sin sincronizar.** `currentUserProvider`
   (`lib/shared/providers/user_provider.dart`) deriva de mock + `isDriverMode`
   (StateProvider), mientras `AuthRepositorySupabase` gestiona la sesión real;
   los guards de rol del router (`lib/core/router/app_router.dart`) usan el mock.
   El control de acceso por rol no es fiable.

6. **Excepciones silenciadas.** `catch (_) {}` sin log en `lib/main.dart`,
   `appearance_screen.dart`, `privacy_screen.dart`, `map_filter_controller.dart`.
   Especialmente grave en el flujo de consentimiento/telemetría (depurar
   incidencias se vuelve imposible).

7. **Backend expuesto.** Edge `import_gtfs` con CORS `*` y descarga de URL
   arbitraria (riesgo SSRF); `send_notification` sin rate-limit ni validación de
   que `user_id` pertenezca al solicitante; ref de proyecto de producción
   hardcodeada en `supabase/migrations/015_push_triggers.sql:85`. En contexto
   académico se clasifica como Alto (no Crítico), pero debe figurar en la memoria
   como deuda de seguridad reconocida.

8. **Pantallas stub enrutadas.** Varias screens (`driver_history_screen.dart`,
   `driver_stats_screen.dart`, `ai_schedule_import.dart`,
   `filter_presets_screen.dart`, `planned_trips_screen.dart`,
   `suggestion_contribute_screen.dart`) muestran solo placeholders pero están en
   el router → UX rota si el tribunal navega allí. Completar u ocultar de la
   navegación.

9. **"WCAG 2.1 AA" sobre-reclamado.** El esfuerzo real es serio, pero no hay
   verificación con TalkBack/VoiceOver, el mapa no es accesible y los Semantics
   están en español hardcodeado. `docs/A11Y_AUDIT.md` es honesto y lista los
   gaps; `pubspec.yaml` y el material divulgativo deberían decir "AA parcial".

### 🟡 Medio

10. **Cobertura de pruebas insuficiente para el tamaño** (143 tests, 23,2 % líneas / 49 K LOC;
    `bus_estimator`, `offline_sync_service` y los repos sin tests reales —
    predominio de smoke/estructura). Aceptable en TFG solo si se declara como
    deuda explícita.
11. **Valores hardcodeados fuera del design system**: ~32 `Color(0x…)`, ~200+
    `EdgeInsets.*` literales y strings quemados (p. ej.
    `profile_contributions_section.dart` "12 reportes · 3 verificadas").
    Contradice el principio de tokens del propio proyecto.
12. **GDPR — orden de init de telemetría**: debe demostrarse que Sentry/PostHog
    **no** se inicializan antes de cargar el consentimiento (`main.dart`,
    `sentry_setup.dart`, `analytics_provider.dart`,
    `privacy_consent_provider.dart`). Si la init es eager → incidencia GDPR.
13. **`google_fonts` en runtime** (TODO F26 sin cerrar): sin red, la tipografía
    cae a system font; además hay fuga de IP a Google. Empaquetar fuentes locales.
14. **FORCE RLS desactivado** (decisión documentada) sin triggers de auditoría:
    cualquier bug en una Edge con `service_role` implica acceso total.
15. **README con nomenclatura de fases obsoleta** ("P15→P42") frente a la real
    "F0→F27" de `docs/tfg` y `multiagent/state`.

### 🔵 Bajo

16. 6 issues `info` de `flutter analyze` (const / conditional / underscore).
17. Modelos manuales (`achievement_model.dart`, `feedback_message_model.dart`)
    fuera del patrón freezed → inconsistencia.
18. `test/hive_temp/` vacío y commiteado; conviene ignorarlo.
19. ~~i18n EN incompleto (~60 % del ES)~~ **Corregido/aclarado:** el "~60 %"
    era un recuento por líneas de un ARB multilínea; verificado por clave, ES y
    EN están **completos y sincronizados (275/275)**. El gap real eran strings
    ES hardcodeados (`offline_banner.dart`), ahora enrutados por l10n.
20. Mezcla de imports relativos/absolutos; ubicación data↔features inconsistente
    (`features/map/map_data_cache.dart`).

---

## Recomendaciones priorizadas (plan de remediación)

**P0 — antes de la defensa (horas):**
- Reescribir `README.md`: stack real, cifras reales de analyze/test, nomenclatura F.
- Regenerar cobertura (`flutter test --coverage`) y citar el valor real en `docs/tfg/05`.
- Alinear `pubspec.yaml:2` y los claims con lo demostrable; mover Realtime y
  multioperador a "trabajo futuro" si no se demuestran.
- Degradar el reclamo de accesibilidad a "WCAG 2.1 AA parcial".

**P1 — calidad / seguridad (días):**
- Implementar F13 (Supabase Realtime) **o** documentarlo claramente como pendiente.
- Unificar el modelo de usuario (mock vs Supabase) y endurecer los guards de rol.
- Añadir logging a todos los `catch (_) {}`.
- Edge Functions: CORS restringido, validación de `user_id`, rate-limit; eliminar
  la ref hardcodeada (usar variable de entorno).
- Completar u ocultar las pantallas stub.

**P2 — deuda técnica (semanas):**
- Subir la cobertura de módulos críticos (`bus_estimator`, sync, repos) a un
  mínimo declarado.
- Migrar los valores hardcodeados a tokens del design system.
- Cerrar el TODO F26 (fuentes locales); completar i18n EN; limpiar `test/hive_temp/`.
- Demostrar/asegurar el consent-gating de telemetría antes de cualquier init.

---

## Veredicto

Proyecto **técnicamente notable** (arquitectura, design system, accesibilidad
seria, trazabilidad por fases, asistencia IA declarada con transparencia) pero con
un **desfase documentación↔código** que un tribunal penalizaría: el README
contradice al código en backend y métricas, y el alcance publicitado no es del
todo demostrable en la build entregada. Corregir los puntos **P0** (coste bajo,
casi todo documental) eleva la nota esperada de **~7.0 a ~8.0–8.5** sin tocar la
arquitectura.
