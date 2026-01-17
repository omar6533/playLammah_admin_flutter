import 'package:cloud_firestore/cloud_firestore.dart';

class SubCategoryModel {
  final String id;
  final String mainCategoryId;
  final String nameAr;
  final String mediaUrl;
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubCategoryModel({
    required this.id,
    required this.mainCategoryId,
    required this.nameAr,
    required this.mediaUrl,
    required this.displayOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubCategoryModel.fromFirestore(Map<String, dynamic> data, String id) {
    return SubCategoryModel(
      id: id,
      mainCategoryId: data['main_category_id'] ?? '',
      nameAr: data['name_ar'] ?? '',
      mediaUrl: data['media_url'] ?? '',
      displayOrder: data['display_order'] ?? 0,
      isActive: data['is_active'] ?? true,
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
      'main_category_id': mainCategoryId,
      'name_ar': nameAr,
      'media_url': mediaUrl,
      'display_order': displayOrder,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
