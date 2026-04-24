import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = false;

  // ================= LOGIN =================
  Future<void> login(String email, String password) async {
    try {
      isLoading = true;
      notifyListeners();

      await _authService.login(email, password);

      print("LOGIN OK");
    } catch (e) {
      print("LOGIN ERROR: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ================= REGISTER =================
  Future<void> register({
    required String email,
    required String password,
    required String fullname,
    required String phone,
    required String dob,
  }) async {
    try {
      isLoading = true;
      notifyListeners();

      await _authService.register(
        email: email,
        password: password,
        fullname: fullname,
        phone: phone,
        dob: dob,
      );

      print("REGISTER OK");
    } catch (e) {
      print("REGISTER ERROR: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ================= LOGOUT =================
  Future<void> logout() async {
    try {
      isLoading = true;
      notifyListeners();

      await GoogleSignIn().signOut(); // 🔥 logout luôn google
      await _authService.logout();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ================= GOOGLE LOGIN (AUTO REGISTER) =================
  Future<void> signInWithGoogle() async {
    try {
      isLoading = true;
      notifyListeners();

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId:
            // "73880434275-v541k5d9vne64ced1dgtr3juc94bjpc4.apps.googleusercontent.com",
            // "231076873717-0p3396mb5d92f2h70i5behfmq4s09hrk.apps.googleusercontent.com",
            "686701251370-dc5o04vp0mfo65358ffku3kc7dn2spve.apps.googleusercontent.com",
      );

      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        isLoading = false;
        notifyListeners();
        return;
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      final user = userCredential.user;

      if (user != null) {
        await _authService.saveUserIfNotExists(
          uid: user.uid,
          email: user.email ?? "",
          fullname: user.displayName ?? "",
          phone: user.phoneNumber ?? "",
          avatar: user.photoURL ?? "",
        );
      }
    } catch (e) {
      print("GOOGLE LOGIN ERROR: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ================= RESET PASSWORD =================
  Future<void> resetPassword(String email) async {
    try {
      isLoading = true;
      notifyListeners();

      await _auth.sendPasswordResetEmail(email: email);

      print("RESET EMAIL SENT");
    } catch (e) {
      print("RESET ERROR: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
