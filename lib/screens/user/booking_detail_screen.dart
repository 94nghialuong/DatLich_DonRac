import 'package:booking_don_rac/screens/staff/chat_screen.dart';
import 'package:booking_don_rac/screens/user/paymen_screen.dart';
import 'package:booking_don_rac/screens/user/reviews_screen.dart';
import 'package:booking_don_rac/screens/user/tracking_screen.dart';
import 'package:booking_don_rac/services/chat_service.dart';
import 'package:booking_don_rac/services/review_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BookingDetailScreen extends StatefulWidget {
  final String bookingId;

  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final db = FirebaseFirestore.instance;
  final chatService = ChatService();
  final reviewService = ReviewService();

  Map<String, dynamic>? booking;
  Map<String, dynamic>? user;
  Map<String, dynamic>? address;
  Map<String, dynamic>? staffUser;

  String? staffId;
  bool isLoading = true;
  bool reviewed = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final bookingDoc = await db
        .collection("bookings")
        .doc(widget.bookingId)
        .get();

    if (!bookingDoc.exists) {
      setState(() => isLoading = false);
      return;
    }

    booking = bookingDoc.data();

    final userId = booking?["userId"];
    final addressId = booking?["addressId"];
    staffId = booking?["employeeId"];

    final results = await Future.wait([
      db.collection("users").doc(userId).get(),
      db.collection("addresses").doc(addressId).get(),
      if (staffId != null) db.collection("users").doc(staffId).get(),
    ]);

    user = results[0].data();
    address = results[1].data();

    if (staffId != null && results.length > 2) {
      staffUser = results[2].data();
    }

    reviewed = await reviewService.hasReviewed(widget.bookingId);

    setState(() => isLoading = false);
  }

  Color statusColor(String status) {
    switch (status) {
      case "COMPLETED":
        return Colors.green;
      case "PENDING":
        return Colors.orange;
      case "CANCELLED":
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  BoxDecoration cardBox() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(color: Colors.green.withOpacity(0.08), blurRadius: 12),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final status = booking?["status"] ?? "UNKNOWN";

    return Scaffold(
      backgroundColor: const Color(0xFFEAF7EF),

      appBar: AppBar(
        backgroundColor: const Color(0xFFEAF7EF),
        elevation: 0,
        title: const Text(
          "Chi tiết đơn hàng",
          style: TextStyle(
            color: Color(0xFF1E8449),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1E8449)),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ===== STATUS =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: cardBox(),
              child: Column(
                children: [
                  const Icon(Icons.push_pin, color: Colors.green, size: 40),
                  const SizedBox(height: 10),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: statusColor(status),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Đơn hàng đã cập nhật trạng thái",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ===== CUSTOMER =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: cardBox(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "👤 Khách hàng",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(user?["fullname"] ?? "N/A"),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ===== STAFF =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: cardBox(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "🧑‍🔧 Nhân viên",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Text(
                          (staffUser?["fullname"] ?? "?")[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        staffUser?["fullname"] ?? "Chưa có nhân viên",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ===== ADDRESS =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: cardBox(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "📍 Địa chỉ",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(address?["receiverName"] ?? ""),
                  Text(address?["phone"] ?? ""),
                  Text(address?["fullAddress"] ?? ""),
                  Text(address?["province"] ?? ""),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ===== BUTTONS =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: cardBox(),
              child: Column(
                children: [
                  // ===== TRACKING =====
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.location_on, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingTrackingScreen(
                              bookingId: widget.bookingId,
                            ),
                          ),
                        );
                      },
                      label: const Text(
                        "Theo dõi",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ===== CHAT =====
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.chat),
                      onPressed: () async {
                        if (staffId == null) return;

                        final roomId = await chatService.getRoomId(
                          widget.bookingId,
                          uid,
                          staffId!,
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              roomId: roomId,
                              myId: uid,
                              myName: user?["fullname"] ?? "",
                            ),
                          ),
                        );
                      },
                      label: const Text("Chat"),
                    ),
                  ),

                  // ===== PAYMENT =====
                  if (status == "COMPLETED") ...[
                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.payment, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PaymentScreen(bookingId: widget.bookingId),
                            ),
                          );
                        },
                        label: const Text(
                          "Thanh toán",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ===== REVIEW =====
            if (status == "COMPLETED")
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: cardBox(),
                child: reviewed
                    ? const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 10),
                          Text("Bạn đã đánh giá"),
                        ],
                      )
                    : ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        icon: const Icon(Icons.star),
                        onPressed: () async {
                          if (staffId == null) return;

                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReviewCreateScreen(
                                bookingId: widget.bookingId,
                                employeeId: staffId!,
                              ),
                            ),
                          );

                          reviewed = await reviewService.hasReviewed(
                            widget.bookingId,
                          );

                          setState(() {});
                        },
                        label: const Text(
                          "Đánh giá",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
