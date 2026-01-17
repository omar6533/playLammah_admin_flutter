import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import '../models/user_model.dart';
import '../models/category_model.dart'; // Keeping this if old CategoryModel is still used elsewhere, but ideally should be replaced
import '../models/main_category_model.dart';
import '../models/sub_category_model.dart';
import '../models/seenjeem_question_model.dart';
import '../models/game_model.dart';
import '../models/payment_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<UserModel>> getUsers() {
    return _db.collection('users').snapshots().map((snapshot) => snapshot.docs
        .map((doc) => UserModel.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  Future<void> addUser(UserModel user) async {
    await _db.collection('users').add(user.toFirestore());
  }

  Future<void> updateUser(String id, UserModel user) async {
    await _db.collection('users').doc(id).update(user.toFirestore());
  }

  Future<void> deleteUser(String id) async {
    await _db.collection('users').doc(id).delete();
  }

  Stream<List<CategoryModel>> getCategories() {
    return _db.collection('categories').snapshots().map((snapshot) => snapshot
        .docs
        .map((doc) => CategoryModel.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  Future<void> addCategory(CategoryModel category) async {
    await _db.collection('categories').add(category.toFirestore());
  }

  Future<void> updateCategory(String id, CategoryModel category) async {
    await _db.collection('categories').doc(id).update(category.toFirestore());
  }

  Future<void> deleteCategory(String id) async {
    await _db.collection('categories').doc(id).delete();
  }

  // Old QuestionModel methods removed to use SeenjeemQuestionModel instead

  Stream<List<GameModel>> getGames() {
    return _db.collection('games').snapshots().map((snapshot) => snapshot.docs
        .map((doc) => GameModel.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  Future<void> addGame(GameModel game) async {
    await _db.collection('games').add(game.toFirestore());
  }

  Future<void> updateGame(String id, GameModel game) async {
    await _db.collection('games').doc(id).update(game.toFirestore());
  }

  Future<void> deleteGame(String id) async {
    await _db.collection('games').doc(id).delete();
  }

  Stream<List<PaymentModel>> getPayments() {
    return _db.collection('payments').snapshots().map((snapshot) => snapshot
        .docs
        .map((doc) => PaymentModel.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  Future<void> addPayment(PaymentModel payment) async {
    await _db.collection('payments').add(payment.toFirestore());
  }

  Future<void> updatePayment(String id, PaymentModel payment) async {
    await _db.collection('payments').doc(id).update(payment.toFirestore());
  }

  Future<void> deletePayment(String id) async {
    await _db.collection('payments').doc(id).delete();
  }

  Future<String> uploadMedia(
      List<int> bytes, String fileName, String folder) async {
    final ref = FirebaseStorage.instance.ref().child('$folder/$fileName');

    // Determine content type from file extension
    String? contentType;
    if (fileName.toLowerCase().endsWith('.jpg') ||
        fileName.toLowerCase().endsWith('.jpeg')) {
      contentType = 'image/jpeg';
    } else if (fileName.toLowerCase().endsWith('.png')) {
      contentType = 'image/png';
    } else if (fileName.toLowerCase().endsWith('.webp')) {
      contentType = 'image/webp';
    }

    final metadata = SettableMetadata(
      contentType: contentType,
      customMetadata: {'picked-file-path': fileName},
    );

    final uploadTask = ref.putData(Uint8List.fromList(bytes), metadata);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  // Main Categories
  Future<List<MainCategoryModel>> getMainCategories() async {
    final snapshot =
        await _db.collection('main_categories').orderBy('display_order').get();
    return snapshot.docs
        .map((doc) => MainCategoryModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Future<void> createMainCategory(Map<String, dynamic> data) async {
    try {
      await _db.collection('main_categories').add({
        ...data,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("failed in create cateogry" + '$e');
    }
  }

  Future<void> updateMainCategory(String id, Map<String, dynamic> data) async {
    await _db.collection('main_categories').doc(id).update({
      ...data,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMainCategory(String id) async {
    await _db.collection('main_categories').doc(id).delete();
  }

  // Sub Categories
  Future<List<SubCategoryModel>> getSubCategories(
      [String? mainCategoryId]) async {
    Query query = _db.collection('sub_categories').orderBy('display_order');
    if (mainCategoryId != null) {
      query = query.where('main_category_id', isEqualTo: mainCategoryId);
    }
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => SubCategoryModel.fromFirestore(
            doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<void> createSubCategory(Map<String, dynamic> data) async {
    await _db.collection('sub_categories').add({
      ...data,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateSubCategory(String id, Map<String, dynamic> data) async {
    await _db.collection('sub_categories').doc(id).update({
      ...data,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteSubCategory(String id) async {
    await _db.collection('sub_categories').doc(id).delete();
  }

  // Questions
  Future<List<SeenjeemQuestionModel>> getQuestions({
    String? mainCategoryId,
    String? subCategoryId,
    int? points,
    String? status,
    String? search,
  }) async {
    Query query = _db.collection('questions');

    if (subCategoryId != null) {
      query = query.where('sub_category_id', isEqualTo: subCategoryId);
    }
    if (points != null) {
      query = query.where('points', isEqualTo: points);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    // Note: Firestore doesn't support complex text search or multiple inequality filters natively easily on client side without extra setup
    // For now we will fetch and filter in memory if search is present, or for complex queries.
    // Ideally we'd use Algolia or similar, but for "admin panel" usage with moderate data, client side filter is okay.

    final snapshot = await query.get();
    var questions = snapshot.docs
        .map((doc) => SeenjeemQuestionModel.fromFirestore(
            doc.data() as Map<String, dynamic>, doc.id))
        .toList();

    if (search != null && search.isNotEmpty) {
      questions = questions
          .where((q) =>
              q.questionTextAr.contains(search) ||
              q.answerTextAr.contains(search))
          .toList();
    }

    return questions;
  }

  Future<void> createQuestion(Map<String, dynamic> data) async {
    await _db.collection('questions').add({
      ...data,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateQuestion(String id, Map<String, dynamic> data) async {
    await _db.collection('questions').doc(id).update({
      ...data,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteQuestion(String id) async {
    await _db.collection('questions').doc(id).delete();
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      // Use timeout for each query to prevent hanging
      final futures = await Future.wait([
        _db
            .collection('users')
            .count()
            .get()
            .timeout(const Duration(seconds: 5)),
        _db
            .collection('games')
            .count()
            .get()
            .timeout(const Duration(seconds: 5)),
        _db
            .collection('questions')
            .count()
            .get()
            .timeout(const Duration(seconds: 5)),
        _db.collection('payments').get().timeout(const Duration(seconds: 5)),
      ]);

      final usersCount = futures[0] as AggregateQuerySnapshot;
      final gamesCount = futures[1] as AggregateQuerySnapshot;
      final questionsCount = futures[2] as AggregateQuerySnapshot;
      final paymentsSnapshot = futures[3] as QuerySnapshot;

      double totalRevenue = 0.0;
      for (var doc in paymentsSnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          if (data['status'] == 'completed') {
            totalRevenue += (data['amount'] as num).toDouble();
          }
        } catch (e) {
          continue;
        }
      }

      return {
        'totalUsers': usersCount.count,
        'totalGames': gamesCount.count,
        'totalQuestions': questionsCount.count,
        'totalRevenue': totalRevenue,
      };
    } catch (e) {
      // Return zero values if there's an error
      return {
        'totalUsers': 0,
        'totalGames': 0,
        'totalQuestions': 0,
        'totalRevenue': 0.0,
      };
    }
  }
}
