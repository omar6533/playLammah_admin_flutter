# Flutter Admin Panel - Local Setup Guide

## 📦 What You Have

The `flutter_admin_package.zip` contains a complete Flutter web admin panel for managing:
- Users
- Games
- Questions & Categories
- Payments
- Settings & Analytics

## 🚀 Quick Start

### 1. Prerequisites
- Flutter SDK (latest stable version)
- Chrome browser (for web)
- Firebase account (free tier works)

### 2. Install Flutter

**macOS/Linux:**
```bash
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"
flutter doctor
```

**Windows:**
Download from: https://flutter.dev/docs/get-started/install/windows

### 3. Extract & Setup

```bash
# Extract the ZIP
unzip flutter_admin_package.zip
cd flutter_admin

# Install dependencies
flutter pub get
```

### 4. Configure Firebase

1. Go to https://console.firebase.google.com
2. Create a new project
3. Enable **Authentication** > Email/Password
4. Create **Firestore Database** (start in production mode)
5. Go to Project Settings > General
6. Scroll to "Your apps" > Add Web app
7. Copy the Firebase configuration

### 5. Update Configuration

**Edit `lib/main.dart`** (lines 10-18):
```dart
await Firebase.initializeApp(
  options: const FirebaseOptions(
    apiKey: "YOUR_API_KEY",
    authDomain: "YOUR_PROJECT.firebaseapp.com",
    projectId: "YOUR_PROJECT_ID",
    storageBucket: "YOUR_PROJECT.appspot.com",
    messagingSenderId: "YOUR_SENDER_ID",
    appId: "YOUR_APP_ID",
  ),
);
```

**Edit `web/index.html`** (around line 40):
```javascript
const firebaseConfig = {
  apiKey: "YOUR_API_KEY",
  authDomain: "YOUR_PROJECT.firebaseapp.com",
  projectId: "YOUR_PROJECT_ID",
  storageBucket: "YOUR_PROJECT.appspot.com",
  messagingSenderId: "YOUR_SENDER_ID",
  appId: "YOUR_APP_ID"
};
```

### 6. Run the App

```bash
# For web (recommended)
flutter run -d chrome

# Or build for production
flutter build web
```

### 7. Create Admin Account

On first run, you'll see the login page. Click "Don't have an account? Sign up" to create your admin account.

## 📊 Firebase Firestore Collections

The app will automatically create these collections:
- `users` - User accounts
- `games` - Game sessions
- `questions` - Quiz questions
- `categories` - Question categories
- `payments` - Payment transactions

## 🔥 Features

- ✅ Excel import/export for questions
- ✅ Real-time data sync
- ✅ User management
- ✅ Game analytics
- ✅ Payment tracking
- ✅ Category management
- ✅ Responsive design

## 🛠 Troubleshooting

**"Flutter command not found"**
- Make sure Flutter is added to your PATH
- Run `flutter doctor` to verify installation

**"Firebase not configured"**
- Double-check your Firebase credentials in both files
- Ensure Firestore and Authentication are enabled

**Build errors**
- Run `flutter clean` then `flutter pub get`
- Make sure you're using Flutter 3.0 or higher

## 📱 Running on Other Platforms

**Desktop (Windows/macOS/Linux):**
```bash
flutter run -d windows  # or macos/linux
```

**Mobile (requires emulator/device):**
```bash
flutter run -d <device-name>
```

## 🔐 Security Notes

- Change default Firebase rules in production
- Enable Firebase App Check for security
- Use environment variables for sensitive data
- Implement proper admin role verification

## 📚 Additional Resources

- Flutter Docs: https://flutter.dev/docs
- Firebase Docs: https://firebase.google.com/docs
- Flutter Web: https://flutter.dev/web

## Need Help?

Check the `SETUP_GUIDE.md` inside the flutter_admin folder for more detailed information.

---

**Package created:** January 11, 2026
**Flutter Version Required:** 3.0+
**Platform:** Web, Desktop, Mobile
