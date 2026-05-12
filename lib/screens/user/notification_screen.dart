import 'package:booking_don_rac/provider/notification_provider.dart';
import 'package:booking_don_rac/screens/staff/chat_screen.dart';
import 'package:booking_don_rac/screens/user/booking_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotificationScreen extends StatefulWidget {
  final String userId;
  final String role;
  final String userName;

  const NotificationScreen({
    super.key,
    required this.userId,
    required this.role,
    required this.userName,
  });

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  static const Color bgColor = Color(0xFFEEFDFD);
  static const Color primaryColor = Color(0xFF006D37);
  static const Color primarySoft = Color(0xFF2ECC71);
  static const Color surfaceColor = Colors.white;
  static const Color surfaceContainer = Color(0xFFE3F0F1);
  static const Color textDark = Color(0xFF121E1F);
  static const Color textVariant = Color(0xFF3D4A3E);
  static const Color outlineColor = Color(0xFF6C7B6D);
  static const Color errorColor = Color(0xFFBA1A1A);

  String currentUserName = '';

  @override
  void initState() {
    super.initState();

    currentUserName = widget.userName;

    Future.microtask(() async {
      Provider.of<NotificationProvider>(
        context,
        listen: false,
      ).listenNotifications(userId: widget.userId, role: widget.role);

      await _loadCurrentUserName();
    });
  }

  Future<void> _loadCurrentUserName() async {
    if (currentUserName.trim().isNotEmpty) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      final data = doc.data();

      if (!mounted) return;

      setState(() {
        currentUserName =
            data?['fullname']?.toString() ??
            data?['fullName']?.toString() ??
            data?['name']?.toString() ??
            widget.userName;
      });
    } catch (_) {}
  }

  String formatTime(Timestamp? time) {
    if (time == null) return '';

    final date = time.toDate();

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String timeAgo(Timestamp? time) {
    if (time == null) return '';

    final date = time.toDate();
    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays == 1) return 'Hôm qua';

    return formatTime(time);
  }

  IconData getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'booking_new':
      case 'new_booking':
        return Icons.assignment;

      case 'booking_created':
        return Icons.check_circle;

      case 'booking_accepted':
      case 'booking_assigned':
        return Icons.engineering;

      case 'booking_done':
      case 'task_completed':
        return Icons.done_all;

      case 'task_assigned':
        return Icons.assignment_ind;

      case 'task_started':
        return Icons.play_circle;

      case 'payment_success':
      case 'payment':
        return Icons.payments;

      case 'chat':
      case 'message':
      case 'new_message':
        return Icons.chat;

      case 'review':
      case 'review_reminder':
        return Icons.star;

      default:
        return Icons.notifications;
    }
  }

  Color getIconColor(String type, bool isRead) {
    if (isRead) return outlineColor;

    switch (type.toLowerCase()) {
      case 'chat':
      case 'message':
      case 'new_message':
        return Colors.blue;

      case 'payment_success':
      case 'payment':
        return Colors.orange;

      case 'review':
      case 'review_reminder':
        return Colors.amber;

      case 'booking_done':
      case 'task_completed':
        return primaryColor;

      case 'booking_new':
      case 'new_booking':
      case 'task_assigned':
        return Colors.deepOrange;

      default:
        return primaryColor;
    }
  }

  String _getSenderName(Map<String, dynamic> data) {
    final sender = data['sender'];

    if (sender is Map<String, dynamic>) {
      final senderMapName = sender['name']?.toString();

      if (senderMapName != null && senderMapName.trim().isNotEmpty) {
        return senderMapName;
      }
    }

    return data['senderName']?.toString() ??
        data['fromName']?.toString() ??
        data['userName']?.toString() ??
        data['customerName']?.toString() ??
        data['staffName']?.toString() ??
        'Người dùng';
  }

  String _getTitle(Map<String, dynamic> data) {
    final type = (data['type'] ?? '').toString().toLowerCase();

    if (type == 'chat' || type == 'message' || type == 'new_message') {
      final senderName = _getSenderName(data);
      return 'Tin nhắn từ $senderName';
    }

    return data['title']?.toString() ?? 'Thông báo';
  }

  String _getContent(Map<String, dynamic> data) {
    final type = (data['type'] ?? '').toString().toLowerCase();

    if (type == 'chat' || type == 'message' || type == 'new_message') {
      return data['message']?.toString() ??
          data['lastMessage']?.toString() ??
          data['content']?.toString() ??
          data['body']?.toString() ??
          'Bạn có tin nhắn mới';
    }

    return data['content']?.toString() ?? data['body']?.toString() ?? '';
  }

  Future<void> _deleteNotification(
    BuildContext context,
    NotificationProvider provider,
    String notificationId,
  ) async {
    await provider.deleteNotification(notificationId);

    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã xóa thông báo')));
  }

  Future<void> _confirmDeleteNotification(
    BuildContext context,
    NotificationProvider provider,
    String notificationId,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa thông báo?'),
        content: const Text('Bạn có chắc chắn muốn xóa thông báo này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: errorColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _deleteNotification(context, provider, notificationId);
    }
  }

  Future<void> _confirmClearAll(
    BuildContext context,
    NotificationProvider provider,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa tất cả thông báo?'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa toàn bộ thông báo không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: errorColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await provider.deleteAllNotifications();

    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã xóa tất cả thông báo')));
  }

  Future<void> _handleNotificationTap({
    required BuildContext context,
    required NotificationProvider provider,
    required DocumentSnapshot doc,
    required Map<String, dynamic> data,
  }) async {
    final isRead = data['isRead'] == true;

    if (!isRead) {
      await provider.markAsRead(doc.id);
    }

    final type = (data['type'] ?? '').toString().toLowerCase();
    final bookingId = data['bookingId']?.toString() ?? '';
    final roomId = data['roomId']?.toString() ?? '';

    if (type == 'chat' || type == 'message' || type == 'new_message') {
      if (roomId.isEmpty) return;
      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            roomId: roomId,
            myId: widget.userId,
            myName: currentUserName.trim().isEmpty
                ? widget.userName
                : currentUserName,
          ),
        ),
      );

      return;
    }

    if (bookingId.isNotEmpty) {
      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingDetailScreen(bookingId: bookingId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NotificationProvider>(context);
    final isStaff = widget.role.toUpperCase() == 'STAFF';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: surfaceColor,
        foregroundColor: primaryColor,
        titleSpacing: 20,
        title: Row(
          children: [
            const Icon(Icons.notifications, color: primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isStaff ? 'Thông báo công việc' : 'Thông báo',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Đọc hết',
            onPressed: provider.notifications.isEmpty
                ? null
                : () async {
                    await provider.markAllAsRead();
                  },
            icon: const Icon(Icons.done_all),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'CLEAR_ALL') {
                await _confirmClearAll(context, provider);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'CLEAR_ALL',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: errorColor),
                    SizedBox(width: 8),
                    Text('Xóa tất cả', style: TextStyle(color: errorColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.notifications.isEmpty
          ? const _EmptyNotificationView()
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                  sliver: SliverToBoxAdapter(
                    child: _SummaryCard(
                      total: provider.notifications.length,
                      unread: provider.unreadCount,
                      onMarkAllRead: provider.notifications.isEmpty
                          ? null
                          : () async {
                              await provider.markAllAsRead();
                            },
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
                  sliver: SliverList.separated(
                    itemCount: provider.notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final doc = provider.notifications[index];
                      final data = doc.data() as Map<String, dynamic>? ?? {};

                      final isRead = data['isRead'] == true;
                      final type = (data['type'] ?? '').toString();
                      final bookingId = data['bookingId']?.toString() ?? '';
                      final taskId = data['taskId']?.toString() ?? '';
                      final roomId = data['roomId']?.toString() ?? '';
                      final title = _getTitle(data);
                      final content = _getContent(data);

                      final createdAt = data['createdAt'] is Timestamp
                          ? data['createdAt'] as Timestamp
                          : null;

                      return Dismissible(
                        key: ValueKey(doc.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          alignment: Alignment.centerRight,
                          decoration: BoxDecoration(
                            color: errorColor,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (_) async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Xóa thông báo?'),
                              content: const Text(
                                'Bạn có chắc chắn muốn xóa thông báo này không?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Hủy'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: errorColor,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Xóa'),
                                ),
                              ],
                            ),
                          );

                          return ok == true;
                        },
                        onDismissed: (_) async {
                          await _deleteNotification(context, provider, doc.id);
                        },
                        child: _NotificationCard(
                          title: title,
                          content: content,
                          type: type,
                          isRead: isRead,
                          bookingId: bookingId,
                          taskId: taskId,
                          roomId: roomId,
                          createdAtText: timeAgo(createdAt),
                          icon: getIcon(type),
                          iconColor: getIconColor(type, isRead),
                          onTap: () => _handleNotificationTap(
                            context: context,
                            provider: provider,
                            doc: doc,
                            data: data,
                          ),
                          onMarkRead: isRead
                              ? null
                              : () async {
                                  await provider.markAsRead(doc.id);
                                },
                          onDelete: () => _confirmDeleteNotification(
                            context,
                            provider,
                            doc.id,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  static String _shortId(String id) {
    if (id.length <= 8) return id;
    return id.substring(0, 8);
  }
}

class _SummaryCard extends StatelessWidget {
  final int total;
  final int unread;
  final VoidCallback? onMarkAllRead;

  const _SummaryCard({
    required this.total,
    required this.unread,
    this.onMarkAllRead,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _NotificationScreenState.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _NotificationScreenState.primaryColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _NotificationScreenState.primarySoft.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active,
              color: _NotificationScreenState.primaryColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trung tâm thông báo',
                  style: TextStyle(
                    color: _NotificationScreenState.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$total thông báo • $unread chưa đọc',
                  style: const TextStyle(
                    color: _NotificationScreenState.textVariant,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (unread > 0)
            TextButton(
              onPressed: onMarkAllRead,
              child: const Text(
                'Đọc hết',
                style: TextStyle(
                  color: _NotificationScreenState.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final String title;
  final String content;
  final String type;
  final bool isRead;
  final String bookingId;
  final String taskId;
  final String roomId;
  final String createdAtText;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final VoidCallback? onMarkRead;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.title,
    required this.content,
    required this.type,
    required this.isRead,
    required this.bookingId,
    required this.taskId,
    required this.roomId,
    required this.createdAtText,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    required this.onDelete,
    this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isRead
        ? _NotificationScreenState.surfaceColor
        : _NotificationScreenState.primarySoft.withOpacity(0.08);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isRead ? Colors.transparent : iconColor.withOpacity(0.22),
            ),
            boxShadow: [
              BoxShadow(
                color: _NotificationScreenState.primaryColor.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(isRead ? 0.10 : 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor),
                  ),
                  if (!isRead)
                    Positioned(
                      right: -1,
                      top: -1,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _NotificationScreenState.errorColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _NotificationScreenState.textDark,
                              fontSize: 16,
                              fontWeight: isRead
                                  ? FontWeight.w600
                                  : FontWeight.bold,
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.more_vert,
                            color: _NotificationScreenState.outlineColor,
                          ),
                          onSelected: (value) {
                            if (value == 'READ') {
                              onMarkRead?.call();
                            }

                            if (value == 'DELETE') {
                              onDelete();
                            }
                          },
                          itemBuilder: (_) => [
                            if (!isRead)
                              const PopupMenuItem(
                                value: 'READ',
                                child: Row(
                                  children: [
                                    Icon(Icons.done, color: Colors.green),
                                    SizedBox(width: 8),
                                    Text('Đánh dấu đã đọc'),
                                  ],
                                ),
                              ),
                            const PopupMenuItem(
                              value: 'DELETE',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text(
                                    'Xóa',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (content.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        content,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _NotificationScreenState.textVariant,
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _TypeChip(type: type),
                        if (bookingId.isNotEmpty)
                          _MiniChip(
                            text:
                                'Booking: ${_NotificationScreenState._shortId(bookingId)}',
                          ),
                        if (taskId.isNotEmpty)
                          _MiniChip(
                            text:
                                'Task: ${_NotificationScreenState._shortId(taskId)}',
                          ),
                        if (roomId.isNotEmpty) const _MiniChip(text: 'Chat'),
                      ],
                    ),
                    if (createdAtText.isNotEmpty) ...[
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 15,
                            color: _NotificationScreenState.outlineColor,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            createdAtText,
                            style: const TextStyle(
                              color: _NotificationScreenState.outlineColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String type;

  const _TypeChip({required this.type});

  String get label {
    switch (type.toLowerCase()) {
      case 'chat':
      case 'message':
      case 'new_message':
        return 'TIN NHẮN';

      case 'payment':
      case 'payment_success':
        return 'THANH TOÁN';

      case 'review':
      case 'review_reminder':
        return 'ĐÁNH GIÁ';

      case 'task_assigned':
      case 'task_started':
      case 'task_completed':
        return 'TASK';

      case 'new_booking':
      case 'booking_new':
      case 'booking_assigned':
      case 'booking_accepted':
      case 'booking_done':
        return 'BOOKING';

      default:
        return 'THÔNG BÁO';
    }
  }

  @override
  Widget build(BuildContext context) {
    return _MiniChip(text: label);
  }
}

class _MiniChip extends StatelessWidget {
  final String text;

  const _MiniChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: _NotificationScreenState.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _NotificationScreenState.primaryColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _EmptyNotificationView extends StatelessWidget {
  const _EmptyNotificationView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _NotificationScreenState.surfaceColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: _NotificationScreenState.primaryColor.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none,
              size: 56,
              color: _NotificationScreenState.primaryColor,
            ),
            SizedBox(height: 12),
            Text(
              'Không có thông báo',
              style: TextStyle(
                color: _NotificationScreenState.textDark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Thông báo mới sẽ xuất hiện tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _NotificationScreenState.textVariant,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
