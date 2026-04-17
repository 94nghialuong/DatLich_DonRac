import 'package:booking_don_rac/screens/staff/staff_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin/home_creen.dart';
import '../user/home_screen.dart';
import 'login.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<String> getRole(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      if (!doc.exists) return "CUSTOMER";

      final data = doc.data();
      return (data?["role"] ?? "CUSTOMER").toString();
    } catch (e) {
      print("GET ROLE ERROR: $e");
      return "CUSTOMER";
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.idTokenChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          print("NOT LOGGED IN");
          return const LoginScreen();
        }

        print("USER UID: ${user.uid}");
        return FutureBuilder<String>(
          future: getRole(user.uid),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final role = roleSnapshot.data ?? "CUSTOMER";

            print("ROLE FINAL: $role");

            // 🔥 ROUTING
            switch (role) {
              case "ADMIN":
                return const AdminHome();

              case "STAFF":
                return StaffHome();

              default:
                return const HomeScreen();
            }
          },
        );
      },
    );
  }
}
