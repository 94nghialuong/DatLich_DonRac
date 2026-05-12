import 'package:booking_don_rac/screens/user/tracking_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TrackingListScreen extends StatelessWidget {
  const TrackingListScreen({super.key});

  String getAddress(Map<String, dynamic> data) {
    return (data["address"] ??
            data["fullAddress"] ??
            data["pickupAddress"] ??
            data["userAddress"] ??
            data["locationText"] ??
            "Không có địa chỉ")
        .toString();
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "ACCEPTED":
        return Colors.blue;
      case "IN_PROGRESS":
        return Colors.green;
      case "DONE":
      case "COMPLETED":
        return Colors.teal;
      case "CANCELLED":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String formatTime(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      return "${date.day}/${date.month}/${date.year} "
          "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    }

    return "Không rõ";
  }

  bool hasValidLocation(Map<String, dynamic> tracking) {
    final location = tracking["location"];

    if (location is GeoPoint) {
      return location.latitude != 0 || location.longitude != 0;
    }

    final lat = tracking["lat"];
    final lng = tracking["lng"];

    if (lat is num && lng is num) {
      return lat != 0 || lng != 0;
    }

    return false;
  }

  Future<Map<String, dynamic>?> getBookingData({
    required FirebaseFirestore db,
    required String bookingId,
    required String uid,
  }) async {
    final bookingDoc = await db.collection("bookings").doc(bookingId).get();

    if (!bookingDoc.exists) return null;

    final data = bookingDoc.data();
    if (data == null) return null;

    if (data["userId"] != uid) return null;

    return data;
  }

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(body: Center(child: Text("Bạn chưa đăng nhập")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Theo dõi đơn"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: db.collection("tracking").snapshots(),
        builder: (context, trackingSnapshot) {
          if (trackingSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (trackingSnapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Lỗi: ${trackingSnapshot.error}",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final trackingDocs =
              trackingSnapshot.data?.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return hasValidLocation(data);
              }).toList() ??
              [];

          if (trackingDocs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  "Chưa có đơn nào có định vị",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: Future.wait(
              trackingDocs.map((trackingDoc) async {
                final trackingData = trackingDoc.data() as Map<String, dynamic>;

                final bookingId = (trackingData["bookingId"] ?? trackingDoc.id)
                    .toString();

                final bookingData = await getBookingData(
                  db: db,
                  bookingId: bookingId,
                  uid: uid,
                );

                if (bookingData == null) {
                  return {};
                }

                return {
                  "id": bookingId,
                  "booking": bookingData,
                  "tracking": trackingData,
                };
              }),
            ),
            builder: (context, bookingSnapshot) {
              if (bookingSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final items = (bookingSnapshot.data ?? [])
                  .where((item) => item.isNotEmpty)
                  .toList();

              items.sort((a, b) {
                final aBooking = a["booking"] as Map<String, dynamic>;
                final bBooking = b["booking"] as Map<String, dynamic>;

                final aTime = aBooking["createdAt"];
                final bTime = bBooking["createdAt"];

                if (aTime is Timestamp && bTime is Timestamp) {
                  return bTime.compareTo(aTime);
                }

                return 0;
              });

              if (items.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      "Chưa có đơn nào có định vị",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = items[index];

                  final bookingId = item["id"].toString();
                  final booking = item["booking"] as Map<String, dynamic>;
                  final tracking = item["tracking"] as Map<String, dynamic>;

                  final status = (booking["status"] ?? "PENDING").toString();

                  final paymentStatus = (booking["paymentStatus"] ?? "UNPAID")
                      .toString();

                  final trackingStatus = (booking["trackingStatus"] ?? "")
                      .toString();

                  final isLive =
                      tracking["isTracking"] == true ||
                      trackingStatus == "LIVE";

                  final address = getAddress(booking);

                  final employeeId =
                      (booking["employeeId"] ?? tracking["employeeId"] ?? "")
                          .toString();

                  final createdText = formatTime(booking["createdAt"]);
                  final updatedText = formatTime(tracking["updatedAt"]);

                  final statusColor = getStatusColor(status);

                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              BookingTrackingScreen(bookingId: bookingId),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: statusColor.withOpacity(0.12),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.location_on, color: statusColor),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "Booking #$bookingId",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),

                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isLive
                                            ? Colors.green.withOpacity(0.12)
                                            : Colors.grey.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        isLive ? "LIVE" : "OFF",
                                        style: TextStyle(
                                          color: isLive
                                              ? Colors.green
                                              : Colors.grey,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.place,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        address,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 6),

                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color: statusColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      status,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Icon(
                                      Icons.payments_outlined,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      paymentStatus,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),

                                if (employeeId.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.person,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          "Nhân viên: $employeeId",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],

                                const SizedBox(height: 6),

                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        "Tạo: $createdText",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 4),

                                Row(
                                  children: [
                                    const Icon(
                                      Icons.gps_fixed,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        "GPS: $updatedText",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 6),

                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
