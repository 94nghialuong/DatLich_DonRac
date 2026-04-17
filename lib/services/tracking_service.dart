import 'package:cloud_firestore/cloud_firestore.dart';

class TrackingService {
  final db = FirebaseFirestore.instance;

  Future<void> updateLocation(String employeeId) async {
    await db.collection("tracking").add({
      "employeeId": employeeId,
      "location": const GeoPoint(16.46, 107.59),
      "updateAt": Timestamp.now(),
    });
  }
}
