import 'package:booking_don_rac/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewService {
  final CollectionReference reviews = FirebaseFirestore.instance.collection(
    "reviews",
  );

  final FirebaseFirestore db = FirebaseFirestore.instance;
  final NotificationService notificationService = NotificationService();

  Future<void> addReview(Map<String, dynamic> data) async {
    await reviews.add({
      ...data,
      "createdAt": data["createdAt"] ?? Timestamp.now(),
    });

    final employeeId = data["employeeId"];
    final bookingId = data["bookingId"];
    final rating = data["rating"] ?? 0;
    final comment = data["comment"]?.toString();

    String customerName = "Khách hàng";

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await db.collection("users").doc(user.uid).get();
      customerName =
          userDoc.data()?["fullname"] ??
          user.displayName ??
          user.email ??
          "Khách hàng";
    }

    if (employeeId != null && bookingId != null) {
      await notificationService.notifyStaffReview(
        employeeId: employeeId,
        bookingId: bookingId,
        customerName: customerName,
        rating: rating is int ? rating : int.tryParse(rating.toString()) ?? 0,
        comment: comment,
      );
    }
  }

  Stream<QuerySnapshot> getEmployeeReviews(String employeeId) {
    return reviews.where("employeeId", isEqualTo: employeeId).snapshots();
  }

  Future<bool> hasReviewed(String bookingId) async {
    final user = FirebaseAuth.instance.currentUser;

    final snapshot = await FirebaseFirestore.instance
        .collection("reviews")
        .where("bookingId", isEqualTo: bookingId)
        .where("userId", isEqualTo: user!.uid)
        .get();

    return snapshot.docs.isNotEmpty;
  }
}
