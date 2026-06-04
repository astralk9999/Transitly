# 02 — Diseño del Proyecto

**Proyecto:** Transitly (repositorio `nexto-stop-v2`).
**Estado verificado original:** `master @ b908f3c` (23 de mayo de 2026).
**Estado actualizado:** `master @ 5231f4c` (4 de junio de 2026); **+94 commits** posteriores, **release pública v1.11.0** distribuida en GitHub Releases (https://github.com/astralk9999/Transitly/releases/tag/v1.11.0), migración SQL adicional `fix_route_shares_rls_recursion` aplicada para resolver recursión en políticas RLS. Métricas históricas del anchor original: **619 tests**, **14 migraciones SQL** consecutivas, **27 features**, **4 Edge Functions** desplegadas, **5 ADRs**, **6 runbooks**, **73 documentos** en `docs/`, **171 ítems** del mega plan cerrados sobre 190 (90,0 %), **628 claves ARB** en tres locales (ES/EN/AR). Scorecard maestro: **TFG 8,9/10 · Producción 6,0/10** (`docs/00_MAESTRO.md` línea 11). Ver §9 al final del documento para el resumen consolidado de los cambios de junio.

---

## 1. Información técnica recopilada

Transitly se sustenta sobre un conjunto de **estándares abiertos** y **especificaciones normativas** que se han estudiado y consolidado antes de iniciar la fase de implementación. El estándar de datos estáticos es **GTFS** (General Transit Feed Specification), formato canónico publicado por Google y la fundación MobilityData para describir redes de transporte público; el feed estático contiene agencias, rutas, paradas, viajes y calendarios. Su complemento dinámico, **GTFS-Realtime**, expone posiciones de vehículo, predicciones de paso y alertas de servicio mediante mensajes Protobuf consumibles vía HTTP; no se integra aún por no estar disponible en COMUJESA, pero el modelo de datos lo contempla.

La cartografía se apoya en **OpenStreetMap** mediante capas vectoriales servidas por proveedores compatibles (MapTiler como primario, CartoDB como respaldo). La interoperación con la tarjeta de transporte se realiza sobre **NFC Mifare Classic 1K**, tecnología empleada por el Consorcio de Transportes de Andalucía y leída en modo solo lectura, lo que evita la necesidad de certificación bancaria. Las notificaciones se vehiculan por **Firebase Cloud Messaging** sobre la API HTTP v1 con autenticación OAuth JWT. La seguridad a nivel de fila se delega en el motor de **Row Level Security de PostgreSQL** con política DENY-by-default.

En cuanto al marco normativo, el proyecto se diseña en conformidad con la **WCAG 2.2 nivel AA**, con el **Reglamento (UE) 2016/679 (RGPD)** y su transposición nacional **LOPDGDD (Ley Orgánica 3/2018)**, con el **Real Decreto 1112/2018** sobre accesibilidad del sector público, y con el **Reglamento (UE) 2022/2065 (Digital Services Act)** en lo relativo a obligaciones de transparencia para plataformas con contenido generado por usuarios.

---

## 2. Objetivos funcionales

Se han fijado **doce objetivos funcionales** con sus respectivos criterios de aceptación verificables.

1. **Consulta de rutas, paradas y horarios** del operador piloto COMUJESA; aceptación: el listado completo se renderiza en menos de un segundo desde caché Hive.
2. **Visualización del autobús en mapa con estimación de posición**; aceptación: la posición se interpola a partir del horario y de la posición real del conductor cuando esta existe en el canal Realtime.
3. **Lectura del saldo de la tarjeta NFC del Consorcio Andaluz** mediante Mifare Classic; aceptación: el saldo se muestra en menos de tres segundos tras el contacto físico.
4. **Reporte de incidencias** geolocalizadas con votación de la comunidad; aceptación: la incidencia se persiste en `incidents` con su geometría PostGIS y se replica vía Realtime.
5. **Feedback sobre rutas existentes** con sistema de rangos y reputación; aceptación: el voto se asocia al perfil autenticado y respeta una política de un voto por usuario y ruta.
6. **Sugerencia de rutas faltantes** por parte de los usuarios; aceptación: la propuesta entra en el panel de moderación y exige aprobación.
7. **Modo conductor con grabación GPS** activable por código de invitación; aceptación: el conductor emite posición al canal Realtime con cadencia configurable.
8. **Panel de administración multi-rol** (pasajero, conductor, administrador de operador, moderador, administrador global); aceptación: el guard del router consume `profiles.role` desde Supabase.
9. **Modo offline** con regiones descargables y cola FIFO de acciones pendientes; aceptación: las acciones se drenan al recuperar conectividad con backoff exponencial.
10. **Accesibilidad ajustable** —contraste configurable, soporte de daltonismo y dislexia, reduce-motion, escala de texto, objetivos táctiles de 48 dp—; aceptación: los ajustes persisten y aplican sin reinicio.
11. **Internacionalización ES/EN/AR** con soporte completo de dirección de lectura inversa; aceptación: las 628 claves ARB existen en los tres locales.
12. **Notificaciones push** con horas silenciosas configurables; aceptación: la entrega se gobierna por consentimiento explícito y `quiet_hours`.

---

## 3. Objetivos no funcionales

Los objetivos no funcionales se agrupan en siete familias. En **rendimiento**, el arranque en frío del percentil 95 se sitúa por debajo de 2 segundos y la transición entre pestañas del percentil 95 por debajo de 300 milisegundos. En **escalabilidad**, la arquitectura soporta 10.000 usuarios activos diarios sin refactor y 100.000 con la incorporación de *clustering* en el mapa.

En **accesibilidad** se persigue la conformidad WCAG 2.2 AA verificable estáticamente sobre el código; el acta de pruebas con productos de apoyo (TalkBack y VoiceOver) se programa para la semana 10. En **seguridad** se aplica RLS DENY-by-default sobre todas las tablas, cifrado en reposo de las cajas Hive sensibles mediante `HiveAesCipher`, y almacenamiento de claves criptográficas en el llavero del sistema operativo a través de `flutter_secure_storage` (Keychain en iOS, Keystore en Android).

En **privacidad** la política es opt-out por defecto, con consentimiento granular y persistente; se implementan el artículo 8 (verificación de edad), el artículo 13 (información al interesado), el artículo 17 (derecho de supresión mediante un worker de borrado), el artículo 20 (portabilidad por exportación) y el artículo 21 (revocación de consentimiento en caliente sin reinicio) del RGPD. En **observabilidad** se instrumentan **6 spans** de Sentry y **17 eventos** de PostHog, todos gobernados por consent-gating. Finalmente, en **mantenibilidad e internacionalización**, la arquitectura limpia se acompaña de **619 tests automatizados**, **6 jobs de CI en verde**, RTL para árabe y `flutter analyze` con cero issues bloqueantes.

---

## 4. Fases y cronograma

El proyecto se desarrolla en un total de **11 semanas**, del 1 de abril al 16 de junio de 2026, organizadas en seis bloques. Las **semanas 1 y 2** (1–14 de abril) se dedican al análisis del contexto y a la detección de necesidades, materializadas en el documento 01. Las **semanas 3 y 4** (15–28 de abril) abarcan el diseño del proyecto —arquitectura, modelo de datos y objetivos— recogido en el presente documento. La **semana 5** (29 de abril–5 de mayo) corresponde a la planificación de la ejecución, con la primera entrega parcial el 5 de mayo. Las **semanas 6 a 9** (6 de mayo–2 de junio) constituyen el desarrollo e implementación, con la segunda entrega parcial el 2 de junio. La **semana 10** (3–9 de junio) se reserva al seguimiento, evaluación y elaboración de los manuales de usuario y desarrollador, incluida el acta de accesibilidad con productos de apoyo. La **semana 11** (10–16 de junio) se destina a la preparación y defensa pública del trabajo.

Las dos entregas parciales —fin de planificación el 5 de mayo y fin de desarrollo el 2 de junio— actúan como hitos de control. El detalle completo del Gantt y de las dependencias internas se recoge en `docs/tfg/03_planificacion.md`.

---

## 5. Estudio de viabilidad técnica

La elección de **Flutter 3.x con Dart 3** se justifica por cuatro razones: lenguaje único para móvil, web y escritorio que reduce a la mitad el esfuerzo de mantenimiento; *hot reload* que acelera el ciclo de iteración; un ecosistema maduro con respaldo de Google y de un consorcio amplio de empresas; y un rendimiento de renderizado nativo basado en Skia/Impeller. La alternativa razonable era React Native; se descartó por la fragmentación del ecosistema de navegadores de estado y por la menor cohesión de su capa nativa.

La elección de **Supabase** combina en un único servicio gestionado un PostgreSQL serio con soporte RLS, un servicio de autenticación, Edge Functions sobre Deno con tiempos de arranque del orden de decenas de milisegundos, suscripciones Realtime sobre WebSocket y almacenamiento de objetos. La alternativa Firebase puro se descartó por su mayor *vendor lock-in* y por la imposibilidad de ejecutar consultas SQL sobre el modelo de datos. La elección de **Riverpod 2.6** se motiva por su naturaleza compilable, su testeabilidad sin necesidad de `BuildContext` y su capacidad de generar proveedores con `autoDispose` de manera segura; la alternativa Bloc se descartó por el mayor *boilerplate* requerido. **Hive 2.2** se selecciona como almacén clave-valor por su rapidez y por la disponibilidad de cifrado AES integrado en las cajas sensibles; Realm se descartó por la pobreza relativa de su ecosistema en Flutter. La arquitectura **feature-first** facilita el crecimiento horizontal del equipo a futuro y aísla los dominios funcionales.

Las dependencias auxiliares completan el cuadro: **Firebase Messaging 16** para notificaciones push, **Sentry 8** para reporte de fallos, **PostHog 5** para analítica de producto, **flutter_secure_storage** para almacenamiento de claves criptográficas, **very_good_analysis** y **leak_tracker_flutter_testing** para enforcement de calidad estática y detección de fugas de memoria en tests.

---

## 6. Planificación de actividades, recursos, personal y financiación

Las **actividades** se detallan en `docs/tfg/03_planificacion.md` y se agrupan en análisis, diseño, planificación, implementación por bloques (cimientos, identidad, datos, experiencia, comunidad, infraestructura, plataformas y cierre) y seguimiento.

Los **recursos humanos** se reducen a un único desarrollador en régimen individual, con el respaldo del tutor académico del módulo y un grupo de cinco usuarios de prueba para la semana 10. La asistencia del sistema multiagente de inteligencia artificial queda declarada con transparencia en `multiagent/ARCHITECTURE.md` por integridad académica. Los **recursos técnicos** comprenden un equipo portátil de desarrollo, un emulador Android Pixel 6 con API 34, una cuenta gratuita de Supabase, una cuenta Firebase en plan Spark, un repositorio de GitHub gratuito y cuentas gratuitas de Sentry y PostHog. La **financiación directa** asciende a 0 euros durante el ciclo del TFG, dado que todas las herramientas se utilizan en sus planes gratuitos y la publicación pública en tiendas (25 euros únicos en Google Play y 99 euros anuales en Apple Developer) queda fuera del alcance académico.

---

## 7. Indicadores de calidad

Se han definido **nueve indicadores medibles** con sus respectivos umbrales y estado verificado. La cobertura de tests se fija como objetivo en el 60 % y se encuentra actualmente en el 24 %; la palanca correctiva, identificada y activa, consiste en escribir tests para la capa `remote/`. El análisis estático con `flutter analyze` debe mantenerse en cero issues bloqueantes. El tamaño del Android App Bundle objetivo es inferior a 50 MB total; el APK release actual ocupa 73,5 MiB sin separación por ABI, deuda explicitada en el scorecard. La accesibilidad WCAG 2.2 AA se verifica estáticamente y se complementará con acta manual. Los *advisors* de seguridad de Supabase deben permanecer en cero. La latencia p95 del flujo de autenticación se limita a 800 milisegundos y la del renderizado inicial del mapa a 1.500 milisegundos. Los 6 jobs de GitHub Actions deben permanecer en verde y el escáner Semgrep actúa de modo bloqueante en *pull request*.

---

## 8. Requisitos legales y conformidad

El proyecto se ajusta a un marco normativo amplio. En materia de **protección de datos** se aplican los artículos del RGPD ya mencionados —5 (minimización), 6 (base legal), 7 (consentimiento), 8 (menores), 13 (información), 17 (supresión), 20 (portabilidad) y 21 (oposición)— en conjunción con la LOPDGDD. En materia de **plataformas digitales** se observa el Reglamento de Servicios Digitales en lo relativo a transparencia, reporte de contenido ilícito y dotación de mecanismos de notificación y reclamación accesibles al usuario.

Respecto a las **licencias de software libre**, las dependencias utilizadas operan bajo licencias permisivas compatibles con uso comercial: **MIT** (Flutter, Riverpod, Hive, freezed, go_router, sentry_flutter), **BSD** (Dart, flutter_local_notifications) y **Apache 2.0** (plugins de Firebase, flutter_map, posthog_flutter). Los datos GTFS de COMUJESA se utilizan bajo licencia de uso público consultada en fuentes oficiales del Ayuntamiento de Jerez. Las tipografías DM Sans e IBM Plex Mono se distribuyen bajo SIL Open Font License y se bundlean como assets locales para evitar peticiones en tiempo de ejecución y preservar la privacidad del usuario. Los iconos Lucide se utilizan bajo licencia ISC.

Por último, el proyecto incluye **Términos del Servicio** y **Política de Privacidad** propias, alojadas en `assets/legal/` en versiones trilingües (español, inglés y árabe), accesibles desde el panel de privacidad de la aplicación. El documento siguiente, `03_planificacion.md`, desarrolla con mayor detalle el Gantt y la asignación temporal de actividades.

---

## 9. Actualización a 4 de junio de 2026

El diseño del proyecto presentado en este documento se mantiene íntegro: la pila tecnológica, los doce objetivos funcionales, los objetivos no funcionales agrupados en siete familias, el cronograma de 11 semanas y los nueve indicadores de calidad continúan siendo el marco de referencia. Los cambios introducidos entre el 23 de mayo y el 4 de junio responden todos a refuerzo, estabilización o extensión incremental dentro del alcance ya planificado, sin alterar ninguna decisión arquitectónica de fondo.

**Cambios significativos a nivel de arquitectura:**

1. **Recovery boot y persistencia diferida de preferencias**: se introdujo `BootCanary` (`lib/core/utils/boot_canary.dart`) y `RecoveryScreen` (`lib/features/recovery/`) como red de seguridad ante crashes nativos del engine de Flutter al combinar opciones de accesibilidad (dislexia + alto contraste + tamaño de texto). El mecanismo persiste sólo tras el primer frame estable y revierte la última preferencia tóxica si se detectan dos crashes consecutivos en arranque. Esto refuerza el objetivo no funcional de mantenibilidad sin alterar el modelo de datos.

2. **Migración SQL adicional `fix_route_shares_rls_recursion`**: se detectó un ciclo entre las políticas RLS de `route_shares` y `routes` que provocaba error PostgreSQL **42P17** (infinite recursion in policy) al consultar las contribuciones del usuario. Se resolvió mediante una función `SECURITY DEFINER` `public.is_route_owner(uuid)` que bypassa RLS para el lookup, manteniendo la semántica original de visibilidad. Documentado en `docs/SUPABASE_SETUP.md`.

3. **Bypass temporal de verificación de email**: ante la imposibilidad de configurar SMTP propio dentro del cronograma del TFG, se desactivó la verificación obligatoria de correo en el listener de auth (`auth_repository_supabase.dart`) y se añadió un auto-login defensivo en `signUpWithEmail`. La infraestructura `EmailVerifyPendingScreen` queda dormida y reactivable cuando se configure SMTP. Documentado en `docs/SUPABASE_SETUP.md`.

4. **Filtros del mapa con árbol jerárquico**: el filtro plano de operadores se sustituyó por un árbol expandible de tres niveles (zona → compañía → líneas) con checkbox tri-state. Refuerza el objetivo de escalabilidad multi-operador del cronograma futuro.

5. **Widgets Android configurables**: pantallas de configuración en perfil para los tres widgets (Próximo bus, Mi línea, Saldo NFC) con preview y botón "Probar". Implementación en `lib/features/widgets_config/`.

6. **Wizard de creación de rutas con tap en mapa**: el formulario manual de coordenadas se complementa con `MapStopPickerScreen` que permite añadir paradas tocando el mapa y buscar lugares vía Nominatim (OpenStreetMap).

7. **Release pública v1.11.0**: el APK release se publica como asset en GitHub Releases (`https://github.com/astralk9999/Transitly/releases/tag/v1.11.0`). La presentación web ahora enlaza a `releases/latest` en lugar de versionar APKs en el repositorio, lo que ha reducido el `working tree` en ~792 MB y previene el bloqueo de push por archivos >100 MB.

Los demás aspectos del diseño —modelo de datos, objetivos de rendimiento, cronograma, indicadores de calidad y marco legal— continúan vigentes sin modificaciones.
