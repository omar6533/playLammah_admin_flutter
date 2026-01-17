import { initializeApp } from 'firebase/app';
import { getFirestore } from 'firebase/firestore';
import { getStorage } from 'firebase/storage';
import { getAuth } from 'firebase/auth';

const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY || "AIzaSyDCxMT_ouWkmcSNw015ANi-MwvsDryHqlE",
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN || "allmahgame.firebaseapp.com",
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID || "allmahgame",
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET || "allmahgame.firebasestorage.app",
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID || "564436165702",
  appId: import.meta.env.VITE_FIREBASE_APP_ID || "1:564436165702:web:e5835d1939d8122cab9647",
  measurementId: import.meta.env.VITE_FIREBASE_MEASUREMENT_ID || "G-STJQ93CRJL"
};

const app = initializeApp(firebaseConfig);

export const db = getFirestore(app);
export const storage = getStorage(app);
export const auth = getAuth(app);
export default app;
