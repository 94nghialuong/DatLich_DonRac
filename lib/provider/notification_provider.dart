import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationProvider extends ChangeNotifier {
  List<DocumentSnapshot> notifications = [];
  int unreadCount = 0;

  StreamSubscription? _sub;

  void listenNotifications({required String userId, required String role}) {
    _sub?.cancel();

    Query query = FirebaseFirestore.instance
        .collection("notifications")
        .orderBy("createdAt", descending: true);

    // 👤 USER
    if (role.toLowerCase() == "user") {
      query = query
          .where("target", isEqualTo: "USER")
          .where("userId", isEqualTo: userId);
    }
    // 👷 STAFF
    else if (role.toLowerCase() == "staff") {
      query = query
          .where("target", isEqualTo: "STAFF")
          .where("employeeId", isEqualTo: userId);
    }

    _sub = query.snapshots().listen((snapshot) {
      notifications = snapshot.docs;

      unreadCount = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return (data["isRead"] ?? false) == false;
      }).length;

      notifyListeners();
    });
  }

  Future<void> markAsRead(String id) async {
    await FirebaseFirestore.instance.collection("notifications").doc(id).update(
      {"isRead": true},
    );
  }

  Future<void> markAllAsRead() async {
    for (var doc in notifications) {
      final data = doc.data() as Map<String, dynamic>;
      if ((data["isRead"] ?? false) == false) {
        await doc.reference.update({"isRead": true});
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
