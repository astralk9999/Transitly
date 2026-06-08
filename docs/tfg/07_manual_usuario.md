# 07 — Manual de Usuario

**Aplicación:** Transitly
**Versión del documento original:** 2026-05-23
**Versión actualizada:** 2026-06-08
**Versión instalable distribuida:** v1.12.1 (APK universal, Android 7.0+) — descarga directa desde https://github.com/astralk9999/Transitly/releases/latest o desde la web del proyecto https://astralk9999.github.io/Transitly/
**Plataformas:** Android, iOS y Web (PWA)
**Audiencia:** usuario final, sin conocimientos técnicos previos

---

## 1. Que es Transitly

Transitly es una aplicación móvil y web que te ayuda a usar el transporte
público urbano e interurbano en ciudades medias espanolas. Te permite
consultar las líneas y paradas de tu ciudad, ver donde están los autobuses
en el mapa, conocer los próximos tiempos de llegada, reportar incidencias
y sugerir mejoras al servicio. La aplicación se ha desarrollado tomando
como operador piloto a COMUJESA (Jerez de la Frontera), aunque su diseno
permite incorporar nuevos operadores en el futuro.

Transitly busca cubrir el hueco que existe en ciudades sin aplicaciónes
oficiales en tiempo real. Por eso combina datos de horario con la
información que aportan los propios conductores y los pasajeros, ofrece
modo sin conexión para zonas con cobertura débil y se ha disenado para
ser accesible: alto contraste, lectores de pantalla, escala de texto,
modo daltonismo y soporte de espanol, ingles y arabe con lectura de
derecha a izquierda.

---

## 2. Instalación

### 2.1. Android (instalación del APK)

Durante la fase de TFG, Transitly se distribuye como APK (aún no está publicada en Google Play). La instalación es sencilla:

1. Desde tu teléfono Android, entra en la web del proyecto
   `https://astralk9999.github.io/Transitly/` y pulsa **Descargar APK**
   (o ve directo a `https://github.com/astralk9999/Transitly/releases/latest`).
2. Cuando termine la descarga, abre el archivo `transitly-vX.Y.Z.apk`.
3. Android te avisará de que procede de un origen desconocido: pulsa
   **Ajustes** y concede permiso para instalar (puedes revocarlo después).
4. Pulsa **Instalar** y, al terminar, **Abrir**. El icono de Transitly
   quedará en tu escritorio.

> Requiere **Android 7.0 o superior**. El APK es universal, así que
> funciona en cualquier móvil (arm64, arm de 32 bits o x86_64).

### 2.2. iOS

1. Abre la App Store en tu iPhone o iPad.
2. Busca **Transitly** o entra en `https://transitly.app/ios`.
3. Pulsa **Obtener** y confirma con Face ID, Touch ID o contrasena.
4. Cuando termine la instalación, pulsa **Abrir**.

### 2.3. Web (PWA)

1. Entra desde tu navegador en `https://transitly.app/web`.
2. En el menu del navegador, seleccióna **Instalar aplicación** o
   **Anadir a pantalla de inicio**.
3. Confirma cuando el navegador te lo pida. Tendras un icono igual que
   el de una aplicación nativa.

> Si tu teléfono no es compatible con la instalación nativa, la versión
> web funciona igualmente desde cualquier navegador moderno.

---

## 3. Primera vez que abres la aplicación

La primera vez que ejecutes Transitly veras tres pantallas de
bienvenida que explican brevemente las funciones principales. Puedes
deslizar el dedo para avanzar o pulsar **Saltar** si prefieres ir
directo a la aplicación.

A continuación se te pediran los siguientes pasos:

1. **Seleccióna ciudad.** Por defecto aparece **Jerez de la Frontera**.
   Si quieres cambiarla, pulsa sobre el nombre y elige otra de la lista.
2. **Concede permisos.** La aplicación solicita ubicación (para mostrar
   tu posición en el mapa), notificaciones (para avisos de retrasos) y,
   solo en Android, acceso a NFC (para leer la tarjeta del Consorcio).
   Puedes denegarlos y la aplicación seguira funcionando con menos
   funciones.
3. **Banner de consentimiento (privacidad).** Veras una pantalla
   resumiendo los tratamientos opcionales: analítica de uso, informes
   de fallos y comúnicaciónes. Cada uno tiene un interruptor
   independiente, todos desactivados por defecto. Acepta o rechaza con
   los botones inferiores.
4. **Iniciar sesión o continuar como invitado.** Pulsa **Continuar como
   invitado** para usar la aplicación sin registro, o **Iniciar sesión**
   para acceder a funciones avanzadas (favoritos sincronizados, reportar
   incidencias verificadas, modo conductor con código, etc.).

---

## 4. Pantalla principal

La pantalla de inicio tiene cinco pestanas en la barra inferior:

- **Inicio.** Resumen personalizado: tus líneas favoritas, últimas
  alertas y accesos rápidos a planificar un viaje.
- **Mapa.** Mapa interactivo con paradas y autobuses en circulación.
- **Tarjeta.** Lectura del saldo de la tarjeta del Consorcio Andalucia
  mediante NFC.
- **Buscar.** Buscador de líneas, paradas y direcciónes.
- **Perfil.** Tu cuenta, ajustes, privacidad, idioma y accesibilidad.

Para cambiar de pestana, pulsa el icono correspondiente. La pestana
activa aparece resaltada.

---

## 5. Consultar una línea

1. Ve a **Buscar** o pulsa una línea desde **Inicio**.
2. Aparecera la pantalla de **Detalle de línea** con:
   - El recorrido en el mapa.
   - La lista de paradas de ida y vuelta.
   - Los horarios programados.
   - Las alertas activas (desvios, cortes, refuerzos).
3. Si quieres guardar la línea, pulsa el icono de **estrella** en la
   esquina superior derecha. Aparecera entre tus favoritos en Inicio.

---

## 6. Ver un autobus en el mapa

1. Pulsa la pestana **Mapa**.
2. Cada parada aparece como un punto y cada autobus en circulación como
   un icono de bus.
3. Pulsa un autobus para ver su línea, sentido y próxima parada.
4. Pulsa una parada para ver las próximas llegadas en esa parada.
5. Usa los gestos habituales: arrastra para desplazar, junta o separa
   los dedos para ampliar o reducir.

---

## 7. Proximas llegadas

Cuando entras en una parada, ya sea desde el mapa o desde el detalle de
una línea, veras una lista con las **próximas tres salidas estimadas**
de las líneas que pasan por ella. Cada estimación indica:

- La línea y el destino.
- Los minutos restantes.
- Si la estimación procede de horario o de GPS de un conductor.

Si la información es antigua o no esta disponible, la aplicación lo
indica claramente y no inventa datos.

---

## 8. Reportar una incidencia

1. Entra en la parada o en la línea afectada.
2. Pulsa el boton **Reportar**.
3. Elige el tipo de incidencia: **Retraso**, **Vehiculo lleno**,
   **Desvio** o **Averia**.
4. Anade un comentario opcional (máximo 200 caracteres). No incluyas
   datos personales de terceros.
5. Pulsa **Enviar**. Tu reporte se mostrara en el mapa para el resto
   de usuarios.

Los reportes se moderan automáticamente y se contrastan con otros
usuarios. Si alguien reporta lo mismo, gana reputación en la comunidad.

---

## 9. Dejar feedback sobre una ruta

1. Entra en el detalle de la línea.
2. Pulsa **Dar feedback**.
3. Puntua de 1 a 5 estrellas:
   - **Puntualidad** del servicio.
   - **Amabilidad** del personal.
   - **Limpieza** del vehiculo.
4. Anade un comentario opcional.
5. Pulsa **Enviar**.

El operador recibe estos comentarios de forma agregada y anonima.

---

## 10. Sugerir una nueva ruta

1. Ve a **Perfil** y pulsa **Sugerir ruta nueva**.
2. Rellena el formulario:
   - **Origen** y **destino** (puedes elegir paradas existentes o
     escribir direcciónes).
   - **Operador** propuesto.
   - **Paradas intermedias** que crees necesarias.
   - **Justificacion** breve.
3. Pulsa **Enviar sugerencia**.

Otros usuarios podrán votar la sugerencia. Las propuestas con más votos
se trasladan al operador.

---

## 11. Leer la tarjeta del Consorcio (NFC)

> Esta función solo esta disponible en Android con NFC y con la tarjeta
> física del **Consorcio de Transporte de Andalucia**.

1. Pulsa la pestana **Tarjeta**.
2. Pulsa **Escanear tarjeta**.
3. Acerca la tarjeta a la parte trasera del teléfono y mantenla quieta
   durante unos segúndos.
4. Veras el **saldo actual** y los **últimos viajes** registrados.

La aplicación no recarga la tarjeta ni modifica su contenido: solo lee
la información pública grabada en el chip.

---

## 12. Usar la aplicación sin conexión

1. Ve a **Perfil** > **Datos sin conexión**.
2. Pulsa **Descargar región de Jerez**.
3. Espera a que termine la descarga (puede tardar uno o dos minutos en
   conexión lenta).
4. A partir de ese momento podras consultar el mapa, las paradas y los
   horarios aunque no tengas internet. Las llegadas en tiempo real
   requieren conexión.

Para liberar espacio, en el mismo apartado puedes **Borrar la región
descargada**.

---

## 13. Cambiar idioma, tema y accesibilidad

Desde **Perfil** tienes tres apartados:

- **Apariencia.** Permite elegir tema claro, oscuro o automático según
  el sistema, escoger la paleta de colores y la fuente.
- **Accesibilidad.** Activa alto contraste, modo daltonismo (varias
  matrices disponibles), aumenta la escala de texto y habilita la
  fuente para dislexia.
- **Idioma.** Seleccióna espanol, ingles o arabe. Al elegir arabe la
  aplicación cambia automáticamente a lectura de derecha a izquierda.

Los cambios se aplican al instante y se recuerdan para la próxima vez.

---

## 14. Privacidad y protección de datos

Transitly cumple el Reglamento General de Protección de Datos. Tienes
control total sobre tu información desde **Perfil** > **Privacidad**.

### 14.1. Modificar el consentimiento

En cualquier momento puedes activar o desactivar:

- **Analitica de uso.**
- **Informes de fallos.**
- **Comúnicaciones comerciales.**

Todos están desactivados por defecto y nunca afectan al funcionamiento
básico de la aplicación.

### 14.2. Solicitar una copia de tus datos (Articulo 20)

1. Entra en **Privacidad** y pulsa **Solicitar mis datos**.
2. Confirma tu correo electrónico.
3. Recibiras un archivo ZIP con tu información en un plazo máximo de
   **siete días**.

### 14.3. Eliminar tu cuenta (Articulo 17)

1. En **Privacidad**, pulsa **Eliminar cuenta**.
2. Confirma tu intención. La cuenta entra en periodo de gracia de
   **30 días**.
3. Si cambias de opinion, puedes cancelarla volviendo a entrar antes
   del **día 29**. A partir del día 30 el borrado es irreversible.

### 14.4. Verificación de edad (Articulo 8)

Al registrarte se solicita la fecha de nacimiento. Los **menores de
16 anos** no pueden crear cuenta. Si la introduces y el sistema detecta
que no cumples la edad mínima, el registro se cancela.

---

## 15. Modo conductor

Si trabajas como conductor o conductora y tu operador te ha fácilitado
un código de invitación:

1. Ve a **Perfil** > **Activar modo conductor**.
2. Introduce el código proporcionado por el operador.
3. Al activarse, en **Perfil** aparece un acceso **Panel de conductor**
   con tu cuadro de turnos.
4. Pulsa **Iniciar ruta** cuando comiences un servicio. El teléfono
   compartira tu ubicación solo durante el trayecto.
5. Cuando termines, pulsa **Finalizar ruta**. El historico queda en
   **Mis viajes** para tu propio control.

Si no eres conductor o conductora, ignora este apartado: la opcion no
hace nada sin un código válido.

---

## 16. Notificaciones

1. Ve a **Perfil** > **Notificaciones**.
2. Activa o desactiva los avisos por categoria:
   - **Alertas de tus líneas favoritas.**
   - **Retrasos significativos.**
   - **Novedades del servicio.**
3. Si una notificacion concreta te molesta, mantenla pulsada para abrir
   los ajustes del sistema y silenciarla.

---

## 17. Reportar un problema con la aplicación

Si encuentras un fallo o una función no se comporta como esperas:

1. Ve a **Perfil** > **Ayuda** > **Reportar un problema**.
2. Describe lo ocurrido y, si quieres, adjunta una captura.
3. Pulsa **Enviar**.

También puedes escribir a `soporte@transitly.app` indicando versión del
teléfono y de la aplicación.

---

## 18. Atajos de accesibilidad

Transitly esta probada con los lectores de pantalla más habituales:

- **TalkBack (Android).** Activa el lector desde **Ajustes del sistema
  > Accesibilidad**. Después, abre Transitly y desplaza el dedo sobre
  la pantalla para escuchar cada elemento. Doble toque activa la
  opcion enfocada.
- **VoiceOver (iOS).** Activalo desde **Ajustes > Accesibilidad >
  VoiceOver**. En Transitly funciona igual: deslizar para enfocar,
  doble toque para activar.

La aplicación incluye descripciones para todos los iconos importantes,
respeta la escala de texto del sistema y mantiene el contraste mínimo
exigido en todos los temas, también con paletas alternativas para
daltonismo.

---

## 19. Preguntas frecuentes

**No me aparece mi ciudad en la lista.** En la versión actual solo
esta disponible Jerez de la Frontera con datos reales. Si necesitas
otra ciudad, escribe a `soporte@transitly.app`.

**La aplicación no detecta mi tarjeta NFC.** Verifica que el NFC del
teléfono este activo, que tu modelo lo soporte y que la tarjeta sea del
Consorcio de Transporte de Andalucia. Algunas fundas gruesas dificultan
la lectura.

**Las llegadas estimadas no son exactas.** Cuando un autobus no tiene
GPS activo, la aplicación usa el horario teórico, que puede no reflejar
retrasos. Reportar incidencias ayuda a mejorar la estimación.

**He borrado la aplicación y quiero recuperar mis favoritos.** Si te
registraste con cuenta, vuelve a iniciar sesión y se restauraran. Si
usaste modo invitado, los favoritos se guardan solo en el dispositivo.

**Quiero borrar todos mis datos.** Sigue el paso 14.3 de este manual.

---

## Adenda — Novedades de la versión v1.11.0 (4 de junio de 2026)

Si vienes de una versión anterior, en v1.11.0 encontrarás los siguientes cambios visibles:

**Login con Google funcional.** El botón "Continuar con Google" en la pantalla de inicio de sesión ya funciona en todos los dispositivos. Si tu cuenta no entra al primer intento, espera unos segundos y vuelve a tocarla — la app reintenta automáticamente.

**Sin obligación de verificar email para usar la app.** El flujo de registro envía las credenciales al servidor y entras directamente al inicio sin esperar a un correo de verificación. Esto es temporal mientras se configura el servidor de correo propio; si más adelante recibes un email de verificación, púlsalo igualmente para mantener la cuenta validada.

**Personalización completa y persistente.** Las paletas de color funcionan ahora en modo claro y oscuro, manteniendo el matiz característico de cada una (Sunrise sigue siendo cálida en claro, Forest sigue siendo verde). El fondo animado (Smoke, Aurora, FloatingLines, etc.) se aplica en todas las pestañas, no solo en Apariencia. El alto contraste fuerza texto negro sobre blanco (o blanco sobre negro en modo oscuro) en lugar del scheme original.

**Pantalla de recuperación ante problemas de arranque.** Si activas varias opciones de accesibilidad a la vez y la app no abre en los siguientes dos arranques, verás una pantalla blanca con un triángulo amarillo y la opción "Restaurar configuración por defecto". Toca ese botón y la app volverá a abrir con los valores iniciales. No es necesario borrar datos del sistema.

**Filtros del mapa por compañía y línea.** En el sheet de filtros del mapa, ahora hay un árbol expandible: Jerez → COMUJESA → líneas L1, L2, ... Puedes desmarcar una compañía entera o solo líneas individuales. El estado se guarda y se conserva entre sesiones.

**Widgets de pantalla de inicio configurables.** En Perfil → Widgets puedes configurar cada uno de los tres widgets:
- **Próximo bus**: elige línea y parada → preview en vivo del widget → "Probar" actualiza el widget de tu launcher en segundos.
- **Mi línea**: elige una línea favorita → preview con próximas salidas.
- **Saldo bonobús**: enlaza directamente al escaneo NFC; no requiere configuración.

**Wizard de crear ruta con mapa interactivo.** Al crear una nueva ruta como usuario normal (Perfil → Comunidad → Crear nueva ruta), el paso "Paradas" ahora abre un mapa donde tocas el punto exacto en lugar de teclear coordenadas. También puedes buscar lugares por nombre ("Hotel Jerez", "Gasolinera Cepsa") y la app los localiza automáticamente.

**Click sobre línea en el mapa.** Si tocas una de las líneas de bus dibujadas sobre el mapa, aparece un snackbar con el código y nombre de la línea (p. ej. "Línea L8 · Norte"). El sheet inferior se filtra para mostrar sólo esa línea y sus paradas; toca la X para volver a ver todas.

**Mejor saludo en el inicio.** El saludo de bienvenida ("Buenos días", "Buenas tardes", "Buenas noches", "Buena madrugada") cambia ahora cuatro veces al día y se ajusta al idioma seleccionado.

---

## Adenda 2 — Novedades de la versión v1.12.1 (8 de junio de 2026)

**Avisos aunque tengas la app cerrada.** Transitly ya recibe notificaciones push reales: cuando se resuelve una incidencia que reportaste, te comparten una ruta o hay novedades de tus líneas, te llega el aviso aunque no tengas la app abierta. Puedes seguir ajustando qué categorías quieres recibir desde **Perfil → Notificaciones** (y las horas silenciosas).

**El modo conductor sigue compartiendo con la pantalla bloqueada.** Si eres conductor o conductora, al **Iniciar ruta** la app mantiene una notificación permanente y sigue compartiendo tu posición aunque bloquees el móvil o cambies de aplicación. Así el resto de viajeros te ven en el mapa durante todo el trayecto. Al pulsar **Finalizar ruta**, deja de compartir y la notificación desaparece.

**Planificador de viaje origen → destino.** En la pestaña **Buscar** puedes indicar de dónde sales y a dónde quieres ir, y la app te propone cómo llegar, incluyendo trayectos con un transbordo.

**Modo claro de la web mejorado.** La página del proyecto se ve correctamente tanto en tema claro como oscuro.

> **Requisito actualizado:** la app requiere **Android 7.0 o superior**.
