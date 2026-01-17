import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final String userId;
  final double amount;
  final String status;
  final String type;
  final DateTime createdAt;

  PaymentModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.status,
    required this.type,
    required this.createdAt,
  });

  factory PaymentModel.fromFirestore(Map<String, dynamic> data, String id) {
    double amountValue = 0.0;
    if (data['amount'] != null) {
      if (data['amount'] is double) {
        amountValue = data['amount'];
      } else if (data['amount'] is num) {
        amountValue = data['amount'].toDouble();
      }
    }

    return PaymentModel(
      id: id,
      userId: data['userId'] ?? '',
      amount: amountValue,
      status: data['status'] ?? 'pending',
      type: data['type'] ?? 'withdrawal',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : data['createdAt'] != null
              ? DateTime.parse(data['createdAt'].toString())
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'amount': amount,
      'status': status,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
