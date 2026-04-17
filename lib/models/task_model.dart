import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String bookingId;
  final String employeeId;

  final GeoPoint currentLocation;

  final String beforeImage;
  final String afterImage;

  final Timestamp startTime;
  final Timestamp? endTime;

  final String status;

  TaskModel({
    required this.id,
    required this.bookingId,
    required this.employeeId,
    required this.currentLocation,
    required this.beforeImage,
    required this.afterImage,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  factory TaskModel.fromDoc(String id, Map<String, dynamic> data) {
    return TaskModel(
      id: id,
      bookingId: data["bookingId"] ?? "",
      employeeId: data["employeeId"] ?? "",
      currentLocation: data["currentLocation"] ?? const GeoPoint(0, 0),
      beforeImage: data["beforeImage"] ?? "",
      afterImage: data["afterImage"] ?? "",
      startTime: data["startTime"] ?? Timestamp.now(),
      endTime: data["endTime"],
      status: data["status"] ?? "",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "bookingId": bookingId,
      "employeeId": employeeId,
      "currentLocation": currentLocation,
      "beforeImage": beforeImage,
      "afterImage": afterImage,
      "startTime": startTime,
      "endTime": endTime,
      "status": status,
    };
  }
}
