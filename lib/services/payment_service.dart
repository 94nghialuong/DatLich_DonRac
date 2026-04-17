import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentService {
  final CollectionReference payments = FirebaseFirestore.instance.collection(
    "payment",
  );

  Future<void> createPayment(Map<String, dynamic> data) async {
    await payments.add(data);
  }

  Future<void> updateStatus(String id, String status) async {
    await payments.doc(id).update({"status": status});
  }
}
