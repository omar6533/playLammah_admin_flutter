# Allmah Admin Panel - Flutter Web with Firebase

A complete admin panel built with Flutter Web and Firebase backend.

## Features

- User Management
- Game Management
- Category Management
- Question Management (with Excel import/export)
- Payment Management
- Dashboard with Statistics
- Firebase Authentication
- Cloud Firestore Database
- Responsive Design

## Prerequisites

- Flutter SDK (>=3.0.0)
- Firebase Project (Project ID: allmahgame)
- Web browser

## Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: allmahgame
3. Go to Project Settings > General
4. Scroll down to "Your apps" section
5. Click on the Web app (</> icon)
6. Copy your Firebase configuration

## Installation

1. Update Firebase configuration in two places:

   **File 1: `web/index.html`**
   ```javascript
   const firebaseConfig = {
     apiKey: "YOUR_API_KEY",
     authDomain: "allmahgame.firebaseapp.com",
     projectId: "allmahgame",
     storageBucket: "allmahgame.appspot.com",
     messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
     appId: "YOUR_APP_ID"
   };
   ```

   **File 2: `lib/main.dart`**
   ```dart
   await Firebase.initializeApp(
     options: const FirebaseOptions(
       apiKey: 'YOUR_API_KEY',
       authDomain: 'allmahgame.firebaseapp.com',
       projectId: 'allmahgame',
       storageBucket: 'allmahgame.appspot.com',
       messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
       appId: 'YOUR_APP_ID',
     ),
   );
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application:
   ```bash
   flutter run -d chrome
   ```

## Building for Production

```bash
flutter build web --release
```

The built files will be in `build/web/` directory.

## Firebase Authentication Setup

1. Go to Firebase Console > Authentication
2. Enable Email/Password sign-in method
3. Add your first admin user

## Firestore Database Setup

1. Go to Firebase Console > Firestore Database
2. Create database in production mode
3. Update security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── user_model.dart
│   ├── category_model.dart
│   ├── question_model.dart
│   ├── game_model.dart
│   └── payment_model.dart
├── services/                 # Business logic
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   └── excel_service.dart
├── widgets/                  # Reusable components
│   ├── sidebar.dart
│   ├── stat_card.dart
│   ├── custom_button.dart
│   ├── custom_data_table.dart
│   └── custom_text_field.dart
└── pages/                    # App pages
    ├── login_page.dart
    ├── home_page.dart
    ├── dashboard_page.dart
    ├── users_page.dart
    ├── games_page.dart
    ├── categories_page.dart
    ├── questions_page.dart
    ├── payments_page.dart
    └── settings_page.dart
```

## Excel Import Format

For importing questions via Excel, use this format:

| Category ID | Question | Option 1 | Option 2 | Option 3 | Option 4 | Correct Answer | Difficulty |
|-------------|----------|----------|----------|----------|----------|----------------|------------|
| cat1        | Q?       | A        | B        | C        | D        | 0              | easy       |

- Correct Answer: 0-3 (index of correct option)
- Difficulty: easy, medium, hard

## License

MIT License
