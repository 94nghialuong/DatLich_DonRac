import 'package:booking_don_rac/services/notification_service.dart';
import 'package:booking_don_rac/services/payment_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingService {
  final db = FirebaseFirestore.instance;
  final paymentService = PaymentService();
  final notificationService = NotificationService();

  Future<void> createBooking(Map<String, dynamic> data) async {
    final docRef = await db.collection('bookings').add({
      ...data,
      'address':
          data['address'] ??
          data['pickupAddress'] ??
          data['userAddress'] ??
          'Không có địa chỉ',
      'status': 'PENDING',
      'paymentStatus': 'UNPAID',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });

    try {
      await notificationService.notifyAllStaffNewBooking(
        bookingId: docRef.id,
        content: 'Có booking mới đang chờ nhân viên nhận đơn',
      );
    } catch (e) {
      print('Lỗi gửi thông báo booking mới cho nhân viên: $e');
    }
  }

  Future<void> acceptBooking(String bookingId, String employeeId) async {
    final bookingRef = db.collection('bookings').doc(bookingId);
    final bookingDoc = await bookingRef.get();

    if (!bookingDoc.exists) return;

    final booking = bookingDoc.data()!;
    final userId = booking['userId'];
    final oldStatus = booking['status'];

    final batch = db.batch();

    final taskRef = db.collection('tasks').doc(bookingId);
    final trackingRef = db.collection('tracking').doc(bookingId);

    batch.update(bookingRef, {
      'status': 'ACCEPTED',
      'employeeId': employeeId,
      'trackingStatus': 'READY',
      'updatedAt': Timestamp.now(),
    });

    batch.set(taskRef, {
      'bookingId': bookingId,
      'employeeId': employeeId,
      'status': 'ASSIGNED',
      'beforeImage': '',
      'afterImage': '',
      'currentLocation': const GeoPoint(16.46, 107.59),
      'startTime': null,
      'endTime': null,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });

    batch.set(trackingRef, {
      'bookingId': bookingId,
      'employeeId': employeeId,
      'location': const GeoPoint(16.46, 107.59),
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));

    batch.set(db.collection('bookinghistory').doc(), {
      'bookingId': bookingId,
      'employeeId': employeeId,
      'oldStatus': oldStatus,
      'newStatus': 'ACCEPTED',
      'changedBy': employeeId,
      'createdAt': Timestamp.now(),
    });

    await batch.commit();

    await notificationService.notifyStaff(
      employeeId: employeeId,
      title: 'Bạn đã nhận đơn',
      content: 'Đơn $bookingId đã được giao cho bạn',
      type: 'booking_assigned',
      bookingId: bookingId,
      taskId: bookingId,
    );

    await notificationService.notifyStaffTaskStatus(
      employeeId: employeeId,
      bookingId: bookingId,
      taskId: bookingId,
      status: 'ASSIGNED',
    );

    if (userId != null) {
      await notificationService.notifyUserBookingStatus(
        userId: userId,
        bookingId: bookingId,
        status: 'ACCEPTED',
      );
    }
  }

  Future<void> completeBooking(String bookingId) async {
    final bookingRef = db.collection('bookings').doc(bookingId);
    final bookingDoc = await bookingRef.get();

    if (!bookingDoc.exists) return;

    final booking = bookingDoc.data()!;
    final userId = booking['userId'];
    final employeeId = booking['employeeId'];

    await bookingRef.update({
      'status': 'DONE',
      'trackingStatus': 'STOPPED',
      'updatedAt': Timestamp.now(),
    });

    if (employeeId != null) {
      await notificationService.notifyStaffTaskStatus(
        employeeId: employeeId,
        bookingId: bookingId,
        taskId: bookingId,
        status: 'COMPLETED',
      );
    }

    if (userId != null) {
      await notificationService.notifyUserBookingStatus(
        userId: userId,
        bookingId: bookingId,
        status: 'DONE',
      );
    }

    await paymentService.createFromBooking(
      bookingId: bookingId,
      method: 'MOMO',
    );
  }
}
