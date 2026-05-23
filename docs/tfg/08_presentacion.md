# 08 — Presentación Final

**Proyecto:** Transitly (nexto-stop-v2)
**Formato:** Guion de diapositivas para defensa oral del TFG
**Ciclo:** Desarrollo de Aplicaciónes Multiplataforma (DAM)
**Defensa prevista:** semana 11 del cronograma (10-16 de junio de 2026)
**Duracion total estimada:** entre 18 y 22 minutos
**Anclaje:** master @ 85b81a1 · 2026-05-23

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
- **Internacionalización:** 628 claves ARB para espanol, ingles y arabe,
  con soporte completo de **RTL** en arabe.
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

- **616 tests** automatizados pasando.
- **14 migraciónes SQL** consecutivas verificadas.
- **27 features** funcionales y empaquetadas.
- **4 Edge Functions** desplegadas: `delete_user`, `import_gtfs`,
  `purge_old_data`, `send_notification`.
- **171 de 190** hitos del mega plan cerrados, equivalente al **90,0%**.
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
- **CI:** **7 jobs verdes** (analyze, test, integration, build).

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
- El TFG se entrega con metrica reproducible: 616 tests, 14 migraciónes,
  27 features, 4 Edge Functions y un mega plan al 90,0%.

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
