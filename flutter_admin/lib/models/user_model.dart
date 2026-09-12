import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String mobile;
  final int trialsRemaining;
  final int availableGames;
  final String createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.mobile,
    required this.trialsRemaining,
    required this.availableGames,
    required this.createdAt,
  });

  int get totalBalance => trialsRemaining + availableGames;

  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      mobile: data['mobile'] as String? ?? '',
      trialsRemaining: _toInt(data['trials_remaining']),
      availableGames: _toInt(data['available_games']),
      createdAt: _toDateString(data['created_at'] ?? data['createdAt']),
    );
  }

  static String _toDateString(dynamic v) {
    if (v == null) return '';
    if (v is String) return v;
    if (v is Timestamp) return v.toDate().toIso8601String();
    return v.toString();
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'mobile': mobile,
      'trials_remaining': trialsRemaining,
      'available_games': availableGames,
      'created_at': createdAt,
    };
  }
}
