import 'dart:io';
import 'package:booking_don_rac/screens/user/edit_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // ================= UPLOAD AVATAR =================
  Future<void> pickAndUploadAvatar(BuildContext context, String uid) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) return;

      File file = File(pickedFile.path);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final ref = FirebaseStorage.instance
          .ref()
          .child("avatars")
          .child("$uid.jpg");

      await ref.putFile(file);

      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection("users").doc(uid).update({
        "avatar": url,
      });

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cập nhật avatar thành công")),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Chưa đăng nhập")));
    }

    final userDoc = FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xffEAF7EF),

      appBar: AppBar(
        backgroundColor: const Color(0xffEAF7EF),
        elevation: 0,
        title: const Text(
          "Profile",
          style: TextStyle(color: Color(0xff1E8449)),
        ),
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xff2ECC71)),
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: userDoc,
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Không có dữ liệu"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // ================= AVATAR =================
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        backgroundImage:
                            data["avatar"] != null && data["avatar"] != ""
                            ? NetworkImage(data["avatar"])
                            : null,
                        child: (data["avatar"] == null || data["avatar"] == "")
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      ),
                    ),

                    // ICON CAMERA
                    Positioned(
                      bottom: 5,
                      right: 5,
                      child: GestureDetector(
                        onTap: () => pickAndUploadAvatar(context, user.uid),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xff2ECC71),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                Text(
                  data["fullname"] ?? data["fullName"] ?? "",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  user.email ?? "",
                  style: const TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 25),

                // ================= INFO CARD =================
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.08),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      buildRow(
                        Icons.person,
                        "Full Name",
                        data["fullname"] ?? data["fullName"] ?? "",
                      ),

                      const Divider(),

                      buildRow(Icons.call, "Phone", data["phone"] ?? ""),

                      const Divider(),

                      buildRow(
                        Icons.calendar_today,
                        "Date of Birth",
                        data["dob"] ?? "",
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // ================= EDIT BUTTON =================
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff2ECC71),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProfileScreen(data: data),
                        ),
                      );
                    },
                    label: const Text(
                      "Sửa thông tin",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ================= LOGOUT =================
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.logout),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      foregroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/login', (r) => false);
                    },
                    label: const Text("Đăng xuất"),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================= ITEM ROW =================
  Widget buildRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xffEEFDF6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xff2ECC71)),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
