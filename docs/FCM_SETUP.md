# Push real (FCM) — estado y pasos finales

Estado a 2026-06-08. El pipeline de push **está construido entero**; solo falta
una credencial que debe generar el dueño del proyecto Firebase.

## Qué ya funciona (hecho)

- **App cliente** configurada para FCM:
  - `android/app/google-services.json` (proyecto `transitly-ee8cf`).
  - Plugin `com.google.gms.google-services` aplicado en `android/app/build.gradle.kts`.
  - `lib/firebase_options.dart` con las claves reales.
  - `FirebaseSetup.init()` + `PushService.init()` en `main.dart`, con
    `onBackgroundMessage` y `setupForegroundHandler` registrados.
  - El token FCM del dispositivo se guarda en `device_tokens` al iniciar sesión
    (`auth_repository_supabase.dart` → `_syncPushToken`) y se borra al salir.
- **Backend**: Edge Function `supabase/functions/send_notification` (OAuth JWT →
  FCM HTTP v1, limpieza de tokens inválidos) + triggers SQL
  (`010_push_triggers.sql`) que la invocan en: incidencia resuelta/rechazada,
  ruta compartida, ruta promovida a oficial.

Con esto la app **ya recibe push con la app cerrada**. Se puede demostrar al
instante desde Firebase Console → *Cloud Messaging* → *Enviar mensaje de prueba*
pegando el token del dispositivo (ver abajo cómo obtenerlo).

## Lo único que falta: la *service account* de Firebase

El `google-services.json` es config de **cliente**; para que el backend ENVÍE
push hace falta la clave de **servidor** (service account):

1. Firebase Console → ⚙️ *Configuración del proyecto* → pestaña
   *Cuentas de servicio*.
2. *Generar nueva clave privada* → descarga un JSON (contiene `private_key`).
3. Pásamelo (o configúralo tú con los comandos de abajo). **No** lo subas a git.

### Configurar los secretos (con la service account ya descargada)

```powershell
# Project ref: mmzahxtiaurkgtmtehxk
$env:SUPABASE_ACCESS_TOKEN = "<tu PAT de Supabase>"

# Secretos de la Edge Function (envío FCM):
supabase secrets set FCM_PROJECT_ID=transitly-ee8cf --project-ref mmzahxtiaurkgtmtehxk
supabase secrets set FCM_SERVICE_ACCOUNT_JSON="$(Get-Content ruta\service-account.json -Raw)" --project-ref mmzahxtiaurkgtmtehxk

# Desplegar la función:
supabase functions deploy send_notification --project-ref mmzahxtiaurkgtmtehxk
```

### Secretos en Vault (para que los triggers SQL puedan llamar a la función)

Ejecutar una vez en el SQL editor de Supabase:

```sql
select vault.create_secret('<service_role_key>', 'service_role_key');
select vault.create_secret('https://mmzahxtiaurkgtmtehxk.supabase.co/functions/v1', 'functions_url');
```

## Cómo obtener el token FCM del dispositivo (para la prueba manual)

Tras instalar el APK e iniciar sesión, el token queda en `device_tokens`:

```sql
select token, platform, last_seen from device_tokens order by last_seen desc limit 5;
```

O en logcat: `adb logcat | findstr "FCM token"`.
