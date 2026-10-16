import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game_package_model.dart';
import '../models/promo_code_model.dart';

/// Game packages and promo codes read by the customer app's purchase dialog.
class StoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _packages => _db.collection('packages');
  CollectionReference<Map<String, dynamic>> get _promos => _db.collection('promo_codes');

  Stream<List<GamePackageModel>> watchPackages() => _packages
      .orderBy('display_order')
      .snapshots()
      .map((s) => s.docs.map(GamePackageModel.fromFirestore).toList());

  Future<void> savePackage(GamePackageModel pkg) async {
    final data = {...pkg.toFirestore(), 'updated_at': FieldValue.serverTimestamp()};
    if (pkg.id.isEmpty) {
      await _packages.add({...data, 'created_at': FieldValue.serverTimestamp()});
    } else {
      await _packages.doc(pkg.id).update(data);
    }
  }

  Future<void> deletePackage(String id) => _packages.doc(id).delete();

  Stream<List<PromoCodeModel>> watchPromoCodes() => _promos
      .orderBy('created_at', descending: true)
      .snapshots()
      .map((s) => s.docs.map(PromoCodeModel.fromFirestore).toList());

  Future<bool> promoCodeExists(String code) async => (await _promos.doc(code).get()).exists;

  Future<void> createPromoCode(PromoCodeModel promo) => _promos.doc(promo.code).set({
        ...promo.toFirestore(),
        'used_count': 0,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

  Future<void> updatePromoCode(PromoCodeModel promo) => _promos.doc(promo.code).update({
        ...promo.toFirestore(),
        'updated_at': FieldValue.serverTimestamp(),
      });

  Future<void> deletePromoCode(String code) => _promos.doc(code).delete();
}
