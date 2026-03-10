# Todo App

A Flutter To‑Do list application with Firebase Authentication and Realtime Database integration via REST API.

## Setup

1. **Configure Firebase**
   - Create a Firebase project at https://console.firebase.google.com
   - Enable Email/Password authentication (Authentication → Sign-in method).
   - Create a Realtime Database (start in test mode for development).
   - Copy your **Web API Key** and database URL. In `lib/main.dart` replace:
     ```dart
     const firebaseApiKey = 'YOUR_FIREBASE_API_KEY';
     const firebaseDatabaseUrl = 'https://<your-project>.firebaseio.com';
     ```
   - (Optional) Enable Google sign‑in or other providers and extend the UI.

2. **Install dependencies**
   ```bash
   cd todo_app
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

4. **Build APK**
   ```bash
   flutter build apk --release
   ```
   APK will be located at `build/app/outputs/flutter-apk/app-release.apk`.

## Features

- Email/password sign‑up & login using Firebase Auth REST API
- Task management: view, add, edit state, delete
- Firebase Realtime Database (REST) under `/tasks/<userId>`
- Provider for auth and todo state management
- Responsive layout adaptable to different screen sizes

## Testing

Simple widget test verifying authentication screen is shown:

```bash
flutter test
```

## GitHub Submission

- Initialize a git repository in the `todo_app` folder, commit all files,
  and push to your GitHub account.
- Share the repo link as required.

---

Feel free to extend the app with offline persistence, Google sign‑in,
or task editing features. Good luck!

