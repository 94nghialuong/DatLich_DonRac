import 'package:booking_don_rac/screens/user/paymen_screen.dart';
import 'package:booking_don_rac/screens/user/booking_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyBookingScreen extends StatelessWidget {
  const MyBookingScreen({super.key});

  Color statusColor(String status) {
    switch (status) {
      case "DONE":
        return const Color(0xFF2ECC71);
      case "PENDING":
        return Colors.orange;
      case "CANCELLED":
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  BoxDecoration cardBox() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF2ECC71).withOpacity(0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  String formatDate(Timestamp? ts) {
    if (ts == null) return "";
    final d = ts.toDate();
    return "${d.day}/${d.month}/${d.year}";
  }

  Widget buildBookingCard(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final id = doc.id;

    final status = data["status"] ?? "UNKNOWN";
    final createdAt = data["createdAt"] as Timestamp?;

    final serviceName = data["serviceName"] ?? "Không có dịch vụ";
    final price = data["price"] ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BookingDetailScreen(bookingId: id)),
        );
      },

      // ================= CARD =================
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: cardBox(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= TOP =================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "MÃ ĐƠN HÀNG",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "#$id",
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor(status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ================= SERVICE NAME =================
            Text(
              serviceName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 6),

            // ================= PRICE =================
            Text(
              "Giá: ${price.toString()} VNĐ",
              style: const TextStyle(
                fontSize: 14,
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 10),

            // ================= DATE =================
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  "Ngày tạo: ${formatDate(createdAt)}",
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // ================= ACTION =================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // PAYMENT BUTTON
                if (status == "COMPLETED")
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2ECC71),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: const Icon(
                      Icons.payment,
                      size: 18,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentScreen(bookingId: id),
                        ),
                      );
                    },
                    label: const Text(
                      "Thanh toán",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                else
                  const SizedBox(),

                // DETAIL
                Row(
                  children: [
                    Text(
                      "Chi tiết",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBookingList(
    BuildContext context,
    List<QueryDocumentSnapshot> docs,
    String emptyText,
  ) {
    if (docs.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: TextStyle(color: Colors.grey[600], fontSize: 15),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return buildBookingCard(context, docs[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final db = FirebaseFirestore.instance;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7F9),

        // ================= APPBAR =================
        appBar: AppBar(
          backgroundColor: const Color(0xFFEAF7EF),
          elevation: 0,
          title: const Text(
            "Đơn của tôi",
            style: TextStyle(
              color: Color(0xFF2ECC71),
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: const IconThemeData(color: Color(0xFF2ECC71)),
          bottom: const TabBar(
            labelColor: Color(0xFF2ECC71),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF2ECC71),
            tabs: [
              Tab(text: "Đang booking"),
              Tab(text: "Hoàn thành"),
              Tab(text: "Đã hủy"),
            ],
          ),
        ),

        // ================= BODY =================
        body: StreamBuilder<QuerySnapshot>(
          stream: db
              .collection("bookings")
              .where("userId", isEqualTo: uid)
              .orderBy("createdAt", descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text("Lỗi: ${snapshot.error}"));
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;

            if (docs.isEmpty) {
              return const Center(child: Text("Chưa có đơn"));
            }

            final bookingDocs = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final status = data["status"] ?? "UNKNOWN";

              return status != "COMPLETED" &&
                  status != "DONE" &&
                  status != "CANCELLED";
            }).toList();

            final completedDocs = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final status = data["status"] ?? "UNKNOWN";

              return status == "COMPLETED" || status == "DONE";
            }).toList();

            final cancelledDocs = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final status = data["status"] ?? "UNKNOWN";

              return status == "CANCELLED";
            }).toList();

            return TabBarView(
              children: [
                buildBookingList(
                  context,
                  bookingDocs,
                  "Không có đơn đang booking",
                ),
                buildBookingList(
                  context,
                  completedDocs,
                  "Không có đơn đã hoàn thành",
                ),
                buildBookingList(context, cancelledDocs, "Không có đơn đã hủy"),
              ],
            );
          },
        ),
      ),
    );
  }
}
