# 03 — Planificación de la Ejecución

**Proyecto:** Transitly
**Fecha:** 2026-05-14

---

## 1. Diagrama de Gantt

```mermaid
gantt
    title Transitly — Plan de Ejecución
    dateFormat  YYYY-MM-DD
    axisFormat  Semana %W
    
    section Bloque I - Cimientos
    F0 Auditoría           :done, f0, 2026-04-28, 3d
    F0.5 Higiene previa    :done, f05, after f0, 2d
    F1 Freezed selectivo   :done, f1, after f05, 2d
    F2 Backend Supabase    :done, f2, after f1, 3d
    F3 Repositorios+Hive   :done, f3, after f2, 4d

    section Bloque II - Identidad
    F4 Auth                :done, f4, after f3, 3d
    F5 Roles tipados       :done, f5, after f4, 1d
    F6 Códigos conductor   :done, f6, after f5, 2d

    section Bloque III - Datos
    F7 Importador GTFS     :done, f7, after f6, 3d
    F8 Detección geográfica:done, f8, after f7, 2d

    section Bloque IV - Experiencia core
    F9 Filtros + revisión  :done, f9, after f8, 2d
    F10 Editor manual      :done, f10, after f9, 3d
    F11 GPS Live Recorder  :done, f11, after f10, 2d
    F12 Compartir + oficializar :done, f12, after f11, 2d

    section Bloque V - Ojos del bus
    F13 GTFS-Realtime      :done, f13, after f12, 3d
    F14 Driver en vivo     :done, f14, after f13, 2d

    section Bloque VI - Comunidad
    F15 Contribuciones     :done, f15, after f14, 3d
    F16 Panel admin        :active, f16, after f15, 4d

    section Bloque VII - Pulido
    F17 Apariencia         :f17, after f16, 3d
    F18 Accesibilidad      :f18, after f17, 2d
    F19 Reputación visible :f19, after f18, 2d

    section Bloque VIII - Infraestructura
    F20 Mapas offline      :f20, after f19, 3d
    F21 Push + Realtime    :f21, after f20, 3d
    F22 Sentry + PostHog   :f22, after f21, 2d

    section Bloque IX - Plataformas
    F23 Web híbrida        :f23, after f22, 3d
    F24 Widgets nativos    :f24, after f23, 2d

    section Bloque X - Cierre
    F25 Privacidad + GDPR  :f25, after f24, 2d
    F26 QA + Performance   :f26, after f25, 3d
    F27 Wearable + Store   :f27, after f26, 2d
```

---

## 2. Asignación de recursos

| Recurso | Detalle |
|---------|---------|
| **Desarrollador** | 1 persona (full-stack Flutter + Supabase) |
| **Entorno** | Windows 11, VS Code, Android Studio |
| **Dispositivos test** | Android físico (API 24+), emulador iOS |
| **Servicios cloud** | Supabase (free tier), GitHub (repo) |
| **Herramientas IA** | OpenCode con sistema multiagente (Queen + Developer + Review + Git + Docs) |

---

## 3. Evaluación de riesgos

| Riesgo | Probabilidad | Impacto | Contingencia |
|--------|:---:|:---:|------|
| Supabase downtime | Baja | Alto | Caché Hive local + modo invitado mock |
| Cambios en API GTFS de operadores | Media | Medio | Edge Function de importación con validación |
| Incompatibilidad Flutter al actualizar | Baja | Medio | Pin de versiones en pubspec.yaml |
| Retraso acumulado por fases largas | Media | Alto | Fases atómicas de 1-3 días; plan flexible |
| Falta de testers reales | Alta | Bajo | Mock data simula usuarios; beta cerrada en F26 |

---

## 4. Entregables parciales

| Entrega | Fase | Fecha estimada | Contenido |
|---------|------|---------------|-----------|
| E1 — MVP backend | F3 | 2026-05-06 | Supabase operativo, repositorios, caché |
| E2 — MVP funcional | F14 | 2026-05-12 | App usable: auth, mapa, tracking, contribuciones |
| E3 — Versión completa | F22 | 2026-05-20 | Offline, push, monitoring, accesibilidad |
| E4 — Release candidate | F27 | 2026-05-25 | GDPR, QA, Play Store ready |

---

**Última actualización:** 2026-05-14 · Documentation Agent
