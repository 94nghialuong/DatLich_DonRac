import 'package:booking_don_rac/screens/staff/chat_screen.dart';
import 'package:booking_don_rac/screens/user/tracking_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/chat_service.dart';

class BookingDetailScreen extends StatefulWidget {
  final String bookingId;

  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final db = FirebaseFirestore.instance;
  final chatService = ChatService();

  Map<String, dynamic>? booking;
  Map<String, dynamic>? user;
  Map<String, dynamic>? address;

  String? staffId;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      // ===== BOOKING =====
      final bookingDoc = await db
          .collection("bookings")
          .doc(widget.bookingId)
          .get();

      if (!bookingDoc.exists) return;

      booking = bookingDoc.data();

      final userId = booking!["userId"];
      final addressId = booking!["addressId"];
      staffId = booking!["employeeId"];

      // ===== FALLBACK TASK =====
      if (staffId == null || staffId!.isEmpty) {
        final taskSnap = await db
            .collection("tasks")
            .where("bookingId", isEqualTo: widget.bookingId)
            .limit(1)
            .get();

        if (taskSnap.docs.isNotEmpty) {
          staffId = taskSnap.docs.first["employeeId"];
        }
      }

      // ===== LOAD USER + ADDRESS =====
      final results = await Future.wait([
        db.collection("users").doc(userId).get(),
        db.collection("addresses").doc(addressId).get(),
      ]);

      user = results[0].data();
      address = results[1].data();

      setState(() => isLoading = false);
    } catch (e) {
      print("❌ LOAD ERROR: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (booking == null) {
      return const Scaffold(
        body: Center(child: Text("Không tìm thấy booking")),
      );
    }

    final fullName = user?["fullName"] ?? "No name";

    final fullAddress = address?["fullAddress"] ?? "";
    final province = address?["province"] ?? "";
    final receiverName = address?["receiverName"] ?? "";
    final phone = address?["phone"] ?? "";
    final label = address?["label"] ?? "";

    final employeeDisplay = (staffId != null && staffId!.isNotEmpty)
        ? staffId!
        : "Chưa có nhân viên";

    return Scaffold(
      appBar: AppBar(title: const Text("Chi tiết booking")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== STATUS =====
            Text(
              "📌 Status: ${booking!["status"]}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            const SizedBox(height: 20),

            // ===== CUSTOMER =====
            const Text(
              "👤 Khách hàng",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text("Tên: $fullName"),

            const SizedBox(height: 20),

            // ===== EMPLOYEE =====
            const Text(
              "🧑‍🔧 Nhân viên",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text("ID: $employeeDisplay"),

            const SizedBox(height: 20),

            // ===== ADDRESS =====
            const Text(
              "📍 Địa chỉ",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text("Label: $label"),
            Text("Người nhận: $receiverName"),
            Text("SĐT: $phone"),
            Text("Địa chỉ: $fullAddress"),
            Text("Tỉnh: $province"),

            const SizedBox(height: 30),

            // ===== TRACK =====
            ElevatedButton.icon(
              icon: const Icon(Icons.location_on),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        BookingTrackingScreen(bookingId: widget.bookingId),
                  ),
                );
              },
              label: const Text("Theo dõi nhân viên"),
            ),

            const SizedBox(height: 10),

            // ===== CHAT =====
            ElevatedButton(
              onPressed: () async {
                try {
                  if (staffId == null || staffId!.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Đơn chưa có nhân viên nhận"),
                      ),
                    );
                    return;
                  }

                  final roomId = await chatService.getRoomId(
                    widget.bookingId,
                    uid,
                    staffId!,
                  );

                  if (!mounted) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        roomId: roomId,
                        myId: uid,
                        myName: fullName,
                      ),
                    ),
                  );
                } catch (e) {
                  print("❌ CHAT ERROR: $e");

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Không thể mở chat")),
                  );
                }
              },
              child: const Text("Chat với nhân viên"),
            ),
          ],
        ),
      ),
    );
  }
}
