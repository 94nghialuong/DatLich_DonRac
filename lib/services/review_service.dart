import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewService {
  final CollectionReference reviews = FirebaseFirestore.instance.collection(
    "reviews",
  );

  Future<void> addReview(Map<String, dynamic> data) async {
    await reviews.add(data);
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
