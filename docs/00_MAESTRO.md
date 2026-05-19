# Transitly — Documento Maestro (fuente única de verdad)

> **Propósito:** punto de entrada y fuente única de verdad de toda la
> documentación. Cualquier cifra o afirmación que contradiga a este documento
> es obsoleta.
> **Óptica de esta auditoría:** **app real en producción** para decenas o
> cientos de miles de usuarios — no la lente indulgente de un TFG. Se evalúa
> contra estándares de ingeniería de producto: escalabilidad, accesibilidad
> WCAG 2.2 AA plena, seguridad, observabilidad y operabilidad.
> **Estado verificado:** `master @ 6f26725` · 2026-05-19 ·
> `flutter analyze` 0 issues · `flutter test` **148/148** ·
> cobertura **24,74 %** (3 860/15 605) · `flutter build apk --release` OK
> (73 MB, firmado con **debug keys** ⚠️) · CI GitHub **verde** (web).

---

## 1. Veredicto crítico (lente de producción)

**Como TFG académico:** notable (≈7,8/10) — arquitectura limpia, design
system, accesibilidad con esfuerzo real, honestidad documental ya reparada,
CI/APK verdes.

**Como producto real en producción: NO está listo. ≈4,5/10.** El proyecto es
un *prototipo demostrable de operador único con datos mock*, no un servicio
escalable. Las tres barreras de fondo siguen intactas y **ninguna es
documental — exigen implementación**:

1. **No hay "tiempo real".** F13 sin implementar: **0 de 12** repos `remote/`
   tienen suscripción Supabase; el bus "en vivo" es una simulación con
   `Timer`. El producto no cumple su propia premisa.
2. **No escala a multi-operador.** Solo datos COMUJESA mock; los ~9 operadores
   restantes dependen de un Supabase no poblado. Sin paginación, sin
   clustering de mapa, sin estrategia de caché a escala.
3. **Accesibilidad sobre-reclamada.** "WCAG 2.1 AA parcial" es generoso:
   mapa inaccesible, `Semantics` en español hardcodeado, sin paso real con
   lector de pantalla, `textScaler` pisa el del sistema operativo.

A esto se suman bloqueadores de **release/operación** que un TFG oculta pero
producción no perdona: APK firmado con **claves de debug** (no publicable),
`.env` empaquetado como asset (SEC2), PAT de Supabase vivo en disco (SEC1),
CI sin gate de cobertura ni build móvil, 0 `autoDispose` (fugas a escala),
sin observabilidad de negocio/SLO.

> **Conclusión honesta:** excelente como prototipo académico y base
> arquitectónica; **lejos de producción**. La distancia no se cierra
> redactando documentación: se cierra implementando los bloques **P2** del
> plan más los bloqueadores de producción nuevos (§4).

---

## 2. Mapa de la documentación (qué es fuente de verdad de qué)

| Documento | Rol | Estado |
|-----------|-----|--------|
| **`docs/00_MAESTRO.md`** (este) | Índice + veredicto + estado verificado | ✅ Fuente de verdad |
| `docs/SCALABILITY.md` | Dossier de escalabilidad (producción) | ✅ Nuevo, autoritativo |
| `docs/ACCESSIBILITY.md` | Dossier WCAG 2.2 AA (producción) | ✅ Nuevo, autoritativo; **supera** a `A11Y_AUDIT.md` |
| `docs/PLAN_ACCION_REMEDIACION.md` | Plan accionable P0–P3 + Workstream R + producción | ✅ Vigente |
| `docs/REVISION_INDEPENDIENTE_2026_05_17.md` | Auditoría crítica (4 pasadas + hallazgos CI/APK) | ✅ Vigente (histórico de pasadas) |
| `README.md` | Entrada del repo | 🟡 Honesto pero falta marco producción/escala (ver §3) |
| `AGENTS.md` | Guía operativa para agentes | 🔴 **Cifras obsoletas** (ver §3) |
| `docs/A11Y_AUDIT.md` | Auditoría a11y previa | 🟡 Honesta pero **incompleta** vs `ACCESSIBILITY.md` |
| `docs/PENDIENTES.md` | Cola de deuda | 🟡 Sincronizar con el plan |
| `docs/REVISION_CRITICA.md` | 1.ª revisión (2026-05-15) | 🟡 Histórico; no es estado actual |
| `docs/tfg/01..08` | Memoria académica | 🟡 Métricas parcialmente reconciliadas (ver §3) |
| `multiagent/state/project.json` | Estado del proceso multiagente | 🟡 tests ya 148; `progress_pct:100` confunde "fases" con "producción" |
| `docs/AUDIT_2026_04.md`, `SESSION_AUDIT_2026_05.md` | Auditorías históricas | ⚪ Archivo (no tocar; son registro temporal) |

**Regla:** ante conflicto de cifras entre documentos, gana este Maestro.
Orden de lectura recomendado: Maestro → Scalability → Accessibility → Plan.

---

## 3. Ledger de correcciones documentales (errores detectados)

Errores concretos pendientes de corregir en cada doc (no se reescriben los 8
TFG inline por volumen; esto es la lista autoritativa de qué está mal):

- **`AGENTS.md`**
  - L27: «107 tests» → **148**.
  - L201: «5 migraciones SQL» → **13** (`supabase/migrations/`).
  - L204: «RLS activo en 25 tablas con 102 policies» → verificar y citar
    cifra real; el número está sin re-verificar tras nuevas migraciones.
  - L200: documenta el project-ref de Supabase en claro — aceptable (es la
    URL pública), pero conviene marcar que **no** implica multi-región.
  - Falta: nota de que `workmanager` fue eliminado y de freezed 3 / go_router 17.
- **`multiagent/state/project.json`**: `flutter_test` ya **148** (corregido);
  pero `progress_pct: 100` induce a error — es "fases del plan completas",
  **no** "producto listo para producción". Renombrar/anotar.
- **`README.md`**: honesto en backend/tests, pero **no advierte** que el APK
  se firma con debug keys, que `.env` se bundlea, ni el carácter
  mock/operador-único. Añadir sección "Production readiness: NOT READY".
- **`docs/tfg/04`**: bloque de fases ya a 28/28; revisar que no queden
  referencias «F0→F25 / En progreso F26».
- **`docs/tfg/05` (evaluación)**: cobertura ya 24,7 % y 148 tests
  (reconciliado en P0-4); añadir caveat de "no apto producción" para no
  inducir a error al tribunal sobre el alcance real.
- **`docs/tfg/02`/`06`/`08`**: revisar claims de "tiempo real" y "WCAG AA" —
  deben decir "simulado / parcial" coherente con §1.
- **`docs/A11Y_AUDIT.md`**: correcto pero queda **subsumido** por
  `docs/ACCESSIBILITY.md`; marcar como histórico y apuntar al nuevo.
- **`docs/REVISION_CRITICA.md`**: 1.ª pasada (15-may); marcar como histórico
  para que nadie lo confunda con el estado actual.

---

## 4. Bloqueadores de producción (resumen; detalle en dossiers)

| # | Bloqueador | Dossier | Severidad prod |
|---|------------|---------|:--:|
| B1 | F13 Realtime inexistente (0/12 repos) | SCALABILITY §Realtime | 🔴 Crítico |
| B2 | Sin paginación en repos `remote/` (carga total) | SCALABILITY §Datos | 🔴 Crítico |
| B3 | APK release firmado con **debug keystore** (`build.gradle.kts:39`) | SCALABILITY §Release | 🔴 Crítico |
| B4 | `.env` empaquetado como asset (SEC2) | SCALABILITY §Seguridad | 🔴 Crítico |
| B5 | PAT de Supabase vivo en `.mcp.json` (SEC1) | SCALABILITY §Seguridad | 🔴 Crítico (rotar ya) |
| B6 | 0 `autoDispose` → fuga de memoria/streams a escala | SCALABILITY §Estado | 🟠 Alto |
| B7 | Mapa sin `Semantics` (inaccesible para lector) | ACCESSIBILITY §1.1/4.1 | 🔴 Crítico a11y |
| B8 | `Semantics` ES hardcodeado; `textScaler` pisa el del SO | ACCESSIBILITY §1.3/1.4 | 🟠 Alto a11y |
| B9 | Doble modelo de usuario (rol no fiable) | SCALABILITY §Seguridad | 🟠 Alto |
| B10 | Sin observabilidad de negocio/SLO/alertas | SCALABILITY §Observabilidad | 🟠 Alto |
| B11 | CI sin gate de cobertura ni build móvil; sólo web | SCALABILITY §Pipeline | 🟠 Alto |
| B12 | Fuentes por red (`_fontsBundled=false`) + APK 73 MB | ACCESSIBILITY §Inclusión | 🟠 Alto |

El plan de remediación priorizado (P0–P3 + producción) vive en
`docs/PLAN_ACCION_REMEDIACION.md`, ahora ampliado con estos bloqueadores.

---

## 5. Cómo evolucionar la documentación (escalable y mantenible)

- **Una fuente de verdad por tema** (este Maestro indexa; los dossiers
  profundizan; el plan acciona). Nada de cifras duplicadas en 8 sitios.
- **Regla de sincronía:** al cerrar un ítem, actualizar SOLO el plan + este
  Maestro; el resto enlaza, no copia.
- **Los `docs/tfg/` citan, no inventan:** las métricas deben venir de
  `flutter test --coverage` + CI, nunca a mano.
- **Archivar lo histórico** (`REVISION_CRITICA`, `AUDIT_2026_04`,
  `SESSION_AUDIT`) en `docs/historico/` para que el árbol activo sea legible.
