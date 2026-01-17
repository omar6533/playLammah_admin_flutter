import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final int gamesPlayed;
  final int totalWinnings;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.gamesPlayed = 0,
    this.totalWinnings = 0,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'user',
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : data['createdAt'] != null
              ? DateTime.parse(data['createdAt'].toString())
              : DateTime.now(),
      gamesPlayed: (data['gamesPlayed'] is int)
          ? data['gamesPlayed']
          : (data['gamesPlayed'] is num)
              ? data['gamesPlayed'].toInt()
              : 0,
      totalWinnings: (data['totalWinnings'] is int)
          ? data['totalWinnings']
          : (data['totalWinnings'] is num)
              ? data['totalWinnings'].toInt()
              : 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'gamesPlayed': gamesPlayed,
      'totalWinnings': totalWinnings,
    };
  }
}
