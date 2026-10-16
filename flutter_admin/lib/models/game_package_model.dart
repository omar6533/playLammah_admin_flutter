import 'package:cloud_firestore/cloud_firestore.dart';

class GamePackageModel {
  final String id;
  final String titleAr;
  final int gamesCount;
  final double priceSar;
  final String color;
  final bool isActive;
  final int displayOrder;

  const GamePackageModel({
    required this.id,
    required this.titleAr,
    required this.gamesCount,
    required this.priceSar,
    required this.color,
    required this.isActive,
    required this.displayOrder,
  });

  factory GamePackageModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return GamePackageModel(
      id: doc.id,
      titleAr: (d['title_ar'] as String?) ?? '',
      gamesCount: (d['games_count'] as num?)?.toInt() ?? 0,
      priceSar: (d['price_sar'] as num?)?.toDouble() ?? 0,
      color: (d['color'] as String?) ?? '#D64453',
      isActive: (d['is_active'] as bool?) ?? true,
      displayOrder: (d['display_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title_ar': titleAr,
        'games_count': gamesCount,
        'price_sar': priceSar,
        'color': color,
        'is_active': isActive,
        'display_order': displayOrder,
      };
}
