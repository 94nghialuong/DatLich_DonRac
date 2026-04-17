import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final String bookingId;
  final double amount;

  final String method;
  final String status;

  final Timestamp createdAt;

  PaymentModel({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.method,
    required this.status,
    required this.createdAt,
  });

  factory PaymentModel.fromDoc(String id, Map<String, dynamic> data) {
    return PaymentModel(
      id: id,
      bookingId: data["bookingId"] ?? "",
      amount: (data["amount"] ?? 0).toDouble(),
      method: data["method"] ?? "CASH",
      status: data["status"] ?? "PENDING",
      createdAt: data["createdAt"] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "bookingId": bookingId,
      "amount": amount,
      "method": method,
      "status": status,
      "createdAt": createdAt,
    };
  }
}
