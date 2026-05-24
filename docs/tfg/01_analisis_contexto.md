# 01 — Análisis del Contexto y Detección de Necesidades

**Proyecto:** Transitly (repositorio `nexto-stop-v2`).
**Autor:** trabajo individual con asistencia documentada de un sistema multiagente de inteligencia artificial.
**Ciclo formativo:** Desarrollo de Aplicaciones Multiplataforma (DAM).
**Estado verificado:** `master @ b908f3c` (23 de mayo de 2026).

---

## 1. Sector y problema concreto

El sector de referencia es la **movilidad urbana basada en transporte público colectivo en ciudades medias españolas**, con especial atención al autobús urbano e interurbano. Según los datos del Instituto Nacional de Estadística publicados durante 2024, los servicios urbanos de autobús transportaron aproximadamente **1.500 millones de viajeros** y los interurbanos cerca de **600 millones**, lo que confirma una demanda diaria masiva, rutinaria y muy sensible a la calidad de la información ofrecida al usuario.

El sector exhibe tres rasgos estructurales relevantes para cualquier iniciativa tecnológica que pretenda actuar sobre él. El primero es la **demanda masiva y diaria**, en la que el viajero valora más la fiabilidad de la información en tiempo real que el precio del trayecto. El segundo es la **fragmentación operativa**, dado que cada ciudad y cada consorcio cuentan con su propio operador, su propio modelo de datos, su propia aplicación móvil y su propia tarjeta sin contacto, lo que obliga al usuario a familiarizarse de nuevo con cada cambio de territorio. El tercero es la **heterogeneidad tecnológica**: mientras grandes ciudades como Madrid o Barcelona publican feeds GTFS-Realtime y mantienen aplicaciones móviles maduras, las ciudades medias —Jerez de la Frontera, Cuenca, Logroño, Cáceres— se apoyan todavía en paneles web estáticos y aplicaciones mínimas sin información en vivo.

El problema concreto que aborda Transitly es la **asimetría informativa que sufre el usuario del autobús urbano en una ciudad media española**. Concretamente, el viajero no puede saber dónde se encuentra su vehículo, no dispone de estimación de tiempo de llegada, no recibe notificación de incidencias por un canal estructurado, debe gestionar tantas aplicaciones como operadores utilice y solo puede consultar el saldo de su tarjeta NFC del Consorcio de Transportes de Andalucía en máquinas físicas. El caso de estudio piloto es **COMUJESA (Compañía Municipal del Transporte Urbano de Jerez, S.A.)**, operador municipal de Jerez de la Frontera, en la provincia de Cádiz.

---

## 2. Tipos de empresas y estructuras

El tejido empresarial del transporte público colectivo en España se articula en torno a cuatro tipologías de actor. Los **operadores municipales** son sociedades de capital público dependientes del ayuntamiento; gestionan flota propia, contratan personal y cuentan con presupuesto subvencionado. COMUJESA en Jerez, EMT en Madrid, Valencia o Málaga, y TUSSAM en Sevilla son ejemplos representativos. Los **consorcios autonómicos o metropolitanos**, como el Consorcio de Transportes de Andalucía o el Consorcio Regional de Transportes de Madrid, agregan a varios operadores municipales e interurbanos, gestionan la tarjeta única zonal e integran las tarifas. Los **operadores privados concesionarios**, adjudicatarios mediante concurso público, explotan rutas interurbanas o municipales con flota propia: Avanza, Damas, AUVASA o TITSA son referentes. Por último, las **aplicaciones agregadoras de terceros** —Moovit, Citymapper o Google Maps Transit— no operan flota, sino que consumen los feeds GTFS publicados por los operadores.

Todos estos actores manejan, con independencia de su forma jurídica, las mismas entidades de negocio: rutas, paradas, horarios, flota, conductores, tarifas e incidencias. Esta convergencia conceptual es la que permite a Transitly proponer un modelo de datos común basado en GTFS y abstraer las diferencias operativas detrás de una única interfaz.

---

## 3. Necesidades actuales detectadas

El análisis del estado del arte y la observación directa del caso COMUJESA permiten identificar **siete carencias estructurales** que sufre el viajero de una ciudad media española. La primera es la **ausencia de información de posición en vivo del vehículo**, ya que los autobuses no aparecen en un mapa y el horario estático rara vez refleja la realidad operativa. La segunda es la **inexistencia de estimación de tiempo de llegada**, derivada de la ausencia de GPS a bordo expuesto al usuario. La tercera es la **fragmentación del ecosistema de aplicaciones**, que obliga al usuario a manejar una aplicación distinta por operador con interfaces dispares.

La cuarta carencia es la **accesibilidad deficiente** de las aplicaciones existentes: contrastes insuficientes, ausencia de soporte para personas con dislexia o daltonismo, falta de etiquetado semántico para lectores de pantalla y ausencia de soporte para idiomas con dirección de lectura inversa como el árabe, idioma con presencia creciente entre la población usuaria de transporte público en Andalucía. La quinta es la **opacidad de la tarjeta NFC Mifare Classic** del Consorcio de Transportes de Andalucía, cuyo saldo solo puede consultarse en taquillas, quioscos o máquinas expendedoras físicas. La sexta es la **inexistencia de un canal estructurado para reportar incidencias** —retrasos, averías, desvíos—, que actualmente se vehicula informalmente a través de redes sociales. La séptima y última es la **ausencia de observabilidad** por parte del operador, que no dispone de telemetría agregada del uso de su red.

---

## 4. Oportunidades de negocio

El diagnóstico anterior abre **cinco oportunidades de negocio** diferenciables. En primer lugar, un **modelo SaaS B2G** dirigido a operadores municipales y consorcios de tamaño medio, mediante una suscripción anual que incluye marca personalizada, panel de moderación, importador GTFS y telemetría agregada. En segundo lugar, una **plataforma multi-operador** que centralice la experiencia del viajero en una única aplicación con cobertura nacional progresiva, partiendo de Jerez como piloto y escalando al resto de operadores andaluces vía Consorcio. En tercer lugar, una **comunidad UGC** —contenido generado por usuarios— con sistema de reputación, votación y moderación, que aporta la información cualitativa que los feeds oficiales no capturan: averías, incidencias puntuales, sugerencias de rutas inexistentes.

En cuarto lugar, la **accesibilidad como elemento diferenciador** competitivo en un sector donde las aplicaciones dominantes ofrecen una accesibilidad genérica y poco verificada; un cumplimiento documentado de WCAG 2.2 AA constituye una ventaja defendible frente a Google Maps Transit o Moovit. En quinto lugar, la **integración futura con GTFS-Realtime** cuando los operadores expongan estos feeds de manera abierta, lo que permitiría ofrecer información de posición real sin depender del modo conductor interno de la propia aplicación.

---

## 5. Guión inicial de trabajo

El guión inicial del trabajo se concreta en la construcción de un **producto mínimo viable de consulta de transporte público, comunidad y accesibilidad**, con COMUJESA como operador piloto en Jerez de la Frontera. La arquitectura se diseña multi-operador desde el primer día, pero el alcance funcional del TFG se limita al operador piloto. El producto incluye consulta de rutas, paradas y horarios, mapa con estimación de posición, lectura del saldo de la tarjeta NFC del Consorcio Andaluz, reporte de incidencias, sistema de reputación comunitaria, modo conductor con grabación GPS, panel administrativo, modo offline con regiones descargables, soporte de accesibilidad multidimensional, internacionalización trilingüe en español, inglés y árabe, y notificaciones push.

Quedan **explícitamente fuera del alcance** del TFG cuatro líneas de trabajo que se documentan como evolución futura: la integración con GTFS-Realtime real (pendiente de que los operadores expongan los feeds), el widget iOS completo (limitado por las restricciones de la plataforma), la expansión activa a otras ciudades distintas de Jerez (requiere acuerdos comerciales con sus respectivos operadores), y el desarrollo de un modelo de aprendizaje automático para predicción precisa de ETA (requiere histórico de posiciones reales que solo se obtiene tras un periodo de operación). Estas exclusiones se recogen formalmente en `docs/EXTERNAL_BLOCKERS.md` junto al resto de bloqueadores externos al control del autor.

El documento siguiente, `02_diseno_proyecto.md`, materializa este análisis en la arquitectura técnica, objetivos funcionales y no funcionales, planificación de recursos y requisitos legales del proyecto.
