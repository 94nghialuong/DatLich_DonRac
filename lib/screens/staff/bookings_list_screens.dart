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
  static const Color _bg = Color(0xFFEEFDFD);
  static const Color _primary = Color(0xFF006D37);
  static const Color _surface = Colors.white;
  static const Color _error = Color(0xFFBA1A1A);

  final CommonService service = CommonService();
  final TextEditingController _searchController = TextEditingController();

  String searchText = '';
  String selectedProvince = 'All';

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<NotificationProvider>().listenNotifications(
        userId: widget.employeeId,
        role: 'STAFF',
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String normalize(String text) {
    return text.toLowerCase().trim().replaceAll('đ', 'd');
  }

  String formatTime(Timestamp time) {
    final date = time.toDate();

    return '${date.day}/${date.month}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  bool _matchFilter({
    required String serviceName,
    required String fullAddress,
    required String province,
    required String name,
    required String phone,
  }) {
    final keyword = normalize(searchText);

    final matchProvince =
        selectedProvince == 'All' ||
        normalize(province) == normalize(selectedProvince);

    final matchSearch =
        keyword.isEmpty ||
        normalize(serviceName).contains(keyword) ||
        normalize(fullAddress).contains(keyword) ||
        normalize(province).contains(keyword) ||
        normalize(name).contains(keyword) ||
        normalize(phone).contains(keyword);

    return matchProvince && matchSearch;
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
            Icon(Icons.eco, color: _primary),
            SizedBox(width: 8),
            Text(
              'Staff Dashboard',
              style: TextStyle(
                color: _primary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notiProvider, _) {
              final unread = notiProvider.unreadCount;

              return Stack(
                children: [
                  IconButton(
                    tooltip: 'Thông báo',
                    icon: const Icon(Icons.notifications, color: _primary),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StaffNotificationScreen(
                            employeeId: widget.employeeId,
                            employeeName: 'Nhân viên',
                          ),
                        ),
                      );
                    },
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 7,
                      top: 7,
                      child: Container(
                        width: 18,
                        height: 18,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _error,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text(
                          unread > 9 ? '9+' : '$unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _FilterSection(
            searchController: _searchController,
            searchText: searchText,
            selectedProvince: selectedProvince,
            onSearchChanged: (value) {
              setState(() => searchText = value);
            },
            onClearSearch: () {
              _searchController.clear();
              setState(() => searchText = '');
            },
            onProvinceChanged: (value) {
              setState(() => selectedProvince = value ?? 'All');
            },
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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

                if (bookings.isEmpty) {
                  return const Center(child: Text('Chưa có booking nào'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];

                    return FutureBuilder<List<Map<String, dynamic>?>>(
                      future: Future.wait([
                        service.getService(booking.serviceId),
                        service.getAddress(booking.addressId),
                      ]),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return const _LoadingCard();
                        }

                        final serviceData = snap.data![0];
                        final address = snap.data![1];

                        final serviceName = (serviceData?['name'] ?? 'Dịch vụ')
                            .toString();

                        final fullAddress = (address?['fullAddress'] ?? '')
                            .toString();

                        final province = (address?['province'] ?? '')
                            .toString();

                        final name = (address?['receiverName'] ?? '')
                            .toString();

                        final phone = (address?['phone'] ?? '').toString();

                        final visible = _matchFilter(
                          serviceName: serviceName,
                          fullAddress: fullAddress,
                          province: province,
                          name: name,
                          phone: phone,
                        );

                        if (!visible) return const SizedBox.shrink();

                        final status = booking.status ?? 'UNKNOWN';

                        return _BookingCard(
                          serviceName: serviceName,
                          fullAddress: fullAddress,
                          province: province,
                          name: name,
                          phone: phone,
                          status: status,
                          time: formatTime(booking.time),
                          onAccept: status.toUpperCase() == 'PENDING'
                              ? () => provider.acceptBooking(booking.id)
                              : null,
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

class _FilterSection extends StatelessWidget {
  final TextEditingController searchController;
  final String searchText;
  final String selectedProvince;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<String?> onProvinceChanged;

  const _FilterSection({
    required this.searchController,
    required this.searchText,
    required this.selectedProvince,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onProvinceChanged,
  });

  static const Color _primary = Color(0xFF006D37);
  static const Color _outline = Color(0xFF6C7B6D);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Tìm địa chỉ, tên khách hoặc dịch vụ...',
              prefixIcon: const Icon(Icons.search, color: _outline),
              suffixIcon: searchText.isEmpty
                  ? null
                  : IconButton(
                      onPressed: onClearSearch,
                      icon: const Icon(Icons.clear),
                    ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
              border: _border(),
              enabledBorder: _border(),
              focusedBorder: _border(color: _primary, width: 1.5),
            ),
          ),
          const SizedBox(height: 14),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('addresses')
                .snapshots(),
            builder: (context, snapshot) {
              final provinces = snapshot.hasData
                  ? (snapshot.data!.docs
                        .map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return (data['district'] ?? '').toString();
                        })
                        .where((province) => province.isNotEmpty)
                        .toSet()
                        .toList()
                      ..sort())
                  : <String>[];

              return _PillDropdown(
                value: selectedProvince,
                items: [
                  const DropdownMenuItem(
                    value: 'All',
                    child: Text('Tất cả các huyện'),
                  ),
                  ...provinces.map(
                    (province) => DropdownMenuItem(
                      value: province,
                      child: Text(province),
                    ),
                  ),
                ],
                onChanged: onProvinceChanged,
              );
            },
          ),
        ],
      ),
    );
  }

  static OutlineInputBorder _border({
    Color color = const Color(0x4D6C7B6D),
    double width = 1,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(999),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _PillDropdown extends StatelessWidget {
  final String value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const _PillDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  static const Color _primary = Color(0xFF006D37);
  static const Color _outline = Color(0xFF6C7B6D);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      icon: const Icon(Icons.expand_more, color: _outline),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        border: _border(),
        enabledBorder: _border(),
        focusedBorder: _border(color: _primary, width: 1.5),
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  static OutlineInputBorder _border({
    Color color = const Color(0x4D6C7B6D),
    double width = 1,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(999),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final String serviceName;
  final String fullAddress;
  final String province;
  final String name;
  final String phone;
  final String status;
  final String time;
  final VoidCallback? onAccept;

  const _BookingCard({
    required this.serviceName,
    required this.fullAddress,
    required this.province,
    required this.name,
    required this.phone,
    required this.status,
    required this.time,
    this.onAccept,
  });

  static const Color _primary = Color(0xFF006D37);
  static const Color _surfaceContainer = Color(0xFFE3F0F1);
  static const Color _outline = Color(0xFF6C7B6D);
  static const Color _textVariant = Color(0xFF3D4A3E);

  @override
  Widget build(BuildContext context) {
    final upperStatus = status.toUpperCase();
    final statusData = _statusData(upperStatus);
    final done = upperStatus == 'DONE' || upperStatus == 'COMPLETED';

    return Opacity(
      opacity: done ? 0.78 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: done ? Colors.white.withOpacity(0.72) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E8449).withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 620;

            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        serviceName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: done ? _outline : _primary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _StatusChip(
                      icon: statusData.icon,
                      text: statusData.label,
                      bg: statusData.bg,
                      fg: statusData.fg,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  runSpacing: 8,
                  spacing: 16,
                  children: [
                    _InfoItem(
                      icon: Icons.location_on,
                      text: fullAddress.isEmpty
                          ? 'Không có địa chỉ'
                          : fullAddress,
                      muted: done,
                    ),
                    _InfoItem(
                      icon: Icons.location_city,
                      text: province.isEmpty ? 'Không có tỉnh/thành' : province,
                      muted: done,
                    ),
                    _InfoItem(
                      icon: Icons.person,
                      text: name.isEmpty ? 'Không có tên' : name,
                      muted: done,
                    ),
                    _InfoItem(
                      icon: Icons.call,
                      text: phone.isEmpty ? 'Không có SĐT' : phone,
                      muted: done,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(height: 1, color: _surfaceContainer),
                const SizedBox(height: 9),
                Row(
                  children: [
                    const Icon(Icons.schedule, color: _outline, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      time,
                      style: const TextStyle(color: _outline, fontSize: 14),
                    ),
                  ],
                ),
              ],
            );

            final button = onAccept == null
                ? const SizedBox.shrink()
                : SizedBox(
                    width: wide ? null : double.infinity,
                    child: ElevatedButton(
                      onPressed: onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'ACCEPT',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  );

            if (!wide) {
              return Column(
                children: [
                  content,
                  if (onAccept != null) ...[const SizedBox(height: 14), button],
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: content),
                const SizedBox(width: 16),
                button,
              ],
            );
          },
        ),
      ),
    );
  }

  static ({String label, IconData icon, Color bg, Color fg}) _statusData(
    String status,
  ) {
    switch (status) {
      case 'PENDING':
        return (
          label: 'PENDING',
          icon: Icons.history,
          bg: Color(0xFFFFF8E1),
          fg: Color(0xFFB45309),
        );
      case 'ACCEPTED':
        return (
          label: 'ACCEPTED',
          icon: Icons.check_circle,
          bg: Color(0xFF94F4AD),
          fg: Color(0xFF00723A),
        );
      case 'DONE':
      case 'COMPLETED':
        return (
          label: 'DONE',
          icon: Icons.task_alt,
          bg: _surfaceContainer,
          fg: _outline,
        );
      case 'CANCELLED':
        return (
          label: 'CANCELLED',
          icon: Icons.cancel,
          bg: Color(0xFFFFDAD6),
          fg: Color(0xFFBA1A1A),
        );
      default:
        return (
          label: status,
          icon: Icons.info,
          bg: _surfaceContainer,
          fg: _outline,
        );
    }
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color bg;
  final Color fg;

  const _StatusChip({
    required this.icon,
    required this.text,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 15),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool muted;

  const _InfoItem({required this.icon, required this.text, this.muted = false});

  static const Color _primary = Color(0xFF006D37);
  static const Color _outline = Color(0xFF6C7B6D);
  static const Color _textVariant = Color(0xFF3D4A3E);

  @override
  Widget build(BuildContext context) {
    final color = muted ? _outline : _textVariant;

    return SizedBox(
      width: MediaQuery.of(context).size.width > 700 ? 280 : double.infinity,
      child: Row(
        children: [
          Icon(icon, color: muted ? _outline : _primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Đang tải booking...'),
        ],
      ),
    );
  }
}
