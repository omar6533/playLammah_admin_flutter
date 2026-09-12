import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential?> signUp(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Returns the role of the given uid from admin_portal_users.
  // If no record exists (first-ever admin login), bootstraps a record with role='admin'.
  Future<String> getOrInitUserRole(String uid, String email) async {
    final doc = await _db.collection('admin_portal_users').doc(uid).get();
    if (!doc.exists || doc.data()?['role'] == null) {
      await _db.collection('admin_portal_users').doc(uid).set({
        'uid': uid,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'system',
        'role': 'admin',
      }, SetOptions(merge: true));
      return 'admin';
    }
    return (doc.data()!['role'] as String?) ?? 'admin';
  }

  // Creates a new admin portal user without touching the current admin session.
  // Uses a uniquely-named secondary Firebase App to avoid DuplicateApp errors.
  // Saves user record to Firestore so we can list them later.
  Future<void> createAdminUser(String email, String password, String role) async {
    final appName = '_admin_create_${DateTime.now().millisecondsSinceEpoch}';
    FirebaseApp? secondary;
    String? newUid;

    try {
      secondary = await Firebase.initializeApp(
        name: appName,
        options: Firebase.app().options,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondary);
      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      newUid = cred.user?.uid;
      await secondaryAuth.signOut();
    } finally {
      await secondary?.delete();
    }

    if (newUid != null) {
      await _db.collection('admin_portal_users').doc(newUid).set({
        'uid': newUid,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _auth.currentUser?.email ?? '',
        'role': role,
      });
    }
  }

  // Change the currently signed-in admin's own password.
  // Throws FirebaseAuthException with code 'requires-recent-login' if
  // the session is too old — caller should re-authenticate then retry.
  Future<void> changeOwnPassword(String newPassword) async {
    await _auth.currentUser!.updatePassword(newPassword);
  }

  Stream<List<Map<String, dynamic>>> getAdminUsers() {
    return _db
        .collection('admin_portal_users')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }
}
