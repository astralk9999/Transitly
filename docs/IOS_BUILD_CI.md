# iOS Build CI — Transitly

> **Version:** 1.0 · **Reference:** PRO-Rel-31 · **Requires:** macOS runner, Apple Developer account

## Overview

Build and sign iOS app in CI using GitHub Actions macOS runner and Fastlane.

---

## CI Workflow

```yaml
# .github/workflows/ios-build.yml
name: iOS Build

on:
  push:
    branches: [master]
  workflow_dispatch:

jobs:
  build-ios:
    name: Build iOS (Release)
    runs-on: macos-latest
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.35.x"
          channel: stable
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Generate l10n
        run: flutter gen-l10n

      - name: Run build_runner
        run: dart run build_runner build --delete-conflicting-outputs

      - name: Setup Fastlane
        run: |
          gem install fastlane -NV

      - name: Decode signing certificates
        env:
          APPSTORE_CERT_BASE64: ${{ secrets.APPSTORE_CERT_BASE64 }}
          PROVISION_PROFILE_BASE64: ${{ secrets.PROVISION_PROFILE_BASE64 }}
        run: |
          echo "$APPSTORE_CERT_BASE64" | base64 -d > cert.p12
          echo "$PROVISION_PROFILE_BASE64" | base64 -d > profile.mobileprovision
          security create-keychain -p "" build.keychain
          security import cert.p12 -k build.keychain -P "${{ secrets.CERT_PASSWORD }}" -A
          security set-key-partition-list -S apple-tool:,apple: -s -k "" build.keychain

      - name: Build iOS (release)
        run: |
          flutter build ios --release --no-codesign \
            --dart-define=SUPABASE_URL=${{ secrets.SUPABASE_URL }} \
            --dart-define=SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}

      - name: Archive with Fastlane
        run: |
          cd ios
          fastlane release
```

## Fastlane Configuration

```ruby
# ios/fastlane/Fastfile
default_platform(:ios)

platform :ios do
  lane :release do
    build_app(
      workspace: "Runner.xcworkspace",
      scheme: "Runner",
      export_method: "app-store",
      output_directory: "../build/ios",
    )
  end
end
```

## Required Secrets

| Secret | Description |
|--------|-------------|
| `APPSTORE_CERT_BASE64` | Apple Distribution certificate (base64) |
| `PROVISION_PROFILE_BASE64` | App Store provisioning profile (base64) |
| `CERT_PASSWORD` | Certificate export password |
| `APPSTORE_CONNECT_KEY` | App Store Connect API key JSON |

## Prerequisites

1. **Apple Developer Program** ($99/year)
2. **App Store Connect** app created with bundle ID `com.transitly.transitly`
3. **Certificates**: Apple Distribution + Provisioning Profile
4. **App Store Connect API key** for Fastlane upload

## Local Build (without CI)

```bash
flutter build ios --release
open ios/Runner.xcworkspace  # Archive in Xcode
```

## Notes

- iOS builds require macOS (no cross-compilation)
- GitHub Actions macOS runners cost 10x Linux minutes
- Without signing, use `flutter build ios --no-codesign` for compile-only verification
- The `PrivacyInfo.xcprivacy` and `Info.plist` must be complete before App Store submission
