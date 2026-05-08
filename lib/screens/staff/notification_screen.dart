import 'package:booking_don_rac/provider/notification_provider.dart';
import 'package:booking_don_rac/screens/staff/chat_screen.dart';
import 'package:booking_don_rac/screens/staff/task_detail_screen.dart';
import 'package:booking_don_rac/screens/user/booking_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/task_model.dart';

class StaffNotificationScreen extends StatefulWidget {
  final String employeeId;
  final String employeeName;

  const StaffNotificationScreen({
    super.key,
    required this.employeeId,
    required this.employeeName,
  });

  @override
  State<StaffNotificationScreen> createState() =>
      _StaffNotificationScreenState();
}

class _StaffNotificationScreenState extends State<StaffNotificationScreen> {
  String employeeName = "";

  @override
  void initState() {
    super.initState();

    employeeName = widget.employeeName;

    Future.microtask(() {
      Provider.of<NotificationProvider>(
        context,
        listen: false,
      ).listenNotifications(userId: widget.employeeId, role: "STAFF");
    });
  }

  String formatTime(Timestamp? time) {
    if (time == null) return "";

    final date = time.toDate();

    return "${date.day}/${date.month}/${date.year} "
        "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  IconData getIcon(String type) {
    switch (type) {
      case "chat":
        return Icons.chat;

      case "booking_new":
        return Icons.assignment;

      case "booking_accepted":
        return Icons.engineering;

      case "booking_done":
        return Icons.done_all;

      case "payment":
        return Icons.payments;

      default:
        return Icons.notifications;
    }
  }

  Color getColor(bool isRead) {
    return isRead ? Colors.grey : Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NotificationProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        title: const Text("Thông báo công việc"),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () => provider.markAllAsRead(),
          ),
        ],
      ),

      body: provider.notifications.isEmpty
          ? const Center(child: Text("Không có thông báo"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: provider.notifications.length,
              itemBuilder: (context, index) {
                final doc = provider.notifications[index];
                final data = doc.data() as Map<String, dynamic>;

                final isRead = data["isRead"] ?? false;
                final type = (data["type"] ?? "").toString();
                final bookingId = data["bookingId"];
                final roomId = data["roomId"];

                return Card(
                  elevation: isRead ? 0 : 2,
                  color: isRead ? Colors.white : Colors.green.shade50,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),

                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),

                    onTap: () async {
                      if (!isRead) {
                        await provider.markAsRead(doc.id);
                      }

                      // ================= CHAT =================
                      if (type == "chat" && roomId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              roomId: roomId,
                              myId: widget.employeeId,
                              myName: employeeName,
                            ),
                          ),
                        );
                        return;
                      }

                      // ================= BOOKING / TASK =================
                      if (bookingId != null) {
                        final taskSnap = await FirebaseFirestore.instance
                            .collection("tasks")
                            .where("bookingId", isEqualTo: bookingId)
                            .where("employeeId", isEqualTo: widget.employeeId)
                            .limit(1)
                            .get();

                        if (taskSnap.docs.isNotEmpty) {
                          final task = TaskModel.fromDoc(
                            taskSnap.docs.first.id,
                            taskSnap.docs.first.data(),
                          );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TaskDetail(task: task),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  BookingDetailScreen(bookingId: bookingId),
                            ),
                          );
                        }
                      }
                    },

                    child: Padding(
                      padding: const EdgeInsets.all(14),

                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isRead
                                  ? Colors.grey.shade200
                                  : Colors.green.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(getIcon(type), color: getColor(isRead)),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data["title"] ?? "",
                                  style: TextStyle(
                                    fontWeight: isRead
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 5),

                                Text(data["content"] ?? ""),

                                const SizedBox(height: 5),

                                Text(
                                  formatTime(data["createdAt"]),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (!isRead)
                            const Icon(
                              Icons.circle,
                              size: 10,
                              color: Colors.green,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
