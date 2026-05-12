import 'dart:io';
import 'dart:typed_data';

import 'package:booking_don_rac/services/notification_service.dart';
import 'package:booking_don_rac/services/tracking_service.dart';
import 'package:booking_don_rac/services/upload_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EmployeeProvider extends ChangeNotifier {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final UploadService uploadService = UploadService();
  final TrackingService trackingService = TrackingService();
  final NotificationService notificationService = NotificationService();

  String userId = "";
  String role = "";
  bool isInit = false;

  Future<void> initUser(String uid, String userRole) async {
    userId = uid;
    role = userRole;
    isInit = true;
    notifyListeners();
  }

  bool get isStaff => role.toUpperCase() == "STAFF";

  Stream<QuerySnapshot> get bookings {
    if (!isStaff || userId.isEmpty) return const Stream.empty();

    return db
        .collection('bookings')
        .where('status', isEqualTo: "PENDING")
        .snapshots();
  }

  Stream<QuerySnapshot> get tasks {
    if (!isStaff || userId.isEmpty) return const Stream.empty();

    return db
        .collection('tasks')
        .where('employeeId', isEqualTo: userId)
        .where('status', whereIn: ["ASSIGNED", "IN_PROGRESS"])
        .snapshots();
  }

  Stream<QuerySnapshot> get history {
    if (!isStaff || userId.isEmpty) return const Stream.empty();

    return db
        .collection('bookinghistory')
        .where('changedBy', isEqualTo: userId)
        .snapshots();
  }

  Future<void> acceptBooking(String bookingId) async {
    final bookingRef = db.collection('bookings').doc(bookingId);

    String? customerId;

    await db.runTransaction((tx) async {
      final bookingDoc = await tx.get(bookingRef);
      if (!bookingDoc.exists) return;

      final data = bookingDoc.data()!;
      final oldStatus = data["status"];
      customerId = data["userId"];

      final taskRef = db.collection('tasks').doc(bookingId);
      final trackingRef = db.collection('tracking').doc(bookingId);

      tx.set(taskRef, {
        "bookingId": bookingId,
        "employeeId": userId,
        "status": "ASSIGNED",
        "startTime": null,
        "endTime": null,
        "beforeImage": "",
        "afterImage": "",
        "currentLocation": null,
        "createdAt": Timestamp.now(),
        "updatedAt": Timestamp.now(),
      });

      tx.update(bookingRef, {
        "status": "ACCEPTED",
        "employeeId": userId,
        "trackingStatus": "READY",
        "updatedAt": Timestamp.now(),
      });

      tx.set(trackingRef, {
        "bookingId": bookingId,
        "employeeId": userId,
        "location": null,
        "lat": null,
        "lng": null,
        "speed": null,
        "heading": null,
        "accuracy": null,
        "isTracking": false,
        "updatedAt": Timestamp.now(),
      }, SetOptions(merge: true));

      tx.set(db.collection("bookinghistory").doc(), {
        "bookingId": bookingId,
        "employeeId": userId,
        "oldStatus": oldStatus,
        "newStatus": "ACCEPTED",
        "changedBy": userId,
        "createdAt": Timestamp.now(),
      });
    });

    await notificationService.notifyStaff(
      employeeId: userId,
      title: "Bạn đã nhận đơn mới",
      content: "Đơn $bookingId đã được giao cho bạn",
      type: "booking_assigned",
      bookingId: bookingId,
      taskId: bookingId,
    );

    await notificationService.notifyStaffTaskStatus(
      employeeId: userId,
      bookingId: bookingId,
      taskId: bookingId,
      status: "ASSIGNED",
    );

    if (customerId != null) {
      await notificationService.notifyUserBookingStatus(
        userId: customerId!,
        bookingId: bookingId,
        status: "ACCEPTED",
      );
    }
  }

  Future<void> startTask(String taskId, String bookingId) async {
    final bookingRef = db.collection('bookings').doc(bookingId);

    String? customerId;

    await db.runTransaction((tx) async {
      final bookingDoc = await tx.get(bookingRef);
      if (!bookingDoc.exists) return;

      final data = bookingDoc.data()!;
      final oldStatus = data["status"];
      customerId = data["userId"];

      tx.update(db.collection('tasks').doc(taskId), {
        "status": "IN_PROGRESS",
        "startTime": Timestamp.now(),
        "updatedAt": Timestamp.now(),
      });

      tx.update(bookingRef, {
        "status": "IN_PROGRESS",
        "trackingStatus": "LIVE",
        "updatedAt": Timestamp.now(),
      });

      tx.set(db.collection("bookinghistory").doc(), {
        "bookingId": bookingId,
        "employeeId": userId,
        "oldStatus": oldStatus,
        "newStatus": "IN_PROGRESS",
        "changedBy": userId,
        "createdAt": Timestamp.now(),
      });
    });

    await trackingService.startRealtimeTracking(
      bookingId: bookingId,
      employeeId: userId,
    );

    await notificationService.notifyStaffTaskStatus(
      employeeId: userId,
      bookingId: bookingId,
      taskId: taskId,
      status: "IN_PROGRESS",
    );

    if (customerId != null) {
      await notificationService.notifyUserBookingStatus(
        userId: customerId!,
        bookingId: bookingId,
        status: "IN_PROGRESS",
      );
    }
  }

  Future<void> completeTaskWithImage(
    String taskId,
    String bookingId,
    File? file,
  ) async {
    String imageUrl = "";
    String? customerId;

    try {
      if (file != null) {
        Uint8List bytes = await file.readAsBytes();
        imageUrl = await uploadService.uploadImage(
          bytes,
          "tasks/$taskId/after.jpg",
        );
      }

      await db.runTransaction((tx) async {
        final bookingRef = db.collection("bookings").doc(bookingId);
        final bookingDoc = await tx.get(bookingRef);
        if (!bookingDoc.exists) return;

        final data = bookingDoc.data()!;
        final oldStatus = data["status"];
        customerId = data["userId"];

        tx.update(db.collection("tasks").doc(taskId), {
          "status": "COMPLETED",
          "endTime": Timestamp.now(),
          "afterImage": imageUrl,
          "updatedAt": Timestamp.now(),
        });

        tx.update(bookingRef, {
          "status": "DONE",
          "trackingStatus": "STOPPED",
          "updatedAt": Timestamp.now(),
        });

        tx.set(db.collection("bookinghistory").doc(), {
          "bookingId": bookingId,
          "employeeId": userId,
          "oldStatus": oldStatus,
          "newStatus": "DONE",
          "changedBy": userId,
          "createdAt": Timestamp.now(),
        });
      });

      await trackingService.stopRealtimeTracking(bookingId: bookingId);

      await notificationService.notifyStaffTaskStatus(
        employeeId: userId,
        bookingId: bookingId,
        taskId: taskId,
        status: "COMPLETED",
      );

      if (customerId != null) {
        await notificationService.notifyUserBookingStatus(
          userId: customerId!,
          bookingId: bookingId,
          status: "DONE",
        );
      }

      print("✅ COMPLETE SUCCESS");
    } catch (e) {
      print("❌ ERROR COMPLETE: $e");
      rethrow;
    }
  }

  Future<void> uploadBeforeImage(String taskId, File file) async {
    Uint8List bytes = await file.readAsBytes();

    final url = await uploadService.uploadImage(
      bytes,
      "tasks/$taskId/before.jpg",
    );

    await db.collection("tasks").doc(taskId).update({"beforeImage": url});
  }

  @override
  void dispose() {
    trackingService.dispose();
    super.dispose();
  }
}
