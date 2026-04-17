import 'package:cloud_firestore/cloud_firestore.dart';

class BookingHistoryModel {
  final String id;
  final String bookingId;
  final String changedBy;
  final Timestamp createdAt;
  final String oldStatus;
  final String newStatus;

  BookingHistoryModel({
    required this.id,
    required this.bookingId,
    required this.changedBy,
    required this.createdAt,
    required this.oldStatus,
    required this.newStatus,
  });

  factory BookingHistoryModel.fromDoc(String id, Map<String, dynamic> data) {
    return BookingHistoryModel(
      id: id,
      bookingId: data["bookingId"] ?? "",
      changedBy: data["changedBy"] ?? "",
      createdAt: data["createdAt"] ?? Timestamp.now(),
      oldStatus: data["oldStatus"] ?? "",
      newStatus: data["newStatus"] ?? "",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "bookingId": bookingId,
      "changedBy": changedBy,
      "createdAt": createdAt,
      "oldStatus": oldStatus,
      "newStatus": newStatus,
    };
  }
}
