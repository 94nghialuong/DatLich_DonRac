import 'package:booking_don_rac/screens/staff/notification_screen.dart';
import 'package:booking_don_rac/services/common_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/booking_model.dart';
import '../../provider/employee_provider.dart';
import '../../provider/notification_provider.dart';

class BookingList extends StatefulWidget {
  final String employeeId;

  const BookingList({super.key, required this.employeeId});

  @override
  State<BookingList> createState() => _BookingListState();
}

class _BookingListState extends State<BookingList> {
  final service = CommonService();

  String searchText = "";
  String selectedProvince = "All";
  String selectedStatus = "ALL";

  @override
  void initState() {
    super.initState();

    // 🔥 realtime notification
    Future.microtask(() {
      Provider.of<NotificationProvider>(
        context,
        listen: false,
      ).listenNotifications(userId: widget.employeeId, role: "STAFF");
    });
  }

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
      appBar: AppBar(
        title: const Text("Staff Dashboard"),

        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notiProvider, _) {
              final unread = notiProvider.unreadCount;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),

                    onPressed: () {
                      Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder: (_) => StaffNotificationScreen(
                            employeeId: widget.employeeId,
                            employeeName: "Nhân viên",
                          ),
                        ),
                      );
                    },
                  ),

                  if (unread > 0)
                    Positioned(
                      right: 6,
                      top: 6,

                      child: Container(
                        padding: const EdgeInsets.all(4),

                        decoration: BoxDecoration(
                          color: Colors.red,

                          borderRadius: BorderRadius.circular(10),
                        ),

                        child: Text(
                          unread > 99 ? "99+" : "$unread",

                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          // ================= FILTER =================
          Padding(
            padding: const EdgeInsets.all(8),

            child: Column(
              children: [
                // 🔍 SEARCH
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),

                    hintText: "Search...",

                    border: OutlineInputBorder(),
                  ),

                  onChanged: (value) {
                    setState(() {
                      searchText = value.toLowerCase();
                    });
                  },
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    // ================= PROVINCE =================
                    Expanded(
                      child: StreamBuilder(
                        stream: FirebaseFirestore.instance
                            .collection('addresses')
                            .snapshots(),

                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox();
                          }

                          final provinces =
                              snapshot.data!.docs
                                  .map(
                                    (d) =>
                                        (d.data()['province'] ?? "").toString(),
                                  )
                                  .where((p) => p.isNotEmpty)
                                  .toSet()
                                  .toList()
                                ..sort();

                          return DropdownButton<String>(
                            value: selectedProvince,

                            isExpanded: true,

                            items: [
                              const DropdownMenuItem(
                                value: "All",

                                child: Text("All Provinces"),
                              ),

                              ...provinces.map(
                                (p) =>
                                    DropdownMenuItem(value: p, child: Text(p)),
                              ),
                            ],

                            onChanged: (v) {
                              setState(() {
                                selectedProvince = v!;
                              });
                            },
                          );
                        },
                      ),
                    ),

                    const SizedBox(width: 8),

                    // ================= STATUS =================
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

                        onChanged: (v) {
                          setState(() {
                            selectedStatus = v!;
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

                final bookings =
                    snapshot.data!.docs
                        .map(
                          (doc) => BookingModel.fromDoc(
                            doc.id,

                            doc.data() as Map<String, dynamic>,
                          ),
                        )
                        .toList()
                      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                // ================= FILTER =================
                final filtered = bookings.where((b) {
                  final status = (b.status ?? "").toUpperCase();

                  final matchStatus =
                      selectedStatus == "ALL" || status == selectedStatus;

                  return matchStatus;
                }).toList();

                return ListView.builder(
                  itemCount: filtered.length,

                  itemBuilder: (context, index) {
                    final b = filtered[index];

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

                        // ================= SEARCH =================
                        final matchSearch =
                            searchText.isEmpty ||
                            fullAddress.toLowerCase().contains(searchText) ||
                            name.toLowerCase().contains(searchText) ||
                            phone.toLowerCase().contains(searchText) ||
                            serviceName.toLowerCase().contains(searchText);

                        // ================= PROVINCE =================
                        final matchProvince =
                            selectedProvince == "All" ||
                            normalize(province) == normalize(selectedProvince);

                        if (!matchSearch || !matchProvince) {
                          return const SizedBox.shrink();
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),

                          child: ListTile(
                            title: Text(serviceName),

                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                Text("📍 $fullAddress"),

                                Text("🏙 $province"),

                                Text("👤 $name"),

                                Text("📞 $phone"),

                                Text("📌 ${b.status}"),

                                Text("⏰ ${formatTime(b.time)}"),
                              ],
                            ),

                            trailing: b.status == "PENDING"
                                ? ElevatedButton(
                                    child: const Text("ACCEPT"),

                                    onPressed: () {
                                      provider.acceptBooking(b.id);
                                    },
                                  )
                                : null,
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
