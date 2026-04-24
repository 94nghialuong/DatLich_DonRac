import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TaskProvider extends ChangeNotifier {
  int taskCount = 0;
  bool _initialized = false;

  StreamSubscription? _sub;

  void listenTasks(String employeeId) {
    _sub?.cancel();

    _sub = FirebaseFirestore.instance
        .collection("tasks")
        .where("employeeId", isEqualTo: employeeId)
        .snapshots()
        .listen(
          (snapshot) {
            // 🔥 tránh flicker khi chưa init
            taskCount = snapshot.docs.length;
            _initialized = true;
            notifyListeners();
          },
          onError: (error) {
            debugPrint("Task stream error: $error");
          },
        );
  }

  bool get isReady => _initialized;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
