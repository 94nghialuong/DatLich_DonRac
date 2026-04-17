import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String bookingId;
  final String userId;
  final String employeeId;

  final String comment;
  final int rating;
  final Timestamp createdAt;

  ReviewModel({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.employeeId,
    required this.comment,
    required this.rating,
    required this.createdAt,
  });

  factory ReviewModel.fromDoc(String id, Map<String, dynamic> data) {
    return ReviewModel(
      id: id,
      bookingId: data["bookingId"] ?? "",
      userId: data["userId"] ?? "",
      employeeId: data["employeeId"] ?? "",
      comment: data["comment"] ?? "",
      rating: (data["rating"] ?? 0) as int,
      createdAt: data["createdAt"] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "bookingId": bookingId,
      "userId": userId,
      "employeeId": employeeId,
      "comment": comment,
      "rating": rating,
      "createdAt": createdAt,
    };
  }
}
