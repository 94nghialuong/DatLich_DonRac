import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceService {
  final CollectionReference services = FirebaseFirestore.instance.collection(
    "services",
  );

  Stream<QuerySnapshot> getServices() {
    return services.snapshots();
  }
}
