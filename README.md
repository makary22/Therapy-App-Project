# Safe Space (Flutter)

Flutter app with Firebase Authentication and Firebase Cloud Messaging.

## Features

- Onboarding flow for first-time users.
- Login/Register with:
  - Email/Password.
  - Google Sign-In.
  - Facebook Sign-In.
- Email verification before final access.
- Push notifications via FCM with topic subscription (`daily_notifications`).

## Tech Stack

- Flutter
- Firebase Core / Auth / Messaging
- Google Sign-In
- Facebook Auth
- Shared Preferences

## Project Structure (Short)

```text
lib/
  main.dart
  features/
    auth/
    home/
    notifications/
    screens/
functions/
  index.js
  package.json
```

## Requirements

Before running, make sure you have:

- Flutter SDK installed and added to PATH.
- Android Studio + Android SDK (for Android).
- Xcode (for iOS on macOS only).
- A configured Firebase project connected to the app.

Check versions:

```bash
flutter --version
dart --version
```

## Quick Start

From the `myproj` folder:

```bash
flutter pub get
flutter run
```

## Run By Platform

### Android

```bash
flutter pub get
flutter run -d android
```

To build a release APK:

```bash
flutter build apk --release
```

### iOS (macOS فقط)

```bash
flutter pub get
cd ios
pod install
cd ..
flutter run -d ios
```

### Web

```bash
flutter pub get
flutter run -d chrome
```

## Firebase Setup

This project relies on Firebase. If you are running it on a new machine:

1. Create or use the same Firebase project.
2. Add an Android app with the same `applicationId` used by the Android config.
3. Download `google-services.json` and place it in:

```text
android/app/google-services.json
```

4. (Optional for iOS) Add `GoogleService-Info.plist` inside Runner.
5. Enable required authentication providers:
  - Email/Password
  - Google
  - Facebook

## Important For Team (Google Sign-In)

If Google Sign-In works for one teammate but fails for another, Firebase is usually missing that machine's debug keystore fingerprint.

Add SHA-1 and SHA-256 for each development machine in Firebase Android app settings.

Get fingerprints:

```bash
cd android
./gradlew signingReport
```

On Windows PowerShell:

```powershell
cd android
.\gradlew.bat signingReport
```

After adding fingerprints, download `google-services.json` again and replace it in the project.

## Facebook Login Note

If you see an error like "App not active", the issue is usually in Facebook Developer Dashboard settings (Status/Roles), not in Flutter code.

## Notifications (FCM)

- The app automatically subscribes to topic: `daily_notifications`.
- Cloud Functions notification setup is documented in:

`FCM_SETUP.md`

## Useful Commands

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
```

## Troubleshooting

### 1) Firebase initialization أو auth errors

- Make sure `google-services.json` exists and is valid.
- Make sure the package name matches the Firebase app.

### 2) Google login fails on teammate machine

- Add that machine's SHA-1/SHA-256 in Firebase.
- Update `google-services.json` after adding fingerprints.

### 3) Notifications not arriving

- Make sure notification permission is granted.
- Review deployment/testing steps in `FCM_SETUP.md`.

## Build & Release

Android APK:

```bash
flutter build apk --release
```

Android App Bundle:

```bash
flutter build appbundle --release
```

---

If you are handing this project over to a new team, this order works best:

1. Set up Flutter SDK.
2. Set up Firebase (apps + auth providers + SHA fingerprints).
3. Copy Firebase config files.
4. Run `flutter pub get` then `flutter run`.
