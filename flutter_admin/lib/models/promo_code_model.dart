import 'package:cloud_firestore/cloud_firestore.dart';

class PromoCodeModel {
  /// Document id is the normalized (upper-case) code, so codes are unique.
  final String code;
  final int discountPercent;
  final bool isActive;
  final DateTime? expiresAt;
  final int? maxUses;
  final int usedCount;

  const PromoCodeModel({
    required this.code,
    required this.discountPercent,
    required this.isActive,
    this.expiresAt,
    this.maxUses,
    this.usedCount = 0,
  });

  static String normalize(String raw) => raw.trim().toUpperCase();

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isUsedUp => maxUses != null && usedCount >= maxUses!;

  factory PromoCodeModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return PromoCodeModel(
      code: doc.id,
      discountPercent: (d['discount_percent'] as num?)?.toInt() ?? 0,
      isActive: (d['is_active'] as bool?) ?? true,
      expiresAt: (d['expires_at'] as Timestamp?)?.toDate(),
      maxUses: (d['max_uses'] as num?)?.toInt(),
      usedCount: (d['used_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'code': code,
        'discount_percent': discountPercent,
        'is_active': isActive,
        'expires_at': expiresAt == null ? null : Timestamp.fromDate(expiresAt!),
        'max_uses': maxUses,
      };
}
