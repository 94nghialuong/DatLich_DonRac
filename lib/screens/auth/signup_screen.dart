import 'package:booking_don_rac/provider/auth_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  final fullname = TextEditingController();
  final phone = TextEditingController();
  final dob = TextEditingController();

  DateTime? selectedDate;

  bool showPassword = false;
  bool showConfirmPassword = false;

  // ================= DATE PICKER =================
  Future<void> pickDate() async {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        DateTime tempDate = selectedDate ?? DateTime(2000);

        return Container(
          height: 300,
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              // ✅ BUTTON DONE
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    child: const Text("Done"),
                    onPressed: () {
                      setState(() {
                        selectedDate = tempDate;
                        dob.text =
                            "${tempDate.year}/${tempDate.month.toString().padLeft(2, '0')}/${tempDate.day.toString().padLeft(2, '0')}";
                      });
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),

              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: selectedDate ?? DateTime(2000),
                  maximumDate: DateTime.now(),
                  minimumYear: 1950,
                  onDateTimeChanged: (date) {
                    tempDate = date;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFEAF7EF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "SIGN UP",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff006d37),
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Join the EcoService community",
                    style: TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 20),

                  // ===== FULLNAME =====
                  buildInput(
                    controller: fullname,
                    hint: "Fullname",
                    icon: Icons.person,
                  ),

                  const SizedBox(height: 12),

                  // ===== EMAIL =====
                  buildInput(
                    controller: email,
                    hint: "Email",
                    icon: Icons.email,
                  ),

                  const SizedBox(height: 12),

                  // ===== PHONE + DOB =====
                  Row(
                    children: [
                      Expanded(
                        child: buildInput(
                          controller: phone,
                          hint: "Phone",
                          icon: Icons.phone,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: buildInput(
                          controller: dob,
                          hint: "DOB",
                          icon: Icons.calendar_today,
                          readOnly: true,
                          onTap: pickDate,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ===== PASSWORD =====
                  buildInput(
                    controller: password,
                    hint: "Password",
                    icon: Icons.lock,
                    obscure: !showPassword,
                    suffix: IconButton(
                      icon: Icon(
                        showPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => showPassword = !showPassword);
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ===== CONFIRM PASSWORD =====
                  buildInput(
                    controller: confirmPassword,
                    hint: "Confirm Password",
                    icon: Icons.lock_outline,
                    obscure: !showConfirmPassword,
                    suffix: IconButton(
                      icon: Icon(
                        showConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(
                          () => showConfirmPassword = !showConfirmPassword,
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ===== REGISTER BUTTON =====
                  auth.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff2ECC71),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 4,
                            ),
                            onPressed: () async {
                              if (password.text != confirmPassword.text) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Password không khớp"),
                                  ),
                                );
                                return;
                              }

                              await context.read<AuthProvider>().register(
                                email: email.text.trim(),
                                password: password.text.trim(),
                                fullname: fullname.text.trim(),
                                phone: phone.text.trim(),
                                dob: dob.text.trim(),
                              );

                              if (context.mounted) Navigator.pop(context);
                            },
                            child: const Text(
                              "REGISTER",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff006d37),
                              ),
                            ),
                          ),
                        ),

                  const SizedBox(height: 20),

                  // ===== FOOTER =====
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have account? "),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          "Sign In",
                          style: TextStyle(
                            color: Color(0xff006d37),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget buildInput({
  required TextEditingController controller,
  required String hint,
  required IconData icon,
  bool obscure = false,
  bool readOnly = false,
  VoidCallback? onTap,
  Widget? suffix,
}) {
  return TextField(
    controller: controller,
    obscureText: obscure,
    readOnly: readOnly,
    onTap: onTap,
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xfff5f7f7),
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
