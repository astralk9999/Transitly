# Multiagent System · Arquitectura

**Versión:** 2.0 · **Fecha:** 14-may-2026

> Sistema de 7 agentes autónomos que trabajan dentro del repo Transitly,
> coordinados vía OpenCode Task tool. Estado compartido en `multiagent/state/`.

---

## Agentes

| # | Agente | Prompt | Rol | ¿Escribe código? | ¿Hace commit? |
|---|--------|--------|-----|:---:|:---:|
| 1 | **Queen** | `agents/queen.md` | Orquesta, descompone, delega, decide | No | No |
| 2 | **Developer** | `agents/developer.md` | Implementa, testea, lintea | Sí | No |
| 3 | **Innovation** | `agents/innovation.md` | Escanea, detecta deuda, propone mejoras | No (solo PROPUESTAS_FUTURAS.md) | No |
| 4 | **Review** | `agents/review.md` | Revisa diff, categoriza issues, emite veredicto | No | No |
| 5 | **Git** | `agents/git.md` | Commit semántico + push a GitHub | No | Sí |
| 6 | **Documentation** | `agents/documentation.md` | Mantiene docs TFG actualizados | No (solo docs/tfg/) | No |
| 7 | **Tracker** | `agents/tracker.md` | Verifica tareas, actualiza PENDIENTES.md, sincroniza fuentes | No (solo docs/) | No |

## Pipeline

```
┌─────────┐
│  Queen  │
│ analiza │
└────┬────┘
     │
     ├───▶ Developer (implementa) ───┐
     │                                │
     ├───▶ Innovation (escanea) ─────┤  ← PARALELO: Dev + Innovation
     │                                │
     │                                ▼
     │                          ┌─────────┐
     │                          │ Review  │
     │                          │ verifica│
     │                          └────┬────┘
     │                               │
     │                    ┌──────────┼──────────┐
     │                    ▼          ▼          ▼
     │              Ready      With fixes   Rejected
     │                    │          │          │
     │                    ▼          ▼          ▼
     │                  ┌─────┐  Developer   ABORT
     │                  │ Git │  (corrige)
     │                  │commit│
     │                  │+push│
     │                  └──┬──┘
     │                     │
     │         ┌───────────┼───────────┐
     │         ▼                       ▼
     │   Documentation           Tracker        ← PARALELO: Docs + Tracker
     │   (actualiza tfg/)   (verifica + PENDIENTES)
     │                     │
     └─────────────────────┘
               │
               ▼
          Queen actualiza
          state + reporta
```

## Estado compartido

```
multiagent/state/
├── project.json    # Fase actual, sprint, último commit, métricas
└── queue.json      # Cola de tareas: pendientes, activas, completadas
```

## Documentación gestionada por el sistema

```
docs/
├── historico/PLAN_TRANSITLY_V2.md          # Plan de 27 fases (leído por Queen)
├── PENDIENTES.md                  # Incidencias y mejoras (mantenido por Tracker)
├── PROPUESTAS_FUTURAS.md          # Ideas y mejoras (mantenido por Innovation)
├── ARCHITECTURE.md                # Reglas de arquitectura (referencia)
├── historico/AUDIT_2026_04.md              # Auditoría (sincronizado por Tracker)
└── tfg/                           # Documentación académica (mantenido por Documentation)
    ├── 01_analisis_contexto.md
    ├── 02_diseno_proyecto.md
    ├── 03_planificacion.md
    ├── 04_desarrollo_implementacion.md
    ├── 05_evaluacion_documentacion.md
    ├── 06_manual_tecnico.md
    ├── 07_manual_usuario.md
    └── 08_presentacion.md
```

## Formato de mensajes (agente → agente)

Cada tarea que Queen delega sigue este esquema JSON:

```json
{
  "task_id": "F16-001",
  "title": "Crear panel admin básico",
  "phase": "F16",
  "priority": "high",
  "files_to_create": ["lib/features/admin/admin_screen.dart"],
  "files_to_modify": ["lib/core/router/app_router.dart"],
  "requirements": [
    "Pantalla accesible solo para role admin",
    "Lista de usuarios con filtro por rol",
    "CRUD básico de operadores"
  ],
  "acceptance_criteria": [
    "flutter analyze pasa sin warnings",
    "flutter test pasa (tests nuevos incluidos)",
    "Navegación desde perfil → admin panel funciona"
  ],
  "references": [
    "docs/historico/PLAN_TRANSITLY_V2.md §F16",
    "lib/data/operator/ (patrón canónico)"
  ]
}
```

## Invocación

El usuario arranca una sesión con:

```
Ejecutar ciclo multiagente. Fase actual: F16. Objetivo: panel admin.
```

## Reglas de oro

1. Queen nunca escribe código ni hace commits.
2. Developer corre `flutter analyze` + `flutter test` antes de reportar.
3. Innovation solo lee código y escribe en `PROPUESTAS_FUTURAS.md`.
4. Review bloquea el merge si hay issues Critical.
5. Git solo commitea si Review dio OK. Push automático a origin.
6. Documentation se ejecuta tras cada commit. Solo actualiza `docs/tfg/`.
7. Tracker verifica, sincroniza PENDIENTES + AUDIT + PLAN. No borra ítems.
8. Todo estado se persiste en `state/` entre sesiones.

## Roadmap del sistema

- ✅ **v1.0 (MVP):** Queen + Developer + Review + Git. Pipeline secuencial.
- ✅ **v1.2:** Documentation Agent (docs TFG: 8 archivos alineados a guía académica).
- ✅ **v2.0:** Innovation Agent + Tracker Agent. 7 agentes total. Paralelismo Dev+Innovation y Docs+Tracker.
- ⏳ **v2.1:** Dispatcher unificado (cambio de agente con palabra clave: `queen`, `dev`, `review`, `git`, `innovate`, `docs`, `track`).
