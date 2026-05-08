import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StaffReviewsScreen extends StatelessWidget {
  final String employeeId;

  const StaffReviewsScreen({super.key, required this.employeeId});

  // =====================================================
  // LOAD EXTRA DATA
  // =====================================================
  Future<Map<String, dynamic>> loadExtraData(
    String userId,
    String bookingId,
  ) async {
    try {
      String userName = "Khách hàng";
      String serviceName = "Dịch vụ";

      // ================= USER =================
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();

        userName = (userData?["fullName"] ?? "Khách hàng").toString();
      }

      // ================= BOOKING =================
      final bookingDoc = await FirebaseFirestore.instance
          .collection("bookings")
          .doc(bookingId)
          .get();

      if (bookingDoc.exists) {
        final bookingData = bookingDoc.data();

        final serviceId = (bookingData?["serviceId"] ?? "").toString();

        if (serviceId.isNotEmpty) {
          // ================= SERVICE =================
          final serviceDoc = await FirebaseFirestore.instance
              .collection("services")
              .doc(serviceId)
              .get();

          if (serviceDoc.exists) {
            final serviceData = serviceDoc.data();

            serviceName = (serviceData?["name"] ?? "Dịch vụ").toString();
          }
        }
      }

      return {"userName": userName, "serviceName": serviceName};
    } catch (e) {
      debugPrint("❌ LOAD REVIEW EXTRA ERROR: $e");

      return {"userName": "Khách hàng", "serviceName": "Dịch vụ"};
    }
  }

  // =====================================================
  // FORMAT TIME
  // =====================================================
  String formatTime(Timestamp time) {
    final date = time.toDate();

    return "${date.day}/${date.month}/${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  // =====================================================
  // STAR WIDGET
  // =====================================================
  Widget buildStars(int rating) {
    return Row(
      children: List.generate(
        5,
        (index) => Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 18,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(title: const Text("Đánh giá của tôi"), centerTitle: true),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("reviews")
            .where("employeeId", isEqualTo: employeeId)
            .snapshots(),

        builder: (context, snapshot) {
          // ================= LOADING =================
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ================= ERROR =================
          if (snapshot.hasError) {
            return Center(child: Text("ERROR: ${snapshot.error}"));
          }

          // ================= EMPTY =================
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("Chưa có đánh giá", style: TextStyle(fontSize: 16)),
            );
          }

          final docs = snapshot.data!.docs;

          // ================= SORT LOCAL =================
          docs.sort((a, b) {
            final aTime = (a["createdAt"] as Timestamp?);

            final bTime = (b["createdAt"] as Timestamp?);

            if (aTime == null && bTime == null) {
              return 0;
            }

            if (aTime == null) {
              return 1;
            }

            if (bTime == null) {
              return -1;
            }

            return bTime.compareTo(aTime);
          });

          // ================= AVG RATING =================
          double avg = 0;

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;

            avg += (data["rating"] ?? 0);
          }

          avg = avg / docs.length;

          return Column(
            children: [
              // =================================================
              // SUMMARY
              // =================================================
              Container(
                width: double.infinity,

                margin: const EdgeInsets.all(12),

                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: Colors.white,

                  borderRadius: BorderRadius.circular(16),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                    ),
                  ],
                ),

                child: Column(
                  children: [
                    Text(
                      avg.toStringAsFixed(1),

                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    buildStars(avg.round()),

                    const SizedBox(height: 8),

                    Text(
                      "${docs.length} đánh giá",
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),

              // =================================================
              // LIST
              // =================================================
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),

                  itemCount: docs.length,

                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;

                    final rating = (data["rating"] ?? 0) as int;

                    final comment = (data["comment"] ?? "").toString();

                    final createdAt = data["createdAt"];

                    final userId = (data["userId"] ?? "").toString();

                    final bookingId = (data["bookingId"] ?? "").toString();

                    return FutureBuilder<Map<String, dynamic>>(
                      future: loadExtraData(userId, bookingId),

                      builder: (context, extraSnap) {
                        final userName =
                            extraSnap.data?["userName"] ?? "Khách hàng";

                        final serviceName =
                            extraSnap.data?["serviceName"] ?? "Dịch vụ";

                        return Card(
                          elevation: 1,

                          margin: const EdgeInsets.only(bottom: 12),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),

                          child: Padding(
                            padding: const EdgeInsets.all(16),

                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                // ================= USER =================
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.green,

                                      child: Text(
                                        userName.isNotEmpty ? userName[0] : "K",

                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,

                                        children: [
                                          Text(
                                            userName,

                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,

                                              fontSize: 15,
                                            ),
                                          ),

                                          const SizedBox(height: 3),

                                          Text(
                                            serviceName,

                                            style: TextStyle(
                                              color: Colors.grey.shade700,

                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // ================= STARS =================
                                buildStars(rating),

                                const SizedBox(height: 10),

                                // ================= COMMENT =================
                                if (comment.isNotEmpty)
                                  Text(
                                    comment,

                                    style: const TextStyle(fontSize: 15),
                                  ),

                                const SizedBox(height: 10),

                                // ================= TIME =================
                                if (createdAt != null)
                                  Text(
                                    formatTime(createdAt as Timestamp),

                                    style: const TextStyle(
                                      color: Colors.grey,

                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
