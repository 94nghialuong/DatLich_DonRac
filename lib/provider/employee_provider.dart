import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:booking_don_rac/services/upload_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class EmployeeProvider extends ChangeNotifier {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final UploadService uploadService = UploadService();

  String userId = "";
  String role = "";
  bool isInit = false;

  Future<void> initUser(String uid, String userRole) async {
    userId = uid;
    role = userRole;
    isInit = true;
    notifyListeners();
  }

  bool get isStaff => role == "STAFF";

  // ================= BOOKINGS =================
  Stream<QuerySnapshot> get bookings {
    if (!isStaff || userId.isEmpty) return const Stream.empty();

    return db
        .collection('bookings')
        .where('status', isEqualTo: "PENDING")
        .snapshots();
  }

  // ================= TASKS =================
  Stream<QuerySnapshot> get tasks {
    if (!isStaff || userId.isEmpty) return const Stream.empty();

    return db
        .collection('tasks')
        .where('employeeId', isEqualTo: userId)
        .where('status', whereIn: ["ASSIGNED", "IN_PROGRESS"])
        .snapshots();
  }

  // ================= HISTORY =================
  Stream<QuerySnapshot> get history {
    if (!isStaff || userId.isEmpty) return const Stream.empty();

    return db
        .collection('bookinghistory')
        .where('changedBy', isEqualTo: userId)
        .snapshots();
  }

  // ================= ACCEPT BOOKING =================
  Future<void> acceptBooking(String bookingId) async {
    final bookingRef = db.collection('bookings').doc(bookingId);

    await db.runTransaction((tx) async {
      final bookingDoc = await tx.get(bookingRef);
      if (!bookingDoc.exists) return;

      final data = bookingDoc.data()!;
      final oldStatus = data["status"];
      final customerId = data["userId"];

      final taskRef = db.collection('tasks').doc();

      // 🔥 CREATE TASK
      tx.set(taskRef, {
        "bookingId": bookingId,
        "employeeId": userId,
        "status": "ASSIGNED",
        "startTime": null,
        "endTime": null,
        "beforeImage": "",
        "afterImage": "",
        "currentLocation": const GeoPoint(0, 0),
      });

      // 🔥 UPDATE BOOKING
      tx.update(bookingRef, {"status": "ACCEPTED", "employeeId": userId});

      // 🔥 HISTORY
      tx.set(db.collection("bookinghistory").doc(), {
        "bookingId": bookingId,
        "employeeId": userId,
        "oldStatus": oldStatus,
        "newStatus": "ACCEPTED",
        "changedBy": userId,
        "createdAt": Timestamp.now(),
      });

      // 🔔 NOTIFICATION (QUAN TRỌNG)
      tx.set(db.collection("notifications").doc(), {
        "title": "Đơn đã được nhận",
        "content": "Nhân viên đã nhận đơn của bạn",
        "userId": customerId,
        "bookingId": bookingId,
        "type": "booking",
        "isRead": false,
        "createdAt": Timestamp.now(),
      });
    });
  }

  // ================= START TASK =================
  Future<void> startTask(String taskId, String bookingId) async {
    final bookingRef = db.collection('bookings').doc(bookingId);

    await db.runTransaction((tx) async {
      final doc = await tx.get(bookingRef);
      final oldStatus = doc["status"];

      tx.update(db.collection('tasks').doc(taskId), {
        "status": "IN_PROGRESS",
        "startTime": Timestamp.now(),
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

    await startTracking(taskId);
  }

  // ================= COMPLETE TASK (SAFE + FIX UPLOAD) =================
  Future<void> completeTaskWithImage(
    String taskId,
    String bookingId,
    File? file,
  ) async {
    String imageUrl = "";

    try {
      // upload ảnh
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
        final customerId = data["userId"];

        // update task
        tx.update(db.collection("tasks").doc(taskId), {
          "status": "COMPLETED",
          "endTime": Timestamp.now(),
          "afterImage": imageUrl,
        });

        // update booking
        tx.update(bookingRef, {"status": "DONE"});

        // history
        tx.set(db.collection("bookinghistory").doc(), {
          "bookingId": bookingId,
          "employeeId": userId,
          "oldStatus": oldStatus,
          "newStatus": "DONE",
          "changedBy": userId,
          "createdAt": Timestamp.now(),
        });

        // 🔔 NOTIFICATION DONE
        tx.set(db.collection("notifications").doc(), {
          "title": "Đơn đã hoàn thành",
          "content": "Đơn của bạn đã hoàn tất",
          "userId": customerId,
          "bookingId": bookingId,
          "type": "booking",
          "isRead": false,
          "createdAt": Timestamp.now(),
        });
      });

      print("✅ COMPLETE SUCCESS");
    } catch (e) {
      print("❌ ERROR COMPLETE: $e");
      rethrow;
    }
  }

  // ================= BEFORE IMAGE =================
  Future<void> uploadBeforeImage(String taskId, File file) async {
    Uint8List bytes = await file.readAsBytes();

    final url = await uploadService.uploadImage(
      bytes,
      "tasks/$taskId/before.jpg",
    );

    await db.collection("tasks").doc(taskId).update({"beforeImage": url});
  }

  // ================= TRACKING =================
  StreamSubscription<Position>? _trackingSub;

  Future<void> startTracking(String taskId) async {
    await Geolocator.requestPermission();

    _trackingSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((pos) async {
          await db.collection("tracking").doc(taskId).set({
            "taskId": taskId,
            "employeeId": userId,
            "location": GeoPoint(pos.latitude, pos.longitude),
            "updatedAt": Timestamp.now(),
          });
        });
  }

  Future<void> stopTracking() async {
    await _trackingSub?.cancel();
    _trackingSub = null;
  }
}
