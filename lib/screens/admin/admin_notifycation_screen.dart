import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  static const Color bgColor = Color(0xFFEAF7EF);
  static const Color primaryColor = Color(0xFF1E8449);
  static const Color primaryDark = Color(0xFF006D37);
  static const Color cardColor = Colors.white;
  static const Color dangerColor = Colors.red;

  final TextEditingController _searchController = TextEditingController();

  String searchText = '';
  String roleFilter = 'ALL';

  FirebaseFirestore get db => FirebaseFirestore.instance;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchSearch(Map<String, dynamic> data, String docId) {
    final keyword = searchText.trim().toLowerCase();
    if (keyword.isEmpty) return true;

    final text = [
      docId,
      data['title'],
      data['content'],
      data['body'],
      data['type'],
      data['target'],
      data['receiverRole'],
      data['receiverId'],
      data['userId'],
      data['employeeId'],
      data['bookingId'],
      data['taskId'],
      data['roomId'],
    ].whereType<Object>().join(' ').toLowerCase();

    return text.contains(keyword);
  }

  bool _matchRole(Map<String, dynamic> data) {
    if (roleFilter == 'ALL') return true;

    final target = (data['target'] ?? '').toString().toUpperCase();
    final receiverRole = (data['receiverRole'] ?? '').toString().toUpperCase();

    if (roleFilter == 'CUSTOMER') {
      return target == 'CUSTOMER' ||
          target == 'USER' ||
          receiverRole == 'CUSTOMER' ||
          receiverRole == 'USER';
    }

    return target == roleFilter || receiverRole == roleFilter;
  }

  String _formatTime(dynamic value) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    }

    if (date == null) return '';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String _shortId(String id) {
    if (id.length <= 8) return id;
    return id.substring(0, 8);
  }

  IconData _iconByType(String type) {
    switch (type.toLowerCase()) {
      case 'chat':
      case 'message':
      case 'new_message':
        return Icons.chat;

      case 'payment':
      case 'payment_success':
        return Icons.payments;

      case 'review':
        return Icons.star;

      case 'booking_new':
      case 'new_booking':
        return Icons.receipt_long;

      case 'booking_cancelled':
        return Icons.cancel;

      case 'task_assigned':
      case 'task_started':
      case 'task_completed':
        return Icons.assignment;

      default:
        return Icons.notifications;
    }
  }

  Color _colorByType(String type, bool isRead) {
    if (isRead) return Colors.grey;

    switch (type.toLowerCase()) {
      case 'booking_cancelled':
        return Colors.red;

      case 'chat':
      case 'message':
      case 'new_message':
        return Colors.blue;

      case 'payment':
      case 'payment_success':
        return Colors.orange;

      case 'review':
        return Colors.amber;

      default:
        return primaryColor;
    }
  }

  Future<void> _markAsRead(String id) async {
    await db.collection('notifications').doc(id).update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _markAllAsRead() async {
    final snapshot = await db
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    await _commitInChunks(
      docs: snapshot.docs,
      action: (batch, doc) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      },
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã đánh dấu tất cả là đã đọc')),
    );
  }

  Future<void> _deleteNotification(String id) async {
    await db.collection('notifications').doc(id).delete();

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã xóa thông báo')));
  }

  Future<void> _deleteAllNotifications() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa tất cả thông báo?'),
        content: const Text(
          'Thao tác này sẽ xóa toàn bộ thông báo trong hệ thống.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: dangerColor),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Xóa tất cả',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final snapshot = await db.collection('notifications').get();

    await _commitInChunks(
      docs: snapshot.docs,
      action: (batch, doc) {
        batch.delete(doc.reference);
      },
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xóa tất cả thông báo hệ thống')),
    );
  }

  Future<void> _commitInChunks({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required void Function(
      WriteBatch batch,
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
    )
    action,
  }) async {
    const chunkSize = 450;

    for (int i = 0; i < docs.length; i += chunkSize) {
      final batch = db.batch();
      final end = (i + chunkSize > docs.length) ? docs.length : i + chunkSize;

      for (final doc in docs.sublist(i, end)) {
        action(batch, doc);
      }

      await batch.commit();
    }
  }

  Future<void> _confirmDeleteOne(String id) async {
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
            style: ElevatedButton.styleFrom(backgroundColor: dangerColor),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _deleteNotification(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,
        elevation: 1,
        title: const Text(
          'Thông báo hệ thống',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Đánh dấu tất cả đã đọc',
            onPressed: _markAllAsRead,
            icon: const Icon(Icons.done_all),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'DELETE_ALL') {
                _deleteAllNotifications();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'DELETE_ALL',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Xóa tất cả', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(
            searchController: _searchController,
            searchText: searchText,
            roleFilter: roleFilter,
            onSearchChanged: (value) => setState(() => searchText = value),
            onClearSearch: () {
              _searchController.clear();
              setState(() => searchText = '');
            },
            onRoleChanged: (value) {
              setState(() => roleFilter = value ?? 'ALL');
            },
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: db
                  .collection('notifications')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Lỗi tải thông báo: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data();
                  return _matchRole(data) && _matchSearch(data, doc.id);
                }).toList();

                if (docs.isEmpty) {
                  return const Center(
                    child: Text('Không có thông báo phù hợp'),
                  );
                }

                final total = snapshot.data!.docs.length;
                final unread = snapshot.data!.docs.where((doc) {
                  return doc.data()['isRead'] != true;
                }).length;

                return CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                      sliver: SliverToBoxAdapter(
                        child: _SummaryCard(
                          total: total,
                          unread: unread,
                          showing: docs.length,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      sliver: SliverList.separated(
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data();

                          final title =
                              data['title']?.toString() ?? 'Thông báo';
                          final content =
                              data['content']?.toString() ??
                              data['body']?.toString() ??
                              '';
                          final type = data['type']?.toString() ?? '';
                          final target =
                              data['receiverRole']?.toString() ??
                              data['target']?.toString() ??
                              'N/A';
                          final receiverId =
                              data['receiverId']?.toString() ??
                              data['userId']?.toString() ??
                              data['employeeId']?.toString() ??
                              '';
                          final bookingId = data['bookingId']?.toString() ?? '';
                          final taskId = data['taskId']?.toString() ?? '';
                          final isRead = data['isRead'] == true;

                          return _NotificationCard(
                            title: title,
                            content: content,
                            type: type,
                            target: target,
                            receiverId: receiverId,
                            bookingId: bookingId,
                            taskId: taskId,
                            time: _formatTime(data['createdAt']),
                            isRead: isRead,
                            icon: _iconByType(type),
                            iconColor: _colorByType(type, isRead),
                            shortId: _shortId,
                            onTap: () {
                              if (!isRead) {
                                _markAsRead(doc.id);
                              }
                            },
                            onMarkRead: isRead
                                ? null
                                : () => _markAsRead(doc.id),
                            onDelete: () => _confirmDeleteOne(doc.id),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final String searchText;
  final String roleFilter;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<String?> onRoleChanged;

  const _FilterBar({
    required this.searchController,
    required this.searchText,
    required this.roleFilter,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Tìm tiêu đề, nội dung, user, booking, task...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchText.isEmpty
                  ? null
                  : IconButton(
                      onPressed: onClearSearch,
                      icon: const Icon(Icons.clear),
                    ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: roleFilter,
            decoration: InputDecoration(
              labelText: 'Lọc người nhận',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'ALL', child: Text('Tất cả')),
              DropdownMenuItem(value: 'STAFF', child: Text('Staff')),
              DropdownMenuItem(value: 'CUSTOMER', child: Text('Customer/User')),
              DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
            ],
            onChanged: onRoleChanged,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int total;
  final int unread;
  final int showing;

  const _SummaryCard({
    required this.total,
    required this.unread,
    required this.showing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E8449).withOpacity(0.08),
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
              color: const Color(0xFF2ECC71).withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active,
              color: Color(0xFF1E8449),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tất cả thông báo hệ thống',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '$total tổng • $unread chưa đọc • Đang hiển thị $showing',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
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
  final String target;
  final String receiverId;
  final String bookingId;
  final String taskId;
  final String time;
  final bool isRead;
  final IconData icon;
  final Color iconColor;
  final String Function(String id) shortId;
  final VoidCallback onTap;
  final VoidCallback? onMarkRead;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.title,
    required this.content,
    required this.type,
    required this.target,
    required this.receiverId,
    required this.bookingId,
    required this.taskId,
    required this.time,
    required this.isRead,
    required this.icon,
    required this.iconColor,
    required this.shortId,
    required this.onTap,
    required this.onDelete,
    this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isRead ? Colors.white : const Color(0xFFEAF7EF),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isRead ? Colors.transparent : iconColor.withOpacity(0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E8449).withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: iconColor.withOpacity(0.14),
                    child: Icon(icon, color: iconColor),
                  ),
                  if (!isRead)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                      ),
                    ),
                    if (content.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        content,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _MiniChip(text: type.isEmpty ? 'NOTIFICATION' : type),
                        _MiniChip(text: 'To: $target'),
                        if (receiverId.isNotEmpty)
                          _MiniChip(text: 'UID: ${shortId(receiverId)}'),
                        if (bookingId.isNotEmpty)
                          _MiniChip(text: 'Booking: ${shortId(bookingId)}'),
                        if (taskId.isNotEmpty)
                          _MiniChip(text: 'Task: ${shortId(taskId)}'),
                      ],
                    ),
                    if (time.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'READ') onMarkRead?.call();
                  if (value == 'DELETE') onDelete();
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
                        Text('Xóa', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
        color: const Color(0xFFE3F0F1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF006D37),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
