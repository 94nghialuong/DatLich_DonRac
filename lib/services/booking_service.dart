import 'package:booking_don_rac/services/payment_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingService {
  final db = FirebaseFirestore.instance;
  final paymentService = PaymentService();

  Future<void> createBooking(Map<String, dynamic> data) async {
    await db.collection('bookings').add({
      ...data,
      "status": "PENDING",
      "paymentStatus": "UNPAID",
      "createdAt": Timestamp.now(),
    });
  }

  Future<void> acceptBooking(String bookingId, String employeeId) async {
    final batch = db.batch();

    final bookingRef = db.collection('bookings').doc(bookingId);
    final taskRef = db.collection('tasks').doc(bookingId);
    final trackingRef = db.collection('tracking').doc(bookingId);

    // booking update
    batch.update(bookingRef, {"status": "ACCEPTED"});

    // task create
    batch.set(taskRef, {
      "bookingId": bookingId,
      "employeeId": employeeId,
      "status": "ASSIGNED",
      "beforeImage": "",
      "afterImage": "",
      "currentLocation": const GeoPoint(0, 0),
      "startTime": Timestamp.now(),
      "endTime": null,
    });

    // tracking create
    batch.set(trackingRef, {
      "employeeId": employeeId,
      "location": const GeoPoint(0, 0),
      "updatedAt": Timestamp.now(),
    });

    await batch.commit();
  }

  Future<void> completeBooking(String bookingId) async {
    await db.collection('bookings').doc(bookingId).update({"status": "DONE"});

    // AUTO CREATE PAYMENT
    await paymentService.createFromBooking(bookingId);
  }
}
