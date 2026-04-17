import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String userId;
  final String serviceId;
  final String addressId;
  final GeoPoint location;
  final Timestamp createdAt;
  final Timestamp time;
  final String status;

  BookingModel({
    required this.id,
    required this.userId,
    required this.serviceId,
    required this.addressId,
    required this.location,
    required this.createdAt,
    required this.time,
    required this.status,
  });

  factory BookingModel.fromDoc(String id, Map<String, dynamic> data) {
    return BookingModel(
      id: id,
      userId: data["userId"] ?? "",
      serviceId: data["serviceId"] ?? "",
      addressId: data["addressId"] ?? "",
      location: data["location"] ?? const GeoPoint(0, 0),
      createdAt: data["createdAt"] ?? Timestamp.now(),
      time: data["time"] ?? Timestamp.now(),
      status: data["status"] ?? "",
    );
  }
  Map<String, dynamic> toMap() {
    return {
      "userId": userId,
      "serviceId": serviceId,
      "addressId": addressId,
      "location": location,
      "createdAt": createdAt,
      "time": time,
      "status": status,
    };
  }
}
