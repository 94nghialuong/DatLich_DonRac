import 'package:booking_don_rac/screens/staff/task_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/task_model.dart';
import '../../models/booking_model.dart';
import '../../provider/employee_provider.dart';
import '../../services/common_service.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final service = CommonService();

  String searchText = "";

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EmployeeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: const InputDecoration(
            hintText: "Search task...",
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {
              searchText = value.toLowerCase().trim();
            });
          },
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: provider.tasks,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No tasks"));
          }

          final tasks = snapshot.data!.docs.map((doc) {
            return TaskModel.fromDoc(
              doc.id,
              doc.data() as Map<String, dynamic>,
            );
          }).toList();

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final t = tasks[index];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection("bookings")
                    .doc(t.bookingId)
                    .get(),
                builder: (context, bookingSnap) {
                  if (!bookingSnap.hasData) {
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
                    builder: (context, dataSnap) {
                      if (!dataSnap.hasData) {
                        return const SizedBox();
                      }

                      final serviceData = dataSnap.data![0];
                      final address = dataSnap.data![1];

                      // ================= FILTER =================
                      final name = (serviceData?["name"] ?? "")
                          .toString()
                          .toLowerCase();
                      final fullAddress = (address?["fullAddress"] ?? "")
                          .toString()
                          .toLowerCase();
                      final receiver = (address?["receiverName"] ?? "")
                          .toString()
                          .toLowerCase();
                      final phone = (address?["phone"] ?? "")
                          .toString()
                          .toLowerCase();

                      if (searchText.isNotEmpty &&
                          !name.contains(searchText) &&
                          !fullAddress.contains(searchText) &&
                          !receiver.contains(searchText) &&
                          !phone.contains(searchText)) {
                        return const SizedBox();
                      }

                      return Card(
                        margin: const EdgeInsets.all(10),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TaskDetail(task: t),
                              ),
                            );
                          },

                          title: Text(
                            "🧹 ${serviceData?["name"] ?? ""}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),

                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("📍 ${address?["fullAddress"] ?? ""}"),
                              Text("👤 ${address?["receiverName"] ?? ""}"),
                              Text("📞 ${address?["phone"] ?? ""}"),

                              const SizedBox(height: 5),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: getStatusColor(
                                    t.status,
                                  ).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  t.status,
                                  style: TextStyle(
                                    color: getStatusColor(t.status),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
    );
  }

  // ================= STATUS COLOR =================
  Color getStatusColor(String status) {
    switch (status) {
      case "ASSIGNED":
        return Colors.orange;
      case "IN_PROGRESS":
        return Colors.blue;
      case "COMPLETED":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
