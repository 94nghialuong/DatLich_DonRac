import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool isLoading = false;

  Future<void> login(String email, String password) async {
    isLoading = true;
    notifyListeners();

    try {
      await _authService.login(email, password);
      print("LOGIN OK");
    } catch (e) {
      print("LOGIN ERROR: $e");
    }

    isLoading = false;
    notifyListeners();
  }

  // 🔥 REGISTER FULL
  Future<void> register({
    required String email,
    required String password,
    required String fullname,
    required String phone,
    required String dob,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
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
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    isLoading = true;
    notifyListeners();

    await _authService.logout();

    isLoading = false;
    notifyListeners();
  }
}
