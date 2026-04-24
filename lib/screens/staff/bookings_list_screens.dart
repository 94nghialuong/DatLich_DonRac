import 'package:booking_don_rac/services/common_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/booking_model.dart';
import '../../provider/employee_provider.dart';

class BookingList extends StatefulWidget {
  @override
  State<BookingList> createState() => _BookingListState();
}

class _BookingListState extends State<BookingList> {
  final service = CommonService();

  String searchText = "";
  String selectedProvince = "All";
  String selectedStatus = "ALL";

  // 🔥 normalize province (fix lệch dấu / khoảng trắng)
  String normalize(String text) {
    return text.toLowerCase().trim().replaceAll("đ", "d");
  }

  String formatTime(Timestamp time) {
    final date = time.toDate();
    return "${date.day}/${date.month}/${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EmployeeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Bookings")),

      body: Column(
        children: [
          // ================= FILTER BAR =================
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                // 🔎 SEARCH
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: "Search address / name / phone / service",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchText = value.toLowerCase();
                    });
                  },
                ),

                const SizedBox(height: 8),

                // 🏙 PROVINCE + 📌 STATUS
                Row(
                  children: [
                    // ===== PROVINCE DROPDOWN =====
                    Expanded(
                      child: StreamBuilder(
                        stream: FirebaseFirestore.instance
                            .collection('addresses')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox();
                          }

                          final docs = snapshot.data!.docs;

                          final provinces = docs
                              .map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                return (data["province"] ?? "")
                                    .toString()
                                    .trim();
                              })
                              .where((p) => p.isNotEmpty)
                              .toSet()
                              .toList();

                          provinces.sort();

                          // 🔥 tránh crash dropdown
                          if (!provinces.contains(selectedProvince) &&
                              selectedProvince != "All") {
                            selectedProvince = "All";
                          }

                          return DropdownButton<String>(
                            value: selectedProvince,
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem(
                                value: "All",
                                child: Text("All Provinces"),
                              ),
                              ...provinces.map((p) {
                                return DropdownMenuItem(
                                  value: p,
                                  child: Text(p),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedProvince = value!;
                              });
                            },
                          );
                        },
                      ),
                    ),

                    const SizedBox(width: 8),

                    // ===== STATUS =====
                    Expanded(
                      child: DropdownButton<String>(
                        value: selectedStatus,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                            value: "ALL",
                            child: Text("All Status"),
                          ),
                          DropdownMenuItem(
                            value: "PENDING",
                            child: Text("Pending"),
                          ),
                          DropdownMenuItem(
                            value: "ACCEPTED",
                            child: Text("Accepted"),
                          ),
                          DropdownMenuItem(value: "DONE", child: Text("Done")),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedStatus = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ================= LIST =================
          Expanded(
            child: StreamBuilder(
              stream: provider.bookings,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                List<BookingModel> bookings = docs.map((doc) {
                  return BookingModel.fromDoc(
                    doc.id,
                    doc.data() as Map<String, dynamic>,
                  );
                }).toList();

                // 🔽 SORT
                bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                return ListView.builder(
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final b = bookings[index];

                    return FutureBuilder(
                      future: Future.wait([
                        service.getService(b.serviceId),
                        service.getAddress(b.addressId),
                      ]),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return const ListTile(title: Text("Loading..."));
                        }

                        final serviceData = snap.data![0];
                        final address = snap.data![1];

                        final serviceName = (serviceData?["name"] ?? "")
                            .toString();

                        final fullAddress = (address?["fullAddress"] ?? "")
                            .toString();

                        final province = (address?["province"] ?? "")
                            .toString();

                        final name = (address?["receiverName"] ?? "")
                            .toString();

                        final phone = (address?["phone"] ?? "").toString();

                        // ===== SEARCH =====
                        final matchSearch =
                            searchText.isEmpty ||
                            fullAddress.toLowerCase().contains(searchText) ||
                            name.toLowerCase().contains(searchText) ||
                            phone.toLowerCase().contains(searchText) ||
                            serviceName.toLowerCase().contains(searchText);

                        // ===== PROVINCE =====
                        final matchProvince =
                            selectedProvince == "All" ||
                            normalize(province) == normalize(selectedProvince);

                        // ===== STATUS =====
                        final matchStatus =
                            selectedStatus == "ALL" ||
                            (b.status ?? "").toString().toUpperCase() ==
                                selectedStatus;

                        if (!matchSearch || !matchProvince || !matchStatus) {
                          return const SizedBox.shrink();
                        }

                        return Card(
                          child: ListTile(
                            title: Text(
                              serviceName.isEmpty ? "Service" : serviceName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("📍 $fullAddress"),
                                Text("🏙️ $province"),
                                Text("👤 $name"),
                                Text("📞 $phone"),
                                Text(
                                  "📌 ${b.status}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "⏰ ${formatTime(b.time)}",
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                            trailing: ElevatedButton(
                              child: const Text("ACCEPT"),
                              onPressed: () {
                                provider.acceptBooking(b.id);
                              },
                            ),
                          ),
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
