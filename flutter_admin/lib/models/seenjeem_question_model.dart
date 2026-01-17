import 'package:cloud_firestore/cloud_firestore.dart';

class SeenjeemQuestionModel {
  final String id;
  final String subCategoryId;
  final String questionTextAr;
  final String answerTextAr;
  final String? questionMediaUrl;
  final String? answerMediaUrl;
  final int points;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  SeenjeemQuestionModel({
    required this.id,
    required this.subCategoryId,
    required this.questionTextAr,
    required this.answerTextAr,
    this.questionMediaUrl,
    this.answerMediaUrl,
    required this.points,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SeenjeemQuestionModel.fromFirestore(
      Map<String, dynamic> data, String id) {
    return SeenjeemQuestionModel(
      id: id,
      subCategoryId: data['sub_category_id'] ?? '',
      questionTextAr: data['question_text_ar'] ?? '',
      answerTextAr: data['answer_text_ar'] ?? '',
      questionMediaUrl: data['question_media_url'],
      answerMediaUrl: data['answer_media_url'],
      points: data['points'] ?? 200,
      status: data['status'] ?? 'active',
      createdAt: data['created_at'] is Timestamp
          ? (data['created_at'] as Timestamp).toDate()
          : data['created_at'] != null
              ? DateTime.parse(data['created_at'].toString())
              : DateTime.now(),
      updatedAt: data['updated_at'] is Timestamp
          ? (data['updated_at'] as Timestamp).toDate()
          : data['updated_at'] != null
              ? DateTime.parse(data['updated_at'].toString())
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sub_category_id': subCategoryId,
      'question_text_ar': questionTextAr,
      'answer_text_ar': answerTextAr,
      'question_media_url': questionMediaUrl,
      'answer_media_url': answerMediaUrl,
      'points': points,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
