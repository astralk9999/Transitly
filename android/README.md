# Android — Release signing

## Estado actual

El APK compila con debug keys (válido para desarrollo y CI, no para Play Store).
Cuando exista `android/key.properties`, el build usa automáticamente las
credenciales de release.

## Generar keystore y firmar para Play Store

```bash
cd android

# 1. Generar keystore (NO commitear upload-keystore.jks)
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# 2. Crear key.properties desde la plantilla
cp key.properties.example key.properties
# Editar key.properties con las contraseñas reales

# 3. Build
cd ..
flutter build apk --release          # APK firmado con release
flutter build appbundle --release    # Para Play Store (recomendado)
```

## Verificar firma

```bash
jarsigner -verify -verbose -certs \
  build/app/outputs/flutter-apk/app-release.apk | head -20
```

## Play App Signing (recomendado)

1. Sube `upload-keystore.jks` a Google Play Console
2. Google gestiona la firma de release
3. Tú solo necesitas el keystore de upload (no el de release)
4. Si pierdes el keystore, Google puede regenerarlo

## CI (GitHub Actions)

Añade estos secrets al repositorio:
- `KEYSTORE_BASE64` — `base64 -w0 upload-keystore.jks`
- `KEY_STORE_PASSWORD`
- `KEY_PASSWORD`
- `KEY_ALIAS` — `upload`

El CI reconstruirá el keystore y `key.properties` antes del build.
