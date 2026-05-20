# 07 — Manual de Usuario

**Aplicación:** Transitly
**Para:** usuarios finales (pasajeros, conductores, administradores)
**Plataformas:** Android, iOS, Web

> Si eres desarrollador o quieres instalar/desplegar la app, ve a
> `06_manual_tecnico.md`.

---

## 1. ¿Qué es Transitly?

Transitly es una **aplicación de transporte público en tiempo real**.
Te permite:

- Ver dónde está el autobús que te interesa **ahora mismo**.
- Saber cuántos minutos faltan para que llegue a tu parada.
- Reportar incidencias (retrasos, averías, masificación) y verlas en
  el mapa.
- Sugerir nuevas rutas o mejoras y votar las sugerencias de otros.
- Leer el **saldo de tu Tarjeta del Consorcio** (móvil con NFC) sin
  pasar por una máquina.
- Trabajar con la app **sin red** si has descargado tu zona.
- Usarla con **alto contraste, fuente para dislexia, lector de
  pantalla** y en **español, inglés o árabe** (con dirección de lectura
  derecha-a-izquierda).

Está pensada para ciudades medias españolas donde los operadores no
ofrecen información en tiempo real propia. El operador piloto es
**COMUJESA (Jerez de la Frontera)**.

---

## 2. Primeros pasos

### 2.1. Instalar la app

- **Android:** Google Play Store → buscar "Transitly" o instalar el
  APK proporcionado.
- **iOS:** App Store → buscar "Transitly".
- **Web:** abre https://transitly.app (si está publicado) o el sitio
  proporcionado por tu tutor / profesor.

### 2.2. Sin registro

Puedes usar la app **sin crear cuenta** (modo invitado). Verás datos
demostrativos de Jerez (COMUJESA). Algunas funciones (contribuir,
reportar, recibir notificaciones, sincronizar preferencias entre
dispositivos) requieren registro.

### 2.3. Crear cuenta

1. En la barra inferior, toca **Perfil**.
2. Toca **Iniciar sesión**.
3. Elige una de las opciones:
   - **Email + contraseña** — introduce tu email y elige contraseña.
   - **Enlace mágico** — introduce tu email; recibirás un correo con
     un enlace de acceso.
4. Confirma tu email haciendo clic en el enlace recibido.
5. ¡Listo! La app detectará tu ciudad automáticamente.

### 2.4. Cambiar idioma o accesibilidad antes de empezar

Desde la pantalla de bienvenida o desde **Perfil →
Accesibilidad**:

- **Idioma:** Español / English / العربية (con RTL).
- **Modo:** Claro / Oscuro / Automático.
- **Apariencia:** paleta de colores, fondo del mapa, fuente.
- **Accesibilidad:** alto contraste, daltonismo, OpenDyslexic, tamaño
  de texto, reducir animaciones.

---

## 3. La pantalla de Inicio

Es la primera pestaña de la barra inferior. Te ofrece:

- **Rutas favoritas** — las que más usas; toca para abrir el detalle.
- **Parada habitual** — la parada cerca de tu casa o trabajo.
- **Próximas salidas** — los buses que están por llegar a tus
  paradas habituales (con minutos restantes o "vivo" si hay un
  conductor compartiendo).
- **Paradas cercanas** — calculadas con tu ubicación (con permiso).

Toca cualquier tarjeta para ver más detalles.

---

## 4. El Mapa

Es la pestaña central. Muestra:

- **Rutas** dibujadas como líneas de colores.
- **Paradas** como puntos.
- **Autobuses en vivo** como iconos de bus moviéndose.
- **Incidencias activas** como triángulos de aviso.

### 4.1. Tipos de autobús en el mapa

Cada bus muestra una etiqueta para que sepas de dónde viene la
información:

- **Oficial · Vivo** — datos oficiales del operador en tiempo real.
- **Oficial · Estimado** — posición calculada según horario (no GPS
  en vivo en ese momento).
- **Comunidad · Driver** — un conductor está compartiendo su
  ubicación con la app.
- **Comunidad · Estimado** — ruta sugerida por la comunidad, posición
  estimada.

### 4.2. Filtrar el mapa

Toca el icono de **embudo** para:

- Mostrar/ocultar rutas oficiales o comunitarias.
- Filtrar por tipo de incidencia (retraso, avería, masificación, etc.).
- Cambiar el estilo del mapa (claro / oscuro / satélite simplificado).
- Ajustar la capacidad mínima del bus que quieres ver (lleno / medio
  / vacío).

### 4.3. Buscar en el mapa

Toca **Buscar** (icono de lupa) para encontrar una parada o ruta por
nombre o código.

### 4.4. Modo accesible al mapa

Si usas lector de pantalla, ve a **Perfil → Accesibilidad → Vista
accesible de buses** para una lista equivalente al mapa con la misma
información en formato textual.

---

## 5. Búsqueda

La pestaña **Buscar** te permite encontrar rutas o paradas:

1. Escribe un nombre de parada, nombre de ruta o código.
2. Toca un resultado para ver los detalles.

---

## 6. Detalle de ruta

Al abrir una ruta verás:

- **Recorrido** dibujado en el mapa.
- **Paradas** en orden.
- **Próximas salidas** desde la parada más cercana.
- **Incidencia activa** (si la hay) destacada.
- **Frecuencia** (cada cuánto pasa el bus).

### Acciones disponibles

- **Compartir** — envía la ruta a un contacto.
- **Reportar incidencia** — notifica un problema en esta ruta.
- **Sugerir mejora** — propón cambios en la ruta o paradas.
- **Oficializar ruta** — si es comunitaria y muy votada, pide que
  pase a oficial.
- **Confirmar** — si todo está bien, da un voto de confianza.

---

## 7. Detalle de parada

Al abrir una parada verás:

- **Líneas que pasan** con sus tiempos estimados.
- **Próximas llegadas** ordenadas por minutos.
- **Saldo NFC** (si has acercado tu tarjeta del Consorcio).
- **Reportar incidencia** específica de la parada (panel roto, mal
  estado, etc.).

### 7.1. Leer tu Tarjeta del Consorcio Andaluz por NFC

1. Activa el NFC en tu móvil (Configuración del sistema).
2. En la app, abre la pestaña **Mi tarjeta** (icono de tarjeta).
3. Acerca tu tarjeta a la parte trasera del móvil.
4. La app leerá el saldo y los últimos viajes.

Si la lectura falla:

- Asegúrate de que la tarjeta es **Mifare Classic** (la del Consorcio
  de Transportes de Andalucía).
- Acerca despacio y mantén unos segundos.
- Si persiste, el chip puede estar dañado — visita tu taquilla local.

---

## 8. Contribuir a la comunidad

### 8.1. Reportar una incidencia

1. En el detalle de una ruta o parada, toca el icono de incidencia
   (triángulo de aviso).
2. Selecciona el tipo (retraso, avería, desvío, masificación, otro).
3. Describe brevemente el problema.
4. Envía. Otros usuarios la verán en el mapa.

### 8.2. Sugerir una ruta nueva

1. Ve a **Contribuciones** desde tu perfil.
2. Toca **Nueva sugerencia**.
3. Dibuja la ruta tocando paradas en el mapa, o grábala con GPS si
   eres conductor.
4. Describe la propuesta y envíala.
5. Otros usuarios podrán votar.

### 8.3. Votar sugerencias

En el detalle de una sugerencia, toca los botones de voto a favor o
en contra. Las sugerencias más votadas tienen más visibilidad y, si
alcanzan un umbral, pueden ser **oficializadas** por el operador.

### 8.4. Reputación y logros

Cada contribución suma reputación. Hay 7 rangos
(Recién llegado → Leyenda) y 9 logros desbloqueables (Primer reporte,
10 sugerencias votadas, etc.). Ve tu progreso en **Perfil →
Reputación**.

---

## 9. Perfil y configuración

### 9.1. Apariencia

- **Modo:** Claro / Oscuro / Automático (sigue al sistema).
- **Paleta de colores:** 6 paletas predefinidas + crear paleta
  personalizada con validación de contraste WCAG AA en tiempo real.
- **Fondo del mapa:** humo animado / gradiente / sólido / imagen.
- **Fuente:** sistema / IBM Plex Mono / OpenDyslexic.

### 9.2. Accesibilidad

- **Alto contraste:** colores más intensos, bordes más gruesos.
- **Modo daltónico:** matrices de color para protanopía, deuteranopía,
  tritanopía.
- **OpenDyslexic:** tipografía especializada para personas con
  dislexia.
- **Tamaño de texto:** escala combinada con la del sistema operativo
  (respeta tu configuración del SO).
- **Reducir animaciones:** menos movimiento en pantalla (transiciones
  instantáneas).
- **Vista accesible:** lista textual equivalente al mapa (en
  desarrollo: integración como ruta accesible paralela).

### 9.3. Notificaciones

- Activar/desactivar push.
- **Horas tranquilas:** sin notificaciones entre dos horas
  configurables.
- Toggles por categoría: incidencia en mi ruta, sugerencia con
  votos, respuesta a mi contribución, etc.

### 9.4. Privacidad

- **Compartir analíticas anónimas** (consentimiento explícito,
  desactivado por defecto).
- **Compartir informes de fallos** (consentimiento explícito).
- **Descargar mis datos** (formato JSON; recibirás un email cuando
  esté listo).
- **Eliminar mi cuenta** — solicita borrado; tus datos se eliminan
  en 30 días para permitir cancelación.

> La revocación de consentimientos es **inmediata**: si desactivas la
> analítica, deja de enviar datos en ese mismo momento, sin reiniciar
> la app.

### 9.5. Idioma

Español / English / العربية. El cambio se aplica al instante. La
dirección de lectura cambia automáticamente cuando eliges árabe (RTL).

### 9.6. Datos offline

- Gestiona las zonas del mapa que has descargado para usar sin red.
- Borra zonas que ya no usas para liberar espacio.

### 9.7. Sesión

- **Cerrar sesión.**
- **Eliminar cuenta** (ver §9.4).

---

## 10. Modo conductor

Si eres conductor de autobús y tu operador te ha proporcionado un
código de invitación:

### 10.1. Activar el modo conductor

1. Ve a **Perfil → Activar modo conductor**.
2. Introduce el **código de invitación** que te dio tu operador.
3. La app valida el código y activa permisos de conductor.

### 10.2. Empezar a emitir tu ruta

1. En **Modo conductor**, selecciona tu ruta.
2. Toca **Iniciar viaje**.
3. La app empezará a publicar tu posición GPS cada pocos segundos al
   canal de la ruta.
4. Los pasajeros verán tu bus en el mapa marcado como
   "Comunidad · Driver".

### 10.3. Otras funciones del conductor

- **Dashboard:** ver tu viaje actual (paradas recorridas, próximas).
- **Historial:** revisar tus viajes anteriores.
- **Estadísticas:** kilómetros, viajes completados, valoración media.

### 10.4. Finalizar

Toca **Finalizar viaje** cuando termines. Tu posición deja de
emitirse y el bus desaparece del mapa.

---

## 11. Widgets en la pantalla de inicio

Tanto Android como iOS soportan widgets de Transitly:

- **Próximo bus:** muestra el próximo bus a tu parada habitual.
- **Estado de mi línea:** muestra incidencias activas en tu ruta
  favorita.

Configura las preferencias en **Perfil → Widgets**.

---

## 12. Preguntas frecuentes

### ¿Funciona sin internet?

Sí, para zonas descargadas. Las funciones que requieren internet:
posición en vivo de buses, reportar/votar contribuciones, recibir
notificaciones, leer tu saldo NFC. Las consultas de horarios, mapas
descargados y datos guardados localmente funcionan offline.

### ¿En qué ciudades funciona?

El **operador piloto activo** es COMUJESA (Jerez de la Frontera). La
arquitectura está preparada para 10 operadores españoles (Sevilla,
Madrid, Barcelona, Málaga, Valencia, Valladolid, Bilbao, Tenerife,
Zaragoza). La incorporación efectiva depende del acuerdo con cada
operador y de la carga de sus datos GTFS.

### ¿Cómo sé si un bus está en vivo o estimado?

Cada bus en el mapa muestra una etiqueta clara (ver §4.1).

### ¿Mis datos están seguros?

Sí:

- **Cifrado en tránsito** (TLS 1.3) con Supabase.
- **Cifrado en reposo** del servidor.
- **No almacenamos datos sensibles innecesarios** — no guardamos
  número de tarjeta NFC, solo el saldo leído en el momento.
- **Cumplimiento GDPR** completo — puedes ver, exportar y eliminar
  tus datos cuando quieras.
- **PII fuera de logs** — los registros internos solo tienen IDs
  truncados, no nombres ni emails.

### ¿Es gratis?

Sí, la app es completamente gratuita en su versión MVP. Modelos
freemium o de suscripción podrían implementarse en el futuro
(consultar `01_analisis_contexto.md §4`).

### ¿Cómo puedo dar feedback?

- Desde la app: **Perfil → Enviar feedback**.
- Por incidencia / sugerencia desde el detalle de una ruta o parada.
- Por email: el contacto está en la pantalla de Privacidad.

### Tengo un problema con la app, ¿qué hago?

1. Intenta cerrar y reabrir la app.
2. Si persiste, ve a **Perfil → Enviar feedback** y describe el
   problema. Si has dado consentimiento de informes de fallos,
   nuestro sistema (Sentry) habrá capturado el detalle técnico.
3. Si no puedes abrir la app, contacta por email (en la web).

---

## 13. Accesibilidad y usabilidad

La app está diseñada para ser usable por todas las personas:

- **Objetivos táctiles ≥ 48 dp** (cualquier botón o área tocable
  cumple el mínimo recomendado por WCAG 2.2 AA y por Material
  Design / Apple Human Interface Guidelines).
- **Texto que escala con el sistema** — si has configurado tu móvil
  con "Texto grande", la app respeta tu elección.
- **Lectores de pantalla** (TalkBack, VoiceOver) — la información se
  anuncia con descripciones claras en tu idioma.
- **Reducir movimiento** — si tu sistema operativo tiene activado
  "Reducir movimiento", la app desactiva las animaciones decorativas.
- **Color no es el único indicador** — los estados se acompañan de
  iconos y texto (no dependemos solo del color).

> Nota honesta: actualmente la app está en **"WCAG 2.2 AA parcial / en
> progreso"**. Los fundamentos están listos; falta una verificación
> formal con personas usuarias de lectores de pantalla. Si encuentras
> una barrera de accesibilidad, por favor repórtala — lo arreglaremos
> con prioridad alta.

---

## 14. Recursos

- **Sitio web:** https://transitly.app (si está publicado).
- **Soporte:** email en la pantalla de Privacidad.
- **Datos abiertos:** los datos GTFS de los operadores son públicos;
  el código de la app está bajo licencia MIT.

Gracias por usar Transitly — y si te ha gustado, comparte la app con
quien creas que le pueda servir.
