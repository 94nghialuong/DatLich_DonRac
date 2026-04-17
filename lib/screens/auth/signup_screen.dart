import 'package:booking_don_rac/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  final fullname = TextEditingController();
  final phone = TextEditingController();
  final dob = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("SIGN UP")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: fullname,
              decoration: const InputDecoration(labelText: "Fullname"),
            ),
            TextField(
              controller: email,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: password,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            TextField(
              controller: phone,
              decoration: const InputDecoration(labelText: "Phone"),
            ),
            TextField(
              controller: dob,
              decoration: const InputDecoration(labelText: "DOB (yyyy/mm/dd)"),
            ),

            const SizedBox(height: 20),

            authProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: () async {
                      await context.read<AuthProvider>().register(
                        email: email.text.trim(),
                        password: password.text.trim(),
                        fullname: fullname.text.trim(),
                        phone: phone.text.trim(),
                        dob: dob.text.trim(),
                      );

                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    child: const Text("REGISTER"),
                  ),
          ],
        ),
      ),
    );
  }
}
