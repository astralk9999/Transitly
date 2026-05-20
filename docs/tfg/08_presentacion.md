# 08 — Presentación Final

**Proyecto:** Transitly — Aplicación multiplataforma de transporte público en tiempo real
**Formato:** Defensa oral TFG · DAM/DAW
**Duración total estimada:** 15–20 minutos (10 min presentación + 5 min demo + 5 min preguntas)
**Estado verificado:** `master @ 3a31fb3` · 28/28 fases · 175/175 tests · `flutter analyze` 0 · APK release 73,5 MB · CI verde

> Este documento es el guion de la presentación. Cada diapositiva
> incluye el contenido, los puntos a comentar y las notas del orador.
> Las diapositivas reales se montan en Canva / Google Slides /
> PowerPoint a partir de esta estructura.

---

## 1. Estructura (13 diapositivas)

### Diapositiva 1 — Portada

**Contenido visual:**
- Logo de Transitly.
- Título: **Transitly — Transporte público en tiempo real**.
- Subtítulo: TFG · DAM (o DAW) · Curso 2025/2026.
- Nombre del autor, tutor, fecha.

**Notas:** introducción de 15 segundos.

### Diapositiva 2 — El problema

**Contenido:**
- Movilidad urbana en España: **~1.500 M de viajes anuales en
  autobús urbano** (INE 2024).
- Apps fragmentadas: una app por operador, sin interoperar.
- Las ciudades medias (Jerez, Cuenca, Logroño…) **no tienen tiempo
  real** ni info de incidencias en vivo.
- Las personas con discapacidad visual o motora encuentran apps poco
  accesibles.

**Hook:** "¿Cuándo fue la última vez que esperaste un bus sin saber
cuánto tardaría?"

### Diapositiva 3 — La solución

**Contenido:**
- App **multi-operador, multi-plataforma** (Android, iOS, Web).
- **Tiempo real híbrido:** GPS de conductor (cuando lo hay) +
  estimación por horario (cuando no).
- **Comunidad activa:** incidencias, sugerencias, votos.
- **Accesible para todo el mundo:** alto contraste, daltonismo,
  dislexia, lector de pantalla, RTL.
- **Offline-first:** funciona sin red.
- **NFC:** lee el saldo de la Tarjeta del Consorcio Andaluz.

### Diapositiva 4 — Demo en vivo (≈3 minutos)

Guion de la demo (encendido del móvil, internet activado):

1. **Pantalla de inicio** — mostrar paradas habituales y próximas
   salidas.
2. **Mapa** — abrir el mapa de Jerez, mostrar líneas, paradas,
   bus en movimiento.
3. **Detalle de ruta** — abrir la línea 1, ver horarios y próximas
   salidas estimadas.
4. **Reportar incidencia** — toca el icono, elige "Retraso", envía
   (verlo aparecer en el mapa).
5. **NFC** — acercar tu tarjeta del Consorcio al móvil y mostrar el
   saldo leído.
6. **Modo accesible** — activar TalkBack 30 s para mostrar
   `Semantics` localizados.
7. **Modo offline** — activar modo avión; mostrar que los datos
   guardados siguen consultables.
8. **Cambiar idioma a árabe** — mostrar RTL aplicado al instante.

> Apoyo: tener un APK ya instalado, móvil cargado al 100 %, datos
> mock con incidencia "interesante" precargada.

### Diapositiva 5 — Arquitectura técnica

**Stack:**
- **Flutter 3.9.2+ / Dart 3** — multiplataforma real.
- **Riverpod 2.6** con `autoDispose` en streams/timers/futures.
- **go_router 17.2** con redirect guards consumiendo rol REAL.
- **freezed 3** + json_serializable para inmutabilidad.
- **Supabase** (PostgreSQL + RLS + Realtime + Storage + Edge Functions).
- **Hive** para caché local + cola offline.
- **flutter_map 7 + MapTiler + FMTC** para mapas y offline.
- **NFC Mifare Classic** para tarjeta del Consorcio.
- **Firebase Messaging + flutter_local_notifications** para push.
- **Sentry + PostHog** con consent-gating GDPR real.
- **Astro** para landing SSR.

**Diagrama:** capas (UI → features → shared → data → core/theme).

### Diapositiva 6 — Modelo de datos

**Diagrama ER simplificado:**

```
profiles (auth.users) ──┐
                        │
operators ──→ routes ──→ route_stops ──→ stops
              │
              ├──→ schedules
              └──→ bus_positions (Realtime)

profiles ──→ incidents / route_feedback / route_suggestions / feature_requests
profiles ──→ notifications (Realtime) / device_tokens
profiles ──→ privacy_consents / data_exports / data_deletion_requests
```

**Datos clave:** 13 migraciones, RLS default-deny activo, 2 Edge
Functions (`import_gtfs`, `send_notification`), `search_path` fijado
en todas las `SECURITY DEFINER`.

### Diapositiva 7 — Funcionalidades destacadas

- **F13 Realtime** — `RealtimeChannelManager` compartido con
  multiplexación + backoff exponencial + jitter (5/12 repos
  críticos).
- **Modelo de usuario unificado** — perfil real de Supabase con
  fallback gradual a mock; guard del router usa rol REAL.
- **Sistema de roles** — passenger / driver / operator_admin /
  moderator / admin.
- **Contribuciones comunitarias** — incidencias, sugerencias,
  feedback, votos, reputación con 7 rangos y 9 logros.
- **Modo conductor** — código de invitación → activación → emite
  posición GPS al canal Realtime.
- **Panel admin** — CRUD de operadores, gestión de usuarios,
  moderación de contribuciones.
- **Accesibilidad multidimensional** — alto contraste, daltonismo
  (3 matrices), OpenDyslexic, lector de pantalla con Semantics
  localizados (ES/EN/AR), `Pressable` con 48 dp, `textScaler`
  compone con el del SO, reduce-motion.
- **i18n trilingüe con RTL** — Español, Inglés, Árabe (343 claves
  por locale).
- **Notificaciones push** — FCM HTTP v1 con OAuth JWT, in-app +
  quiet hours.
- **Privacidad GDPR** — consent-gating real con revocación
  inmediata, export, deletion con plazo de 30 días.
- **Widgets nativos** — Android home widget + iOS widget.

### Diapositiva 8 — Honestidad académica e innovación: asistencia IA

**Innovación metodológica declarada con transparencia:**

- Sistema multiagente IA con 5 roles (**Queen** planificación,
  **Developer** código, **Review** crítica independiente, **Git**
  commits semánticos, **Documentation** sincronía).
- Documentado en `multiagent/ARCHITECTURE.md` y referenciado en
  este TFG.
- **Revisiones críticas independientes** documentadas
  (`docs/historico/REVISION_INDEPENDIENTE_2026_05_17.md`) — 4
  pasadas que descubrieron deuda real y se cerró en ciclos
  posteriores.

**Por qué se declara explícitamente:** el proyecto se evalúa por las
**decisiones tomadas**, la **arquitectura defendida** y los
**resultados verificables**, no por la negación de herramientas. La
asistencia IA está al servicio del rigor, no lo sustituye.

### Diapositiva 9 — Planificación y ejecución

**Cronograma:** 28 fases atómicas (F0 → F27) en ~4 semanas.

**Diagrama de Gantt** (mostrar gráfico exportado de
`docs/tfg/03_planificacion.md`).

**Metodología:** ágil iterativa por fases atómicas de 1-4 días, cierre
verificable con `flutter analyze` 0 + `flutter test` 100 % verde +
commit + push.

**Ciclos de remediación post-cierre:** Workstream R + múltiples
ciclos P0/P1 para pulir deuda descubierta en revisiones críticas.

### Diapositiva 10 — Métricas verificadas

| Métrica | Valor |
|---------|-------|
| Fases completadas | **28/28** (100 %) |
| Tests | **175 verdes / 175 totales** |
| Cobertura de líneas | **24,30 %** (4 004/16 476) — deuda declarada |
| `flutter analyze` | **0 issues** |
| Build APK release | **OK 73,5 MB** |
| CI GitHub Actions | **4 jobs verdes** |
| Repositorios con patrón canónico | **12** |
| Modelos `@freezed` | **27+** |
| Widgets compartidos | **27+** |
| Idiomas (ES/EN/AR) | **343 claves/locale** |
| F13 Realtime real | **5/12 repos** + manager compartido |
| Paginación | **11/11** repos de lista |
| `autoDispose` providers | **6 cerrados** |

### Diapositiva 11 — Calidad: accesibilidad y producción

**Accesibilidad declarada con honestidad:**

- ✅ **Pressable ≥ 48 dp**, `textScaler` del SO, Semantics
  localizados, fuentes locales, contraste configurable, daltonismo,
  dislexia, reduce-motion, RTL.
- 🟨 **"WCAG 2.2 AA parcial / en progreso"** — falta verificación
  REAL con TalkBack/VoiceOver (sin esto no es defendible "AA
  pleno"). Documentado en `docs/ACCESSIBILITY.md`.

**Producción a escala:**

- Lo que **sí** está: APK release que compila, CI verde, modelo de
  usuario unificado, paginación completa, Realtime en repos críticos,
  consent-gating GDPR real con revocación inmediata.
- Lo que **falta** para producción real (documentado en
  `docs/SCALABILITY.md`): keystore real para Play Store,
  observabilidad SLO/tracing, mapa con clustering, caché Hive
  particionada por operador, FORCE RLS + pooling.

### Diapositiva 12 — Lecciones aprendidas

1. **Verificar siempre con el pipeline completo.** El APK release no
   compilaba durante semanas porque solo se ejecutaba `flutter build
   web` localmente. Lección: **un CI que construye todos los targets
   relevantes es no negociable**.
2. **Una fuente única de verdad para métricas.** Tener 8 documentos
   con cifras distintas confunde y resta credibilidad. La
   arquitectura documental con `00_MAESTRO.md` + dossiers cierra
   esa puerta.
3. **Honestidad documental > pulido visual.** Declarar "AA parcial"
   con evidencia es más valioso que reclamar "AA pleno" sin
   verificación.
4. **Asistencia IA exige verificación independiente** —
   especialmente en capas que `flutter analyze` no toca (Gradle,
   Edge Functions Deno).
5. **Planificación en fases atómicas (1-4 días) funciona** —
   permite cerrar progreso medible y mantener foco.
6. **Offline-first no es opcional** en transporte público —
   los usuarios viajan en metro y túneles sin red.

### Diapositiva 13 — Trabajo futuro y agradecimientos

**Trabajo futuro (priorizado en `docs/MEGA_PLAN_REFINAMIENTO.md`):**

- **Cerrar accesibilidad AA defendible** (verificación con
  TalkBack/VoiceOver + alternativa accesible al mapa).
- **Tests de la capa `remote/`** (subir cobertura ≥ 35 %).
- **Observabilidad** (SLO + tracing + alertas).
- **Multi-operador real** (poblar más operadores españoles + clustering
  en mapa).
- **Publicación** (keystore real para Play Store + TestFlight iOS).

**Agradecimientos:**
- Tutor del módulo.
- Comunidad open source (Flutter, Supabase, Riverpod, freezed,
  flutter_map, MapTiler).
- COMUJESA por publicar sus horarios.

**Cierre:**
- "Gracias. Estoy a disposición para preguntas."

---

## 2. Timing detallado

| Sección | Tiempo | Acumulado |
|---------|:--:|:--:|
| 1 Portada | 0:15 | 0:15 |
| 2 Problema | 0:45 | 1:00 |
| 3 Solución | 1:00 | 2:00 |
| 4 **Demo en vivo** | 3:00 | 5:00 |
| 5 Arquitectura técnica | 1:30 | 6:30 |
| 6 Modelo de datos | 1:00 | 7:30 |
| 7 Funcionalidades destacadas | 2:00 | 9:30 |
| 8 Honestidad académica e IA | 1:00 | 10:30 |
| 9 Planificación | 1:00 | 11:30 |
| 10 Métricas | 1:00 | 12:30 |
| 11 Accesibilidad y producción | 1:00 | 13:30 |
| 12 Lecciones aprendidas | 1:00 | 14:30 |
| 13 Trabajo futuro + cierre | 0:30 | 15:00 |
| **Preguntas** | 5:00 | 20:00 |

---

## 3. Recursos a preparar antes de la defensa

### Hardware

- [ ] Móvil Android cargado al 100 % con APK release **ya instalado**.
- [ ] Tarjeta del Consorcio Andaluz para demo NFC.
- [ ] Cable HDMI / adaptador para proyector (mostrar la pantalla del
      móvil con `scrcpy` o equivalente).
- [ ] Conexión Wi-Fi del aula confirmada con antelación.

### Software

- [x] **APK release compilado** (`build/app/outputs/flutter-apk/app-release.apk`,
      73 MB, 2026-05-20) — *Nota: firmado con keystore de debug; suficiente
      para demo, no publicable.*
- [ ] **Slides** montadas en Canva / Google Slides / PowerPoint
      basadas en este guion.
- [ ] **Diagrama de Gantt** exportado como imagen
      (`docs/tfg/03_planificacion.md`).
- [ ] **Diagrama ER** simplificado del esquema Supabase.
- [ ] **Mock data** precargado con una incidencia "interesante" para
      la demo.
- [ ] **Vídeo de respaldo** (1 min) de la demo grabado con `scrcpy`
      como fallback por si falla el cable HDMI.

### Documentación de apoyo

- [ ] Memoria completa (`docs/tfg/01..08`) impresa o accesible.
- [ ] `docs/00_MAESTRO.md` accesible para responder con cifras
      precisas.
- [ ] `docs/SCALABILITY.md` y `docs/ACCESSIBILITY.md` para preguntas
      sobre producción y accesibilidad.

---

## 4. Preguntas previsibles y respuestas preparadas

**Q1: ¿Por qué cobertura solo 24 %?**

> "Es deuda declarada con palanca identificada. La capa `lib/data/*/remote/`
> está a ~0 % porque exige mocks de `SupabaseClient` y `PostgrestClient`
> que aún no he escrito. Es el ítem P2-4 del plan vivo. La cobertura
> nominal del 60 % era objetivo de la guía; preferí ser honesto a
> inflar números con tests triviales."

**Q2: ¿Por qué dices "AA parcial" si tu app es muy accesible?**

> "Porque no he hecho una pasada formal con TalkBack/VoiceOver con
> personas usuarias reales. Los fundamentos están: 48 dp, textScaler
> compone con el del SO, Semantics localizados en 3 idiomas
> incluido RTL, contraste configurable. Pero declarar AA pleno
> requiere un acta de pruebas con producto de apoyo. Es el ítem
> A11Y-3 del plan."

**Q3: ¿Cómo declaras el uso de IA?**

> "Está documentado en `multiagent/ARCHITECTURE.md` y referenciado en
> la memoria. Usé un sistema multiagente con 5 roles. Las
> revisiones críticas independientes documentadas en `historico/`
> demuestran que cada decisión arquitectónica se sometió a escrutinio
> crítico. La asistencia IA está al servicio del rigor, no lo
> sustituye."

**Q4: ¿Por qué solo COMUJESA?**

> "La arquitectura multi-operador está implementada (modelo de datos,
> RLS, importador GTFS, detección geográfica). COMUJESA es el operador
> piloto poblado para demo. Los 9 operadores restantes están definidos
> pero no cargados — requieren acuerdo con cada operador para datos
> en vivo o cargas masivas de GTFS público."

**Q5: ¿Por qué F13 solo en 5/12 repos?**

> "Los 5 repos con Realtime real son los críticos para la
> experiencia del usuario: bus_location, stop, route, incident,
> route_feedback. Tienen un `RealtimeChannelManager` compartido con
> multiplexación, backoff exponencial y jitter. Los 7 restantes
> (operator, schedule, etc.) no se actualizan en tiempo real en la
> vida real, así que no necesitan Realtime; snapshot + refresh manual
> es suficiente."

**Q6: ¿El APK que tienes en el móvil es publicable?**

> "No. Compila release y es válido para esta demo, pero está firmado
> con la keystore de debug. Para publicar en Play Store hay que
> generar una keystore real (≈15 minutos con `keytool`) y configurar
> `android/key.properties`. Es el último bloqueador de release y está
> documentado en `android/README.md` y en el plan vivo. Una decisión
> consciente para mantener el alcance del TFG."

---

## 5. Tono y estilo

- **Concreto, con datos.** Cifras verificadas siempre (175 tests,
  24,30 %, 5/12, etc.).
- **Honestidad sobre limitaciones.** Las deudas declaradas suben la
  credibilidad, no la bajan.
- **Mostrar el código en vivo si lo piden.** Tener abierto Visual
  Studio Code con `docs/00_MAESTRO.md` y el repositorio listo.
- **No alargar las preguntas.** Responder con frase + dato + dónde
  está documentado.

---

## 6. Checklist final pre-defensa

- [ ] Slides revisadas, ortografía corregida, sin texto cortado.
- [ ] APK instalado y abierto en el móvil; modo avión preparado.
- [ ] Tarjeta NFC en bolsillo accesible.
- [ ] Cable / adaptador probado en aula similar.
- [ ] Mock data cargado con incidencia precargada.
- [ ] Vídeo de respaldo de la demo grabado y subido al USB.
- [ ] Memoria y documentación accesible (en USB + nube).
- [ ] Cronómetro silencioso para no pasarte de tiempo.
- [ ] Botella de agua.
- [ ] Respuestas a preguntas previsibles ensayadas.

**Última verificación de cifras** justo antes de la defensa:

```bash
flutter analyze            # → No issues found!
flutter test --coverage    # → All tests passed!
awk -F: '/^LF:/{lf+=$2}/^LH:/{lh+=$2}END{printf "%.2f%%\n",(lh/lf)*100}' coverage/lcov.info
```

Si las cifras han cambiado respecto a las de las slides → actualizar
la diapositiva 10 minutos antes de empezar.
