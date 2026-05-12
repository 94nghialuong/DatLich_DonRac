import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  // =====================================================
  // CREATE COMMON NOTIFICATION
  // =====================================================
  Future<void> create({
    required String title,
    required String content,
    required String type,
    required String target,
    String? receiverId,
    String? userId,
    String? employeeId,
    String? bookingId,
    String? taskId,
    String? roomId,
    Map<String, dynamic>? data,
  }) async {
    final finalReceiverId = receiverId ?? userId ?? employeeId;

    if (finalReceiverId == null || finalReceiverId.trim().isEmpty) return;

    final normalizedTarget = target.toUpperCase();

    await db.collection('notifications').add({
      'title': title,
      'content': content,
      'body': content,
      'type': type,
      'target': normalizedTarget,
      'receiverRole': normalizedTarget == 'USER'
          ? 'CUSTOMER'
          : normalizedTarget,
      'receiverId': finalReceiverId,
      'userId': userId,
      'employeeId': employeeId,
      'bookingId': bookingId ?? '',
      'taskId': taskId ?? '',
      'roomId': roomId,
      'data': data ?? {},
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'readAt': null,
    });
  }

  // =====================================================
  // USER / CUSTOMER
  // =====================================================
  Future<void> notifyUser({
    required String userId,
    required String title,
    required String content,
    required String type,
    String? bookingId,
    String? taskId,
    String? roomId,
    Map<String, dynamic>? data,
  }) async {
    await create(
      title: title,
      content: content,
      type: type,
      target: 'USER',
      receiverId: userId,
      userId: userId,
      bookingId: bookingId,
      taskId: taskId,
      roomId: roomId,
      data: data,
    );
  }

  // =====================================================
  // STAFF
  // =====================================================
  Future<void> notifyStaff({
    required String employeeId,
    required String title,
    required String content,
    required String type,
    String? bookingId,
    String? taskId,
    String? roomId,
    Map<String, dynamic>? data,
  }) async {
    await create(
      title: title,
      content: content,
      type: type,
      target: 'STAFF',
      receiverId: employeeId,
      employeeId: employeeId,
      bookingId: bookingId,
      taskId: taskId,
      roomId: roomId,
      data: data,
    );
  }

  // =====================================================
  // ALL STAFF: NEW BOOKING
  // =====================================================
  Future<void> notifyAllStaffNewBooking({
    required String bookingId,
    required String content,
  }) async {
    final staffSnap = await db
        .collection('users')
        .where('role', whereIn: ['STAFF', 'staff'])
        .get();

    if (staffSnap.docs.isEmpty) return;

    final batch = db.batch();

    for (final doc in staffSnap.docs) {
      final ref = db.collection('notifications').doc();

      batch.set(ref, {
        'title': 'Có booking mới',
        'content': content,
        'body': content,
        'type': 'booking_new',
        'target': 'STAFF',
        'receiverRole': 'STAFF',
        'receiverId': doc.id,
        'employeeId': doc.id,
        'userId': null,
        'bookingId': bookingId,
        'taskId': '',
        'roomId': null,
        'data': {},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'readAt': null,
      });
    }

    await batch.commit();
  }

  // =====================================================
  // USER: BOOKING STATUS
  // =====================================================
  Future<void> notifyUserBookingStatus({
    required String userId,
    required String bookingId,
    required String status,
  }) async {
    final upperStatus = status.toUpperCase();

    String title = 'Cập nhật booking';
    String content = 'Booking $bookingId đã được cập nhật';

    if (upperStatus == 'ACCEPTED') {
      title = 'Đơn đã được nhận';
      content = 'Nhân viên đã nhận đơn $bookingId của bạn';
    } else if (upperStatus == 'IN_PROGRESS') {
      title = 'Đơn đang được thực hiện';
      content = 'Nhân viên đang thực hiện đơn $bookingId của bạn';
    } else if (upperStatus == 'DONE' || upperStatus == 'COMPLETED') {
      title = 'Đơn đã hoàn thành';
      content =
          'Đơn $bookingId đã hoàn tất. Bạn có thể thanh toán và đánh giá.';
    } else if (upperStatus == 'CANCELLED') {
      title = 'Đơn đã bị hủy';
      content = 'Booking $bookingId đã bị hủy';
    }

    await notifyUser(
      userId: userId,
      title: title,
      content: content,
      type: 'booking_status',
      bookingId: bookingId,
      data: {'status': upperStatus},
    );
  }

  // =====================================================
  // ADMIN CANCEL BOOKING: USER + STAFF
  // =====================================================
  Future<void> notifyBookingCancelledByAdmin({
    required String bookingId,
    String? userId,
    String? employeeId,
    String? reason,
  }) async {
    final cleanReason = reason?.trim() ?? '';

    if (userId != null && userId.trim().isNotEmpty) {
      await notifyUser(
        userId: userId,
        title: 'Đơn đã bị hủy',
        content: cleanReason.isEmpty
            ? 'Admin đã hủy booking $bookingId của bạn.'
            : 'Admin đã hủy booking $bookingId. Lý do: $cleanReason',
        type: 'booking_cancelled',
        bookingId: bookingId,
        data: {
          'status': 'CANCELLED',
          'cancelledBy': 'ADMIN',
          'reason': cleanReason,
        },
      );
    }

    if (employeeId != null && employeeId.trim().isNotEmpty) {
      await notifyStaff(
        employeeId: employeeId,
        title: 'Booking đã bị hủy',
        content: cleanReason.isEmpty
            ? 'Admin đã hủy booking $bookingId.'
            : 'Admin đã hủy booking $bookingId. Lý do: $cleanReason',
        type: 'booking_cancelled',
        bookingId: bookingId,
        data: {
          'status': 'CANCELLED',
          'cancelledBy': 'ADMIN',
          'reason': cleanReason,
        },
      );
    }
  }

  // =====================================================
  // USER: PAYMENT
  // =====================================================
  Future<void> notifyUserPayment({
    required String userId,
    required String bookingId,
    required String status,
  }) async {
    final upperStatus = status.toUpperCase();

    String title = 'Thông báo thanh toán';
    String content = 'Thanh toán của bạn đã được cập nhật';

    if (upperStatus == 'PENDING') {
      title = 'Yêu cầu thanh toán';
      content = 'Vui lòng thanh toán cho booking $bookingId';
    } else if (upperStatus == 'PAID') {
      title = 'Thanh toán thành công';
      content = 'Bạn đã thanh toán thành công booking $bookingId';
    } else if (upperStatus == 'CANCELLED') {
      title = 'Thanh toán đã hủy';
      content = 'Thanh toán của booking $bookingId đã bị hủy';
    }

    await notifyUser(
      userId: userId,
      title: title,
      content: content,
      type: 'payment',
      bookingId: bookingId,
      data: {'paymentStatus': upperStatus},
    );
  }

  // =====================================================
  // STAFF: TASK STATUS
  // =====================================================
  Future<void> notifyStaffTaskStatus({
    required String employeeId,
    required String bookingId,
    required String taskId,
    required String status,
  }) async {
    final upperStatus = status.toUpperCase();

    String title = 'Cập nhật task';
    String content = 'Task $taskId đã được cập nhật';
    String type = 'task_status';

    if (upperStatus == 'ASSIGNED') {
      title = 'Task mới được giao';
      content = 'Bạn có task mới từ booking $bookingId';
      type = 'task_assigned';
    } else if (upperStatus == 'IN_PROGRESS') {
      title = 'Task đã bắt đầu';
      content = 'Bạn đã bắt đầu xử lý task $taskId';
      type = 'task_started';
    } else if (upperStatus == 'COMPLETED' || upperStatus == 'DONE') {
      title = 'Task đã hoàn thành';
      content = 'Bạn đã hoàn thành task $taskId';
      type = 'task_completed';
    } else if (upperStatus == 'CANCELLED') {
      title = 'Task đã bị hủy';
      content = 'Task $taskId từ booking $bookingId đã bị hủy';
      type = 'task_cancelled';
    }

    await notifyStaff(
      employeeId: employeeId,
      title: title,
      content: content,
      type: type,
      bookingId: bookingId,
      taskId: taskId,
      data: {'status': upperStatus},
    );
  }

  // =====================================================
  // STAFF: REVIEW
  // =====================================================
  Future<void> notifyStaffReview({
    required String employeeId,
    required String bookingId,
    required String customerName,
    required int rating,
    String? comment,
  }) async {
    final cleanComment = comment?.trim() ?? '';

    await notifyStaff(
      employeeId: employeeId,
      title: 'Bạn có đánh giá mới',
      content: cleanComment.isEmpty
          ? '$customerName đã đánh giá bạn $rating sao'
          : '$customerName đã đánh giá bạn $rating sao: $cleanComment',
      type: 'review',
      bookingId: bookingId,
      data: {
        'customerName': customerName,
        'rating': rating,
        'comment': cleanComment,
      },
    );
  }
}
