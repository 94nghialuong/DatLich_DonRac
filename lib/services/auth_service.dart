import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ================= LOGIN =================
  Future<UserCredential> login(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  // ================= REGISTER =================
  Future<UserCredential> register({
    required String email,
    required String password,
    required String fullname,
    required String phone,
    required String dob,
    String? avatar,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;

    await _firestore.collection("users").doc(user!.uid).set({
      "uid": user.uid,
      "avatar": avatar ?? "",
      "createdAt": FieldValue.serverTimestamp(),
      "dob": dob,
      "email": email,
      "fullname": fullname,
      "phone": phone,
      "role": "CUSTOMER",
      "status": true,
    });

    return userCredential;
  }

  // ================= SAVE USER GOOGLE =================
  Future<void> saveUserIfNotExists({
    required String uid,
    required String email,
    required String fullname,
    required String phone,
    required String avatar,
  }) async {
    final doc = await _firestore.collection("users").doc(uid).get();

    if (!doc.exists) {
      await _firestore.collection("users").doc(uid).set({
        "uid": uid,
        "email": email,
        "fullname": fullname,
        "phone": phone,
        "avatar": avatar,
        "role": "CUSTOMER",
        "status": true,
        "createdAt": FieldValue.serverTimestamp(),
      });

      print("USER CREATED (GOOGLE)");
    } else {
      print("USER ALREADY EXISTS");
    }
  }

  // ================= LOGOUT =================
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ================= CURRENT USER =================
  User? get currentUser => _auth.currentUser;
}
