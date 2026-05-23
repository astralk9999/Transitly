# Archivo histórico documental — Transitly

> Documentos archivados el 2026-05-23 como parte de la sesión de limpieza
> documentada en `docs/historico/GUIA_LIMPIEZA_2026_05_23.md`.
>
> Estos archivos se mantienen aquí por trazabilidad académica (TFG) y
> auditoría histórica. **No son fuente operativa activa.** Para el estado
> actual del proyecto consultar:
> - `docs/00_MAESTRO.md` — fuente única de verdad
> - `docs/MEGA_PLAN_REFINAMIENTO.md` — roadmap activo
> - `docs/historico/REVISION_INDEPENDIENTE_2026_05_17.md` — decisiones críticas
> - `docs/historico/REVISION_FINAL_2026_05_23.md` — último informe de revisión

## Planes históricos (3 archivos)

| Archivo | Tamaño | Razón de archivado |
|---------|-------:|--------------------|
| `PLAN_TRANSITLY_V2.md` | 4.635 líneas | Plan original v2; absorbido por MEGA_PLAN_REFINAMIENTO.md |
| `PLAN_ACCION_REMEDIACION_v1.md` | 235 líneas | Plan v1 pre-auditoría (2026-05-18); reemplazado por v2 |
| `PLAN_ACCION_REMEDIACION_v2.md` | 2.805 líneas | Plan v2 ejecutado; objetivos absorbidos por MEGA_PLAN |

## Auditorías cerradas (5 archivos)

| Archivo | Fecha | Razón de archivado |
|---------|-------|--------------------|
| `AUDIT_2026_04.md` | 2026-04 | Auditoría abril; estado superado, hallazgos cerrados |
| `AUDIT_2026_05_22.md` | 2026-05-22 | Auditoría deep-dive; data refleja en 00_MAESTRO |
| `SESSION_AUDIT_2026_05.md` | 2026-05 | Auditoría sesión mayo; subsumida en PENDIENTE_PARA_CERRAR |
| `REVISION_CRITICA.md` | 2026-05-15 | 1.ª revisión crítica; trazabilidad histórica |
| `A11Y_AUDIT.md` | 2026-05 | Auditoría a11y; superada por ACCESSIBILITY.md + CONTRAST_MATRIX.md |

## Docs de features cerradas (12 archivos)

Implementaciones cerradas; documentación de cómo se hicieron, no referencia operativa.

| Archivo | Tema |
|---------|------|
| `ABI_SPLITS.md` | Split-per-ABI Android (implementado) |
| `FONTS_F26.md` | Bundling de fuentes locales (implementado) |
| `FMTC_LRU.md` | Caché LRU de tiles (implementado) |
| `FCM_SETUP.md` | Configuración Firebase Cloud Messaging (implementado) |
| `INFLESZ_AUDIT.md` | Auditoría legibilidad Inflesz (cerrada) |
| `SECURITY_PAT_ROTATION.md` | Rotación de PAT Supabase (procedimiento puntual) |
| `LOW_DATA_MODE.md` | Modo bajo consumo (implementado) |
| `HIVE_CACHE_TENANT.md` | Particionado Hive multi-operador (implementado parcial) |
| `MAP_CLUSTERING.md` | Clustering de markers (planificado) |
| `F2_VERIFICATION.md` | Verificación fase F2 del plan v2 |
| `SESSION_SUMMARY.md` | Resumen sesión cerrada |
| `PLAN_V2_PROGRESS.md` | Tracker progreso plan v2 (sustituido por MEGA_PLAN) |

## Docs fusionados (2 archivos)

| Archivo | Fusionado en |
|---------|--------------|
| `HOME_WIDGETS_DECISION.md` | `docs/HOME_WIDGETS.md` (sección "Decisión arquitectónica") |
| `WEARABLE_NIVEL_1.md` | `docs/HOME_WIDGETS.md` (sección "Wearable Nivel 1") |

---

**Total archivado:** 22 archivos
**Tamaño aprox.:** ~12.000 líneas
**Reducción de ruido:** 74 docs no-tfg → ~30 docs activos (-60%)
