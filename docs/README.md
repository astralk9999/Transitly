# Documentación de Transitly — Índice

> Punto de entrada de toda la documentación del proyecto. Si solo lees un
> documento, lee **[`00_MAESTRO.md`](./00_MAESTRO.md)** (veredicto crítico,
> estado verificado y mapa de blockers).

---

## Entregables del TFG (mapeo a la guía)

La guía del proyecto exige siete entregables. Aquí está el fichero
correspondiente en este repositorio:

| # | Entregable exigido | Documento en el repo |
|---|--------------------|----------------------|
| 1 | **Memoria del Proyecto** (PDF, recopila todas las fases) | Conjunto **`docs/tfg/`** (8 ficheros, ver tabla abajo). Generar PDF concatenado al final. |
| 2 | **Aplicación Final** (código fuente y ejecutable) | Repositorio completo + `flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk` (73 MB) |
| 3 | **Documentación Técnica** (instalación, configuración, mantenimiento) | [`tfg/06_manual_tecnico.md`](./tfg/06_manual_tecnico.md) + [`PLATFORM_SETUP.md`](./PLATFORM_SETUP.md) + [`FCM_SETUP.md`](./FCM_SETUP.md) + [`HOME_WIDGETS.md`](./HOME_WIDGETS.md) + [`WEB_SETUP.md`](./WEB_SETUP.md) + [`FONTS_F26.md`](./FONTS_F26.md) + [`SECURITY_PAT_ROTATION.md`](./SECURITY_PAT_ROTATION.md) + [`../android/README.md`](../android/README.md) |
| 4 | **Manual de Usuario** (no técnico) | [`tfg/07_manual_usuario.md`](./tfg/07_manual_usuario.md) |
| 5 | **Presentación Final** (diapositivas defensa) | [`tfg/08_presentacion.md`](./tfg/08_presentacion.md) |
| 6 | **Diagrama de Gantt y cronograma** | [`tfg/03_planificacion.md`](./tfg/03_planificacion.md) |
| 7 | **Evaluación del Proyecto** (indicadores, incidencias, mejoras) | [`tfg/05_evaluacion_documentacion.md`](./tfg/05_evaluacion_documentacion.md) + [`00_MAESTRO.md`](./00_MAESTRO.md) + dossiers críticos |

### Memoria del Proyecto — desglose por fase de la guía

| Fase de la guía | Documento |
|-----------------|-----------|
| 1. Análisis del Contexto y Detección de Necesidades | [`tfg/01_analisis_contexto.md`](./tfg/01_analisis_contexto.md) |
| 2. Diseño del Proyecto | [`tfg/02_diseno_proyecto.md`](./tfg/02_diseno_proyecto.md) |
| 3. Planificación de la Ejecución | [`tfg/03_planificacion.md`](./tfg/03_planificacion.md) |
| 4. Desarrollo e Implementación | [`tfg/04_desarrollo_implementacion.md`](./tfg/04_desarrollo_implementacion.md) |
| 5. Seguimiento, Evaluación y Documentación | [`tfg/05_evaluacion_documentacion.md`](./tfg/05_evaluacion_documentacion.md) |
| Manual técnico | [`tfg/06_manual_tecnico.md`](./tfg/06_manual_tecnico.md) |
| Manual de usuario | [`tfg/07_manual_usuario.md`](./tfg/07_manual_usuario.md) |
| Presentación / defensa | [`tfg/08_presentacion.md`](./tfg/08_presentacion.md) |

---

## Auditoría de calidad (óptica de producción)

Documentación crítica del estado real del proyecto, con lente más exigente
que la mínima del TFG (escala, accesibilidad para todo el mundo,
seguridad). Útil para la sección de **Evaluación** y la **defensa**.

| Documento | Para qué |
|-----------|----------|
| [`00_MAESTRO.md`](./00_MAESTRO.md) | **Fuente única de verdad**: veredicto, trayectoria, bloqueadores, mapa documental. **Empieza aquí.** |
| [`SCALABILITY.md`](./SCALABILITY.md) | Dossier de escalabilidad para producción a escala (Top-10 blockers). |
| [`ACCESSIBILITY.md`](./ACCESSIBILITY.md) | Dossier WCAG 2.2 AA (sustituye y supera al histórico `A11Y_AUDIT.md`). |
| [`MEGA_PLAN_REFINAMIENTO.md`](./MEGA_PLAN_REFINAMIENTO.md) | **Mega-plan superset** (190 ítems = 57 originales + 133 nuevos de auditoría multi-agente) priorizado en hitos H0–H8 para TFG + stores + portfolio senior. |
| [`PENDIENTE_PARA_CERRAR.md`](./PENDIENTE_PARA_CERRAR.md) | Playbook táctico para el próximo ciclo. |
| [`PENDIENTES.md`](./PENDIENTES.md) | Cola de deuda interna con tags `[F<n>]`. |

---

## Referencia técnica viva

| Documento | Contenido |
|-----------|-----------|
| [`ARCHITECTURE.md`](./ARCHITECTURE.md) | Reglas de oro de arquitectura, capas, errores, logging. |
| [`DATA_INVENTORY.md`](./DATA_INVENTORY.md) | Catálogo de assets, JSON mock y pipeline de datos. |
| [`PLATFORM_SETUP.md`](./PLATFORM_SETUP.md) | Configuración Android/iOS/Web. |
| [`FCM_SETUP.md`](./FCM_SETUP.md) | Push notifications (Firebase Cloud Messaging). |
| [`HOME_WIDGETS.md`](./HOME_WIDGETS.md) | Widgets nativos Android/iOS. |
| [`WEB_SETUP.md`](./WEB_SETUP.md) | Setup específico Flutter Web. |
| [`FONTS_F26.md`](./FONTS_F26.md) | Empaquetado de fuentes (cerrado: DM Sans + IBM Plex Mono bundled). |
| [`SECURITY_PAT_ROTATION.md`](./SECURITY_PAT_ROTATION.md) | Procedimiento de rotación del PAT de Supabase. |
| [`WEARABLE_NIVEL_1.md`](./WEARABLE_NIVEL_1.md) | Integración wearables (F27). |
| [`RELEASE_CHECKLIST.md`](./RELEASE_CHECKLIST.md) | Checklist pre-release. |
| [`PROPUESTAS_FUTURAS.md`](./PROPUESTAS_FUTURAS.md) | Ideas y trabajo futuro. |
| [`../AGENTS.md`](../AGENTS.md) | Guía operativa para agentes (sesiones de desarrollo asistido). |

---

## Histórico (no leer salvo trazabilidad)

Documentos archivados en [`historico/`](./historico/). Conservados para
auditoría temporal del proceso, **no representan el estado actual**.

- `REVISION_CRITICA.md` — 1.ª revisión crítica del 2026-05-15.
- `REVISION_INDEPENDIENTE_2026_05_17.md` — Auditoría comprehensiva de 4
  pasadas; superada por [`00_MAESTRO.md`](./00_MAESTRO.md).
- `A11Y_AUDIT.md` — Auditoría de accesibilidad previa; superada por
  [`ACCESSIBILITY.md`](./ACCESSIBILITY.md).
- `AUDIT_2026_04.md` — Auditoría estática pre-sesión (abril 2026).
- `SESSION_AUDIT_2026_05.md` — Registro de la sesión 02-12 mayo 2026.
- `PLAN_TRANSITLY_V2.md` — Plan original de 28 fases (F0→F27); cerradas
  todas; reemplazado operativamente por
  [`MEGA_PLAN_REFINAMIENTO.md`](./MEGA_PLAN_REFINAMIENTO.md).

---

## Estado verificado a fecha de este índice

`master @ HEAD` · 2026-05-22 ·
`flutter analyze` **0 errors (22 info)** · `flutter test` **304 (1 skipped)** ·
cobertura **24,8 %** · `flutter build apk --release` OK 73,5 MB ·
**CI verde** (7 jobs incl. Build Android APK). · **112/190 mega-plan (58,9 %)** · **33 commits**.

Detalle y trayectoria completa en [`00_MAESTRO.md`](./00_MAESTRO.md).
