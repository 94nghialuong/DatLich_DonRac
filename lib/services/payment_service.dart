import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_model.dart';

class PaymentService {
  final db = FirebaseFirestore.instance;

  // ================= GET PAYMENT BY BOOKING =================
  Stream<List<PaymentModel>> getByBooking(String bookingId) {
    return db
        .collection("payment")
        .where("bookingId", isEqualTo: bookingId)
        .snapshots()
        .map((snapshot) {
          final data = snapshot.docs.map((doc) {
            return PaymentModel.fromDoc(doc.id, doc.data());
          }).toList();

          print("🔥 PAYMENT STREAM DATA: ${data.length}");
          return data;
        });
  }

  // ================= AUTO CREATE PAYMENT =================
  Future<void> createFromBooking(String bookingId) async {
    final bookingDoc = await db.collection("bookings").doc(bookingId).get();

    final booking = bookingDoc.data();
    if (booking == null) return;

    final serviceId = booking["serviceId"];

    final serviceDoc = await db.collection("services").doc(serviceId).get();

    final service = serviceDoc.data();
    if (service == null) return;

    final price = (service["price"] ?? 0).toDouble();

    // check trùng
    final existing = await db
        .collection("payment")
        .where("bookingId", isEqualTo: bookingId)
        .get();

    if (existing.docs.isNotEmpty) {
      print("⚠️ PAYMENT ALREADY EXISTS");
      return;
    }

    await db.collection("payment").add({
      "bookingId": bookingId,
      "amount": price,
      "method": "CASH",
      "status": "PENDING",
      "createdAt": FieldValue.serverTimestamp(),
    });

    print("✅ PAYMENT CREATED");
  }

  // ================= PAY =================
  Future<void> pay(String paymentId, String bookingId) async {
    await db.collection("payment").doc(paymentId).update({"status": "PAID"});

    await db.collection("bookings").doc(bookingId).update({
      "paymentStatus": "PAID",
    });

    print("✅ PAYMENT PAID");
  }
}
