import 'package:cloud_firestore/cloud_firestore.dart';

class TaskService {
  final db = FirebaseFirestore.instance;

  // ===============================
  // ▶ START TASK
  // ===============================
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

  // ===============================
  // 💰 COMPLETE + AUTO PAYMENT
  // ===============================
  Future<void> completeTask(String bookingId) async {
    final now = Timestamp.now();

    final taskQuery = await db
        .collection("tasks")
        .where("bookingId", isEqualTo: bookingId)
        .get();

    final taskId = taskQuery.docs.first.id;

    // =========================
    // 1. UPDATE TASK
    // =========================
    await db.collection("tasks").doc(taskId).update({
      "status": "COMPLETED",
      "endTime": now,
    });

    // =========================
    // 2. UPDATE BOOKING
    // =========================
    await db.collection("bookings").doc(bookingId).update({"status": "DONE"});

    // =========================
    // 3. AUTO CREATE PAYMENT
    // =========================
    await db.collection("payments").add({
      "bookingId": bookingId,
      "amount": await _calculateAmount(bookingId),
      "status": "PENDING",
      "createdAt": now,
    });

    print("💰 PAYMENT AUTO CREATED");
  }

  // ===============================
  // 💵 CALCULATE PRICE
  // ===============================
  Future<double> _calculateAmount(String bookingId) async {
    final doc = await db.collection("bookings").doc(bookingId).get();

    final price = doc.data()?["price"] ?? 0;

    return price.toDouble();
  }
}
