import 'dart:async';

import 'package:booking_don_rac/services/common_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/employee_provider.dart';
import '../../models/booking_model.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  final service = CommonService();

  String searchText = "";
  Timer? _debounce;

  void onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() {
        searchText = value.toLowerCase().trim();
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EmployeeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("History")),

      body: Column(
        children: [
          // ================= SEARCH STAFF UID =================
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: "Search by Staff UID...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ================= LIST =================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: provider.history,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("ERROR: ${snapshot.error}"));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No history"));
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;

                    final bookingId = data["bookingId"];
                    final changedBy = (data["changedBy"] ?? "")
                        .toString()
                        .toLowerCase();

                    // ================= FILTER STAFF UID =================
                    if (searchText.isNotEmpty &&
                        !changedBy.contains(searchText)) {
                      return const SizedBox.shrink();
                    }

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection("bookings")
                          .doc(bookingId)
                          .get(),
                      builder: (context, bookingSnap) {
                        if (!bookingSnap.hasData || !bookingSnap.data!.exists) {
                          return const SizedBox();
                        }

                        final booking = BookingModel.fromDoc(
                          bookingSnap.data!.id,
                          bookingSnap.data!.data() as Map<String, dynamic>,
                        );

                        return FutureBuilder(
                          future: Future.wait([
                            service.getService(booking.serviceId),
                            service.getAddress(booking.addressId),
                          ]),
                          builder: (context, extraSnap) {
                            if (!extraSnap.hasData) {
                              return const SizedBox();
                            }

                            final serviceData = extraSnap.data![0];
                            final address = extraSnap.data![1];

                            return Card(
                              margin: const EdgeInsets.all(10),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "🧹 ${serviceData?["name"] ?? ""}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),

                                    const SizedBox(height: 6),

                                    Text("📍 ${address?["fullAddress"] ?? ""}"),
                                    Text(
                                      "👤 ${address?["receiverName"] ?? ""}",
                                    ),
                                    Text("📞 ${address?["phone"] ?? ""}"),

                                    const SizedBox(height: 6),

                                    Text(
                                      "⏰ ${booking.time.toDate()}",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),

                                    const Divider(),

                                    Text(
                                      "${data["oldStatus"]} → ${data["newStatus"]}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),

                                    Text(
                                      (data["createdAt"] as Timestamp)
                                          .toDate()
                                          .toString(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),

                                    Text(
                                      "By: ${data["changedBy"]}",
                                      style: const TextStyle(fontSize: 12),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
