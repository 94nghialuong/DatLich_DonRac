import 'package:cloud_firestore/cloud_firestore.dart';

class BookingService {
  final db = FirebaseFirestore.instance;

  Future<void> createBooking(Map<String, dynamic> data) async {
    await db.collection('bookings').add({
      ...data,
      "status": "PENDING",
      "createdAt": Timestamp.now(),
    });
  }

  Future<void> acceptBooking(String bookingId, String employeeId) async {
    final taskRef = db.collection('tasks').doc();

    await taskRef.set({
      "bookingId": bookingId,
      "employeeId": employeeId,
      "status": "ASSIGNED",
      "beforeImage": "",
      "afterImage": "",
      "currentLocation": const GeoPoint(0, 0),
      "startTime": Timestamp.now(),
      "endTime": null,
    });

    await db.collection('bookings').doc(bookingId).update({
      "status": "ACCEPTED",
    });
  }

  Future<void> completeBooking(String bookingId) async {
    await db.collection('bookings').doc(bookingId).update({"status": "DONE"});
  }
}
