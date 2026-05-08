import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationProvider extends ChangeNotifier {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  List<DocumentSnapshot> notifications = [];

  int unreadCount = 0;

  // ================= REALTIME LISTENER =================
  void listenNotifications({required String userId, required String role}) {
    role = role.toUpperCase();
    Query query;

    // ================= STAFF =================
    if (role == "STAFF") {
      query = db
          .collection("notifications")
          .where("employeeId", isEqualTo: userId);
    }
    // ================= USER =================
    else {
      query = db
          .collection("notifications")
          .where("userId", isEqualTo: userId)
          .orderBy("createdAt", descending: true);
    }

    query.snapshots().listen((snapshot) {
      notifications = snapshot.docs;

      unreadCount = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;

        return (data["isRead"] ?? false) == false;
      }).length;
      // ================= DEBUG =================
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
      }

      notifyListeners();
    });
  }

  // ================= MARK AS READ =================
  Future<void> markAsRead(String notificationId) async {
    try {
      await db.collection("notifications").doc(notificationId).update({
        "isRead": true,
      });

      debugPrint("✅ MARK READ: $notificationId");
    } catch (e) {
      debugPrint("❌ MARK READ ERROR: $e");
    }
  }

  // ================= MARK ALL =================
  Future<void> markAllAsRead() async {
    try {
      final unread = notifications.where((doc) {
        final data = doc.data() as Map<String, dynamic>;

        return (data["isRead"] ?? false) == false;
      }).toList();

      for (var doc in unread) {
        await db.collection("notifications").doc(doc.id).update({
          "isRead": true,
        });
      }

      debugPrint("✅ MARK ALL AS READ");
    } catch (e) {
      debugPrint("❌ MARK ALL ERROR: $e");
    }
  }

  // ================= CLEAR =================
  void clear() {
    notifications.clear();
    unreadCount = 0;

    notifyListeners();
  }
}
