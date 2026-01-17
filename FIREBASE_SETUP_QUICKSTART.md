# Firebase Setup Quickstart 🚀

## 1. Firebase Console Setup (5 minutes)

### Step 1: Create Firestore Database
1. Go to https://console.firebase.google.com
2. Select project: **allmahgame**
3. Click **Firestore Database** → **Create Database**
4. Choose **Production mode** → Select location → **Enable**

### Step 2: Add Security Rules
In Firestore → **Rules**, paste:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```
Click **Publish**

### Step 3: Create Collections
In Firestore → **Data**, create these collections by adding one test document to each:

**main_categories:**
```javascript
{
  name_ar: "اختبار",
  display_order: 0,
  is_active: true,
  status: "active",
  created_at: (Click "Add timestamp"),
  updated_at: (Click "Add timestamp")
}
```

**sub_categories:**
```javascript
{
  main_category_id: "(Copy ID from main_categories above)",
  name_ar: "اختبار فرعي",
  display_order: 0,
  is_active: true,
  media_url: "https://via.placeholder.com/150",
  created_at: (timestamp),
  updated_at: (timestamp)
}
```

**questions:**
```javascript
{
  sub_category_id: "(Copy ID from sub_categories above)",
  question_text_ar: "سؤال تجريبي؟",
  answer_text_ar: "جواب تجريبي",
  points: 200,
  status: "active",
  created_at: (timestamp),
  updated_at: (timestamp)
}
```

**users:**
```javascript
{
  email: "test@example.com",
  display_name: "Test User",
  created_at: (timestamp)
}
```

**games:**
```javascript
{
  status: "completed",
  created_at: (timestamp)
}
```

**game_players:**
```javascript
{
  game_id: "(any ID)",
  user_id: "(any ID)",
  player_name: "Player 1",
  score: 1000,
  position: 1
}
```

**payments:**
```javascript
{
  user_id: "(any ID)",
  amount: 29.99,
  currency: "SAR",
  status: "completed",
  payment_method: "credit_card",
  created_at: (timestamp)
}
```

### Step 4: Enable Firebase Storage
1. Click **Storage** → **Get Started**
2. Choose **Production mode** → Select same location → **Done**

### Step 5: Add Storage Rules
In Storage → **Rules**, paste:
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if true;
    }
  }
}
```
Click **Publish**

---

## 2. Run the App

```bash
npm install
npm run dev
```

Open http://localhost:5173

---

## ✅ Done!

Your admin panel is now connected to Firebase. You can:
- View dashboard with stats
- Create/edit main categories
- Create/edit sub categories (with required images)
- Create/edit questions (with optional images)
- Upload images to Firebase Storage
- Export/import via Excel

---

## 🔥 Firebase Project Info

- **Project ID:** allmahgame
- **API Key:** AIzaSyDCxMT_ouWkmcSNw015ANi-MwvsDryHqlE
- **Auth Domain:** allmahgame.firebaseapp.com
- **Storage Bucket:** allmahgame.firebasestorage.app

All credentials are already configured in `.env` file.

---

## Need More Details?

See `FIREBASE_MIGRATION_COMPLETE.md` for comprehensive documentation.
