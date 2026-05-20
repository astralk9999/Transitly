# 01 — Análisis del Contexto y Detección de Necesidades

**Proyecto:** Transitly — Aplicación multiplataforma de transporte público en tiempo real
**Autor:** Desarrollo individual (con asistencia documentada de sistema multiagente IA)
**TFG:** DAM/DAW — Desarrollo de Aplicaciones Multiplataforma
**Estado actual:** `master @ 3a31fb3` · 28/28 fases · 175 tests verdes · cobertura 24,30 % · CI verde

---

## 1. Sector y problema concreto

### 1.1. Sector

**Movilidad urbana e interurbana en España: transporte público colectivo
(autobús, principalmente).** Es un sector con tres rasgos distintivos
relevantes para una aplicación tecnológica:

- **Demanda masiva y diaria.** En 2024 (INE) los autobuses urbanos
  transportaron ~1.500 millones de viajeros en España; los interurbanos,
  ~600 millones. La inmensa mayoría son desplazamientos *rutinarios* en
  los que el usuario *valora información fiable a tiempo más que coste*.
- **Fragmentación operativa.** Cada ciudad o consorcio tiene su propio
  operador, su propia app, su propio modelo de datos y su propia tarjeta
  monedero. Cambiar de ciudad significa empezar de cero.
- **Heterogeneidad tecnológica.** Grandes ciudades (Madrid, Barcelona)
  exponen GTFS-Realtime y tienen apps maduras; ciudades medias (Jerez,
  Cuenca, Logroño) dependen de paneles web estáticos o apps mínimas sin
  tiempo real.

### 1.2. Problema detectado

El usuario de autobús urbano en una ciudad media española **no puede
saber con confianza dónde está su bus**. Las consecuencias prácticas:

- **No información de posición en vivo** — los autobuses no se ven en un
  mapa; el horario estático rara vez refleja la realidad.
- **No estimación de tiempo de llegada** — sin GPS en el vehículo, no hay
  predicción de minutos a la parada.
- **No comunicación de incidencias** — retrasos, desvíos o averías se
  conocen por redes sociales si tienen suerte.
- **App distinta por operador** — un viajero que se desplaza entre Jerez,
  Cádiz y Sevilla necesita tres apps con tres interfaces distintas.
- **Tarjeta de transporte opaca** — el saldo de la *Consorcio de
  Transportes de Andalucía* (NFC Mifare Classic) solo se consulta en
  taquillas o quioscos físicos.

El sub-problema relevante para este proyecto es: **dar al usuario de una
ciudad media (Jerez de la Frontera, COMUJESA) la experiencia de tiempo
real, accesibilidad y comunidad que solo tienen hoy las grandes
ciudades** — y dejar la arquitectura preparada para escalar a otros
operadores españoles.

### 1.3. Oportunidad

- **Una app unificada multi-operador** con datos GTFS oficiales,
  contribuciones de la comunidad (incidencias, sugerencias de rutas),
  tracking GPS opcional desde la app del propio conductor y estimación
  basada en horario cuando no hay vivo.
- **Accesibilidad de primera clase** para personas con discapacidad
  visual, motora o cognitiva — un colectivo grande de usuarios habituales
  del transporte público que las apps actuales atienden mal.
- **Lectura NFC de la tarjeta del Consorcio andaluz** sin pasar por
  máquinas físicas.

---

## 2. Tipos de empresas y estructuras

### 2.1. Operadores de transporte público en España

| Tipo | Ejemplos | Estructura típica |
|------|----------|-------------------|
| **Empresas municipales** (propiedad del ayuntamiento) | COMUJESA (Jerez), EMT (Madrid, Valencia, Málaga), TUSSAM (Sevilla), Bilbobus | Operan la flota directamente; contratan conductores; el ayuntamiento subvenciona el déficit. |
| **Consorcios metropolitanos** | TMB (Barcelona), Consorcio de Transportes de la Bahía de Cádiz, Consorcio de Transportes Sevilla | Agregan operadores municipales + interurbanos; gestionan tarjeta única; integran tarifas. |
| **Concesionarias privadas** | Avanza, TITSA (Tenerife), AUVASA (Valladolid), DAMAS | Adjudicación por concurso público; explotan rutas con flota propia. |
| **Apps agregadoras de terceros** | Moovit, Citymapper, Google Maps Transit | Consumen GTFS público pero no operan flota. |

### 2.2. Estructura interna típica de un operador

Independientemente de la forma jurídica, todos gestionan los mismos
objetos de negocio:

- **Rutas** (líneas con código y nombre comercial).
- **Paradas** (puntos físicos con código, nombre, coordenadas).
- **Horarios** (salidas por día de la semana, dirección y parada).
- **Flota** (vehículos con matrícula y plazas).
- **Conductores** (turnos, asignación a rutas).
- **Tarifas** (zonas, billete sencillo, tarjeta mensual, bonificaciones).
- **Incidencias** (averías, desvíos, refuerzos).

Transitly abstrae esto con un **modelo de datos común basado en GTFS**
(General Transit Feed Specification, el estándar de facto) que permite
interoperar entre operadores.

### 2.3. Marco normativo y de datos

- **GDPR / LOPDGDD** — datos personales (perfil, ubicación, contribuciones).
- **Real Decreto 1112/2018** — accesibilidad de sitios web y apps móviles
  del sector público en España; obliga a WCAG 2.1 AA.
- **Ley de Servicios Digitales (DSA)** — obligaciones de transparencia
  para apps con contribuciones de usuarios.
- **Licencias de datos GTFS** — varían por operador (algunos abiertos
  CC-BY, otros bajo convenio con el ayuntamiento).

---

## 3. Necesidades actuales del sector

### 3.1. Necesidades del usuario final (pasajero)

| Necesidad | Estado actual en ciudades medias | Solución Transitly |
|-----------|----------------------------------|--------------------|
| Saber dónde está mi bus AHORA | Inexistente o solo web operador grande | GPS del conductor + Realtime + estimación por horario |
| Cuántos minutos faltan a mi parada | Horario estático impreciso | ETA derivado de posición y ruta |
| Hay incidencias en mi línea | Twitter del operador | Incidencias geolocalizadas con votación de la comunidad |
| Búsqueda multimodal y geoespacial | App por operador | Búsqueda y mapa unificados |
| Saldo de mi tarjeta sin ir a la taquilla | Solo en máquinas físicas | NFC del móvil leyendo Mifare Classic |
| Accesibilidad real | Variable, mayoritariamente AA "parcial" | A11Y multidimensional: alto contraste, daltonismo, dislexia, lector, RTL |
| Idiomas | A menudo solo español | es / en / ar (RTL) |

### 3.2. Necesidades del conductor y del operador

- **Conductor:** poder activar el modo "estoy conduciendo la ruta X" y
  que la app emita su posición a intervalos cortos; ver su panel de
  estadísticas.
- **Operador (admin):** dar de alta operadores y rutas, moderar las
  contribuciones de los usuarios (incidencias, sugerencias), gestionar
  códigos de invitación para activar conductores.

### 3.3. Necesidades transversales (producto a escala)

- **Backend pensado para muchos operadores** (multi-tenant lógico) con
  control de acceso por roles (passenger / driver / operator_admin / admin).
- **Operación sin red** — la app sigue siendo útil offline.
- **Privacidad GDPR-compliant** — consentimiento, exportación y borrado.
- **Telemetría con gating real** — solo si el usuario lo consiente.

---

## 4. Oportunidades de negocio

### 4.1. Modelos B2C

- **Freemium**: app gratuita con ads opcionales o suscripción mensual
  que desbloquea mapas offline ampliados, notificaciones push ilimitadas
  y exportación de datos.
- **Tarjeta virtual de transporte** integrada en la app (NFC HCE) — a
  largo plazo, con acuerdo con el Consorcio.

### 4.2. Modelos B2B

- **Licencia a operador** — el operador paga una suscripción anual por
  rebrandeable + soporte + dashboard de incidencias y analítica
  agregada.
- **Servicio a consorcios** — varias ciudades de un consorcio
  comparten infraestructura, pagando por uso (usuarios mensuales activos).
- **Datos agregados anónimos** a ayuntamientos para planificación de
  movilidad (siempre con cumplimiento GDPR y k-anonimización).

### 4.3. Escalabilidad geográfica

- **Inmediato:** otros operadores españoles vía GTFS (10+ identificados).
- **Medio plazo:** Europa (todos los países con feeds GTFS abiertos —
  Francia transport.data.gouv.fr, Holanda OV-API, Países nórdicos, etc.).
- **Largo plazo:** LATAM (Chile, México, Brasil tienen GTFS en
  expansión).

### 4.4. Posicionamiento frente a competidores

| Competidor | Fortaleza | Hueco que cubre Transitly |
|------------|-----------|---------------------------|
| Google Maps Transit | Cobertura mundial | Cero comunidad, sin NFC, accesibilidad genérica |
| Moovit | Crowdsourcing maduro | Sin lectura NFC, sin modo conductor |
| App del operador (p.ej. COMUJESA web) | Datos oficiales | Sin tiempo real, sin app móvil moderna, sin a11y |

El hueco real es **"app móvil moderna, accesible y multi-operador para
ciudades medias españolas que hoy no aparecen en Moovit o están a medio
gas"**.

---

## 5. Guión de trabajo inicial (28 fases ejecutadas, F0→F27)

El proyecto siguió un plan incremental por fases:

1. **F0** — Auditoría del código base de partida.
2. **F0.5** — Higiene previa al backend (modelos `@freezed`, providers,
   pantallas estáticas).
3. **F1** — Migración completa a `@freezed`.
4. **F2** — Backend Supabase (auth, RLS, migraciones, Edge Functions).
5. **F3** — Capa de repositorios (`domain/remote/local/mock`) + caché
   Hive + cola offline.
6. **F4-F6** — Autenticación (email/password + magic link) y modelo de
   roles (passenger / driver / operator_admin / admin).
7. **F7-F8** — Importación de datos GTFS y carga del operador COMUJESA.
8. **F9-F14** — Mapa, búsqueda, filtros, detalle de ruta y parada, modo
   conductor con tracking GPS.
9. **F15-F16** — Comunidad: incidencias, sugerencias, votos, reputación,
   panel de moderación.
10. **F17-F22** — Pulido visual, accesibilidad (alto contraste,
    daltonismo, dislexia, lector), infraestructura (Sentry, PostHog),
    seguridad.
11. **F23-F24** — Plataformas adicionales (Astro SSR para marketing,
    widgets nativos Android/iOS).
12. **F25-F27** — Privacidad GDPR (consent, export, deletion), QA y
    publicación.

Cada fase con sus subitems queda trazada en el histórico
`docs/historico/PLAN_TRANSITLY_V2.md` y reemplazada operativamente por
el plan vivo `docs/PLAN_ACCION_REMEDIACION.md`.

---

## 6. Conclusión del análisis

El sector tiene una demanda real, un hueco claro en ciudades medias y
un marco técnico (GTFS) y normativo (WCAG, GDPR) que permite escalar.
La oportunidad concreta para este TFG es **construir el MVP funcional
con COMUJESA como operador piloto**, demostrar la arquitectura
multi-operador en el código y dejar el camino abierto a una expansión
posterior. El siguiente documento (`02_diseno_proyecto.md`) recoge el
diseño técnico que materializa este análisis.
