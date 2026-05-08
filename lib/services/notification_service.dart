import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final db = FirebaseFirestore.instance;

  Future<void> create({
    required String title,
    required String content,
    required String type,
    required String target,

    String? userId,
    String? employeeId,
    String? bookingId,
    String? roomId,
  }) async {
    await db.collection("notifications").add({
      "title": title,
      "content": content,
      "type": type,

      "target": target,

      "userId": userId,
      "employeeId": employeeId,

      "bookingId": bookingId,
      "roomId": roomId,

      "isRead": false,

      "createdAt": Timestamp.now(),
    });
  }
}
