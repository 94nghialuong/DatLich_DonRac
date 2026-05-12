import 'dart:async';

import 'package:booking_don_rac/models/booking_model.dart';
import 'package:booking_don_rac/provider/employee_provider.dart';
import 'package:booking_don_rac/screens/staff/reviews_screen.dart';
import 'package:booking_don_rac/services/common_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  static const Color _bg = Color(0xFFEEFDFD);
  static const Color _primary = Color(0xFF006D37);
  static const Color _primarySoft = Color(0xFF2ECC71);
  static const Color _surface = Colors.white;
  static const Color _surfaceContainer = Color(0xFFE3F0F1);
  static const Color _outline = Color(0xFF6C7B6D);
  static const Color _textDark = Color(0xFF121E1F);
  static const Color _textVariant = Color(0xFF3D4A3E);
  static const Color _error = Color(0xFFBA1A1A);

  final CommonService service = CommonService();
  final TextEditingController _searchController = TextEditingController();

  String searchText = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void onSearchChanged(String value) {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        searchText = value.toLowerCase().trim();
      });
    });
  }

  bool _matchSearch({
    required String changedBy,
    required String bookingId,
    required String serviceName,
    required String address,
    required String receiver,
    required String phone,
  }) {
    if (searchText.isEmpty) return true;

    final text = [
      changedBy,
      bookingId,
      serviceName,
      address,
      receiver,
      phone,
    ].join(' ').toLowerCase();

    return text.contains(searchText);
  }

  String _formatDateTime(dynamic value) {
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

  String _timeAgo(dynamic value) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    }

    if (date == null) return '';

    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays == 1) return 'Hôm qua';
    return '${diff.inDays} ngày trước';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeeProvider>();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _surface,
        foregroundColor: _primary,
        titleSpacing: 20,
        title: const Row(
          children: [
            Icon(Icons.history, color: _primary),
            SizedBox(width: 8),
            Text(
              'History',
              style: TextStyle(
                color: _primary,
                fontWeight: FontWeight.w600,
                fontSize: 22,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Đánh giá',
            icon: const Icon(Icons.reviews, color: _primary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      StaffReviewsScreen(employeeId: provider.userId),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            sliver: SliverToBoxAdapter(
              child: _SearchBox(
                controller: _searchController,
                onChanged: onSearchChanged,
                onClear: () {
                  _searchController.clear();
                  setState(() => searchText = '');
                },
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: provider.history,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(child: Text('ERROR: ${snapshot.error}')),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('No history')),
                );
              }

              final docs = snapshot.data!.docs;

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                sliver: SliverList.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final bookingId = data['bookingId']?.toString() ?? '';

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('bookings')
                          .doc(bookingId)
                          .get(),
                      builder: (context, bookingSnap) {
                        if (!bookingSnap.hasData ||
                            !bookingSnap.data!.exists ||
                            bookingSnap.data!.data() == null) {
                          return const SizedBox.shrink();
                        }

                        final booking = BookingModel.fromDoc(
                          bookingSnap.data!.id,
                          bookingSnap.data!.data() as Map<String, dynamic>,
                        );

                        return FutureBuilder<List<Map<String, dynamic>?>>(
                          future: Future.wait([
                            service.getService(booking.serviceId),
                            service.getAddress(booking.addressId),
                          ]),
                          builder: (context, extraSnap) {
                            if (!extraSnap.hasData) {
                              return const _LoadingHistoryCard();
                            }

                            final serviceData = extraSnap.data![0];
                            final address = extraSnap.data![1];

                            final serviceName =
                                serviceData?['name']?.toString() ?? 'Dịch vụ';
                            final fullAddress =
                                address?['fullAddress']?.toString() ??
                                'Không có địa chỉ';
                            final receiver =
                                address?['receiverName']?.toString() ??
                                'Không có tên';
                            final phone =
                                address?['phone']?.toString() ?? 'Không có SĐT';

                            final changedBy =
                                data['changedBy']?.toString() ?? '';
                            final oldStatus =
                                data['oldStatus']?.toString() ?? 'UNKNOWN';
                            final newStatus =
                                data['newStatus']?.toString() ?? 'UNKNOWN';
                            final createdAt = data['createdAt'];

                            final visible = _matchSearch(
                              changedBy: changedBy,
                              bookingId: bookingId,
                              serviceName: serviceName,
                              address: fullAddress,
                              receiver: receiver,
                              phone: phone,
                            );

                            if (!visible) return const SizedBox.shrink();

                            return _HistoryCard(
                              bookingId: bookingId,
                              serviceName: serviceName,
                              fullAddress: fullAddress,
                              receiver: receiver,
                              phone: phone,
                              bookingTime: _formatDateTime(booking.time),
                              oldStatus: oldStatus,
                              newStatus: newStatus,
                              changedAt: _formatDateTime(createdAt),
                              timeAgo: _timeAgo(createdAt),
                              changedBy: changedBy,
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBox({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Tìm theo Staff UID, booking, dịch vụ, địa chỉ...',
            prefixIcon: const Icon(
              Icons.search,
              color: _BookingHistoryScreenState._outline,
            ),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(onPressed: onClear, icon: const Icon(Icons.clear)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: BorderSide(
                color: _BookingHistoryScreenState._outline.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: BorderSide(
                color: _BookingHistoryScreenState._outline.withOpacity(0.3),
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(999)),
              borderSide: BorderSide(
                color: _BookingHistoryScreenState._primary,
                width: 1.5,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final String bookingId;
  final String serviceName;
  final String fullAddress;
  final String receiver;
  final String phone;
  final String bookingTime;
  final String oldStatus;
  final String newStatus;
  final String changedAt;
  final String timeAgo;
  final String changedBy;

  const _HistoryCard({
    required this.bookingId,
    required this.serviceName,
    required this.fullAddress,
    required this.receiver,
    required this.phone,
    required this.bookingTime,
    required this.oldStatus,
    required this.newStatus,
    required this.changedAt,
    required this.timeAgo,
    required this.changedBy,
  });

  @override
  Widget build(BuildContext context) {
    final status = _statusData(newStatus);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _BookingHistoryScreenState._surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E8449).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: status.iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(status.icon, color: status.iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🧹 $serviceName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _BookingHistoryScreenState._textDark,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Ref: #${_shortId(bookingId)}',
                      style: const TextStyle(
                        color: _BookingHistoryScreenState._outline,
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusChip(
                text: newStatus.toUpperCase(),
                bg: status.bg,
                fg: status.fg,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(
                  color: _BookingHistoryScreenState._outline.withOpacity(0.1),
                ),
              ),
            ),
            child: Column(
              children: [
                _InfoLine(icon: Icons.location_on, text: fullAddress),
                const SizedBox(height: 8),
                _InfoLine(icon: Icons.person, text: '$receiver • $phone'),
                if (bookingTime.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _InfoLine(icon: Icons.schedule, text: bookingTime),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          _StatusTransition(oldStatus: oldStatus, newStatus: newStatus),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  timeAgo.isEmpty ? changedAt : timeAgo,
                  style: const TextStyle(
                    color: _BookingHistoryScreenState._outline,
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  'By: ${changedBy.isEmpty ? 'Không rõ' : changedBy}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: _BookingHistoryScreenState._textVariant,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _shortId(String id) {
    if (id.length <= 8) return id;
    return id.substring(0, 8);
  }

  static ({Color bg, Color fg, IconData icon, Color iconBg, Color iconColor})
  _statusData(String raw) {
    final status = raw.toUpperCase();

    switch (status) {
      case 'COMPLETED':
      case 'DONE':
        return (
          bg: _BookingHistoryScreenState._primarySoft.withOpacity(0.14),
          fg: const Color(0xFF00723A),
          icon: Icons.delete_sweep,
          iconBg: const Color(0xFFE9F6F7),
          iconColor: _BookingHistoryScreenState._primary,
        );
      case 'ACCEPTED':
        return (
          bg: const Color(0xFF94F4AD),
          fg: const Color(0xFF00723A),
          icon: Icons.recycling,
          iconBg: const Color(0xFFE9F6F7),
          iconColor: _BookingHistoryScreenState._primary,
        );
      case 'CANCELLED':
        return (
          bg: const Color(0xFFFFDAD6),
          fg: const Color(0xFF93000A),
          icon: Icons.warning,
          iconBg: const Color(0xFFFFEBEE),
          iconColor: _BookingHistoryScreenState._error,
        );
      default:
        return (
          bg: _BookingHistoryScreenState._surfaceContainer,
          fg: _BookingHistoryScreenState._outline,
          icon: Icons.history,
          iconBg: const Color(0xFFE9F6F7),
          iconColor: _BookingHistoryScreenState._primary,
        );
    }
  }
}

class _StatusTransition extends StatelessWidget {
  final String oldStatus;
  final String newStatus;

  const _StatusTransition({required this.oldStatus, required this.newStatus});

  @override
  Widget build(BuildContext context) {
    final oldText = oldStatus.toUpperCase();
    final newText = newStatus.toUpperCase();
    final isCancelled = newText == 'CANCELLED';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _BookingHistoryScreenState._surfaceContainer.withOpacity(0.75),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 8,
        children: [
          _StatusText(
            text: oldText,
            color: _BookingHistoryScreenState._outline,
          ),
          Icon(
            Icons.trending_flat,
            color: isCancelled
                ? _BookingHistoryScreenState._error
                : _BookingHistoryScreenState._primary,
          ),
          _StatusText(
            text: newText,
            color: isCancelled
                ? _BookingHistoryScreenState._error
                : _BookingHistoryScreenState._primary,
            bold: true,
          ),
        ],
      ),
    );
  }
}

class _StatusText extends StatelessWidget {
  final String text;
  final Color color;
  final bool bold;

  const _StatusText({
    required this.text,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: bold ? FontWeight.bold : FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;

  const _StatusChip({required this.text, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _BookingHistoryScreenState._primary, size: 19),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _BookingHistoryScreenState._textVariant,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingHistoryCard extends StatelessWidget {
  const _LoadingHistoryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _BookingHistoryScreenState._surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const CircularProgressIndicator(strokeWidth: 2),
    );
  }
}
