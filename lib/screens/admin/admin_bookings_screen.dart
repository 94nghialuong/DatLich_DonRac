import 'package:booking_don_rac/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final NotificationService notificationService = NotificationService();

  String searchText = '';
  String statusFilter = 'ALL';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _updateBookingStatus(String bookingId, String status) async {
    final db = FirebaseFirestore.instance;
    final bookingRef = db.collection('bookings').doc(bookingId);

    final bookingDoc = await bookingRef.get();
    if (!bookingDoc.exists) return;

    final bookingData = bookingDoc.data() as Map<String, dynamic>;
    final oldStatus = bookingData['status']?.toString() ?? '';
    final userId = bookingData['userId']?.toString();
    final employeeId = bookingData['employeeId']?.toString();

    await bookingRef.update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
      if (status == 'CANCELLED') 'trackingStatus': 'STOPPED',
    });

    await db.collection('bookinghistory').add({
      'bookingId': bookingId,
      'employeeId': employeeId ?? '',
      'oldStatus': oldStatus,
      'newStatus': status,
      'changedBy': 'ADMIN',
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (status == 'CANCELLED') {
      await notificationService.notifyBookingCancelledByAdmin(
        bookingId: bookingId,
        userId: userId,
        employeeId: employeeId,
      );
    }

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Đã cập nhật booking sang $status')));
  }

  Future<void> _updatePaymentStatus(String bookingId, String status) async {
    final db = FirebaseFirestore.instance;

    await db.collection('bookings').doc(bookingId).update({
      'paymentStatus': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final paymentDocs = await db
        .collection('payment')
        .where('bookingId', isEqualTo: bookingId)
        .get();

    final batch = db.batch();

    for (final doc in paymentDocs.docs) {
      batch.update(doc.reference, {
        'status': status,
        if (status == 'PAID') 'paidAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã cập nhật thanh toán sang $status')),
    );
  }

  Future<Map<String, dynamic>?> _getAddress(String? addressId) async {
    if (addressId == null || addressId.isEmpty) return null;

    final doc = await FirebaseFirestore.instance
        .collection('addresses')
        .doc(addressId)
        .get();

    if (!doc.exists) return null;

    return doc.data();
  }

  Future<Map<String, dynamic>?> _getUser(String? userId) async {
    if (userId == null || userId.isEmpty) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    if (!doc.exists) return null;

    return doc.data();
  }

  Future<Map<String, dynamic>?> _getPayment(String bookingId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('payment')
        .where('bookingId', isEqualTo: bookingId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return snapshot.docs.first.data();
  }

  bool _matchBasic(Map<String, dynamic> data, String docId) {
    final status = (data['status'] ?? '').toString().toUpperCase();

    if (statusFilter != 'ALL' && status != statusFilter) return false;

    final keyword = searchText.trim().toLowerCase();
    if (keyword.isEmpty) return true;

    final text = [
      docId,
      data['status'],
      data['paymentStatus'],
      data['userId'],
      data['employeeId'],
      data['serviceId'],
      data['addressId'],
    ].whereType<Object>().join(' ').toLowerCase();

    return text.contains(keyword);
  }

  bool _matchDetail({
    required Map<String, dynamic>? user,
    required Map<String, dynamic>? address,
  }) {
    final keyword = searchText.trim().toLowerCase();
    if (keyword.isEmpty) return true;

    final text = [
      user?['fullname'],
      user?['fullName'],
      user?['email'],
      user?['phone'],
      address?['receiverName'],
      address?['phone'],
      address?['fullAddress'],
      address?['province'],
    ].whereType<Object>().join(' ').toLowerCase();

    return text.contains(keyword);
  }

  void _showBookingDetail({
    required BuildContext context,
    required String bookingId,
    required Map<String, dynamic> data,
    required Map<String, dynamic>? user,
    required Map<String, dynamic>? address,
    required Map<String, dynamic>? payment,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          maxChildSize: 0.95,
          builder: (context, controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Chi tiết booking',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _InfoRow(label: 'Mã booking', value: bookingId),
                _InfoRow(
                  label: 'Khách hàng',
                  value:
                      user?['fullname']?.toString() ??
                      user?['fullName']?.toString() ??
                      'N/A',
                ),
                _InfoRow(
                  label: 'Email',
                  value: user?['email']?.toString() ?? 'N/A',
                ),
                _InfoRow(
                  label: 'SĐT',
                  value:
                      address?['phone']?.toString() ??
                      user?['phone']?.toString() ??
                      'N/A',
                ),
                _InfoRow(
                  label: 'Người nhận',
                  value: address?['receiverName']?.toString() ?? 'N/A',
                ),
                _InfoRow(
                  label: 'Địa chỉ',
                  value: address?['fullAddress']?.toString() ?? 'N/A',
                ),
                _InfoRow(
                  label: 'Tỉnh/TP',
                  value: address?['province']?.toString() ?? 'N/A',
                ),
                _InfoRow(
                  label: 'Trạng thái',
                  value: data['status']?.toString() ?? 'N/A',
                ),
                _InfoRow(
                  label: 'Thanh toán',
                  value:
                      payment?['status']?.toString() ??
                      data['paymentStatus']?.toString() ??
                      'N/A',
                ),
                _InfoRow(
                  label: 'Phương thức',
                  value: payment?['method']?.toString() ?? 'N/A',
                ),
                _InfoRow(
                  label: 'Số tiền',
                  value: _money(
                    payment?['amount'] ??
                        data['price'] ??
                        data['amount'] ??
                        data['totalPrice'] ??
                        0,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () =>
                          _updateBookingStatus(bookingId, 'PENDING'),
                      icon: const Icon(Icons.pending_actions),
                      label: const Text('PENDING'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () =>
                          _updateBookingStatus(bookingId, 'ACCEPTED'),
                      icon: const Icon(Icons.check),
                      label: const Text('ACCEPTED'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () =>
                          _updateBookingStatus(bookingId, 'IN_PROGRESS'),
                      icon: const Icon(Icons.run_circle),
                      label: const Text('IN_PROGRESS'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () =>
                          _updateBookingStatus(bookingId, 'COMPLETED'),
                      icon: const Icon(Icons.done_all),
                      label: const Text('COMPLETED'),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () =>
                          _confirmCancelBooking(context, bookingId),
                      icon: const Icon(Icons.cancel, color: Colors.white),
                      label: const Text(
                        'CANCELLED',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _updatePaymentStatus(bookingId, 'PAID'),
                      icon: const Icon(Icons.payments),
                      label: const Text('Đã thanh toán'),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmCancelBooking(
    BuildContext context,
    String bookingId,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hủy booking?'),
        content: const Text(
          'Bạn có chắc chắn muốn hủy booking này không? User và nhân viên sẽ nhận thông báo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Hủy booking',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _updateBookingStatus(bookingId, 'CANCELLED');

      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => searchText = value),
                  decoration: InputDecoration(
                    hintText: 'Tìm booking, khách hàng, SĐT, địa chỉ...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchText.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => searchText = '');
                            },
                            icon: const Icon(Icons.clear),
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: statusFilter,
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('Tất cả')),
                  DropdownMenuItem(value: 'PENDING', child: Text('PENDING')),
                  DropdownMenuItem(value: 'ACCEPTED', child: Text('ACCEPTED')),
                  DropdownMenuItem(
                    value: 'IN_PROGRESS',
                    child: Text('IN_PROGRESS'),
                  ),
                  DropdownMenuItem(
                    value: 'COMPLETED',
                    child: Text('COMPLETED'),
                  ),
                  DropdownMenuItem(
                    value: 'CANCELLED',
                    child: Text('CANCELLED'),
                  ),
                ],
                onChanged: (v) => setState(() => statusFilter = v ?? 'ALL'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text('Lỗi tải booking: ${snapshot.error}'),
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _matchBasic(data, doc.id);
              }).toList();

              if (docs.isEmpty) {
                return const Center(child: Text('Không có booking phù hợp'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final bookingId = doc.id;
                  final userId = data['userId']?.toString();
                  final addressId = data['addressId']?.toString();

                  return FutureBuilder<List<Map<String, dynamic>?>>(
                    future: Future.wait([
                      _getUser(userId),
                      _getAddress(addressId),
                      _getPayment(bookingId),
                    ]),
                    builder: (context, detailSnapshot) {
                      if (detailSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Card(
                          child: ListTile(title: Text('Đang tải booking...')),
                        );
                      }

                      final user = detailSnapshot.data?[0];
                      final address = detailSnapshot.data?[1];
                      final payment = detailSnapshot.data?[2];

                      if (!_matchDetail(user: user, address: address)) {
                        return const SizedBox.shrink();
                      }

                      final fullname =
                          user?['fullname']?.toString() ??
                          user?['fullName']?.toString() ??
                          'Không rõ khách';

                      final phone =
                          address?['phone']?.toString() ??
                          user?['phone']?.toString() ??
                          '';

                      final fullAddress =
                          address?['fullAddress']?.toString() ??
                          'Không có địa chỉ';

                      final status = data['status']?.toString() ?? 'N/A';

                      final paymentStatus =
                          payment?['status']?.toString() ??
                          data['paymentStatus']?.toString() ??
                          'N/A';

                      return Card(
                        child: ListTile(
                          onTap: () => _showBookingDetail(
                            context: context,
                            bookingId: bookingId,
                            data: data,
                            user: user,
                            address: address,
                            payment: payment,
                          ),
                          leading: const Icon(
                            Icons.receipt_long,
                            color: Color(0xFF1E8449),
                          ),
                          title: Text(
                            fullAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Khách: $fullname'),
                              if (phone.isNotEmpty) Text('SĐT: $phone'),
                              Text(
                                'Booking: $status • Payment: $paymentStatus',
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value.startsWith('PAY_')) {
                                await _updatePaymentStatus(
                                  bookingId,
                                  value.replaceFirst('PAY_', ''),
                                );
                              } else if (value == 'CANCELLED') {
                                await _confirmCancelBooking(context, bookingId);
                              } else {
                                await _updateBookingStatus(bookingId, value);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'PENDING',
                                child: Text('Booking PENDING'),
                              ),
                              PopupMenuItem(
                                value: 'ACCEPTED',
                                child: Text('Booking ACCEPTED'),
                              ),
                              PopupMenuItem(
                                value: 'IN_PROGRESS',
                                child: Text('Booking IN_PROGRESS'),
                              ),
                              PopupMenuItem(
                                value: 'COMPLETED',
                                child: Text('Booking COMPLETED'),
                              ),
                              PopupMenuItem(
                                value: 'CANCELLED',
                                child: Text(
                                  'Booking CANCELLED',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                              PopupMenuDivider(),
                              PopupMenuItem(
                                value: 'PAY_PENDING',
                                child: Text('Payment PENDING'),
                              ),
                              PopupMenuItem(
                                value: 'PAY_PAID',
                                child: Text('Payment PAID'),
                              ),
                              PopupMenuItem(
                                value: 'PAY_CANCELLED',
                                child: Text('Payment CANCELLED'),
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
          ),
        ),
      ],
    );
  }

  static String _money(dynamic value) {
    final number = double.tryParse(value.toString()) ?? 0;
    return '${number.toStringAsFixed(0)}đ';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
