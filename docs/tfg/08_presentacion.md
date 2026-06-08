# 08 — Presentación Final

**Proyecto:** Transitly (nexto-stop-v2)
**Formato:** Guion de diapositivas para defensa oral del TFG
**Ciclo:** Desarrollo de Aplicaciónes Multiplataforma (DAM)
**Defensa prevista:** semana 11 del cronograma (10-16 de junio de 2026)
**Duracion total estimada:** entre 18 y 22 minutos
**Anclaje original:** master @ b908f3c · 2026-05-23
**Anclaje actualizado:** master @ b47180d0 · 2026-06-08
**Release pública:** v1.12.1 (APK universal) — https://github.com/astralk9999/Transitly/releases/tag/v1.12.1

> Este documento es la base textual sobre la que se montan las
> diapositivas reales en la herramienta de presentación. Cada sección
> representa una diapositiva. El bloque **Notas** corresponde al
> discurso del orador.

---

## Diapositiva 1 — Portada

- Titulo: **Transitly**.
- Subtitulo: aplicación multiplataforma de transporte público para
  ciudades medias.
- Autor del TFG y ciclo formativo: **DAM**.
- Centro y tutor o tutora.
- Fecha de defensa: junio de 2026.

**Notas:** saludo breve, presentación personal, anuncio de la
estructura: contexto, demostración, decisiónes técnicas, resultados y
preguntas. (30 segúndos)

---

## Diapositiva 2 — Problema detectado

- En ciudades medias espanolas no existe información oficial de
  transporte público en tiempo real.
- Las personas usuarias dependen de horarios impresos o de aplicaciónes
  fragmentadas por operador.
- La experiencia se agrava con discapacidad visual, motora o cognitiva.
- Ejemplo concreto: Jerez de la Frontera, operador COMUJESA, sin app
  oficial con seguimiento en vivo.

**Notas:** plantear el problema con una pregunta sencilla al tribunal,
"cuando esperais un autobus, sabeis cuanto tardara". Mencionar que el
TFG nace de esa observación. (60 segúndos)

---

## Diapositiva 3 — Sector y oportunidad

- Movilidad urbana en Espana: apróximadamente **1.500 millones de
  viajes anuales en autobus urbano** (INE).
- Apróximadamente **600 millones** adicionales corresponden a transporte
  interurbano.
- Mercado muy fragmentado por operador, sin estandar único de datos en
  tiempo real.
- Oportunidad para una capa de aplicación comunitaria que cubra ese
  hueco hasta que GTFS-Realtime se generalice.

**Notas:** contextualizar el tamano del problema, sin inflar cifras y
citando la fuente. (60 segúndos)

---

## Diapositiva 4 — Demo grabada de la aplicación

- Reproducir un video de 30 segúndos con la aplicación real.
- Mostrar: pantalla de inicio, mapa con autobuses, reporte de
  incidencia y lectura NFC.

**Notas:** dejar que el video hable. Comentar solo el cierre,
"esto es lo que vais a ver en la demo final". (30 segúndos)

---

## Diapositiva 5 — Objetivos

- **Funciónal 1.** Consultar líneas, paradas y horarios sin fricciones.
- **Funciónal 2.** Reportar y consumir incidencias en comunidad.
- **Funciónal 3.** Soportar tarjeta NFC del Consorcio Andalucia.
- **No funcional 1.** Accesibilidad WCAG 2.2 AA estructural.
- **No funcional 2.** Cumplimiento GDPR completo.
- **No funcional 3.** Funciónamiento sin conexión con datos
  precargados.

**Notas:** subrayar que los objetivos se definieron al inicio y se han
verificado al final. (60 segúndos)

---

## Diapositiva 6 — Stack tecnológico

- **Cliente.** Flutter con Dart 3, Riverpod para estado, Hive para
  persistencia local.
- **Backend.** Supabase (PostgreSQL gestiónado, autenticación, RLS,
  almacenamiento, Edge Functions).
- **Observabilidad.** Sentry para errores y PostHog para producto.
- **Mensajeria.** Firebase Cloud Messaging para notificaciones push.
- **Plataformas objetivo.** Android, iOS y Web PWA.

**Notas:** justificar cada elección en una frase. Flutter por capa
única multiplataforma, Supabase por reducir backend a configurar,
Riverpod por testabilidad. (60 segúndos)

---

## Diapositiva 7 — Arquitectura

- Diagrama Mermaid con cuatro capas: presentación, dominio,
  infraestructura y datos.
- Organizacion por **feature-first**: cada funcionalidad es una carpeta
  autocontenida en `lib/features/`.
- 27 features funcionales actualmente.
- Aislamiento de dependencias mediante repositorios y casos de uso.

**Notas:** explicar la decisión de feature-first frente a layer-first,
ventajas para mantenimiento y onboarding de nuevos desarrolladores.
(90 segúndos)

---

## Diapositiva 8 — Funciónalidades clave

- **Mapa en vivo** con paradas y autobuses en circulación.
- **Lectura NFC** del saldo de la tarjeta del Consorcio Andalucia.
- **Reporte de incidencias** con tipologia y moderación comunitaria.
- **Modo sin conexión** con región descargable.
- **Modo conductor** con código de invitación y seguimiento GPS.

**Notas:** acompanar cada bullet con una captura. Insistir en que las
27 features funcionan y están cubiertas por pruebas. (120 segúndos)

---

## Diapositiva 9 — Accesibilidad

- **WCAG 2.2 AA estructural** alcanzada; acta de verificación con
  TalkBack y VoiceOver prevista para la semana 10.
- **Daltonismo:** ocho matrices de transformación de color
  configurables.
- **Internacionalización:** 642 claves ARB en espanol, con cobertura en
  ingles y arabe y soporte completo de **RTL** en arabe.
- **Escala de texto** y **fuente para dislexia** disponibles.
- Auditoria interna con baterías automatizadas de pruebas de contraste
  y tamanos mínimos de objetivo tactil.

**Notas:** la accesibilidad no es un anadido, es una decisión desde la
semana 1. Mencionar que el acta de TalkBack y VoiceOver se firma con
el tutor antes de la defensa. (60 segúndos)

---

## Diapositiva 10 — Seguridad y privacidad

- **RLS en PostgreSQL con DENY-by-default** sobre todas las tablas.
- **GDPR** cubierto en sus Articulos 8, 13, 17, 20 y 21.
- **Cifrado en reposo** del almacenamiento local con HiveAesCipher.
- **Credenciales** gestiónadas mediante flutter_secure_storage.
- **Banner de consentimiento** granular y opt-out por defecto en
  analítica, informes de fallos y comúnicaciónes.

**Notas:** explicar que el modelo de seguridad se ha disenado para que
ninguna operación sea posible sin política explicita. (90 segúndos)

---

## Diapositiva 11 — Calidad

- **679 tests** automatizados pasando (0 fallos).
- **51 migraciónes SQL** consecutivas verificadas.
- **27 features** funcionales y empaquetadas (446 ficheros `.dart`, ~94k LOC).
- **8 Edge Functions** desplegadas: `send_notification`, `import_gtfs`,
  `delete_user`, `purge_old_data`, `generate_data_export`,
  `approve_user_route`, `promote_stop_to_official`, `validate_share_code`.
- **6 jobs de CI** en verde (analyze, test, build web, build APK,
  Semgrep, Gitleaks).
- **Scorecard:** 8,9 sobre 10 en el eje TFG y 6,0 sobre 10 en el eje
  Produccion.

**Notas:** la calidad se mide, no se afirma. La scorecard distingue
deliberadamente el rigor académico del nivel de producción real, donde
quedan 19 bloqueadores externos documentados. (60 segúndos)

---

## Diapositiva 12 — Métodologia y gestión

- **Scrum solo adaptado:** sprints de una semana, ceremonias reducidas.
- **11 semanas** de cronograma documentado.
- **Auditorias independientes deep-dive** al cierre de cada sprint
  relevante.
- **Documentación como contrato verificable:** todo cambio se refleja
  en `docs/` y se ancla a un commit.
- **CI:** **6 jobs verdes** (analyze, test, integration, build).

**Notas:** explicar que trabajar en solitario requiere una disciplina
mayor de revisión externa. (60 segúndos)

---

## Diapositiva 13 — Bloqueadores superados

- **APK release no compilaba.** Ajuste de flags de R8 y dependencias
  nativas.
- **Drift documental.** Documentos divergiendo del código; se resolvio
  introduciendo anclajes a commit en cada documento maestro.
- **Migración SQL corrupta.** Se reconstruyo la cadena y se anadio una
  prueba de aplicación secuencial.
- **Accesibilidad AA verificable.** Se diseno una batería automatizada
  de matrices de contraste para no depender solo del juicio humano.

**Notas:** referenciar los SHA reales del git log al exponer cada caso.
Mostrar que son fallos resueltos, no ocultados. (90 segúndos)

---

## Diapositiva 14 — Resultados frente a objetivos

- Tabla con tres columnas: objetivo, estado y evidencia.
- Marcar **Cumplido** o **Parcial** según corresponda.
- Lineas en **Parcial** deben llevar un enlace a su bloqueador externo.
- Lineas en **Cumplido** se respaldan con el test, la migración o la
  Edge Function correspondientes.

**Notas:** transparencia. Lo parcial es parcial. (60 segúndos)

---

## Diapositiva 15 — Lecciones aprendidas

- **La documentación solo vale si es contrato verificable.** Cada
  decisión tiene que apuntar a un commit, una prueba o un documento.
- **Una auditoria independiente vale más que cien autorrevisiónes.**
- **Las inteligencias artificiales colaboran bien, pero exigen
  governance.** Decisiónes, prompts y revisiónes están documentadas.
- **El alcance se gestióna acotando, no estirando.** Mejor 27 features
  solidas que 50 a medias.

**Notas:** estas son las cuatro lecciónes que se llevaria a futuros
proyectos. (60 segúndos)

---

## Diapositiva 16 — Trabajo futuro

- Integración con **GTFS-Realtime** cuando los operadores expongan
  APIs públicas.
- Soporte completo de **WidgetKit en iOS** equivalente a los widgets
  Android ya existentes.
- Modelo de **aprendizaje automático para predicción de ETA**, entrenado
  con historicos de GPS de conductor.
- **Expansion multi-ciudad** más allá del piloto en Jerez.

**Notas:** dejar claro que el trabajo futuro existe porque hay una base
sólida sobre la que construirlo. (60 segúndos)

---

## Diapositiva 17 — Conclusiones

- Transitly demuestra que es viable construir, en solitario y con
  asistencia de IA documentada, una aplicación móvil profesional con
  exigencias reales de accesibilidad y privacidad.
- La arquitectura feature-first y la disciplina documental han sido las
  decisiónes de mayor retorno.
- El TFG se entrega con metrica reproducible: 679 tests, 51 migraciónes,
  27 features, 8 Edge Functions y una release pública instalable (v1.12.1).

**Notas:** cerrar con una frase memorable, "Transitly no es una
maqueta, es un sistema verificable". (45 segúndos)

---

## Diapositiva 18 — Demostracion en vivo

- Reproducir el flujo guiado de la aplicación en el dispositivo real.
- Recorrido: alta como invitado, consulta de línea, mapa, reporte de
  incidencia, lectura NFC simulada, descarga offline y cambio de
  idioma a arabe (RTL).
- Plan B: en caso de fallo de red, ejecutar todo el flujo en modo
  offline.

**Notas:** cinco minutos planificados, con un guion impreso de apoyo
y un plan B documentado. (300 segúndos)

---

## Diapositiva 19 — Preguntas y respuestas

- Tribunal: cinco minutos para preguntas abiertas.
- Recursos preparados: scorecard, mega plan, registro de bloqueadores
  externos y política de privacidad.
- Disposición para profundizar en cualquier feature concreta o en la
  arquitectura.

**Notas:** mantener calma, repetir la pregunta antes de contestarla,
no rellenar con suposiciónes. (300 segúndos)

---

## Diapositiva 20 — Agradecimientos

- Al tutor o tutora del TFG por la orientacion y revisiónes.
- A la familia por el sostenimiento durante los meses de trabajo.
- A las companeras y companeros del ciclo por las revisiónes cruzadas.
- A la comunidad de software libre y a los proyectos Flutter,
  Supabase, Sentry y PostHog cuyo trabajo hace posible Transitly.

**Notas:** cerrar con una frase breve de cierre y dar paso al
tribunal. (30 segúndos)

---

## Diapositivas adicionales — Versión 1.11.0 (4 de junio de 2026)

Estas diapositivas se insertan entre la **slide 8 (Demostración)** y la **slide 9 (Resultados y métricas)** del guion original. Refuerzan el bloque de "trabajo realizado entre el cierre del anchor original y la defensa".

### Slide 8.bis — Estabilización post-MVP en cifras

**Título:** Del MVP al release público — 12 días, 94 commits, una versión instalable.

**Cuerpo:**

- 94 commits entre 23/05 y 04/06 organizados en cinco oleadas de estabilización.
- Cuatro planes de acción ejecutados (`PLAN_15_BUGS`, `PLAN_8_BUGS_LOGS`, `PLAN_CRASH_NATIVO_RECOVERY`, `PLAN_21_BUGS_MAPA_PERFIL`, `PLAN_8_MEJORAS`, `PLAN_42P17_RLS_RECURSION`).
- Release oficial v1.11.0 publicado en GitHub Releases con APK firmado.
- Una migración SQL adicional (`fix_route_shares_rls_recursion`).
- 18 nuevas claves ARB (widgets config, avisos de zona).
- Cinco features nuevas: widgets configurables, wizard con mapa, árbol de filtros, recovery boot, tile prewarming.

**Notas para la defensa:** explicar que el ciclo de estabilización post-MVP no estaba contemplado con detalle en el plan original pero se absorbió dentro del margen de la semana 10. Subrayar que cada plan se documenta como `PLAN_*.md` en `docs/historico/`, con causa raíz, decisiones tomadas y criterios de aceptación verificables. (90 segundos)

### Slide 8.ter — Bug crítico que la app sobrevivió por sí sola

**Título:** Boot canary — cómo una app puede recuperarse sola sin clear data.

**Cuerpo:**

Caso real detectado en pruebas con dispositivos físicos:
1. Usuario activa simultáneamente: dislexia + alto contraste + tamaño de texto máximo + filtro de daltonismo.
2. La app crashea en el siguiente arranque por una combinación tóxica en el subsistema nativo de Flutter (font + shader + matrix de color).
3. Las defensas Dart (`try/catch`, validación de NaN, fallbacks) **no capturan** el crash: ocurre en C++, no en Dart.
4. El estado tóxico ya está persistido en Hive → al reabrir la app vuelve a crashear → bucle.

**Solución implementada:**
- `BootCanary` marca `BOOTING` al inicio de `main()` y lo cambia a `STABLE` tras el primer `addPostFrameCallback`.
- Si el siguiente arranque ve `BOOTING` → la app crasheó antes del primer frame → se incrementa el contador.
- Se revierte la última preferencia sensible (sólo persistimos preferencias después de `markStable`).
- Tras dos crashes consecutivos, se monta `RecoveryScreen` con `MaterialApp` propio, **sin shaders ni fuentes custom**, con botón "Restaurar valores por defecto".

**Resultado:** indicador "crashes que requieren clear data" pasa de cualquier valor a **cero**. La aplicación se vuelve auto-recuperable.

**Notas para la defensa:** este es uno de los puntos más diferenciadores del proyecto. Resiliencia ante errores nativos no es algo que se enseñe en el ciclo y demuestra capacidad de razonamiento sobre la diferencia entre Dart y el engine subyacente. (120 segundos)

### Slide 8.quater — Detección y resolución de un ciclo recursivo en RLS

**Título:** Error 42P17 — "infinite recursion in policy". Un caso real de auditoría SQL.

**Cuerpo:**

Tras conseguir que el login con Google funcionara, el flujo post-login fallaba al cargar las contribuciones del usuario:

```
PostgrestException: infinite recursion detected in policy for relation "route_shares"
code: 42P17
```

**Auditoría con MCP de Supabase** (consulta a `pg_policies`):

- `route_shares.route_shares_select_owner` hacía `EXISTS (SELECT FROM routes WHERE owner_id = auth.uid())`.
- `routes.routes_select_visible` hacía `EXISTS (SELECT FROM route_shares WHERE shared_with_id = auth.uid())`.
- PostgreSQL detecta el ciclo → aborta.

**Solución desplegada** (migración `fix_route_shares_rls_recursion`):

```sql
CREATE FUNCTION public.is_route_owner(p_route_id uuid)
RETURNS boolean LANGUAGE sql SECURITY DEFINER STABLE
AS $$ SELECT EXISTS (SELECT 1 FROM routes WHERE id = p_route_id AND owner_id = auth.uid()); $$;
```

La función ejecuta con permisos de owner (bypassa RLS) y rompe el ciclo. Las tres policies que consultaban `routes` (SELECT, DELETE, INSERT del owner) llaman ahora a la función. Semántica de visibilidad preservada.

**Notas para la defensa:** explicar conceptualmente qué es Row Level Security y por qué un sistema multi-rol como Transitly lo necesita. Mencionar que la decisión de mantener el patrón `SECURITY DEFINER` versus desnormalizar el schema es un trade-off documentado en `docs/SUPABASE_SETUP.md`. (90 segundos)

### Slide 8.quinta — Release pública y limpieza del repositorio

**Título:** De `presentation/public/*.apk` a GitHub Releases — 792 MB liberados.

**Cuerpo:**

**Estado anterior al 04/06:**
- 9 APKs históricos versionados en `presentation/public/transitly-v1.{3..11}.0.apk`.
- ~792 MB en el `working tree`.
- GitHub avisaba `>50 MB` por archivo y bloquearía con `>100 MB`.
- Cada nuevo APK duplicaba ~88 MB en el `.git/` indefinidamente.

**Acción tomada:**
1. Eliminar los 9 APKs del HEAD del repositorio.
2. Añadir patrón `*.apk` al `.gitignore` raíz.
3. Cambiar las URLs de descarga en la presentación web a `https://github.com/astralk9999/Transitly/releases/latest` (URL estable que GitHub redirige al último release).
4. Crear el release oficial `v1.11.0` con el APK como asset usando `gh release create`.

**Resultado:**
- `working tree` reducido en ~792 MB.
- Distribución profesional vía Releases (límite 2 GB por archivo, sin contaminar el repo).
- Una sola URL que la presentación nunca tiene que actualizar.

**Notas para la defensa:** mencionar que esto se descubrió en el aviso de GitHub al hacer `git push` y se decidió aplicar la práctica estándar del ecosistema (Releases para binarios, repo sólo para código). La presentación HTML usaba `import.meta.env.BASE_URL` que apuntaba a `/Transitly/<archivo>.apk`; la sustitución por `releases/latest` deja la web independiente del versionado. (60 segundos)

---

## Diapositivas adicionales — Versión 1.12.1 (8 de junio de 2026)

Estas diapositivas cierran el bloque de "trabajo realizado hasta la defensa" y se insertan tras la slide 8.quinta. Demuestran que los objetivos funcionales 2, 7 y 12 quedan totalmente cubiertos en la release final.

### Slide 8.sexta — Notificaciones push reales con la app cerrada

**Título:** De la notificación local al push real — Firebase Cloud Messaging extremo a extremo.

**Cuerpo:**

- **Cliente:** integración completa de FCM (proyecto `transitly-ee8cf`): `google-services.json`, plugin Gradle, `firebase_options.dart` con claves reales, manejadores de mensajes en primer y segundo plano y registro del token del dispositivo en `device_tokens` al iniciar sesión.
- **Servidor (ya existente):** Edge Function `send_notification` que firma un JWT OAuth y envía por **FCM HTTP v1**, con limpieza automática de tokens inválidos, disparada por triggers SQL (incidencia resuelta, ruta compartida, ruta promovida).
- **Resultado verificado:** la app recibe push **con la app cerrada** (`FlutterFirebaseMessagingBackgroundService started`).
- **Dependencia externa documentada:** la *service account* del operador para el envío programático (`docs/FCM_SETUP.md`).

**Notas para la defensa:** distinguir entre la config de **cliente** (`google-services.json`) y la credencial de **servidor** (service account), y por qué el envío programático depende de esta última. (90 segundos)

### Slide 8.séptima — Modo conductor en segundo plano (foreground service)

**Título:** Compartir posición con la pantalla bloqueada — un foreground service de Android.

**Cuerpo:**

- El seguimiento del conductor pasó de un `Timer` en primer plano a `Geolocator.getPositionStream` con **foreground service** (`ForegroundNotificationConfig`, wake-lock, notificación persistente nativa).
- La posición se sigue emitiendo al canal Realtime con la app en segundo plano o el móvil bloqueado; al terminar la ruta se cancela el stream y la notificación.
- Permisos `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION` y `WAKE_LOCK` en el manifiesto. En web (sin foreground service) se mantiene el envío periódico mientras la pestaña está activa.

**Notas para la defensa:** explicar por qué un `Timer` se pausa al bloquear la pantalla y cómo el foreground service garantiza la continuidad, requisito real para un conductor en ruta. (75 segundos)

### Slide 8.octava — Planificador origen→destino reactivado

**Título:** Cerrar el bucle de consulta — trayectos con transbordos.

**Cuerpo:**

- Reactivación de la pestaña **Buscar** y del flujo origen→destino (`RoutePlannerService`: rutas directas y con un transbordo) navegando a `/route-plan`.
- Completa la carencia informativa: el viajero no solo ve líneas y paradas, sino cómo ir de A a B.

**Notas para la defensa:** mencionar que el motor de planificación es heurístico sobre el grafo de paradas y que la integración con horarios reales es la línea de evolución natural. (45 segundos)

### Slide 8.novena — La web del proyecto en GitHub Pages

**Título:** Distribución y documentación pública.

**Cuerpo:**

- Sitio público en **GitHub Pages** (`https://astralk9999.github.io/Transitly/`) con la presentación del proyecto, los **entregables del TFG** navegables y la **descarga del APK** resuelta automáticamente desde la release más reciente.
- Release **v1.12.1**: APK **universal** (arm64-v8a, armeabi-v7a, x86_64), Android 7.0+.
- La web de producto (landing + app Flutter embebida en `/app`) se ejecuta en local para la demo, con la app Android como eje central de la defensa.

**Notas para la defensa:** señalar que la página sirve a la vez de portfolio, de canal de distribución y de índice documental del TFG. (45 segundos)
