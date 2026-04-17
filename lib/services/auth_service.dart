import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential> login(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      print("LOGIN SUCCESS: ${result.user?.uid}");
      return result;
    } on FirebaseAuthException catch (e) {
      print("LOGIN ERROR CODE: ${e.code}");
      print("LOGIN ERROR MESSAGE: ${e.message}");
      rethrow;
    } catch (e) {
      print("UNKNOWN ERROR: $e");
      rethrow;
    }
  }

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

    await FirebaseFirestore.instance.collection("users").doc(user!.uid).set({
      "avatar": avatar ?? "",
      "createdAt": Timestamp.now(),
      "dob": dob,
      "email": email,
      "fullname": fullname,
      "passwordhash": password,
      "phone": phone,
      "role": "CUSTOMER",
      "status": true,
    });

    return userCredential;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
}
