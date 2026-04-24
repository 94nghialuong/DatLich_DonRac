import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const EditProfileScreen({super.key, required this.data});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final fullnameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final dobCtrl = TextEditingController();
  final avatarCtrl = TextEditingController();

  DateTime? selectedDob;

  final db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();

    fullnameCtrl.text = widget.data["fullName"] ?? "";
    phoneCtrl.text = widget.data["phone"] ?? "";
    avatarCtrl.text = widget.data["avatar"] ?? "";

    final dobStr = widget.data["dob"];
    if (dobStr != null && dobStr.toString().isNotEmpty) {
      try {
        selectedDob = DateTime.parse(dobStr);
        dobCtrl.text = DateFormat("yyyy/MM/dd").format(selectedDob!);
      } catch (_) {}
    }
  }

  void pickDobIOS() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) {
        DateTime tempDate = selectedDob ?? DateTime(2000, 1, 1);

        return Container(
          height: 320,
          color: Colors.white,
          child: Column(
            children: [
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: tempDate,
                  maximumDate: DateTime.now(),
                  onDateTimeChanged: (date) {
                    tempDate = date;
                  },
                ),
              ),
              CupertinoButton(
                child: const Text("Xong"),
                onPressed: () {
                  setState(() {
                    selectedDob = tempDate;
                    dobCtrl.text = DateFormat("yyyy/MM/dd").format(tempDate);
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> updateProfile() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await db.collection("users").doc(uid).update({
      "fullName": fullnameCtrl.text,
      "phone": phoneCtrl.text,
      "dob": dobCtrl.text,
      "avatar": avatarCtrl.text,
    });

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Cập nhật thành công")));

    Navigator.pop(context);
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffEAF7EF),

      appBar: AppBar(
        title: const Text(
          "Edit Profile",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xff2ecc71),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ===== AVATAR =====
            Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: avatarCtrl.text.isNotEmpty
                          ? NetworkImage(avatarCtrl.text)
                          : null,
                      child: avatarCtrl.text.isEmpty
                          ? const Icon(Icons.person, size: 50)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xff2ecc71),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  "Cập nhật ảnh đại diện",
                  style: TextStyle(
                    color: Color(0xff006d37),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ===== FORM CARD =====
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.08),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(
                children: [
                  buildInput(
                    controller: fullnameCtrl,
                    label: "FULL NAME",
                    icon: Icons.person,
                  ),

                  const SizedBox(height: 15),

                  buildInput(
                    controller: phoneCtrl,
                    label: "PHONE",
                    icon: Icons.phone,
                  ),

                  const SizedBox(height: 15),

                  buildInput(
                    controller: dobCtrl,
                    label: "DATE OF BIRTH",
                    icon: Icons.calendar_month,
                    readOnly: true,
                    onTap: pickDobIOS,
                  ),

                  const SizedBox(height: 15),

                  buildInput(
                    controller: avatarCtrl,
                    label: "AVATAR URL",
                    icon: Icons.link,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ===== ECO CARD =====
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: const [
                  Icon(Icons.eco, color: Colors.green),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Thành viên EcoService\nDữ liệu được bảo mật.",
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ===== SAVE BUTTON =====
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff2ecc71),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
                onPressed: updateProfile,
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text(
                  "Lưu",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== INPUT STYLE =====
  Widget buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            filled: true,
            fillColor: const Color(0xfff5f5f5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
