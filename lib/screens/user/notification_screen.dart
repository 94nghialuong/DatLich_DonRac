import 'package:booking_don_rac/screens/user/booking_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/notification_provider.dart';

class NotificationScreen extends StatefulWidget {
  final String userId;
  final String role; // 🔥 thêm role

  const NotificationScreen({
    super.key,
    required this.userId,
    required this.role,
  });

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      Provider.of<NotificationProvider>(
        context,
        listen: false,
      ).listenNotifications(userId: widget.userId, role: widget.role);
    });
  }

  String formatTime(Timestamp time) {
    final date = time.toDate();
    return "${date.day}/${date.month}/${date.year} "
        "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NotificationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.role == "STAFF" ? "Thông báo công việc" : "Thông báo",
        ),
        actions: [
          TextButton(
            onPressed: () => provider.markAllAsRead(),
            child: const Text("Đọc hết", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: provider.notifications.isEmpty
          ? const Center(child: Text("Không có thông báo"))
          : ListView.builder(
              itemCount: provider.notifications.length,
              itemBuilder: (context, index) {
                final doc = provider.notifications[index];
                final data = doc.data() as Map<String, dynamic>;

                final isRead = data["isRead"] ?? false;
                final type = data["type"] ?? "normal";

                return InkWell(
                  onTap: () async {
                    final bookingId = data["bookingId"];

                    if (!isRead) {
                      await provider.markAsRead(doc.id);
                    }

                    // 👉 STAFF: mở booking mới
                    if (type == "bookings") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              BookingDetailScreen(bookingId: bookingId),
                        ),
                      );
                      return;
                    }

                    // 👉 USER: mở booking của mình
                    if (bookingId != null && bookingId.toString().isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              BookingDetailScreen(bookingId: bookingId),
                        ),
                      );
                    }
                  },
                  child: Container(
                    color: isRead ? Colors.white : Colors.green.shade50,
                    child: ListTile(
                      leading: Icon(
                        _getIcon(type),
                        color: isRead ? Colors.grey : Colors.green,
                      ),
                      title: Text(
                        data["title"] ?? "",
                        style: TextStyle(
                          fontWeight: isRead
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                  ),
                );
              },
            ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case "bookings":
        return Icons.assignment;
      case "done":
        return Icons.check_circle;
      default:
        return Icons.notifications;
    }
  }
}
