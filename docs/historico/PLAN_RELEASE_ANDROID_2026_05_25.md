# PLAN DE RELEASE ANDROID + ASTRO — Transitly

**Fecha:** 2026-05-25
**HEAD base:** `master @ 4064b8e`
**Defensa final:** 2026-06-09 (15 días vista)
**Scope:** Android + Web Astro híbrida. iOS descartado por coste (anexo F).
**Origen:** verificación post 3 fixes finales (`INFORME_VERIFICACION_2026_05_25.md`) + agente Explore que detectó 6 pendientes no documentados.
**Predecesores:** `PLAN_FIXES_FINALES_2026_05_25.md`, `EXTERNAL_BLOCKERS.md`, `PLAN_DEFENSA_2026_05_24.md`.
**Audiencia:** dev (humano o IA) que ejecutará los pasos.
**Tiempo total estimado:** ~5 h pre-defensa + ~15 h post-defensa hasta MVP publicable.
**Coste estimado:** $12/año dominio (opcional) + $25 one-off Google Play + $100 traducción AR (opcional) = **~$137 primer año**.

---

## Reglas transversales

1. **Cada acción PR-able**: 1 cambio significativo = 1 commit atómico con Conventional Commits en español.
2. **Nunca commitear secretos**: `.env`, `google-services.json`, `key.properties`, `*.jks`. Validar con `git status` antes de cada commit.
3. **Antes de cada paso, verificar prerequisitos** (sección "Pre-requisito" cuando aplica).
4. **Backup keystore en 3 sitios**: USB encriptado + cloud privado + impreso en caja fuerte. **Si se pierde, no se puede actualizar la app en Play Store nunca.**
5. **`flutter analyze` debe quedar 0 errors tras cada cambio de código.** Si rompe, revertir.
6. **Comandos pensados para Windows + PowerShell o WSL** según el caso (se indica explícitamente cuando importa).

---

## Índice

- [A. Pre-defensa Android (~3-4 h, crítico)](#a-pre-defensa)
- [B. Post-defensa: release a Play Store (~6-8 h + esperas)](#b-play-store)
- [C. Web Astro híbrida (~3-4 h)](#c-astro)
- [D. Accesibilidad + Legal + Operaciones (~5-7 h)](#d-a11y-legal-ops)
- [E. Internacionalización árabe (1-2 días)](#e-i18n)
- [F. Anexo: iOS (futuro descartado)](#f-ios)
- [G. Smoke test Android pre-defensa (manual)](#g-smoke-test)
- [H. Cronograma sugerido D-15 → D-0](#h-cronograma)
- [I. Resumen ejecutivo](#i-resumen)

---

<a id="a-pre-defensa"></a>
## A. Pre-defensa Android (~3-4 h, crítico)

**Objetivo:** APK release firmado con keystore real + push notifications funcionando en device físico durante demo TFG.

---

### A.1 — Crear proyecto Firebase Console

**Esfuerzo:** 15 min · **Coste:** €0 (plan Spark gratuito)

**Pasos:**

1. Ir a [https://console.firebase.google.com/](https://console.firebase.google.com/) con la cuenta Google del proyecto.
2. Click "Add project" → nombre: `Transitly` (o `transitly-prod`).
3. Desactivar Google Analytics si no se va a usar (acelera setup; se puede activar después).
4. Esperar provisioning (~1-2 min).
5. En el dashboard del proyecto, **anotar el Project ID** (ej. `transitly-12345`). Se usa en A.2.

**Verificación:** dashboard accesible en `https://console.firebase.google.com/project/<PROJECT_ID>/overview`.

---

### A.2 — Generar `lib/firebase_options.dart` con FlutterFire CLI

**Pre-requisito:** A.1 completado + Firebase CLI instalado (`npm install -g firebase-tools` si no).

**Esfuerzo:** 10 min

**Pasos:**

1. Instalar FlutterFire CLI (solo primera vez):
   ```powershell
   dart pub global activate flutterfire_cli
   ```

2. Login en Firebase:
   ```powershell
   firebase login
   ```

3. Desde la raíz del proyecto, ejecutar:
   ```powershell
   flutterfire configure --project=<PROJECT_ID> --platforms=android
   ```
   - Selecciona la app Android cuando lo pida. Si no existe, la creará con `applicationId` `app.transitly` (verificar en `android/app/build.gradle.kts`).

4. Verifica que se ha creado:
   ```powershell
   ls lib/firebase_options.dart
   ls android/app/google-services.json
   ```

**Verificación:**
- `lib/firebase_options.dart` existe y contiene `DefaultFirebaseOptions.android`.
- `android/app/google-services.json` existe (debe estar en `.gitignore` — verificar con `git check-ignore android/app/google-services.json`).

**Commit (solo `firebase_options.dart` si está en repo):**
```bash
git add lib/firebase_options.dart
git commit -m "feat(firebase): generar firebase_options.dart con flutterfire CLI (A.2)"
```

> **Importante:** `google-services.json` **NO se commitea**. Va a `.gitignore` y se sube a CI como secret base64.

---

### A.3 — Verificar `google-services.json` y `.gitignore`

**Esfuerzo:** 5 min

**Pasos:**

1. Confirmar que `android/app/google-services.json` está ignorado:
   ```powershell
   git check-ignore android/app/google-services.json
   # Esperado: la salida muestra el archivo (significa que SÍ está ignorado)
   ```

2. Si NO está ignorado, añadir a `.gitignore`:
   ```
   android/app/google-services.json
   ios/Runner/GoogleService-Info.plist
   ```

3. Commit si se modificó `.gitignore`:
   ```bash
   git add .gitignore
   git commit -m "chore(gitignore): asegurar que google-services.json no se commitea"
   ```

---

### A.4 — Aplicar plugin Google Services en Gradle

**Pre-requisito:** A.2.

**Esfuerzo:** 10 min

**Archivos a modificar:**

#### A.4.a — `android/settings.gradle.kts` (o `android/build.gradle.kts` raíz)

Añadir al bloque `plugins` o `buildscript.dependencies`:

```kotlin
plugins {
    id("com.android.application") version "8.x.x" apply false
    id("org.jetbrains.kotlin.android") version "1.9.x" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false  // ← AÑADIR
}
```

#### A.4.b — `android/app/build.gradle.kts`

En el bloque `plugins {}` del top:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // ← AÑADIR
}
```

**Verificación:**
```powershell
flutter clean
flutter pub get
flutter build apk --debug
```
Debe compilar sin errores. Si dice "Plugin not found", revisar la versión del plugin en A.4.a.

**Commit:**
```bash
git add android/settings.gradle.kts android/app/build.gradle.kts
git commit -m "feat(android): aplicar plugin google-services para Firebase Messaging (A.4)"
```

---

### A.5 — Declarar canal FCM en AndroidManifest.xml

**Esfuerzo:** 10 min

**Archivo:** `android/app/src/main/AndroidManifest.xml`

Dentro de `<application>`, añadir antes del `</application>`:

```xml
<!-- Canal de notificaciones FCM por defecto -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="transitly_push" />
<meta-data
    android:name="com.google.firebase.messaging.default_notification_icon"
    android:resource="@drawable/ic_notification" />
<meta-data
    android:name="com.google.firebase.messaging.default_notification_color"
    android:resource="@color/notification_color" />
```

**Recursos asociados a crear:**

1. `android/app/src/main/res/drawable/ic_notification.xml` (icono vectorial blanco transparente para Android 5+):
   ```xml
   <vector xmlns:android="http://schemas.android.com/apk/res/android"
       android:width="24dp" android:height="24dp"
       android:viewportWidth="24" android:viewportHeight="24">
     <path android:fillColor="#FFFFFF"
       android:pathData="M12,22c1.1,0 2,-0.9 2,-2h-4c0,1.1 0.89,2 2,2zM18,16v-5c0,-3.07 -1.64,-5.64 -4.5,-6.32V4c0,-0.83 -0.67,-1.5 -1.5,-1.5s-1.5,0.67 -1.5,1.5v0.68C7.63,5.36 6,7.92 6,11v5l-2,2v1h16v-1l-2,-2z"/>
   </vector>
   ```

2. `android/app/src/main/res/values/colors.xml`:
   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <resources>
       <color name="notification_color">#977DDF</color>
   </resources>
   ```

**Verificación:**
```powershell
grep "default_notification_channel_id" android/app/src/main/AndroidManifest.xml
# Esperado: 1 hit
```

**Commit:**
```bash
git add android/app/src/main/AndroidManifest.xml android/app/src/main/res/drawable/ic_notification.xml android/app/src/main/res/values/colors.xml
git commit -m "feat(android): declarar canal FCM transitly_push + recursos icono/color (A.5)"
```

---

### A.6 — Generar keystore upload Android

**Pre-requisito:** Java JDK instalado (`keytool` está en `$JAVA_HOME/bin`).

**Esfuerzo:** 10 min

**Pasos:**

1. Desde la raíz del proyecto:
   ```powershell
   keytool -genkeypair -v `
     -keystore android/upload-keystore.jks `
     -keyalg RSA -keysize 2048 -validity 10000 `
     -alias upload `
     -storepass <STORE_PASSWORD> `
     -keypass <KEY_PASSWORD> `
     -dname "CN=Transitly, OU=Dev, O=Transitly, L=Jerez de la Frontera, ST=Cadiz, C=ES"
   ```

   Reemplaza `<STORE_PASSWORD>` y `<KEY_PASSWORD>` por contraseñas fuertes (mínimo 12 caracteres, mezclar mayúsculas, números, símbolos).

2. **Guardar las contraseñas en password manager** (1Password, Bitwarden, KeePass). **Si las pierdes, no puedes actualizar la app en Play Store.**

3. Backup del `.jks` en 3 sitios:
   - USB encriptado (VeraCrypt o BitLocker)
   - Cloud privado (Google Drive, OneDrive personal, no compartido)
   - Impreso (los bytes en base64 + contraseñas) en caja fuerte física

4. **NUNCA commitear el `.jks`** — verificar:
   ```powershell
   git check-ignore android/upload-keystore.jks
   ```

   Si NO está ignorado, añadir a `.gitignore`:
   ```
   *.jks
   *.keystore
   android/upload-keystore.jks
   ```

**Verificación:**
```powershell
ls android/upload-keystore.jks
keytool -list -v -keystore android/upload-keystore.jks -storepass <STORE_PASSWORD>
# Esperado: muestra el certificado con alias "upload"
```

---

### A.7 — Crear `android/key.properties`

**Pre-requisito:** A.6.

**Esfuerzo:** 5 min

**Archivo nuevo:** `android/key.properties` (gitignored)

```properties
storeFile=upload-keystore.jks
storePassword=<STORE_PASSWORD>
keyAlias=upload
keyPassword=<KEY_PASSWORD>
```

**Pre-requisito en `android/app/build.gradle.kts`** (verificar que lee `key.properties` si existe):

```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ...
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }
    buildTypes {
        getByName("release") {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")  // fallback elegante
            }
        }
    }
}
```

**Verificación:**
```powershell
ls android/key.properties
git check-ignore android/key.properties
# Esperado: ambos OK
```

---

### A.8 — Build AAB firmado y verificar

**Pre-requisito:** A.2-A.7 completados.

**Esfuerzo:** 10 min

```powershell
flutter clean
flutter pub get
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
```

**Verificación:**
```powershell
ls build/app/outputs/bundle/release/app-release.aab
# Esperado: AAB existe, ~25-40 MiB
```

**Commit (solo gradle, no keystore/key.properties):**
```bash
git add android/app/build.gradle.kts android/.gitignore
git commit -m "feat(android): configurar signingConfig release con key.properties (A.7-A.8)"
```

---

### A.9 — Verificar firma del AAB

**Esfuerzo:** 5 min

```powershell
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab
```

**Resultado esperado:**
```
jar verified.
- Signed by "CN=Transitly, OU=Dev, O=Transitly, ..."
- Digest algorithm: SHA-256
```

Si dice "jar is unsigned" o "WARNING": revisar `key.properties` y rebuilds.

Para extraer APK desde AAB (para testing local sin Play Store):
```powershell
# Descargar bundletool desde https://github.com/google/bundletool/releases
java -jar bundletool.jar build-apks `
  --bundle=build/app/outputs/bundle/release/app-release.aab `
  --output=build/transitly.apks `
  --ks=android/upload-keystore.jks `
  --ks-key-alias=upload `
  --ks-pass=pass:<STORE_PASSWORD>

# Instalar en device físico conectado
java -jar bundletool.jar install-apks --apks=build/transitly.apks
```

---

### A.10 — Smoke test push end-to-end en device físico

**Pre-requisito:** A.1-A.9 + device Android físico con USB debugging.

**Esfuerzo:** 30 min

**Pasos:**

1. Instalar APK firmado en device:
   ```powershell
   flutter install --release
   ```

2. Abrir la app, iniciar sesión (o usar invitado), navegar a Home.

3. En Firebase Console → tu proyecto → **Engage → Messaging** → New campaign → Notifications.

4. Configurar:
   - **Title:** "Test Transitly"
   - **Body:** "Notificación de prueba"
   - **Target:** seleccionar tu device por FCM token (lo obtienes en logs de la app o desde Firebase Console → Cloud Messaging → registration token).

5. **Test 1: Foreground**
   - App abierta en pantalla → enviar notif desde Firebase → debería aparecer notif local con título y body.

6. **Test 2: Background**
   - Minimizar app (no cerrar) → enviar notif → debería aparecer en barra de notificaciones del sistema → tocarla → app debe abrirse en pantalla actual.

7. **Test 3: Cold start con deeplink**
   - Cerrar app completamente (swipe en task manager) → enviar notif **con custom data**:
     ```json
     {
       "deeplink": "/route/L1"
     }
     ```
   - Tocar notif → app debe abrir directamente en detalle de ruta L1.

**Verificación de cada test:** sin crashes, sin warnings en logcat:
```powershell
adb logcat | findstr "PushService\|Firebase\|Exception"
```

**Si todo OK:** push notifications funcionando para defensa.

**Si falla cold start:** verificar `handleColdStartMessage` en `lib/main.dart` (debe llamarse con un handler que use `navigatorKey`).

---

### A.11 — Commit final + verificación pre-defensa

**Esfuerzo:** 5 min

```powershell
git status --short
# Esperado: working tree limpio salvo cambios ya stageados
git log --oneline -5
# Esperado: ver los 4 commits de A.2, A.4, A.5, A.7-A.8

git push origin master
```

**Verificación final:**

```powershell
flutter analyze        # 0 errors
flutter test           # 615+ passed
flutter build apk --release   # AAB firmado
ls lib/firebase_options.dart   # existe
ls android/app/google-services.json   # existe localmente (gitignored)
ls android/key.properties      # existe localmente (gitignored)
```

**Tras A.11:** la app **está lista para demo TFG con push funcional**.

---

<a id="b-play-store"></a>
## B. Post-defensa: release a Play Store (~6-8 h + esperas)

**Objetivo:** AAB publicado en Play Store con listing trilingüe, screenshots y review aprobada.

> Estos pasos se ejecutan **después** de la defensa. Asumir que la app cumple los requisitos de demo y se procede a publicación.

---

### B.1 — Capturar screenshots Android

**Esfuerzo:** 1 h

**Pasos:**

1. Tener device Android físico (o emulador Pixel 6 API 34) con la app instalada y datos cargados (login completo, favoritos, etc.).

2. Capturar **mínimo 4, máximo 8** pantallas en orden de impacto:
   - **Home** con mapa + paradas cercanas (modo claro)
   - **Mapa** con buses en tiempo real (modo claro)
   - **Detalle de ruta** con paradas y horarios
   - **Tarjeta NFC** leyendo (si device soporta)
   - **Modo oscuro** (cualquier pantalla)
   - Opcional: pantalla en árabe (RTL) para destacar i18n

3. Formato: PNG 1080×1920 mínimo, sin marcos del device, sin texto encima.

4. Guardar en `assets/marketing/screenshots/android/`:
   ```
   01_home_light.png
   02_map_realtime.png
   03_route_detail.png
   04_nfc_card.png
   05_dark_mode.png
   06_rtl_arabic.png
   ```

5. Repetir para idioma EN y AR (capturas en cada idioma).

---

### B.2 — Crear cuenta Google Play Console

**Esfuerzo:** 45 min + esperas

**Coste:** **$25 USD one-off** (registration fee).

**Pasos:**

1. Ir a [https://play.google.com/console/](https://play.google.com/console/) con cuenta Google.
2. Aceptar términos de developer + pagar $25.
3. Verificación de identidad: subir DNI/pasaporte. Tarda 24-48 h.
4. Una vez verificado, crear app:
   - Nombre: **Transitly**
   - Idioma principal: Español (España)
   - Tipo: App (no juego)
   - Gratuita / De pago: Gratis
   - Declaración: NO contiene anuncios, NO contiene compras dentro de la app

---

### B.3 — Configurar Play App Signing

**Pre-requisito:** B.2 verificado + keystore generado en A.6.

**Esfuerzo:** 15 min

**Recomendación:** usar **Play App Signing** (Google maneja la firma final). Tu keystore upload es solo para autenticar tu identidad ante Google.

**Pasos:**

1. Play Console → Tu app → **Setup → App integrity → App signing** → Enroll in Play App Signing.
2. Subir el certificado de upload key (no el `.jks` completo, solo el certificado público):
   ```powershell
   keytool -export -rfc -keystore android/upload-keystore.jks -alias upload -file upload_cert.pem
   ```
3. Subir `upload_cert.pem` a Play Console.
4. Google genera su propio **app signing key** (no lo verás nunca; queda en sus servidores).

---

### B.4 — Rellenar Play Store listing en 3 idiomas

**Esfuerzo:** 2-3 h

**Pasos por idioma (ES, EN, AR):**

1. **Short description** (≤80 chars):
   - ES: "Transporte público de España en tiempo real. Rutas, paradas, NFC, sin conexión."
   - EN: "Spain public transit in real-time. Routes, stops, NFC, offline."
   - AR: "النقل العام في إسبانيا في الوقت الفعلي. الطرق والمحطات و NFC وغير متصل."

2. **Full description** (≤4000 chars): describir funcionalidades, operadores, modo offline, accesibilidad. Plantilla en `docs/EXTERNAL_BLOCKERS.md §2`.

3. **App name** (≤30 chars):
   - ES/EN: "Transitly"
   - AR: "ترانزيتلي"

4. **Feature graphic** (1024×500 px): banner principal del listing. Crear en Figma o Canva.

5. **Screenshots:** subir los 4-8 de B.1 por idioma.

6. **Icono:** 512×512 px PNG sin transparencia.

---

### B.5 — Subir AAB a Internal Testing

**Pre-requisito:** B.2-B.4 + AAB firmado de A.8.

**Esfuerzo:** 30 min

**Pasos:**

1. Play Console → Tu app → **Testing → Internal testing** → Create new release.
2. Subir el AAB:
   ```
   build/app/outputs/bundle/release/app-release.aab
   ```
3. Añadir release notes en 3 idiomas (una línea cada uno).
4. Crear lista de testers: emails de familia / compañeros (máx. 100 cuentas Google).
5. Publicar → esperar verificación (~horas).
6. Los testers reciben email con opt-in URL.

---

### B.6 — Revisar Pre-Launch Report

**Esfuerzo:** 1-2 h (auto-generación + correcciones)

**Pasos:**

1. ~1 h después de subir el AAB en B.5, Google ejecuta Pre-Launch Report automático en device farm.
2. Play Console → Tu app → **Testing → Pre-launch report** → ver resultados.
3. **4 secciones a revisar:**
   - **Stability:** crash rate >0% → investigar stack trace (cruzar con Sentry).
   - **Performance:** cold start, frame drops, memory.
   - **Accessibility:** contrastes, touch targets, content labeling.
   - **Security:** certs SSL, permisos, cleartext.
4. Corregir hallazgos bloqueantes en código + re-subir AAB.
5. Iterar hasta 0 crashes, 0 security issues, accessibility warnings aceptables.

---

### B.7 — Promover a Closed → Open → Production

**Esfuerzo:** ~30 min por promoción + esperas review (24-48 h cada una)

**Pasos:**

1. Tras Internal OK, ir a **Testing → Closed testing** → promover el AAB.
2. Tras review OK (~24-48 h), promover a **Open testing**.
3. Tras OK, promover a **Production**.
4. En cada paso, Google revisa políticas (GDPR, contenido, permisos). Si rechazan, corregir según email.

---

### B.8 — Configurar GitHub Secrets para CI

**Esfuerzo:** 15 min

**Pasos:**

1. En GitHub → repo → **Settings → Secrets and variables → Actions → New repository secret**.
2. Añadir 5 secrets:
   ```
   ANDROID_KEYSTORE_BASE64        = base64 del .jks (Linux/WSL: base64 -w0 upload-keystore.jks)
   ANDROID_KEYSTORE_PASSWORD      = store password
   ANDROID_KEY_ALIAS              = upload
   ANDROID_KEY_PASSWORD           = key password
   GOOGLE_SERVICES_JSON_BASE64    = base64 de android/app/google-services.json
   ```

3. En `.github/workflows/ci.yml`, en el job `build-android`, antes de `flutter build`, decodificar los secrets:
   ```yaml
   - name: Decode signing secrets
     run: |
       echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > android/upload-keystore.jks
       cat > android/key.properties <<EOF
       storeFile=upload-keystore.jks
       storePassword=${{ secrets.ANDROID_KEYSTORE_PASSWORD }}
       keyAlias=${{ secrets.ANDROID_KEY_ALIAS }}
       keyPassword=${{ secrets.ANDROID_KEY_PASSWORD }}
       EOF
       echo "${{ secrets.GOOGLE_SERVICES_JSON_BASE64 }}" | base64 -d > android/app/google-services.json
   ```

4. Verificar push a `master` activa el job y genera AAB firmado en artefactos.

**Commit:**
```bash
git add .github/workflows/ci.yml
git commit -m "ci: decodificar secrets keystore + google-services.json para build-android (B.8)"
git push origin master
```

---

<a id="c-astro"></a>
## C. Web Astro híbrida (~3-4 h)

**Objetivo:** desplegar `astro/` con páginas de Privacy Policy y Terms of Service para enlazar desde Play Store listing.

> Sin estas URLs, Play Store rechaza el listing por incumplimiento GDPR.

---

### C.1 — Decidir dominio

**Opciones:**

| Opción | Coste | Pros | Contras |
|--------|------:|------|---------|
| **GitHub Pages** | €0 | Gratis, fácil, push a master deploya | URL `astralk9999.github.io/Transitly` poco profesional |
| **Cloudflare Pages** | €0 | Gratis, dominio personalizado opcional | Requiere registro Cloudflare |
| **Vercel** | €0 | Gratis, CI integrado, dominio `.vercel.app` | Mismo nivel que Cloudflare |
| **Dominio propio** | $12/año | Profesional `transitly.app` | Coste recurrente, configuración DNS |

**Recomendación para defensa TFG:** **GitHub Pages** (gratis, suficiente).
**Recomendación para release real:** **Cloudflare Pages + dominio propio** ($12/año).

---

### C.2 — Build local del Astro site

**Esfuerzo:** 15 min

**Pre-requisito:** Node.js 20+ instalado.

```powershell
cd astro
npm install
npm run build
```

**Verificación:**
```powershell
ls dist/
# Esperado: archivos HTML/CSS/JS estáticos
```

Si hay errores de build, revisar logs y corregir `astro.config.mjs` o componentes.

---

### C.3 — Deploy automático (GitHub Pages — opción gratis)

**Esfuerzo:** 1 h

**Pasos:**

1. Crear `.github/workflows/deploy-astro.yml`:
   ```yaml
   name: Deploy Astro to GitHub Pages

   on:
     push:
       branches: [master]
       paths:
         - 'astro/**'
         - '.github/workflows/deploy-astro.yml'

   permissions:
     contents: read
     pages: write
     id-token: write

   jobs:
     build:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4
         - uses: actions/setup-node@v4
           with:
             node-version: '20'
         - name: Install dependencies
           run: cd astro && npm install
         - name: Build Astro
           run: cd astro && npm run build
         - uses: actions/upload-pages-artifact@v3
           with:
             path: astro/dist

     deploy:
       needs: build
       runs-on: ubuntu-latest
       environment:
         name: github-pages
         url: ${{ steps.deployment.outputs.page_url }}
       steps:
         - uses: actions/deploy-pages@v4
           id: deployment
   ```

2. En GitHub → Settings → Pages → Source: **GitHub Actions**.

3. Push:
   ```bash
   git add .github/workflows/deploy-astro.yml
   git commit -m "ci(astro): deploy automático a GitHub Pages en push a master (C.3)"
   git push origin master
   ```

4. Tras ~2 min, verificar deploy en `https://<github-user>.github.io/<repo>/`.

---

### C.4 — Página `/privacy` con Privacy Policy

**Esfuerzo:** 1 h

**Pre-requisito:** contenido de privacy policy ya redactado en `docs/DATA_RETENTION.md` + `docs/RIGHT_TO_BE_FORGOTTEN.md` + `docs/EXTERNAL_BLOCKERS.md §12`.

**Pasos:**

1. Crear `astro/src/pages/privacy.astro` con contenido legal (en 3 idiomas idealmente):
   ```astro
   ---
   import Layout from '../layouts/Layout.astro';
   ---
   <Layout title="Política de Privacidad">
     <article>
       <h1>Política de Privacidad</h1>
       <p>Última actualización: 2026-06-XX</p>
       <!-- Secciones: responsable, datos, finalidad, base legal, terceros,
            transferencias, retención, derechos ARCO, cookies, menores -->
     </article>
   </Layout>
   ```

2. Contenido obligatorio (RGPD mínimo):
   - **Responsable del tratamiento:** nombre del autor TFG + email contacto.
   - **Datos recopilados:** email, ubicación (mapa, conductor), NFC UID hash, crash reports, analytics.
   - **Finalidad:** funcionalidad app, mejora servicio, seguridad.
   - **Base legal:** consentimiento explícito (login + privacy consent screen).
   - **Terceros:** Supabase (backend AWS Frankfurt UE), Sentry (UE), PostHog (UE/USA).
   - **Retención:** mientras dure la cuenta + 30 días post borrado.
   - **Derechos ARCO:** acceso, rectificación, cancelación, oposición → email contacto.
   - **Cookies:** Hive local, sin tracking cookies.
   - **Menores:** edad mínima 16 años (GDPR-ES Art. 8).

3. Build y verificar:
   ```powershell
   cd astro && npm run build
   ```

4. Push y esperar deploy.

---

### C.5 — Página `/terms` con Terms of Service

**Esfuerzo:** 1 h

Crear `astro/src/pages/terms.astro` análogo a privacy.

**Secciones obligatorias:**
- Aceptación al crear cuenta
- Descripción del servicio
- Cuenta de usuario (responsabilidad credenciales)
- Contenido del usuario (UGC: incidencias, sugerencias, feedback) y moderación
- Limitación de responsabilidad
- Propiedad intelectual
- Modificaciones del servicio
- Terminación
- Ley aplicable y jurisdicción (España)

---

### C.6 — Enlazar URLs desde Play Store

**Esfuerzo:** 15 min

**Pasos:**

1. Play Console → Tu app → **Policy → App content → Privacy policy** → URL: `https://<tu-dominio>/privacy`.
2. Lo mismo para Terms si Play Store lo pide (opcional pero recomendado).
3. Verificar que las URLs son **accesibles desde incógnito** (sin login).

---

### C.7 — Verificación final Astro

```bash
curl -I https://<tu-dominio>/privacy
# Esperado: 200 OK

curl -I https://<tu-dominio>/terms
# Esperado: 200 OK
```

Si devuelve 404, revisar el deploy y la estructura de `astro/src/pages/`.

---

<a id="d-a11y-legal-ops"></a>
## D. Accesibilidad + Legal + Operaciones (~5-7 h)

---

### D.1 — Acta TalkBack manual (Android)

**Esfuerzo:** 1-2 h

**Pasos:**

1. Activar TalkBack en device físico Android: **Settings → Accessibility → TalkBack → On**.
2. Aprender gestos:
   - Swipe right: siguiente elemento.
   - Double tap: activar elemento seleccionado.
   - Two-finger swipe: scroll.
   - Three-finger swipe down: leer todo desde aquí.

3. Recorrer flujo completo:
   - Onboarding (3 pantallas) → Home (5 tabs) → Detalle ruta → Detalle parada → Búsqueda → Reportar incidencia → Perfil → Accesibilidad settings → Cambio idioma EN → Cambio AR (RTL) → Modo oscuro.

4. Verificar:
   - Cada elemento interactivo tiene `contentDescription` o `Semantics.label` legible.
   - Elementos decorativos están `excludeSemantics: true`.
   - `Pressable` ≥48dp.
   - Sin elementos huérfanos sin foco.
   - Sin saltos de foco bruscos.

5. **Crear acta:** `docs/a11y/TALKBACK_ACTA_2026_06.md`:
   ```markdown
   # Acta de verificación TalkBack — Transitly

   **Fecha:** 2026-06-XX
   **Dispositivo:** Pixel 7 Android 14
   **TalkBack:** versión X.Y.Z
   **Auditor:** [nombre]

   ## Pantallas verificadas

   | # | Pantalla | Veredicto | Incidencias |
   |---|----------|:--:|------|
   | 1 | Onboarding slide 1 | ✓ AA | — |
   | 2 | ... | ... | ... |

   ## Veredicto global
   APROBADO AA / NO APROBADO (con lista de issues bloqueantes)

   ## Firma
   [nombre + fecha]
   ```

---

### D.2 — Firmar DPA con Supabase (GDPR Art. 28)

**Esfuerzo:** 30 min

**Pasos:**

1. Supabase Dashboard → **Settings → General → Legal** → **Data Processing Addendum**.
2. Descargar PDF, revisar, firmar (digital o impreso).
3. Subir firmado o aceptar online.
4. Guardar copia firmada en `docs/legal/DPA_SUPABASE_2026.pdf`.

---

### D.3 — Crear Edge Function `generate_data_export`

**Esfuerzo:** 2 h

**Archivos nuevos:**

1. `supabase/functions/generate_data_export/deno.json`:
   ```json
   {
     "imports": {
       "@supabase/supabase-js": "https://esm.sh/@supabase/supabase-js@2"
     }
   }
   ```

2. `supabase/functions/generate_data_export/index.ts`:
   ```typescript
   import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

   Deno.serve(async (req) => {
     const { user_id } = await req.json();
     const supabase = createClient(
       Deno.env.get("SUPABASE_URL")!,
       Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
     );

     // Recopilar todos los datos del usuario
     const [profile, favorites, contributions, feedback, incidents] =
       await Promise.all([
         supabase.from("profiles").select("*").eq("id", user_id).single(),
         supabase.from("user_favorites").select("*").eq("user_id", user_id),
         supabase.from("route_suggestions").select("*").eq("user_id", user_id),
         supabase.from("route_feedback").select("*").eq("user_id", user_id),
         supabase.from("incidents").select("*").eq("reporter_id", user_id),
       ]);

     const exportData = {
       exported_at: new Date().toISOString(),
       user_id,
       profile: profile.data,
       favorites: favorites.data,
       contributions: contributions.data,
       feedback: feedback.data,
       incidents: incidents.data,
     };

     // Subir a Storage bucket exports/ con expiración 7 días
     const fileName = `exports/${user_id}/${Date.now()}.json`;
     await supabase.storage
       .from("exports")
       .upload(fileName, JSON.stringify(exportData, null, 2));

     const { data: signedUrl } = await supabase.storage
       .from("exports")
       .createSignedUrl(fileName, 60 * 60 * 24 * 7);

     // Marcar request como completada
     await supabase
       .from("data_exports")
       .update({ executed_at: new Date().toISOString(), download_url: signedUrl?.signedUrl })
       .eq("user_id", user_id);

     return new Response(JSON.stringify({ ok: true, url: signedUrl?.signedUrl }), {
       status: 200,
     });
   });
   ```

3. `supabase/functions/generate_data_export/test.ts` con casos: usuario sin datos, usuario con datos, usuario inexistente.

4. Desplegar:
   ```powershell
   supabase functions deploy generate_data_export --verify-jwt
   ```

---

### D.4 — Invocar `generate_data_export` desde la app

**Archivo:** `lib/features/privacy/privacy_screen.dart:82-94` (zona `_requestDataExport()`)

Añadir tras el insert en `data_exports`:

```dart
await ref.read(supabaseClientProvider).functions.invoke(
  'generate_data_export',
  body: {'user_id': userId},
);
```

**Verificación:**
- Solicitar exportación en app → tras ~1 min, recibir notificación con URL de descarga (o ver en tabla `data_exports.download_url`).

**Commit:**
```bash
git add supabase/functions/generate_data_export/ lib/features/privacy/privacy_screen.dart
git commit -m "feat(gdpr): edge function generate_data_export + invocación en privacy_screen (D.3-D.4, Art. 20)"
```

---

### D.5 — (Opcional) Sentry Session Replay

**Coste:** $26/mes (plan Team o superior).

**Pasos:**
1. Sentry Dashboard → tu proyecto Transitly → Replays → Enable.
2. En `lib/core/utils/sentry_setup.dart`, añadir `replaysSessionSampleRate: 0.1`.
3. Verificar replays aparecen en dashboard tras 1 día de uso.

---

### D.6 — (Opcional) Status page

**Coste:** €0 plan gratuito.

**Pasos:**
1. Crear cuenta en `https://atlassian.com/software/statuspage` (gratis hasta 100 suscriptores).
2. Configurar 3 componentes monitoreados: App, Supabase API, Firebase.
3. Conectar webhooks de Supabase + Firebase para alertas automáticas.
4. Enlazar URL `https://status.transitly.app` desde dentro de la app (Perfil → Estado del servicio).

---

### D.7 — (Opcional) Load testing con k6

**Pre-requisito:** Supabase plan Pro ($25/mes) para no chocar con rate limits del free.

**Esfuerzo:** 2 h

**Pasos:**
1. Instalar k6: `winget install k6`.
2. Crear script `tools/load-test.js` con escenarios típicos (auth, query rutas, insert feedback).
3. Ejecutar contra staging:
   ```powershell
   k6 run --vus 100 --duration 5m tools/load-test.js
   ```
4. Verificar p95 latencia < 800ms, error rate < 0.5%.

---

<a id="e-i18n"></a>
## E. Internacionalización árabe (1-2 días)

**Coste:** ~$100 (Fiverr/Upwork) o $30 (DeepL Pro + revisión nativa).

**Estado actual:** 628 claves ES traducidas, 258 claves AR completas (~41 %), 370 claves AR pendientes.

**Pasos:**

1. Exportar las 370 claves pendientes a CSV:
   ```bash
   # Identificar claves AR vacías
   python tools/find_missing_arb.py lib/l10n/app_ar.arb > pending_ar.csv
   ```

2. **Opción A — Fiverr/Upwork (~$100):**
   - Buscar traductor nativo árabe (preferible MSA/Modern Standard) con experiencia en apps.
   - Briefing: app de transporte público, registro coloquial pero formal.
   - Entrega 1-2 días.

3. **Opción B — DeepL Pro + revisión nativa (~$30):**
   - Suscripción DeepL Pro mensual ($7.49) para traducción inicial.
   - Pago a revisor nativo (~$20) para validar y ajustar términos técnicos.

4. **Opción C — Crowdin (€0):**
   - Crear proyecto Crowdin gratis (open source).
   - Subir ARB, invitar comunidad árabe.
   - Tiempo variable (1-4 semanas).

5. Integrar traducción en `lib/l10n/app_ar.arb`, regenerar:
   ```powershell
   flutter gen-l10n
   ```

6. Verificar RTL en device:
   ```powershell
   adb shell settings put system system_locales ar-EG
   ```

**Commit:**
```bash
git add lib/l10n/app_ar.arb
git commit -m "i18n(ar): traducción humana 370 claves AR pendientes (E.1)"
```

---

<a id="f-ios"></a>
## F. Anexo: iOS (futuro descartado por coste)

> El proyecto **está preparado para iOS** (carpetas `ios/`, código Flutter cross-platform), pero el scope actual descarta iOS por el coste del Apple Developer Program ($99/año).

**Si en el futuro se retoma iOS**, los pasos requeridos serían:

| # | Acción | Esfuerzo | Coste |
|---|--------|---------:|------:|
| F.1 | Inscripción Apple Developer Program | 1-14 días (D-U-N-S) | $99/año |
| F.2 | `flutterfire configure --platforms=ios` → `GoogleService-Info.plist` | 15 min | — |
| F.3 | `ios/Runner/Runner.entitlements` con `aps-environment` | 10 min | — |
| F.4 | `UIBackgroundModes` con `remote-notification` en `Info.plist` | 5 min | — |
| F.5 | Job `build-ios-release` en CI con macOS runner + Fastlane | 3 h | $0.08/min macOS runner |
| F.6 | Screenshots iOS (iPhone 6.7" obligatorio) | 1 h | — |
| F.7 | App Store privacy details + submission | 2 h | — |
| **Total** | | **~7 h activas + esperas** | **$99+/año** |

**Detalle ejecutable** disponible en `docs/EXTERNAL_BLOCKERS.md §6-10`.

---

<a id="g-smoke-test"></a>
## G. Smoke test Android pre-defensa (manual, recordatorio)

> Esta sección es **recordatorio de las pruebas que tú debes hacer manualmente** en device físico. No se ejecutan vía CI ni se documentan automáticamente.

### G.1 — Checklist pre-defensa (~1 h, día D-3)

Ejecutar **en el device Android físico que se usará en la defensa**:

1. **Cold start (app cerrada → abrir):**
   - Splash aparece y desaparece en ~2 s
   - Si no hay sesión → onboarding (3 slides) → signup/login
   - Si hay sesión → home directamente

2. **Login/logout:**
   - Login con email + password → home
   - Logout → vuelve a signin
   - Login como invitado (si está habilitado) → home con badges visibles

3. **Mapa Jerez:**
   - Zoom in/out con pinch
   - Pan
   - Tap en parada → sheet con info + horarios
   - Tap en bus (si hay realtime simulado) → sheet con trip info

4. **Búsqueda de ruta:**
   - Buscar "L1" → resultados aparecen
   - Si "Buscador en construcción" → estado honesto OK

5. **Detalle de ruta:**
   - Tap en una ruta → ver header (sin "COMUJESA · Ana Martín" hardcoded)
   - Pulsar "AÑADIR A MIS LÍNEAS" → toast confirmación
   - Volver, cerrar app, reabrir → favorito persiste

6. **Tarjeta NFC** (si device soporta):
   - Pestaña Tarjeta → "Escanear"
   - Acercar tarjeta del Consorcio Andalucía
   - Saldo + viajes recientes aparecen

7. **Modo offline:**
   - Perfil → "Datos offline" → "Descargar región Jerez" (banner demo OK)
   - Desactivar WiFi/datos en device
   - Mapa sigue funcionando con tiles cacheados

8. **i18n:**
   - Perfil → Idioma → English → toda la UI en inglés
   - Volver a Idioma → العربية → UI en árabe RTL (textos derecha-izquierda)

9. **Accesibilidad:**
   - Perfil → Accesibilidad → activar daltonismo → mapa adapta colores
   - Activar alto contraste → UI más contrastada
   - Aumentar tamaño texto → todo escala sin overflow

10. **Push notification (tras A.10):**
    - Recibir notif test desde Firebase Console
    - Tocar notif → app abre en pantalla correcta del deeplink

11. **Modo conductor:**
    - Perfil → "Activar modo conductor" → introducir código (válido del operator_admin)
    - Iniciar ruta → ver GPS tracking simulado

### G.2 — Si algo falla

Anotar en `docs/historico/SMOKE_TEST_BUGS_<fecha>.md` con:
- Pantalla afectada
- Acción que disparó el bug
- Comportamiento esperado vs observado
- Logcat (`adb logcat -d > bug.log`)

Solo arreglar pre-defensa si es **P0 visible**. Resto a deuda post-defensa.

---

<a id="h-cronograma"></a>
## H. Cronograma sugerido (defensa 2026-06-09, 15 días vista)

| Día | Fase | Acción | Esfuerzo |
|-----|------|--------|---------:|
| **D-15** (hoy) | A.1-A.5 | Setup Firebase Android | 1 h |
| **D-14** | A.6-A.9 | Keystore + AAB firmado verificado | 45 min |
| **D-13** | A.10-A.11 | Smoke test push end-to-end + commit | 35 min |
| **D-12** | G | Smoke test manual exhaustivo (G.1) | 1 h |
| **D-10** | C.2-C.3 | Astro build + deploy gratis GitHub Pages | 1.5 h |
| **D-7** | C.4-C.5 | Privacy + Terms en Astro | 2 h |
| **D-5** | — | Ensayo demo cronometrado (18-22 min) | 30 min |
| **D-3** | — | Re-leer slides + checklist pre-defensa | 1 h |
| **D-2** | — | Smoke test rápido + repaso preguntas tribunal | 1 h |
| **D-1** | — | Backup APK + repo en USB | 30 min |
| **D-0** (2026-06-09) | — | Smoke test express 2 h antes + defensa | 30 min |

**Total esfuerzo pre-defensa:** ~10 h distribuidas en 15 días.

**Post-defensa** (orden recomendado):

| Semana | Acción |
|--------|--------|
| Semana 1 post-defensa | B.1-B.5 Play Store hasta Internal Testing |
| Semana 2 | B.6 Pre-Launch Report + iteraciones |
| Semana 3 | B.7 Closed → Open → Production |
| Mes 2+ | D.1 acta TalkBack + D.2 DPA + D.3-D.4 export GDPR |
| Mes 3+ | E traducción AR + D.5-D.7 ops opcionales |

---

<a id="i-resumen"></a>
## I. Resumen ejecutivo

### Estado actual (2026-05-25)

- Tests: 615+ passed, 6 skipped, 0 failed
- Cobertura: 24,04 %
- `flutter analyze`: 0 errors
- 0 bugs P0/P1 conocidos
- HEAD `master @ 4064b8e`

### Estado tras completar este plan

| Fase | Items | Esfuerzo | Crítico defensa | Crítico release |
|------|------:|---------:|:--:|:--:|
| A — Pre-defensa Android | 11 | 3-4 h | **SÍ** | **SÍ** |
| B — Play Store | 8 | 6-8 h + esperas | NO | **SÍ** |
| C — Astro Web | 7 | 3-4 h | NO | **SÍ** (Privacy/Terms) |
| D — A11Y + Legal + Ops | 7 | 5-7 h | parcial (D.1) | **SÍ** |
| E — Traducción AR | 1 | 1-2 días | NO | recomendado |
| F — iOS futuro | (anexo) | — | — | descartado |
| G — Smoke test usuario | recordatorio | 1 h | **SÍ** | — |

**Total críticos pre-defensa:** ~5 h
**Total post-defensa hasta MVP publicable:** ~15 h activas + esperas (Google review 24-48 h × 2-3 iteraciones)

### Costes

| Concepto | Coste | Cuándo |
|----------|------:|--------|
| Google Play Console one-off | $25 | Antes de B.2 |
| Dominio `transitly.app` (opcional) | $12/año | Antes de C.4 |
| Traducción AR humana (opcional) | $30-100 | E |
| Sentry Replay (opcional) | $26/mes | D.5 |
| Supabase Pro (opcional, para load testing) | $25/mes | D.7 |
| **Total mínimo pre-release** | **$25** | one-off |
| **Total recomendado primer año** | **~$137** | |

### Recomendación final

1. **Esta semana (D-15 → D-12):** Sección A completa. Tras esto, demo tiene push real funcionando.
2. **Próxima semana (D-10 → D-7):** Sección C (Astro + Privacy/Terms). Permite enlazar URLs reales.
3. **D-3 → D-0:** ensayos + smoke test + defensa.
4. **Post-defensa:** Sección B (Play Store), D (acta TalkBack + DPA + edge function export).

---

**FIN DEL PLAN**

> Documento generado el 2026-05-25 tras verificación de los 3 fixes finales (commits `3db6454`, `4064b8e`, `offlineDataReloaded`).
> Cada comando verificado contra estructura real del repo.
> El usuario (humano o IA) ejecuta los pasos siguiendo el cronograma de Sección H.
> Backup del keystore Android es **CRÍTICO** — si se pierde, no se puede actualizar la app en Play Store nunca.
