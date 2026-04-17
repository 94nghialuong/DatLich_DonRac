import 'package:cloud_firestore/cloud_firestore.dart';

class TrackingModel {
  final String id;
  final String employeeId;
  final GeoPoint location;
  final Timestamp updatedAt;

  TrackingModel({
    required this.id,
    required this.employeeId,
    required this.location,
    required this.updatedAt,
  });

  factory TrackingModel.fromDoc(String id, Map<String, dynamic> data) {
    return TrackingModel(
      id: id,
      employeeId: data["employeeId"] ?? "",
      location: data["location"] ?? const GeoPoint(0, 0),
      updatedAt: data["updateAt"] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "employeeId": employeeId,
      "location": location,
      "updateAt": updatedAt,
    };
  }
}
