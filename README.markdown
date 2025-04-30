# RemMe --> DementiaCareApp

A Flutter-based mobile application designed to support dementia patients and their guardians. The app provides features such as live patient tracking, danger zone alerts, routine management, memory quizzes, and a medical AI chatbot to assist patients and guardians in managing daily care and monitoring.

## Features

- **Guardian Dashboard**: Allows guardians to monitor patients, set up danger zones, view patient progress, manage routines, and receive alerts.
- **Patient Dashboard**: Enables patients to access memory quizzes, manage routines, upload memories with images and voice recordings, and interact with a medical AI chatbot.
- **Live Tracking**: Real-time location tracking for patients using geolocation.
- **Danger Zones**: Setup and alerts for predefined geographic areas to ensure patient safety.
- **Routine Management**: Create, edit, and track daily routines for patients.
- **Memory Quiz Game**: Engages patients with quizzes based on their uploaded memories to enhance cognitive function.
- **Firebase Integration**: Uses Firestore for data storage, Firebase Authentication for user management, and Firebase Storage for image uploads.

## Prerequisites

Before running the app, ensure you have the following installed:

- **Flutter**: Version 3.24.3 or later (stable channel). [Install Flutter](https://flutter.dev/docs/get-started/install)
- **Dart**: Included with Flutter.
- **IDE**: Android Studio, VS Code, or any IDE with Flutter support.
- **Firebase Account**: For authentication, Firestore, and storage. [Set up Firebase](https://firebase.google.com/)
- **Android Emulator/Device** or **iOS Simulator/Device**: For testing the app.
- **Node.js** (optional): For web deployment.
- **Git**: To clone the repository.

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/ADURITEJA/RemMe_App_access.git
cd DementiaCareApp
```

Replace `ADURITEJA` with your GitHub username.

### 2. Install Dependencies

Ensure Flutter is installed and run the following to install the required packages:

```bash
flutter pub get
```

This installs dependencies listed in `pubspec.yaml`, including `firebase_core`, `cloud_firestore`, `firebase_auth`, `firebase_storage`, `geolocator`, `google_maps_flutter`, `fl_chart`, `image_picker`, `speech_to_text`, and others.

### 3. Configure Firebase

1. **Create a Firebase Project**:
   - Go to the [Firebase Console](https://console.firebase.google.com/).
   - Create a new project named "DementiaCareApp".
   - Enable Authentication (Email/Password provider), Firestore, and Storage.

2. **Add Firebase to the App**:
   - For **Android**:
     - Register your app in Firebase with the package name `com.example.dementia_app`.
     - Download `google-services.json` and place it in `android/app/`.
   - For **iOS**:
     - Register your app with the bundle ID `com.example.dementia_app`.
     - Download `GoogleService-Info.plist` and place it in `ios/Runner/`.
   - For **Web** (optional):
     - Register a web app in Firebase and copy the Firebase configuration (apiKey, authDomain, etc.).
     - Update `web/index.html` with the Firebase config (if not already included).

3. **Enable Firebase Services**:
   - In Firestore, create collections for `patients`, `guardians`, and subcollections (`memories`, `scores`, `routines`).
   - In Storage, set rules to allow authenticated users to upload images.
   - In Authentication, enable Email/Password sign-in.

4. **Update Firebase Rules**:
   - Firestore rules:
     ```firestore
     rules_version = '2';
     service cloud.firestore {
       match /databases/{database}/documents {
         match /patients/{patientId} {
           allow read, write: if request.auth != null && request.auth.uid == patientId;
           match /{subcollection=**} {
             allow read, write: if request.auth != null && request.auth.uid == patientId;
           }
         }
         match /guardians/{guardianId} {
           allow read, write: if request.auth != null && request.auth.uid == guardianId;
         }
       }
     }
     ```
   - Storage rules:
     ```storage
     rules_version = '2';
     service firebase.storage {
       match /b/{bucket}/o {
         match /memories/{userId}/{allPaths=**} {
           allow read, write: if request.auth != null && request.auth.uid == userId;
         }
       }
     }
     ```

### 4. Configure Permissions

Ensure the following permissions are set in the app:

- **Android** (`android/app/src/main/AndroidManifest.xml`):
  ```xml
  <uses-permission android:name="android.permission.INTERNET"/>
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
  <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
  <uses-permission android:name="android.permission.CAMERA"/>
  <uses-permission android:name="android.permission.RECORD_AUDIO"/>
  ```

- **iOS** (`ios/Runner/Info.plist`):
  ```xml
  <key>NSLocationWhenInUseUsageDescription</key>
  <string>Used for live tracking of patients.</string>
  <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
  <string>Used for live tracking of patients.</string>
  <key>NSCameraUsageDescription</key>
  <string>Used to capture images for memories.</string>
  <key>NSMicrophoneUsageDescription</key>
  <string>Used for voice recording in memories.</string>
  ```

### 5. Run the App

1. **Start an Emulator/Simulator or Connect a Device**:
   - Android: Use Android Studio to start an emulator or connect a physical device with USB debugging enabled.
   - iOS: Use Xcode to start a simulator or connect an iOS device.
   - Web: Ensure Chrome is installed.

2. **Run the App**:
   - For Android/iOS:
     ```bash
     flutter run
     ```
   - For Web:
     ```bash
     flutter run -d chrome
     ```

   If you encounter issues, ensure the correct device is selected (`flutter devices`) and Firebase is properly configured.

3. **Build for Release** (optional):
   - Android APK:
     ```bash
     flutter build apk --release
     ```
   - iOS IPA:
     ```bash
     flutter build ios --release
     ```
   - Web:
     ```bash
     flutter build web
     ```

### 6. Testing the App

- **Guardian Login**:
  - Register as a guardian using an email and password.
  - Add a patient, set up danger zones, track live location, manage routines, and monitor progress.
- **Patient Login**:
  - Register as a patient using an email and password.
  - Upload memories, play the memory quiz, manage routines, and interact with the chatbot.
- **Firebase Emulator** (optional):
  - Use the Firebase Emulator Suite for local testing:
    ```bash
    firebase emulators:start
    ```
  - Update `main.dart` to connect to the emulator if needed.

## Troubleshooting

- **Firebase Errors**:
  - Ensure `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) is correctly placed.
  - Verify Firebase rules allow authenticated access.
- **Location Issues**:
  - Grant location permissions on the device.
  - Ensure Google Maps API is enabled in Firebase for live tracking.
- **Dependency Issues**:
  - Run `flutter clean` and `flutter pub get` if dependencies fail to resolve.
- **Platform-Specific Issues**:
  - For iOS, ensure you have a valid provisioning profile in Xcode.
  - For Android, check the `minSdkVersion` in `android/app/build.gradle` (recommended: 21).

## Contributing

Contributions are welcome! Please follow these steps:
1. Fork the repository.
2. Create a new branch (`git checkout -b feature/your-feature`).
3. Commit your changes (`git commit -m 'Add your feature'`).
4. Push to the branch (`git push origin feature/your-feature`).
5. Open a Pull Request.

## Contact

For questions or support, please open an issue on GitHub or contact [teja10aduri@gmail.com](mailto:teja10aduri@gmail.com).
