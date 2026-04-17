import 'package:cloud_firestore/cloud_firestore.dart';

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
}
