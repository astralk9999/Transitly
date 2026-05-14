# 01 — Análisis del Contexto y Detección de Necesidades

**Proyecto:** Transitly — Aplicación de transporte público en tiempo real
**Autor:** Desarrollo individual
**Fecha:** 2026-05-14
**TFG:** DAM/DAW — Desarrollo de Aplicaciones Multiplataforma

---

## 1. Sector y problema concreto

### Sector
Transporte público urbano e interurbano en España.

### Problema detectado
Los usuarios de autobuses urbanos en ciudades medias españolas carecen de información en tiempo real sobre:
- Ubicación exacta de los autobuses en ruta
- Tiempos de llegada estimados a paradas
- Incidencias en el servicio (retrasos, desvíos, averías)
- Paradas cercanas con rutas disponibles

Las aplicaciones oficiales de cada operador son dispares, no interoperables entre ciudades, y muchas carecen de tracking en vivo.

### Oportunidad
Crear una **app unificada multioperador** que funcione en cualquier ciudad española, combinando:
- Datos oficiales GTFS de cada operador
- Datos comunitarios aportados por los propios usuarios
- Tracking GPS en vivo desde conductores
- Estimación de posiciones por horario cuando no hay datos en vivo

---

## 2. Tipos de empresas y estructuras

### Operadores de transporte público
- **Empresas municipales:** COMUJESA (Jerez), EMT (Madrid, Málaga, Valencia), TUSSAM (Sevilla), Bilbobus (Bilbao)
- **Consorcios metropolitanos:** TMB (Barcelona), Consorcio Bahía de Cádiz
- **Concesionarias privadas:** Avanza (Zaragoza), TITSA (Tenerife), AUVASA (Valladolid)

### Estructura típica
Cada operador gestiona: rutas, horarios, flota de vehículos, conductores, incidencias.
Transitly abstrae esta estructura en un modelo de datos común (GTFS) que permite interoperar.

---

## 3. Necesidades actuales del sector

| Necesidad | Estado actual | Solución Transitly |
|-----------|--------------|-------------------|
| Información en tiempo real | Solo en grandes ciudades (Madrid, Barcelona) | GTFS-Realtime + comunidad + estimación |
| App unificada multioperador | Apps por operador, sin interoperar | App única con lazy loading geoespacial |
| Participación ciudadana | Buzones de sugerencias estáticos | Contribuciones en vivo: incidencias, sugerencias, votos |
| Tracking de bus por conductor | Solo en flotas con hardware GPS | App móvil del conductor emite posición cada 5s |
| Accesibilidad universal | Variable por operador | Modo alto contraste, fuente dislexia, lector de pantalla |

---

## 4. Oportunidades de negocio

- **B2C:** App gratuita con suscripción premium (offline maps, alertas push ilimitadas)
- **B2B:** Panel de administración para operadores (gestión de flota, incidencias, estadísticas)
- **Datos:** Análisis agregado de movilidad urbana (anónimo, GDPR-compliant)
- **Expansión:** Modelo escalable a cualquier país con GTFS (Europa, LATAM)

---

## 5. Guión de trabajo inicial

1. Auditoría del código base existente (F0)
2. Migración a arquitectura limpia con Supabase backend (F1-F3)
3. Sistema de autenticación y roles (F4-F6)
4. Importación masiva de datos GTFS de operadores españoles (F7-F8)
5. Experiencia core: mapa, búsqueda, filtros, tracking (F9-F14)
6. Comunidad: contribuciones, reputación, moderación (F15-F16)
7. Pulido visual, accesibilidad, infraestructura (F17-F22)
8. Plataformas extra: web, widgets nativos (F23-F24)
9. Privacidad, QA, publicación (F25-F27)

---

**Última actualización:** 2026-05-14 · Documentación Agent
