import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final CollectionReference users = FirebaseFirestore.instance.collection(
    "users",
  );

  Future<void> createUser(String uid, Map<String, dynamic> data) async {
    await users.doc(uid).set(data);
  }

  Future<DocumentSnapshot> getUser(String uid) async {
    return await users.doc(uid).get();
  }
}
