import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final CollectionReference notifications = FirebaseFirestore.instance
      .collection("notifications");

  Future<void> sendNotification(Map<String, dynamic> data) async {
    await notifications.add(data);
  }

  Stream<QuerySnapshot> getUserNotifications(String userId) {
    return notifications
        .where("userId", isEqualTo: userId)
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  Future<void> markAsRead(String id) async {
    await notifications.doc(id).update({"isRead": true});
  }
}
