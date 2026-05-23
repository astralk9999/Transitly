# Firebase Cloud Messaging (FCM) — Manual Setup

> Fase F21 · Push notifications for Transitly

---

## 1. Create Firebase project

1. Go to https://console.firebase.google.com
2. Click **Add project** → name it `transitly` (or your preferred name)
3. Enable Google Analytics (optional but recommended)
4. Click **Create project** and wait for provisioning

---

## 2. Android: google-services.json

1. In Firebase Console → **Project settings** → **Add app** → **Android**
2. Package name: match the one in `android/app/build.gradle.kts`
   - Default: `com.transitly.app`
3. SHA-1 (optional for now; needed later for dynamic links / phone auth)
4. Click **Register app**, then **Download google-services.json**
5. Place the file at: `android/app/google-services.json`
6. The `android/build.gradle.kts` and `android/app/build.gradle.kts` already
   contain the Google Services plugin (added automatically by `flutter pub add firebase_core`)

---

## 3. iOS: GoogleService-Info.plist

1. In Firebase Console → **Project settings** → **Add app** → **iOS**
2. Bundle ID: match the one in Xcode project → Runner target
   - Default: `com.transitly.app`
3. Click **Register app**, then **Download GoogleService-Info.plist**
4. Place the file at: `ios/Runner/GoogleService-Info.plist`
5. In Xcode: drag the file into Runner → ensure **Copy items if needed** is checked
   and target membership includes `Runner`

---

## 4. iOS: APNs key (required for notifications)

1. Go to https://developer.apple.com → **Certificates, Identifiers & Profiles**
2. Under **Keys**, create a new **APNs Auth Key**
3. Download the `.p8` file and note the **Key ID**
4. In Firebase Console → **Project settings** → **Cloud Messaging** →
   **Apple app configuration**
5. Upload the `.p8` file, enter the Key ID and your Apple Team ID
6. Also enable **Push Notifications** capability in Xcode → Runner target →
   **Signing & Capabilities** → **+ Capability** → **Push Notifications**

---

## 5. firebase_options.dart (optional but recommended)

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=transitly
```

This generates `lib/firebase_options.dart` with platform-specific config.
If you skip this, `Firebase.initializeApp()` will still work as long as
`google-services.json` / `GoogleService-Info.plist` are in place.

When `firebase_options.dart` exists, update `lib/data/push/firebase_setup.dart`:

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

---

## 6. Test notification

1. In Firebase Console → **Cloud Messaging** → **Send your first message**
2. Enter a title and body → **Send test message**
3. Add an FCM registration token (logged by the app once configured)
4. Click **Test**

If the token is generated and the message is received, FCM is working.

---

## 7. Troubleshooting

| Symptom | Check |
|---------|-------|
| App crashes on start | Verify `google-services.json` or `GoogleService-Info.plist` exists |
| No token generated | Check network / Google Play Services (Android) / APNs (iOS) |
| iOS: no notification permission | Ensure `Info.plist` has no `FirebaseMessagingAutoInitEnabled = false` |
| Notifications not received in background | iOS requires APNs key uploaded; Android requires correct priority |
