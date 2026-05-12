import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TaskProvider extends ChangeNotifier {
  int taskCount = 0;
  bool _initialized = false;

  StreamSubscription<QuerySnapshot>? _sub;

  void listenTasks(String employeeId) {
    _sub?.cancel();

    _sub = FirebaseFirestore.instance
        .collection("tasks")
        .where("employeeId", isEqualTo: employeeId)
        .where("status", whereIn: ["ASSIGNED", "IN_PROGRESS"])
        .snapshots()
        .listen(
          (snapshot) {
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

  void clear() {
    _sub?.cancel();
    _sub = null;
    taskCount = 0;
    _initialized = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
