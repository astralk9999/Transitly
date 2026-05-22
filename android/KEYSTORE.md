# Android Keystore Setup

## Generate upload keystore

```bash
keytool -genkey -v -keystore android/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

## Create key.properties

Create `android/key.properties`:

```
storePassword=<your-password>
keyPassword=<your-password>
keyAlias=upload
storeFile=upload-keystore.jks
```

## CI Setup

Add these GitHub secrets:
- `KEYSTORE_BASE64`: `base64 android/upload-keystore.jks`
- `KEY_STORE_PASSWORD`
- `KEY_PASSWORD`
- `KEY_ALIAS`

The `build.gradle.kts` already handles conditional signing.
