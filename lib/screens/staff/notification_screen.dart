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
  late String employeeName;

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

  String formatTime(dynamic time) {
    if (time == null) return "";

    if (time is Timestamp) {
      final date = time.toDate();

      return "${date.day}/${date.month}/${date.year} "
          "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    }

    return "";
  }

  IconData getIcon(String type) {
    switch (type.toLowerCase()) {
      case "chat":
        return Icons.chat;

      case "booking_new":
        return Icons.assignment;

      case "booking_assigned":
      case "task_assigned":
        return Icons.assignment_turned_in;

      case "task_started":
        return Icons.play_circle;

      case "task_completed":
        return Icons.task_alt;

      case "booking_accepted":
      case "booking_status":
        return Icons.engineering;

      case "booking_done":
        return Icons.done_all;

      case "payment":
      case "payment_success":
        return Icons.payments;

      case "review":
        return Icons.star;

      case "tracking_live":
        return Icons.location_searching;

      default:
        return Icons.notifications;
    }
  }

  Color getColor(String type, bool isRead) {
    if (isRead) return Colors.grey;

    switch (type.toLowerCase()) {
      case "chat":
        return Colors.blue;

      case "booking_new":
      case "booking_assigned":
      case "task_assigned":
      case "booking_accepted":
      case "booking_status":
        return Colors.green;

      case "task_started":
        return Colors.blue;

      case "task_completed":
        return Colors.teal;

      case "booking_done":
        return Colors.teal;

      case "review":
        return Colors.orange;

      case "payment":
      case "payment_success":
        return Colors.purple;

      case "tracking_live":
        return Colors.red;

      default:
        return Colors.green;
    }
  }

  Future<void> openNotification({
    required BuildContext context,
    required NotificationProvider provider,
    required String notificationId,
    required bool isRead,
    required String type,
    required dynamic bookingId,
    required dynamic roomId,
  }) async {
    if (!isRead) {
      await provider.markAsRead(notificationId);
    }

    if (!context.mounted) return;

    // ================= CHAT =================
    if (type == "chat") {
      if (roomId != null && roomId.toString().isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              roomId: roomId.toString(),
              myId: widget.employeeId,
              myName: employeeName,
            ),
          ),
        );
      }

      return;
    }

    // ================= BOOKING / TASK / REVIEW =================
    if (bookingId != null && bookingId.toString().isNotEmpty) {
      final taskSnap = await FirebaseFirestore.instance
          .collection("tasks")
          .where("bookingId", isEqualTo: bookingId.toString())
          .where("employeeId", isEqualTo: widget.employeeId)
          .limit(1)
          .get();

      if (!context.mounted) return;

      if (taskSnap.docs.isNotEmpty) {
        final task = TaskModel.fromDoc(
          taskSnap.docs.first.id,
          taskSnap.docs.first.data(),
        );

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TaskDetail(task: task)),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                BookingDetailScreen(bookingId: bookingId.toString()),
          ),
        );
      }
    }
  }

  Future<void> confirmDeleteOne({
    required BuildContext context,
    required NotificationProvider provider,
    required String notificationId,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Xóa thông báo"),
          content: const Text("Bạn có chắc muốn xóa thông báo này?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Xóa"),
            ),
          ],
        );
      },
    );

    if (ok == true) {
      await provider.deleteNotification(notificationId);
    }
  }

  Future<void> confirmDeleteAll({
    required BuildContext context,
    required NotificationProvider provider,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Xóa tất cả"),
          content: const Text("Bạn có chắc muốn xóa toàn bộ thông báo?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Xóa tất cả"),
            ),
          ],
        );
      },
    );

    if (ok == true) {
      await provider.deleteAllNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NotificationProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text("Thông báo công việc (${provider.unreadCount})"),
        actions: [
          IconButton(
            tooltip: "Đọc hết",
            icon: const Icon(Icons.done_all),
            onPressed: provider.notifications.isEmpty
                ? null
                : () => provider.markAllAsRead(),
          ),
          IconButton(
            tooltip: "Xóa hết",
            icon: const Icon(Icons.delete_sweep),
            onPressed: provider.notifications.isEmpty
                ? null
                : () => confirmDeleteAll(context: context, provider: provider),
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
                final taskId = data["taskId"];
                final roomId = data["roomId"];

                final title = (data["title"] ?? "Thông báo").toString();
                final content = (data["content"] ?? data["body"] ?? "").toString();

                final color = getColor(type, isRead);

                return Dismissible(
                  key: Key(doc.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) {
                        return AlertDialog(
                          title: const Text("Xóa thông báo"),
                          content: const Text(
                            "Bạn có chắc muốn xóa thông báo này?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Hủy"),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("Xóa"),
                            ),
                          ],
                        );
                      },
                    );

                    return ok == true;
                  },
                  onDismissed: (_) {
                    provider.deleteNotification(doc.id);
                  },
                  child: Card(
                    elevation: isRead ? 0 : 2,
                    color: isRead ? Colors.white : color.withOpacity(0.08),
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        openNotification(
                          context: context,
                          provider: provider,
                          notificationId: doc.id,
                          isRead: isRead,
                          type: type,
                          bookingId: bookingId,
                          roomId: roomId,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isRead
                                    ? Colors.grey.shade200
                                    : color.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(getIcon(type), color: color),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontWeight: isRead
                                          ? FontWeight.normal
                                          : FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    content,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  if ((bookingId ?? '').toString().isNotEmpty ||
                                      (taskId ?? '').toString().isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        if ((bookingId ?? '').toString().isNotEmpty)
                                          _MiniChip(text: 'Booking: ${_shortId(bookingId.toString())}'),
                                        if ((taskId ?? '').toString().isNotEmpty)
                                          _MiniChip(text: 'Task: ${_shortId(taskId.toString())}'),
                                      ],
                                    ),
                                  ],
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
                            const SizedBox(width: 8),
                            Column(
                              children: [
                                if (!isRead)
                                  Icon(Icons.circle, size: 10, color: color),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    confirmDeleteOne(
                                      context: context,
                                      provider: provider,
                                      notificationId: doc.id,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}


String _shortId(String id) {
  if (id.length <= 8) return id;
  return id.substring(0, 8);
}

class _MiniChip extends StatelessWidget {
  final String text;

  const _MiniChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.green,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
