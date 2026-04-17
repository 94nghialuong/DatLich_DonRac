import 'package:cloud_firestore/cloud_firestore.dart';

class TaskService {
  final db = FirebaseFirestore.instance;

  Future<void> startTask(String bookingId) async {
    final now = Timestamp.now();

    final taskQuery = await db
        .collection("tasks")
        .where("bookingId", isEqualTo: bookingId)
        .get();

    final taskId = taskQuery.docs.first.id;

    await db.collection("tasks").doc(taskId).update({
      "status": "IN_PROGRESS",
      "startTime": now,
    });

    await db.collection("bookings").doc(bookingId).update({
      "status": "IN_PROGRESS",
    });
  }

  Future<void> completeTask(String bookingId) async {
    final now = Timestamp.now();

    final taskQuery = await db
        .collection("tasks")
        .where("bookingId", isEqualTo: bookingId)
        .get();

    final taskId = taskQuery.docs.first.id;

    await db.collection("tasks").doc(taskId).update({
      "status": "COMPLETED",
      "endTime": now,
    });
  }
}
