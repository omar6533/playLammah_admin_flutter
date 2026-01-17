# Complete Setup Guide for Allmah Admin Panel

## Step 1: Get Firebase Configuration

1. Visit [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **allmahgame**
3. Click the gear icon (⚙️) next to "Project Overview"
4. Select "Project settings"
5. Scroll down to "Your apps"
6. If you don't have a web app yet:
   - Click the Web icon (`</>`)
   - Register app with nickname: "Allmah Admin"
   - Click "Register app"
7. Copy the firebaseConfig values

You will get something like:
```javascript
const firebaseConfig = {
  apiKey: "AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
  authDomain: "allmahgame.firebaseapp.com",
  projectId: "allmahgame",
  storageBucket: "allmahgame.appspot.com",
  messagingSenderId: "123456789012",
  appId: "1:123456789012:web:abcdef123456"
};
```

## Step 2: Update Configuration Files

### File 1: `web/index.html`

Open `flutter_admin/web/index.html` and replace this section:

```javascript
const firebaseConfig = {
  apiKey: "YOUR_API_KEY",              // Replace with your actual apiKey
  authDomain: "allmahgame.firebaseapp.com",
  projectId: "allmahgame",
  storageBucket: "allmahgame.appspot.com",
  messagingSenderId: "YOUR_MESSAGING_SENDER_ID",  // Replace with your actual messagingSenderId
  appId: "YOUR_APP_ID"                 // Replace with your actual appId
};
```

### File 2: `lib/main.dart`

Open `flutter_admin/lib/main.dart` and replace this section:

```dart
await Firebase.initializeApp(
  options: const FirebaseOptions(
    apiKey: 'YOUR_API_KEY',              // Replace with your actual apiKey
    authDomain: 'allmahgame.firebaseapp.com',
    projectId: 'allmahgame',
    storageBucket: 'allmahgame.appspot.com',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',  // Replace with your actual messagingSenderId
    appId: 'YOUR_APP_ID',                // Replace with your actual appId
  ),
);
```

## Step 3: Enable Firebase Authentication

1. In Firebase Console, go to **Authentication**
2. Click "Get started" if you haven't set it up
3. Go to "Sign-in method" tab
4. Enable "Email/Password"
5. Click "Save"

## Step 4: Create Firestore Database

1. In Firebase Console, go to **Firestore Database**
2. Click "Create database"
3. Choose "Start in production mode"
4. Select a location (choose closest to your users)
5. Click "Enable"

## Step 5: Set Up Firestore Security Rules

1. In Firestore Database, click on "Rules" tab
2. Replace with these rules:

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

3. Click "Publish"

## Step 6: Create Admin User

1. In Firebase Console, go to **Authentication** > **Users** tab
2. Click "Add user"
3. Enter email and password (e.g., admin@allmahgame.com)
4. Click "Add user"

## Step 7: Install Flutter Dependencies

Navigate to the flutter_admin directory and run:

```bash
cd flutter_admin
flutter pub get
```

## Step 8: Run the Application

To run in development mode:

```bash
flutter run -d chrome
```

To build for production:

```bash
flutter build web --release
```

The production files will be in `build/web/` directory.

## Step 9: Deploy to Firebase Hosting (Optional)

1. Install Firebase CLI:
```bash
npm install -g firebase-tools
```

2. Login to Firebase:
```bash
firebase login
```

3. Initialize Firebase in your project:
```bash
firebase init hosting
```

Select:
- Use existing project: allmahgame
- Public directory: build/web
- Configure as single-page app: Yes
- Set up automatic builds: No

4. Deploy:
```bash
flutter build web --release
firebase deploy --only hosting
```

## Troubleshooting

### Issue: "Firebase not initialized"
- Make sure you've updated BOTH `web/index.html` AND `lib/main.dart` with correct Firebase config

### Issue: "Permission denied" when accessing Firestore
- Check that you've enabled Email/Password authentication
- Verify Firestore security rules are set correctly
- Make sure you're logged in

### Issue: "CORS error"
- This is normal in development. Use `flutter run -d chrome` instead of opening the HTML file directly

### Issue: Flutter command not found
- Make sure Flutter SDK is installed and added to PATH
- Download from: https://flutter.dev/docs/get-started/install

## Collections Structure

The app will automatically create these Firestore collections:

- **users**: User accounts and game statistics
- **categories**: Question categories
- **questions**: Quiz questions with options and answers
- **games**: Game sessions and results
- **payments**: Payment transactions

## Default Credentials

After creating your admin user in Firebase Authentication, use those credentials to log in.

Example:
- Email: admin@allmahgame.com
- Password: (whatever you set during Step 6)

## Support

For issues or questions, please check:
- Flutter documentation: https://flutter.dev/docs
- Firebase documentation: https://firebase.google.com/docs
- Flutter Web documentation: https://flutter.dev/web
