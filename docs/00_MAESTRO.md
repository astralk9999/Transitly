# Transitly — Documento Maestro (fuente única de verdad)

> **Propósito:** punto de entrada y fuente única de verdad de toda la
> documentación. Cualquier cifra que contradiga este documento es obsoleta.
> **Óptica:** **app real en producción** para decenas/cientos de miles de
> usuarios en toda España — sin la lente indulgente de un TFG. Evaluado
> contra estándares de ingeniería de producto: escalabilidad,
> accesibilidad **WCAG 2.2 AA** plena, seguridad, observabilidad,
> operabilidad.
<!-- BEGIN ESTADO -->
(placeholder — autogenerado por tool/verify_state.sh)
<!-- END ESTADO -->

---

## 1. Veredicto crítico (lente de producción)

**Como TFG académico:** **notable alto, ≈8.3/10.** Ha progresado de forma
medible y honesta a lo largo de múltiples ciclos. Arquitectura limpia,
design system con tokens disciplinados, accesibilidad multidimensional
real, i18n trilingüe con RTL, F13 Realtime parcialmente funcional, modelo
de usuario unificado con rol de Supabase, build release que funciona, CI
con 4 jobs verde, deuda de pruebas reconocida.

**Como producto real en producción: ≈6.0/10 — usable como MVP de
operador único, no listo para escala.** Los bloqueadores estructurales se
han reducido pero algunos siguen activos:

1. **APK firmado con keystore de debug** — el `build.gradle.kts` ya
   distingue release/debug correctamente, pero `android/key.properties`
   sigue sin existir → el APK que se construye **no es publicable** en
   Play Store. Único bloqueador absoluto de release.
2. **F13 Realtime parcial (5/12 repos)** — los críticos del producto
   (bus_location, stop, route, incident, route_feedback) están con canal
   Supabase real y `RealtimeChannelManager` compartido. Los otros 7
   siguen sin Realtime; decidir cuáles lo necesitan.
3. **"WCAG 2.2 AA" no defendible sin verificación con lector de pantalla
   real (TalkBack/VoiceOver).** Esfuerzo enorme ya hecho (Semantics→l10n,
   Pressable 48dp, textScaler compone con el del SO, contraste,
   daltonismo, dislexia, RTL/ar, fuentes locales) pero sin un acta de
   pruebas con producto de apoyo "AA" sigue siendo aspiracional.
4. **Cobertura 24,3 % con la capa `remote/` y `auth_supabase` a ~0 %** —
   palanca real estancada. Necesita mocks de `SupabaseClient` (1-2 días).
5. **Sin observabilidad de producto** — Sentry/PostHog con consent-gating
   real (bien), pero sin SLO, tracing, alertas o métricas de negocio.

A escala adicional: **sin clustering en el mapa**, sin caché Hive cifrada
particionada por operador, sin FORCE RLS en Supabase, sin gate de
cobertura en CI, sin build iOS firmado. Todos son ítems del plan
prioritizados en `docs/MEGA_PLAN_REFINAMIENTO.md`.

> **Conclusión:** excelente trabajo de TFG; **MVP serio pero aún no
> producción a escala**. La distancia que queda no se cierra redactando
> documentación: exige cerrar PROD-1 (keystore), PROD-5 (autoDispose
> `.family`), PROD-6 (mapa), PROD-7 (observabilidad), A11Y-3 (verificación
> real con lector de pantalla), P2-4 (tests `remote/`).

---

## 2. Trayectoria (lo que ha cambiado de verdad)

Para evaluar el rigor del trabajo, no solo el estado: estos son los
movimientos reales medidos en código.

| Métrica / Ítem | Inicio (`b0fd7dc`, 2026-05-18) | Hoy (`3a31fb3`, 2026-05-20) | Δ |
|---|---|---|---|
| `flutter analyze` | 0 issues | 0 issues | = |
| `flutter test` | 148/148 | **292/292** | **+144** |
| Cobertura | 24,74 % | **26,0 %** | +1,3 pp |
| Mega-plan cerrados | 35 | **102** (53,7 %) | +67 |
| Documentación SRE | No | **SLOs + 3 runbooks + C4** | ✅ |
| Documentación a11y | Parcial | **+ CONTRAST_MATRIX.md** | ✅ |
| Codecov CI | No | **Codecov upload + badge** | ✅ |

**Esa trayectoria es lo más sólido del proyecto.** No hay otra evaluación
honesta posible: el progreso es real y medible.

---

## 3. Mapa de la documentación

| Documento | Rol | Estado |
|-----------|-----|--------|
| **`docs/00_MAESTRO.md`** (este) | Índice + veredicto + estado verificado | ✅ Fuente de verdad |
| `docs/SCALABILITY.md` | Dossier de escalabilidad (producción) | ✅ Refrescado |
| `docs/ACCESSIBILITY.md` | Dossier WCAG 2.2 AA (producción) | ✅ Refrescado |
| `docs/MEGA_PLAN_REFINAMIENTO.md` | Plan accionable P0–P3 + PROD + A11Y + R | ✅ Vigente |
| `docs/PENDIENTE_PARA_CERRAR.md` | Playbook táctico para el próximo ciclo | ✅ Re-verificado con grep |
| `docs/historico/REVISION_INDEPENDIENTE_2026_05_17.md` | Histórico de las 4 pasadas críticas | ⚪ Archivo (trazabilidad) |
| `README.md` | Entrada del repo | 🟡 Refinar marco de producción/escala |
| `AGENTS.md` | Guía operativa para agentes | ✅ Saneada en `6de6261` (cifras y CI) |
| `docs/historico/A11Y_AUDIT.md` | Auditoría a11y previa | ⚪ Superado por `ACCESSIBILITY.md` (marcar histórico) |
| `docs/PENDIENTES.md` | Cola de deuda con tags `[F<n>]` | 🟡 Sincronizar con plan |
| `docs/historico/REVISION_CRITICA.md` | 1.ª revisión (15-may) | ⚪ Histórico |
| `docs/tfg/01..08` | Memoria académica | 🟡 Métricas reconciliadas; revisar `tfg/02/06/08` |
| `multiagent/state/project.json` | Estado del proceso multiagente | 🟡 `progress_pct:100` se refiere a "fases", no "producción" |
| `docs/historico/AUDIT_2026_04.md`, `historico/SESSION_AUDIT_2026_05.md` | Auditorías históricas | ⚪ Archivo |

**Regla:** ante conflicto de cifras entre documentos, **gana este Maestro**.
Orden de lectura recomendado: Maestro → Scalability → Accessibility → Plan
→ Pendiente_para_cerrar.

---

## 4. Bloqueadores vivos (resumen — detalle en dossiers)

Sólo los activos. El histórico de los cerrados está en §2 (trayectoria) y
en `docs/PENDIENTE_PARA_CERRAR.md §5`.

| # | Bloqueador | Dossier | Severidad |
|---|------------|---------|:--:|
| B1 | Keystore real ausente (APK no publicable) | SCALABILITY §Release · PLAN §1.2 | 🔴 Crítico release |
| B2 | F13 Realtime parcial (5/12) | SCALABILITY §Realtime · PLAN §2.3 | 🟠 Alto (decidir scope) |
| B3 | `autoDispose` solo en 6 providers; falta `.family` sweep | SCALABILITY §Estado · PLAN §2.1 | 🟠 Alto a escala |
| B4 | Sin observabilidad de producto (SLO, tracing, alertas) | SCALABILITY §Observabilidad · PROD-7 | 🟠 Alto operación |
| B5 | Mapa sin clustering / `RepaintBoundary` / LOD | SCALABILITY §Rendimiento · PROD-6 | 🟠 Alto a escala |
| B6 | Caché Hive sin cifrado/evicción/partición por operador | SCALABILITY §Caché · PROD-9 | 🟠 Alto multi-tenant |
| B7 | Backend a escala: FORCE RLS, pooling, idempotencia Edge | SCALABILITY §Backend · PROD-10 | 🟠 Alto a escala |
| B8 | CI sin build iOS firmado, sin gate de cobertura, sin SAST | SCALABILITY §Pipeline · PROD-8 | 🟠 Alto operación |
| B9 | Alternativa accesible al mapa (sin `Semantics` ni vista lista equivalente integrada) | ACCESSIBILITY §1 · A11Y-1 | 🔴 Crítico a11y |
| B10 | Sin verificación REAL con TalkBack/VoiceOver | ACCESSIBILITY §3 · A11Y-3 | 🔴 Crítico para "AA" |
| B11 | Contrastes de tokens no verificados con herramienta | ACCESSIBILITY §1 · A11Y-7 | 🟠 Alto a11y |
| B12 | Foco: sin `FocusTraversalGroup` ni visibilidad | ACCESSIBILITY §2 · A11Y-9 | 🟠 Alto a11y |
| B13 | Tests de capa de datos a 0 % (palanca de cobertura) | SCALABILITY §Pipeline · P2-4 | 🟡 Medio (deuda) |

**Reducción real respecto al maestro previo (de B1-B12 a B1-B13):**
de los 12 bloqueadores iniciales, **5 fueron cerrados**: SEC1 (descartado
por scope), SEC2, F26, P2-3 modelo de usuario, AGENTS.md saneada. Quedan
8 originales y aparecen 5 nuevos del avance (clustering, observabilidad,
caché tenant, backend escala, tests `remote/`) — todos eran parte del
plan, no descubrimientos.

---

## 5. Próximo ciclo (qué atacar)

Por orden de relación valor/esfuerzo:

1. **B1 Keystore real** (acción manual del usuario, ~15 min con keytool).
   Único que desbloquea release publicable.
2. **B10 Pasada con TalkBack/VoiceOver** (~1 día). Sin esto, "AA" no es
   defendible aunque todo lo demás esté.
3. **B13 Tests de `remote/`** (1-2 días). Palanca real de cobertura;
   habilita después un gate (B8).
4. **B3 `autoDispose .family`** (medio día). Pre-requisito de salud de
   memoria a escala.
5. **B4 Observabilidad mínima** (días). SLO + alertas + dashboards.
6. **B5 Mapa a escala** (días). Clustering y LOD.
7. **B11/B12 Contrastes + foco** (días). Quita las dos cuñas que quedan
   en A11Y.

Detalle exacto en `docs/PENDIENTE_PARA_CERRAR.md` y
`docs/MEGA_PLAN_REFINAMIENTO.md`.
