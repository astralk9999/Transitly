# 08 — Presentación Final

**Proyecto:** Transitly — Aplicación de transporte público en tiempo real
**Formato:** Defensa oral TFG · DAM/DAW
**Duración estimada:** 15-20 minutos

---

## 1. Estructura de la presentación

### Diapositiva 1 — Portada
- Título: **Transitly — Transporte público en tiempo real**
- Subtítulo: TFG · Desarrollo de Aplicaciones Multiplataforma
- Autor, fecha, logo de la app

### Diapositiva 2 — El problema
- Transporte público en España: apps dispares por operador
- Sin tracking en vivo en ciudades medias
- Sin participación ciudadana en la mejora del servicio
- **Dato:** 10 operadores, cada uno con su propia app o sin app

### Diapositiva 3 — La solución
- App unificada multioperador para toda España
- Tracking en vivo: oficial (GTFS-Realtime) + comunitario (conductores)
- Comunidad: incidencias, sugerencias, votos
- Offline-first: funciona sin internet

### Diapositiva 4 — Demo en vivo (3 min)
- Abrir la app en Android
- Mostrar mapa con rutas de Jerez
- Buscar una parada y ver próximas llegadas
- Reportar una incidencia de prueba
- Mostrar panel de administración

### Diapositiva 5 — Arquitectura técnica
- **Frontend:** Flutter 3.x + Dart (multiplataforma real)
- **Backend:** Supabase (PostgreSQL + Auth + Realtime + Storage + RLS + PostGIS)
- **Estado:** Riverpod 2.x
- **Mapas:** flutter_map + MapTiler
- **Caché offline:** Hive con cifrado AES
- **Arquitectura:** Feature-first con clean architecture

### Diapositiva 6 — Modelo de datos
- Diagrama ER simplificado: User → Operator → Route → Stop → Schedule → BusLocation
- Sistema de contribuciones: Incident, RouteFeedback, RouteSuggestion
- 25 tablas con Row-Level Security (102 policies)

### Diapositiva 7 — Funcionalidades clave
- **Multioperador:** 10 ciudades españolas, lazy loading geoespacial
- **Tracking híbrido:** GTFS-Realtime + GPS conductor + estimación horaria
- **Comunidad activa:** Incidencias, sugerencias, votos, reputación
- **Offline-first:** Caché local + cola de acciones pendientes
- **Accesibilidad:** WCAG 2.1 AA, alto contraste, fuente dislexia, color-blind
- **Admin panel:** Gestión de usuarios, operadores, moderación
- **Apariencia:** 6 paletas, 5 fondos, tema custom con validación WCAG AA
- **Notificaciones push:** FCM + in-app con quiet hours y preferencias
- **Web híbrida:** Astro SSR con páginas públicas SEO-friendly
- **Privacidad GDPR:** Consentimientos, exportación/borrado de datos

### Diapositiva 8 — Sistema multiagente (innovación)
- 5 agentes autónomos para desarrollo con IA
- Queen → Developer → Review → Git → Documentation
- Pipeline automatizado con estado compartido
- Commits semánticos + push automático

### Diapositiva 9 — Planificación
- Mostrar Gantt con 27 fases completadas/restantes
- 26/28 fases completadas (92.9%)
- ~80 commits, 137 tests, 35k+ líneas de código

### Diapositiva 10 — Métricas y calidad
- 137 tests pasando, 0 fallando
- flutter analyze: 0 errors, 0 warnings
- CI/CD con GitHub Actions (analyze + test en push/PR)
- 27 widgets compartidos reusables
- 12 repositorios con patrón canónico
- 20+ modelos @freezed tipados

### Diapositiva 11 — Lecciones aprendidas
- **Planificación:** Fases atómicas de 1-3 días funcionan mejor
- **IA como herramienta:** Multiagente reduce errores y acelera desarrollo
- **Offline-first:** Más complejo pero esencial para transporte público
- **RLS en Supabase:** 102 policies = seguridad granular sin código backend
- **Comunidad:** Los datos de usuarios son tan valiosos como los oficiales
- **Accesibilidad desde el inicio:** Integrar WCAG AA evita retrabajo masivo

### Diapositiva 12 — Trabajo futuro
- F27: Wearables nivel 1 (Apple Watch complications, Wear OS tiles)
- Post-TFG: Publicación en Play Store (internal testing → beta)
- App Store: iOS release con TestFlight
- Monetización: B2C premium, B2B operadores
- Comunidad: gamificación de contribuciones, moderadores comunitarios

### Diapositiva 13 — Agradecimientos y preguntas
- Gracias
- ¿Preguntas?
- Demo adicional si hay tiempo

---

## 2. Timing

| Sección | Tiempo |
|---------|--------|
| Portada + Problema + Solución | 2 min |
| Demo en vivo | 3 min |
| Arquitectura + Datos | 3 min |
| Funcionalidades + Multiagente | 3 min |
| Planificación + Métricas | 2 min |
| Lecciones + Futuro | 2 min |
| Preguntas | 5 min |

---

## 3. Recursos a preparar

- [ ] App compilada en APK para demo rápida
- [ ] Datos de prueba cargados (modo invitado)
- [ ] Conexión a internet para mostrar modo online
- [ ] Modo avión para mostrar funcionamiento offline
- [ ] Slides en Canva / Google Slides / PowerPoint
- [ ] Diagrama ER exportado de Supabase
- [ ] Gantt actualizado de docs/tfg/03_planificacion.md

---

**Última actualización:** 2026-05-15 · F26 · Documentation Agent
