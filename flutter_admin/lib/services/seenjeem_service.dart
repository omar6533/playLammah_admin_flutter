import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import '../models/main_category_model.dart';
import '../models/sub_category_model.dart';
import '../models/seenjeem_question_model.dart';
import '../models/user_model.dart';
import '../models/game_model.dart';
import '../models/payment_model.dart';

class SeenjeemService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<List<MainCategoryModel>> getMainCategories() {
    return _db
        .collection('main_categories')
        .orderBy('display_order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MainCategoryModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Future<String> addMainCategory(MainCategoryModel category) async {
    final docRef = await _db.collection('main_categories').add(category.toFirestore());
    return docRef.id;
  }

  Future<void> updateMainCategory(String id, MainCategoryModel category) async {
    await _db.collection('main_categories').doc(id).update(category.toFirestore());
  }

  Future<void> deleteMainCategory(String id) async {
    await _db.collection('main_categories').doc(id).delete();
  }

  Stream<List<SubCategoryModel>> getSubCategories({String? mainCategoryId}) {
    Query query = _db.collection('sub_categories').orderBy('display_order');

    if (mainCategoryId != null && mainCategoryId.isNotEmpty) {
      query = query.where('main_category_id', isEqualTo: mainCategoryId);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => SubCategoryModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  Future<String> addSubCategory(SubCategoryModel category) async {
    final docRef = await _db.collection('sub_categories').add(category.toFirestore());
    return docRef.id;
  }

  Future<void> updateSubCategory(String id, SubCategoryModel category) async {
    await _db.collection('sub_categories').doc(id).update(category.toFirestore());
  }

  Future<void> deleteSubCategory(String id) async {
    await _db.collection('sub_categories').doc(id).delete();
  }

  Stream<List<SeenjeemQuestionModel>> getQuestions({
    String? subCategoryId,
    int? points,
    String? status,
  }) {
    Query query = _db.collection('questions');

    if (subCategoryId != null && subCategoryId.isNotEmpty) {
      query = query.where('sub_category_id', isEqualTo: subCategoryId);
    }

    if (points != null) {
      query = query.where('points', isEqualTo: points);
    }

    if (status != null && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => SeenjeemQuestionModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  Future<String> addQuestion(SeenjeemQuestionModel question) async {
    final exists = await _db
        .collection('questions')
        .where('sub_category_id', isEqualTo: question.subCategoryId)
        .where('points', isEqualTo: question.points)
        .get();

    if (exists.docs.isNotEmpty) {
      throw Exception('A question with ${question.points} points already exists for this sub-category');
    }

    final docRef = await _db.collection('questions').add(question.toFirestore());
    return docRef.id;
  }

  Future<void> updateQuestion(String id, SeenjeemQuestionModel question) async {
    final exists = await _db
        .collection('questions')
        .where('sub_category_id', isEqualTo: question.subCategoryId)
        .where('points', isEqualTo: question.points)
        .get();

    if (exists.docs.isNotEmpty && exists.docs.first.id != id) {
      throw Exception('A question with ${question.points} points already exists for this sub-category');
    }

    await _db.collection('questions').doc(id).update(question.toFirestore());
  }

  Future<void> deleteQuestion(String id) async {
    await _db.collection('questions').doc(id).delete();
  }

  Future<String> uploadMedia(Uint8List fileBytes, String fileName, String folder) async {
    try {
      final ref = _storage.ref().child('$folder/$fileName');
      final uploadTask = await ref.putData(fileBytes);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload media: $e');
    }
  }

  Future<void> deleteMedia(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete media: $e');
    }
  }

  Stream<List<UserModel>> getUsers() {
    return _db.collection('users').snapshots().map((snapshot) => snapshot.docs
        .map((doc) => UserModel.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  Stream<List<GameModel>> getGames() {
    return _db.collection('games').orderBy('created_at', descending: true).snapshots().map((snapshot) => snapshot.docs
        .map((doc) => GameModel.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  Stream<List<PaymentModel>> getPayments() {
    return _db.collection('payments').orderBy('created_at', descending: true).snapshots().map((snapshot) => snapshot
        .docs
        .map((doc) => PaymentModel.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final futures = await Future.wait([
        _db.collection('main_categories').get().timeout(const Duration(seconds: 5)),
        _db.collection('sub_categories').get().timeout(const Duration(seconds: 5)),
        _db.collection('questions').get().timeout(const Duration(seconds: 5)),
        _db.collection('questions').where('status', isEqualTo: 'active').get().timeout(const Duration(seconds: 5)),
        _db.collection('users').get().timeout(const Duration(seconds: 5)),
        _db.collection('games').get().timeout(const Duration(seconds: 5)),
      ]);

      return {
        'totalMainCategories': futures[0].docs.length,
        'totalSubCategories': futures[1].docs.length,
        'totalQuestions': futures[2].docs.length,
        'activeQuestions': futures[3].docs.length,
        'totalUsers': futures[4].docs.length,
        'totalGames': futures[5].docs.length,
      };
    } catch (e) {
      return {
        'totalMainCategories': 0,
        'totalSubCategories': 0,
        'totalQuestions': 0,
        'activeQuestions': 0,
        'totalUsers': 0,
        'totalGames': 0,
      };
    }
  }
}
