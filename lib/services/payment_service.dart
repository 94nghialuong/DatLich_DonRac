import 'package:booking_don_rac/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/payment_model.dart';

class PaymentService {
  final db = FirebaseFirestore.instance;
  final notificationService = NotificationService();

  Stream<List<PaymentModel>> getByBooking(String bookingId) {
    return db
        .collection('payment')
        .where('bookingId', isEqualTo: bookingId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return PaymentModel.fromDoc(doc.id, doc.data());
          }).toList();
        });
  }

  Future<void> createFromBooking({
    required String bookingId,
    required String method,
  }) async {
    final bookingDoc = await db.collection('bookings').doc(bookingId).get();
    final booking = bookingDoc.data();
    if (booking == null) return;

    final userId = booking['userId'];
    final serviceId = booking['serviceId'];

    final serviceDoc = await db.collection('services').doc(serviceId).get();
    final service = serviceDoc.data();
    if (service == null) return;

    final price = double.tryParse((service['price'] ?? 0).toString()) ?? 0;

    final existing = await db
        .collection('payment')
        .where('bookingId', isEqualTo: bookingId)
        .get();

    if (existing.docs.isNotEmpty) {
      print('⚠️ PAYMENT ALREADY EXISTS');
      return;
    }

    String paymentUrl = '';
    String qrContent = '';

    if (method == 'MOMO') {
      paymentUrl = 'momo://pay?amount=$price&orderId=$bookingId';
      qrContent = 'MOMO_PAYMENT_$bookingId';
    } else if (method == 'ZALOPAY') {
      paymentUrl = 'zalopay://pay?amount=$price&orderId=$bookingId';
      qrContent = 'ZALOPAY_PAYMENT_$bookingId';
    } else {
      throw Exception('Payment method không hợp lệ');
    }

    await db.collection('payment').add({
      'bookingId': bookingId,
      'amount': price,
      'method': method,
      'status': 'PENDING',
      'paymentUrl': paymentUrl,
      'qrContent': qrContent,
      'createdAt': FieldValue.serverTimestamp(),
      'paidAt': null,
    });

    await db.collection('bookings').doc(bookingId).update({
      'paymentStatus': 'PENDING',
      'paymentMethod': method,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (userId != null) {
      await notificationService.notifyUserPayment(
        userId: userId,
        bookingId: bookingId,
        status: 'PENDING',
      );
    }

    print('✅ $method PAYMENT CREATED');
  }

  Future<void> pay(String paymentId, String bookingId) async {
    final bookingDoc = await db.collection('bookings').doc(bookingId).get();
    final booking = bookingDoc.data();
    final userId = booking?['userId'];

    await db.collection('payment').doc(paymentId).update({
      'status': 'PAID',
      'paidAt': FieldValue.serverTimestamp(),
    });

    await db.collection('bookings').doc(bookingId).update({
      'paymentStatus': 'PAID',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (userId != null) {
      await notificationService.notifyUserPayment(
        userId: userId,
        bookingId: bookingId,
        status: 'PAID',
      );
    }

    print('✅ PAYMENT PAID');
  }

  Future<void> cancelPayment(String paymentId, String bookingId) async {
    final bookingDoc = await db.collection('bookings').doc(bookingId).get();
    final booking = bookingDoc.data();
    final userId = booking?['userId'];

    await db.collection('payment').doc(paymentId).update({
      'status': 'CANCELLED',
    });

    await db.collection('bookings').doc(bookingId).update({
      'paymentStatus': 'CANCELLED',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (userId != null) {
      await notificationService.notifyUserPayment(
        userId: userId,
        bookingId: bookingId,
        status: 'CANCELLED',
      );
    }

    print('❌ PAYMENT CANCELLED');
  }
}
