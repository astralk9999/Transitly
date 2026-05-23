# External Blockers — Transitly

> Acciones que requieren intervención humana externa (cuentas, consolas,
> dispositivos reales, servicios de pago). No automatizables vía CI/CLI.
>
> **Origen:** `docs/MEGA_PLAN_REFINAMIENTO.md` §6 + §4 bloques PRO-Rel,
> PRO-Ops, PRO-A11Y, P0.
>
> **Estado:** 19 ítems pendientes. Sin ellos la app no es publicable en
> stores ni alcanza "AA defendible" ni opera a escala.

---

## Stores & Certificates

### 1. PROD-4 / PRO-Rel-1 (parcial) — Generar upload keystore + GitHub secrets

**Bloquea:** Play Store submission (el APK release sin keystore real no es
publicable).

**Instrucciones:**

```bash
keytool -genkeypair -v \
  -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload \
  -storepass <store-password> \
  -keypass <key-password> \
  -dname "CN=Transitly, OU=Dev, O=Transitly, L=City, ST=State, C=ES"
```

Guardar el `.jks` en lugar seguro (NO en el repo). Luego:

1. Codificar en base64 y añadir a GitHub Secrets:
   - `ANDROID_KEYSTORE_BASE64` = `base64 -w0 upload-keystore.jks`
   - `ANDROID_KEYSTORE_PASSWORD` = store password
   - `ANDROID_KEY_ALIAS` = `upload`
   - `ANDROID_KEY_PASSWORD` = key password
2. Crear `android/key.properties` local (NO commitear):
   ```
   storeFile=upload-keystore.jks
   storePassword=<store-password>
   keyAlias=upload
   keyPassword=<key-password>
   ```
3. Verificar: `flutter build appbundle --release` debe producir un AAB
   firmado con keystore real (no debug).
4. Ejecutar CI job `build-android-release-aab` y verificar que el
   artefacto se firma con el keystore de los secrets.

**Referencia:** `docs/MEGA_PLAN_REFINAMIENTO.md` §4.9 PRO-Rel-1 · `docs/00_MAESTRO.md` §4 B1.

---

### 2. PRO-Rel-2 — Play Store listing (3 idiomas)

**Bloquea:** publicación en Google Play Console.

**Instrucciones:**

1. Ir a Google Play Console → App → Grow → Store settings → Manage
   translations.
2. Añadir 3 idiomas: **Español (España)** [default], **English (United
   Kingdom)**, **العربية**.
3. Rellenar para cada idioma:
   - **Short description** (≤80 chars). Ej ES: "Transporte público de
     España en tiempo real. Rutas, paradas, NFC, sin conexión."
   - **Full description** (≤4000 chars). Cubrir: funcionalidades
     principales, operadores soportados, NFC, modo offline, comunidad,
     accesibilidad.
   - **App name** (≤30 chars). Ej ES: "Transitly", EN: "Transitly", AR:
     "ترانزيتلي".
4. Subir feature graphic (1024×500 px) en el idioma default.

**Catálogo de features a incluir:**
- Tiempo real de buses con posición en mapa
- Lectura NFC de tarjetas de transporte
- Rutas comunitarias + sistema de reputación
- Modo offline con datos cacheados
- Accesibilidad WCAG 2.2 AA (TalkBack/VoiceOver)
- 3 idiomas + RTL árabe
- Modo conductor con GPS en vivo
- Reporte de incidencias + sugerencias ciudadanas

---

### 3. PRO-Rel-6 — Subir AAB a Internal Testing

**Depende de:** PRO-Rel-1 (keystore).

**Instrucciones:**

1. Descargar el AAB firmado del artefacto CI (`build-android-release-aab`
   job) o generar localmente: `flutter build appbundle --release`.
2. Google Play Console → App → Testing → Internal testing.
3. Crear release → Subir AAB.
4. Añadir release notes (una línea por idioma).
5. Configurar testers: emails de cuentas Google del equipo.
6. Publicar → esperar aprobación (horas).
7. Instalar desde Play Store Internal Testing en dispositivo real para
   smoke test.

---

### 4. PRO-Rel-7 — Screenshots en dispositivos reales

**Bloquea:** listing de Play Store (Android) sin screenshots reales las
reviews bajan visibilidad.

**Instrucciones:**

1. Capturar en **mínimo 2 dispositivos** (teléfono + tablet recomendado):
   - **JPEG o PNG 24-bit**, mínimo 320 px, máximo 3840 px.
   - Mínimo 4 screenshots, máximo 8.
2. Capturas obligatorias (Play Store guidelines):
   - **Home** con mapa y paradas cercanas
   - **Búsqueda** de ruta con resultados
   - **Detalle de ruta** con paradas y horarios
   - **NFC** leyendo tarjeta (si aplica)
   - **Modo oscuro** al menos 1 captura
3. Para **tablet 7" y 10"** (opcional pero recomendado): 4-8 capturas
   adicionales.
4. Subir en Google Play Console → App → Grow → Store settings → Store
   listing → Screenshots.
5. Repetir para cada idioma (ES, EN, AR) — las capturas pueden ser las
   mismas.

**Tip:** Usar el modo debug con `--dart-define=IS_TESTING=true` para
simular datos poblados.

---

### 5. PRO-Rel-8 — Revisar Pre-Launch Report

**Depende de:** PRO-Rel-6 (AAB subido a testing).

**Instrucciones:**

1. Tras cada subida a Internal/Closed/Open testing, Google genera
   automáticamente un Pre-Launch Report en ~1 h.
2. Google Play Console → App → Testing → Pre-launch report.
3. Revisar 4 secciones:
   - **Stability:** crash rate >0 % → investigar stack traces (chequear
     Sentry también).
   - **Performance:** cold start >2 s, frame drops en pantallas
     principales.
   - **Accessibility:** contrastes, touch target <48 dp, content labeling
     sin texto.
   - **Security:** certificados SSL, permisos declarados vs usados,
     cleartext traffic.
4. Corregir en código los hallazgos bloqueantes y repetir ciclo.
5. Iterar hasta 0 crashes, 0 security issues, accessibility warnings
   aceptables.

---

### 6. PRO-Rel-11 — App Store listing (iOS)

**Depende de:** PRO-Rel-12 (Apple Developer Program activo).

**Instrucciones:**

1. App Store Connect → Mi App → App Store → Información de la app.
2. Rellenar:
   - **Nombre:** Transitly
   - **Subtítulo:** "Transporte público en tiempo real" (ES), "Real-time
     public transport" (EN)
   - **Categoría principal:** Navegación; **Secundaria:** Viajes
   - **Palabras clave:** transporte público, bus, metro, nfc, paradas,
     rutas, tiempo real, offline
   - **URL de soporte:** `https://transitly.app/support`
   - **URL de marketing:** `https://transitly.app`
3. Añadir localizaciones: **Español (España)** [default], **Inglés (RU)**,
   **Árabe**.
4. Rellenar descripción para cada idioma (mismo contenido que Play Store,
   adaptado al tono App Store).
5. Subir icono 1024×1024 px (sin transparencia, PNG/RGB).

**Nota:** El listing no se publica hasta que el build pase Review.

---

### 7. PRO-Rel-12 — Apple Developer Program ($99/yr)

**Bloquea:** cualquier build iOS firmado y cualquier submission a App
Store.

**Instrucciones:**

1. Ir a https://developer.apple.com/programs/enroll/
2. Iniciar sesión con Apple ID (crear uno nuevo para la organización si no
   existe).
3. Completar enrollment como **Organization** (requiere D-U-N-S Number):
   - Si no hay D-U-N-S: https://developer.apple.com/enroll/duns-lookup/
   - Tiempo: 5-14 días hábiles para obtener D-U-N-S.
4. Pagar **99 USD/año** con tarjeta o PayPal (no reembolsable).
5. Una vez aprobado (~48 h si individual, ~2 semanas si organización):
   - Acceder a https://developer.apple.com/account/
   - Generar certificados: **Apple Development** + **Apple Distribution**
   - Generar **provisioning profiles** para desarrollo y distribución
6. En Xcode → Preferences → Accounts → Añadir Apple ID → Download Manual
   Profiles.
7. Configurar CI (GitHub Actions macOS runner) con:
   - `IOS_DISTRIBUTION_CERTIFICATE_BASE64`
   - `IOS_DISTRIBUTION_CERTIFICATE_PASSWORD`
   - `IOS_PROVISIONING_PROFILE_BASE64`
   - `APP_STORE_CONNECT_API_KEY`

**Referencia:** `docs/MEGA_PLAN_REFINAMIENTO.md` §6 Stores y certificados.

---

### 8. PRO-Rel-14 — App Store Privacy Details

**Depende de:** PRO-Rel-12 (Apple Developer Program activo).

**Instrucciones:**

1. App Store Connect → Mi App → App Store → Privacidad de la app.
2. Completar el cuestionario **App Privacy** por tipo de dato:

| Tipo de dato | Se recopila | Vinculado al usuario | Uso |
|---|---|---|---|
| Ubicación precisa | Sí | Sí | Funcionalidad de la app (mapa, rutas cercanas, conductor GPS) |
| Ubicación aproximada | Sí | No | Analítica (PostHog, agregada) |
| Información de contacto (email) | Sí | Sí | Cuenta de usuario (Supabase Auth) |
| Identificadores (User ID, Device ID) | Sí | Sí | Funcionalidad de la app, analítica |
| Datos de uso del producto | Sí | No | Analítica (PostHog), crash reporting (Sentry) |
| Diagnósticos (crash data) | Sí | No | Rendimiento de la app (Sentry) |

3. Marcar **NO** para el resto de tipos de dato (compras, ubicación en
   segundo plano, salud, etc.).
4. Subir o enlazar la **Privacy Policy** (ver PRO-Rel-21).

**Nota:** Esto es un requisito legal y de App Review. Sin ello, rechazan
la submission.

---

### 9. PRO-Rel-16 — App Store screenshots (iOS)

**Depende de:** PRO-Rel-12 (Apple Developer Program activo).

**Instrucciones:**

1. Capturar en **iPhone 6.7"** (obligatorio) y **iPad 12.9"** (opcional):
   - Mínimo 3 screenshots, máximo 10.
   - Formatos permitidos: PNG, JPEG.
2. Pantallas obligatorias (App Store Connect guidelines):
   - **Home** con mapa y paradas
   - **Búsqueda** con autocompletado
   - **Detalle de ruta** con timeline de paradas
   - **NFC** escaneando tarjeta
   - **Modo oscuro** (mínimo 1)
3. Subir en App Store Connect → Mi App → App Store → Screenshots.
4. Usar el simulador Xcode si no hay dispositivo físico iPhone Pro Max.
   Comando:
   ```bash
   flutter run --release -d "iPhone 16 Pro Max"
   ```
   Capturar con `Cmd+S` en el simulador.
5. Repetir para cada localización (ES, EN, AR).

---

### 10. PRO-Rel-18 — App Store submission (iOS)

**Depende de:** PRO-Rel-12, PRO-Rel-14, PRO-Rel-16.

**Instrucciones:**

1. Asegurar que `ios/Runner/Info.plist` tiene todas las claves necesarias
   (ya configuradas en H3):
   - `NFCReaderUsageDescription`
   - `NSLocationWhenInUseUsageDescription`
   - `NSCameraUsageDescription` (códigos QR de conductor)
   - `NSPhotoLibraryUsageDescription`
2. Verificar `ios/Runner/PrivacyInfo.xcprivacy` (ya generado en H3).
3. Generar build archive en Xcode:
   - Product → Archive (con esquema Release, dispositivo genérico).
   - Validar y subir a App Store Connect.
4. O vía CI (macOS runner con Fastlane):
   - Ejecutar `build-ios-release` CI job.
   - Verificar que el `.ipa` se firma con certificado de distribución.
5. En App Store Connect → Mi App → App Store → Prepare for Submission:
   - Seleccionar build subido.
   - Revisar que las 3 localizaciones tienen descripción + screenshots.
   - Revisar Privacy Details (PRO-Rel-14).
   - Configurar **Rating** (cuestionario de contenido).
   - Activar o desactivar **App Encryption** (no usa encriptación custom →
     exenta).
6. **Submit for Review**.
7. Tiempo típico de review: 24-48 h. Posible rechazo por:
   - Privacy manifest incompleto.
   - Screenshots no representativos.
   - Funcionalidad rota (probar NFC, GPS, login).
8. Si rechazan, corregir y repetir desde paso 4.

---

## Accessibility

### 11. A11Y-3 / PRO-A11Y-18 (parcial) — Manual TalkBack/VoiceOver verification

**Bloquea:** certificación "WCAG 2.2 AA defendible". Sin acta de pruebas
con producto de apoyo, "AA" es aspiracional.

**Instrucciones:**

1. **Android (TalkBack):**
   - Activar TalkBack: Settings → Accessibility → TalkBack → On.
   - Navegar flujo completo con gestos (swipe right para siguiente
     elemento, double-tap para activar):
     - Onboarding (3 pantallas) → Home tabs (5 tabs) → Detalle de ruta →
       Detalle de parada → Búsqueda → Reporte de incidencia → Perfil →
       Configuración de accesibilidad → Cambio de idioma a EN → Cambio a
       AR (RTL) → Modo oscuro.
     - Verificar que **cada** elemento tiene `contentDescription` (texto o
       botón) y que los elementos decorativos tienen
       `excludeSemantics: true`.
     - Verificar que los `Pressable` tienen touch target ≥48 dp (TalkBack
       los lee igual aunque el widget sea más pequeño si está dentro de
       uno de 48 dp).
   - **Criterio de aprobado:** completar todo el flujo en ≤10 minutos sin
     quedarse atascado en ningún paso. Cada pantalla debe leerse de forma
     comprensible, sin saltos de foco ni elementos huérfanos.

2. **iOS (VoiceOver):**
   - Activar VoiceOver: Settings → Accessibility → VoiceOver → On.
   - Mismo flujo que TalkBack. Gestos iOS: swipe right = siguiente, double
     tap = activar, three-finger swipe = scroll.
   - Verificar que el rotor announce los headings correctamente.
   - Verificar que el mapa tiene alternativa accesible (lista de paradas
     cercanas con distancias legibles).

3. **Acta de verificación:**
   - Crear documento `docs/a11y/TALKBACK_VOICEOVER_ACTA.md` con:
     - Fecha, dispositivo, versión de SO, versión de TalkBack/VoiceOver.
     - Checklist de pantallas visitadas (marca ✅/❌ por pantalla).
     - Incidencias encontradas con captura de pantalla o descripción.
     - Veredicto: **APROBADO AA** o lista de issues bloqueantes.
   - Firmar el acta (nombre + timestamp).

**Referencia:** `docs/ACCESSIBILITY.md` §3 · `docs/00_MAESTRO.md` §4 B10.

---

## Legal

### 12. PRO-Rel-21 — Publish Privacy Policy at transitly.app/privacy

**Bloquea:** publicación en ambas stores (Play Store y App Store exigen
Privacy Policy pública accesible).

**Instrucciones:**

1. El contenido de la política de privacidad ya está en
   `docs/legal/PRIVACY_POLICY.md` o se puede derivar de
   `docs/DATA_RETENTION.md` + `docs/RIGHT_TO_BE_FORGOTTEN.md`.
2. La política debe cubrir (GDPR mínimo):
   - **Responsable del tratamiento:** nombre de la entidad legal + email
     de contacto.
   - **Datos recopilados:** email (auth), ubicación (mapa, conductor),
     NFC UID hash, crash reports, analytics.
   - **Finalidad:** funcionalidad de la app, mejora del servicio,
     seguridad.
   - **Base legal:** consentimiento explícito (login + privacy consent
     screen).
   - **Terceros:** Supabase (backend), Sentry (crash), PostHog
     (analytics). Incluir enlaces a sus propias políticas.
   - **Transferencias internacionales:** Supabase (AWS Frankfurt, UE),
     Sentry (UE).
   - **Periodo de retención:** mientras dure la cuenta + 30 días post
     borrado.
   - **Derechos ARCO:** acceso, rectificación, cancelación, oposición →
     email de contacto.
   - **Cookies / local storage:** Hive local, sin cookies de tracking.
   - **Menores:** edad mínima 16 años (GDPR-ES).
   - **Fecha de última actualización.**
3. Publicar en `https://transitly.app/privacy` como HTML estático.
   - Si no hay dominio aún, usar GitHub Pages temporalmente:
     `astralk9999.github.io/Transitly/privacy`.
4. Verificar accesible desde incógnito (sin auth).
5. Enlazar desde la app: `Settings → About → Privacy Policy`

**Referencia:** `docs/DATA_RETENTION.md` · `docs/RIGHT_TO_BE_FORGOTTEN.md`.

---

### 13. PRO-Rel-22 — Publish Terms of Service at transitly.app/terms

**Bloquea:** publicación en ambas stores + cumplimiento DSA (Digital
Services Act).

**Instrucciones:**

1. Redactar o adaptar ToS cubriendo:
   - **Aceptación de los términos** al crear cuenta.
   - **Descripción del servicio:** app de transporte público con datos
     oficiales + comunitarios.
   - **Cuentas de usuario:** responsabilidad de credenciales, prohibición
     de cuentas múltiples abusivas.
   - **Contenido generado por usuarios:** rutas comunitarias, sugerencias,
     feedback, incidencias → licencia no exclusiva a Transitly para
     mostrar en la app.
   - **Conducta prohibida:** spam, datos falsos, acoso, contenido ilegal.
   - **Modo conductor:** responsabilidad del conductor sobre la precisión
     de los datos GPS emitidos.
   - **Propiedad intelectual:** código abierto MIT, datos de transporte de
     fuentes públicas.
   - **Limitación de responsabilidad:** la app no garantiza precisión del
     100 % de los horarios (dependen de operadores externos).
   - **Terminación:** derecho a suspender cuentas que violen los términos.
   - **Modificaciones:** notificación de cambios con 30 días.
   - **Ley aplicable:** España, jurisdicción de [ciudad].
   - **Contacto:** email legal.
2. Publicar en `https://transitly.app/terms` como HTML estático.
3. Enlazar desde la app: `Settings → About → Terms of Service`.

---

### 14. PRO-Ops-29 — Sign DPA with Supabase

**Bloquea:** cumplimiento GDPR (Supabase como procesador de datos
personales).

**Instrucciones:**

1. Ir a https://supabase.com/dpa
2. Leer el Data Processing Agreement (DPA) estándar de Supabase.
3. Firmar digitalmente desde el dashboard de Supabase:
   - Organization → Legal → Data Processing Agreement.
4. Para el tier Free, Supabase ya incluye DPA estándar como parte de los
   términos. Para Pro, se firma explícitamente.
5. Guardar copia del DPA firmado en `docs/legal/DPA_SUPABASE.pdf`.
6. Registrar en el Record of Processing Activities (ROPA) interno:
   - **Procesador:** Supabase, Inc.
   - **Categorías de datos:** email, ubicación GPS, NFC UID hash, device
     ID.
   - **Finalidad:** backend de la app (auth, base de datos, storage,
     realtime).
   - **Duración:** mientras dure la relación contractual.
   - **Transferencia internacional:** AWS Frankfurt (UE) — Art. 45 GDPR
     (decisión de adecuación).
7. Este DPA es obligatorio para el registro de ficheros ante la AEPD
   (Agencia Española de Protección de Datos).

---

## Operations

### 15. PRO-Ops-7 — Activate Sentry Session Replay

**Bloquea:** debugging de bugs reportados por usuarios sin poder
reproducirlos.

**Instrucciones:**

1. Ir a https://sentry.io → Proyecto Transitly → Settings → Session
   Replay.
2. Activar **Session Replay** (revisar plan: incluido en Team plan $26/mes
   — 50k replays/mes).
3. Configurar:
   - **Sampling rate:** 10 % de sesiones (para no disparar coste).
   - **Masking:** activar por defecto (todos los inputs, texto, emails se
     enmascaran automáticamente).
   - **Unmask:** elementos de UI que no contienen PII (botones, labels de
     transporte).
   - **Duration:** máximo 60 min por replay.
4. Configurar SDK en Flutter (ya está `sentry_flutter` en
   `pubspec.yaml`):
   - Añadir `SentryReplay` al init de Sentry en `main.dart`:
     ```dart
     await SentryFlutter.init((options) {
       // ... existing config
       options.experimental.replay.sessionSampleRate = 0.1;
       options.experimental.replay.onErrorSampleRate = 1.0; // graba siempre en error
     });
     ```
5. Verificar en Sentry Dashboard → Replays que aparecen sesiones
   grabadas.
6. Probar en dispositivo real: forzar crash → verificar que el replay
   captura los últimos segundos antes del crash.

**Coste estimado:** ~$26/mes (Team plan). Alternativa gratuita: sampling
rate 0 % (solo grabar en error) en plan Developer.

---

### 16. PRO-Ops-19 — Status page (statuspage.io)

**Bloquea:** comunicación de incidencias a usuarios (expectativa de
servicio profesional).

**Instrucciones:**

1. Ir a https://statuspage.io
2. Crear cuenta. Plan **Hobby** ($0/mes): 3 componentes, 1 página, 2
   suscriptores email.
3. Configurar página:
   - **URL:** `status.transitly.app`
   - **Nombre:** Transitly Status
   - **Componentes a monitorizar:**
     1. **Supabase API** (backend principal)
     2. **Mapa / Tiles** (MapTiler)
     3. **Push Notifications** (FCM)
4. Conectar con Supabase:
   - Crear webhook en Supabase Dashboard → Database → Webhooks →
     `status_page_alert`.
   - O usar Statuspage API manualmente al declarar incidencia.
5. Añadir badge en `README.md` y en la app (Settings → About → System
   Status).
6. Documentar procedimiento en `docs/runbooks/incident_communication.md`:
   - Quién actualiza la status page.
   - Template de mensaje por severidad (degraded → major outage).

---

### 17. PRO-Ops-25 — Load testing with k6

**Bloquea:** confianza en que Supabase soporta X usuarios concurrentes
antes de lanzamiento público.

**Instrucciones:**

1. Instalar k6: https://k6.io/docs/get-started/installation/
   ```bash
   winget install k6
   ```
2. Crear script `tool/k6/load_test.js` con escenarios:
   - **Auth:** 50 usuarios haciendo sign-in concurrente.
   - **Nearby stops:** 200 peticiones/min a RPC `nearby_stops`.
   - **Route detail:** 100 peticiones/min a `routes` + `schedules`.
   - **Bus positions:** 50 suscripciones WebSocket concurrentes a
     `bus_positions` (Supabase Realtime).
3. Configurar variables de entorno:
   ```bash
   export SUPABASE_URL="https://mmzahxtiaurkgtmtehxk.supabase.co"
   export SUPABASE_ANON_KEY="<anon-key>"
   ```
4. Ejecutar contra staging (o entorno de desarrollo):
   ```bash
   k6 run --vus 50 --duration 5m tool/k6/load_test.js
   ```
5. Analizar resultados:
   - **p95 latency** < 500 ms para RPC + REST.
   - **Error rate** < 1 %.
   - **WebSocket connections:** 0 disconnects inesperados.
6. Repetir con 100, 200, 500 VUs hasta encontrar punto de quiebre.
7. Documentar resultados en `docs/LOAD_TEST_<fecha>.md`:
   - Configuración del test.
   - Métricas obtenidas (p50, p95, p99, error rate).
   - Punto de quiebre (VUs donde error rate >5 % o p95 >2 s).
   - Recomendación de plan Supabase (Free → Pro → Team).

**Atención:** No hacer load testing contra producción. Usar staging o
entorno de desarrollo separado. Supabase Free tiene rate limits que
falsearían el test — usar plan Pro para la prueba.

---

## i18n

### 18. PRO-A11Y-13 — AR Arabic human translation (370 remaining keys)

**Bloquea:** cobertura completa de árabe (actualmente parcial,
~claves_pendientes claves sin traducir). Sin esto, el reporte de
accesibilidad PRO-A11Y-18 miente.

**Instrucciones:**

1. Identificar claves pendientes:
   ```bash
   grep -c '^  "' lib/l10n/app_en.arb
   grep -c '^  "' lib/l10n/app_ar.arb
   ```
   La diferencia son las claves sin traducir.
2. Extraer claves faltantes a un archivo de trabajo:
   ```bash
   dart tool/extract_untranslated_ar.dart > tool/ar_pending.json
   ```
   (Crear el script si no existe — lee `app_en.arb` y `app_ar.arb`,
   produce JSON con claves en `en` sin correspondencia en `ar`.)
3. Contratar traductor humano nativo árabe (no machine translation — la
   app aspira a AAA):
   - Plataformas: ProZ.com, translatorscafe.com, Upwork.
   - Budget: ~$0.08-0.12/palabra. 370 claves × ~3 palabras/clave ≈
     1110 palabras ≈ **$90-130 USD**.
   - Especificar: árabe estándar moderno (MSA), tono de app de transporte
     público (formal pero accesible), consistencia terminológica.
4. Entregar al traductor:
   - `tool/ar_pending.json` con las claves en inglés.
   - Glosario de términos clave (ej. "stop" = "موقف", "route" = "مسار",
     "NFC" = "NFC").
   - Instrucciones de formato: respetar placeholders `{count}`, `{name}`,
     etc.
5. Recibir traducción, revisar placeholder integrity:
   ```bash
   dart tool/validate_ar_placeholders.dart
   ```
6. Integrar en `lib/l10n/app_ar.arb` manteniendo orden alfabético de
   claves.
7. Ejecutar `flutter gen-l10n` y verificar compilación.
8. Ejecutar test de paridad ARB: `flutter test test/arb_parity_test.dart`
   (debe existir de PRO-QA-16).
9. Hacer smoke test visual en Android con locale `ar`:
   - Verificar RTL layout (texto alineado a la derecha, iconos
     direccionales invertidos).
   - Verificar que ningún texto se sale del contenedor (árabe expande
     ~30 % vs inglés).
   - Verificar dígitos arábigos ٠١٢٣٤٥٦٧٨٩ si se implementó
     PRO-A11Y-15.

---

## Resumen de dependencias

| # | ID externo | Bloquea | Depende de | Esfuerzo estimado |
|---|-----------|---------|------------|:-:|
| 1 | PRO-Rel-1 keystore | Play Store release | — | 30 min |
| 2 | PRO-Rel-2 Play listing | Play Store | PRO-Rel-7 (screenshots) | 2 h |
| 3 | PRO-Rel-6 AAB testing | Play Store | PRO-Rel-1 | 30 min |
| 4 | PRO-Rel-7 screenshots Android | Play Store | PRO-Rel-1 | 2 h |
| 5 | PRO-Rel-8 pre-launch review | Play Store | PRO-Rel-6 | 1 h × N iteraciones |
| 6 | PRO-Rel-11 App Store listing | App Store | PRO-Rel-12 | 1 h |
| 7 | PRO-Rel-12 Apple Developer | Todo iOS | — | 1-14 días (espera) |
| 8 | PRO-Rel-14 privacy details | App Store | PRO-Rel-12, PRO-Rel-21 | 30 min |
| 9 | PRO-Rel-16 screenshots iOS | App Store | PRO-Rel-12 | 2 h |
| 10 | PRO-Rel-18 App submission | App Store | PRO-Rel-12,14,16 | 1 h + review wait |
| 11 | A11Y-3 TalkBack/VoiceOver | WCAG AA | — | 3 h |
| 12 | PRO-Rel-21 privacy policy | Ambas stores | Dominio transitly.app | 2 h |
| 13 | PRO-Rel-22 terms of service | Ambas stores | Dominio transitly.app | 2 h |
| 14 | PRO-Ops-29 DPA Supabase | GDPR | — | 30 min |
| 15 | PRO-Ops-7 Sentry replay | Debugging | — | 1 h + $26/mes |
| 16 | PRO-Ops-19 status page | Operación | — | 1 h + $0-29/mes |
| 17 | PRO-Ops-25 load testing | Escala | Supabase Pro plan | 3 h |
| 18 | PRO-A11Y-13 AR translation | i18n completa | PRO-QA-16 (parity test) | ~$100 + 1 h setup |

**Total esfuerzo estimado:** ~20 h de trabajo activo + tiempos de espera
de Apple y Google (1-14 días). **Coste externo:** ~$200-300 USD (Apple
Developer $99/yr + traducción ~$100 + servicios opcionales).

---

## Orden recomendado de ejecución

1. **PRO-Rel-1 keystore** (30 min) — desbloquea todo Android.
2. **PRO-Rel-12 Apple Developer** (iniciar cuanto antes — espera 1-14
   días).
3. Mientras esperas Apple: **PRO-Rel-2 + 6 + 7 + 8** (Android store,
   ~6 h).
4. **PRO-Rel-21 + 22** (Privacy + Terms) en dominio — blockea ambas
   stores.
5. **PRO-Rel-11 + 14 + 16 + 18** (App Store, ~5 h + review wait).
6. **PRO-Ops-29 DPA Supabase** (30 min) — compliance.
7. **A11Y-3 TalkBack/VoiceOver** (3 h) — certifica AA.
8. **PRO-Ops-7 + 19 + 25** (operación, ~5 h) — previo a launch público.
9. **PRO-A11Y-13 AR translation** (esperar traducción ~1 semana + 1 h
   integración).

---

**Última actualización:** 2026-05-23 · Extraído de
`docs/MEGA_PLAN_REFINAMIENTO.md` §4 + §6. Sincronizar con
`docs/MEGA_PLAN_REFINAMIENTO.md` y `docs/00_MAESTRO.md` cuando un ítem se
complete.
