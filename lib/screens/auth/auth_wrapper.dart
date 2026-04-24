import 'package:booking_don_rac/provider/employee_provider.dart';
import 'package:booking_don_rac/screens/staff/staff_home_screen.dart';
import 'package:booking_don_rac/screens/user/main_user_screen.dart';
import 'package:booking_don_rac/services/employee_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../admin/home_creen.dart';
import 'login.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<String> getRole(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();

    if (!doc.exists) return "CUSTOMER";

    return (doc.data()?["role"] ?? "CUSTOMER").toString();
  }

  Future<String> getName(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();

    return (doc.data()?["fullname"] ?? "").toString();
  }

  @override
  Widget build(BuildContext context) {
    final employeeProvider = Provider.of<EmployeeProvider>(context);

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.idTokenChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        final user = snapshot.data!;

        return FutureBuilder<List<dynamic>>(
          future: Future.wait([getRole(user.uid), getName(user.uid)]),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final role = snap.data![0];
            final name = snap.data![1];

            // 🔥 INIT ONCE
            if (!employeeProvider.isInit) {
              Future.microtask(() async {
                employeeProvider.initUser(user.uid, role);

                // 🔥 SYNC EMPLOYEE HERE
                await EmployeeSyncService().syncIfStaff(
                  uid: user.uid,
                  role: role,
                  fullname: name,
                );
              });

              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            switch (role) {
              case "ADMIN":
                return const AdminHome();

              case "STAFF":
                return StaffHome(employeeId: user.uid);

              default:
                return const MainScreen();
            }
          },
        );
      },
    );
  }
}
