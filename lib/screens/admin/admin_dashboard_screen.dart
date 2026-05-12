import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatelessWidget {
  final void Function(int index)? onNavigate;

  const AdminDashboardScreen({super.key, this.onNavigate});

  static const _bg = Color(0xFFEAF7EF);
  static const _primary = Color(0xFF1E8449);
  static const _primaryDark = Color(0xFF006D37);
  static const _primarySoft = Color(0xFF2ECC71);
  static const _surface = Color(0xFFE3F0F1);
  static const _textDark = Color(0xFF121E1F);

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Stream<int> _count(String collection, {String? field, Object? isEqualTo}) {
    Query query = _db.collection(collection);
    if (field != null) query = query.where(field, isEqualTo: isEqualTo);
    return query.snapshots().map((s) => s.docs.length);
  }

  Stream<double> _totalPaid() {
    return _db.collection('payment').snapshots().map((s) {
      return s.docs.fold<double>(0, (total, doc) {
        final data = doc.data();
        final status = (data['status'] ?? '').toString().toUpperCase();
        final amount = double.tryParse((data['amount'] ?? 0).toString()) ?? 0;
        return status == 'PAID' ? total + amount : total;
      });
    });
  }

  Stream<double> _avgRating() {
    return _db.collection('reviews').snapshots().map((s) {
      if (s.docs.isEmpty) return 0;

      final total = s.docs.fold<double>(0, (sum, doc) {
        return sum +
            (double.tryParse((doc.data()['rating'] ?? 0).toString()) ?? 0);
      });

      return total / s.docs.length;
    });
  }

  Future<Map<String, dynamic>?> _docData(String collection, String? id) async {
    if (id == null || id.isEmpty) return null;

    final doc = await _db.collection(collection).doc(id).get();
    return doc.exists ? doc.data() : null;
  }

  void _openReviews(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ReviewFeedbackSheet(getDoc: _docData),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _WelcomeSection(),
          const SizedBox(height: 24),

          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 720;

              return GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 4 : 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: isWide ? 1.2 : 1.12,
                ),
                children: [
                  _DashboardCard<double>(
                    title: 'Tổng doanh thu',
                    icon: Icons.payments,
                    stream: _totalPaid(),
                    borderLeft: true,
                    onTap: () => onNavigate?.call(2),
                    valueBuilder: (v) => _money(v),
                    badge: '+12%',
                  ),
                  _DashboardCard<int>(
                    title: 'Người dùng',
                    icon: Icons.group,
                    stream: _count('users'),
                    onTap: () => onNavigate?.call(1),
                  ),
                  _DashboardCard<int>(
                    title: 'Booking',
                    icon: Icons.event_note,
                    stream: _count('bookings'),
                    onTap: () => onNavigate?.call(2),
                  ),
                  _DashboardCard<int>(
                    title: 'Chờ xử lý',
                    icon: Icons.pending_actions,
                    stream: _count(
                      'bookings',
                      field: 'status',
                      isEqualTo: 'PENDING',
                    ),
                    dotColor: Colors.red,
                    onTap: () => onNavigate?.call(2),
                  ),
                  _DashboardCard<int>(
                    title: 'Hoàn thành',
                    icon: Icons.done_all,
                    stream: _count(
                      'bookings',
                      field: 'status',
                      isEqualTo: 'COMPLETED',
                    ),
                    dotColor: _primarySoft,
                    onTap: () => onNavigate?.call(2),
                  ),
                  _DashboardCard<int>(
                    title: 'Thanh toán',
                    icon: Icons.payments,
                    stream: _count('payment'),
                    onTap: () => onNavigate?.call(2),
                  ),
                  _DashboardCard<double>(
                    title: 'Đánh giá',
                    icon: Icons.star,
                    stream: _avgRating(),
                    iconColor: Colors.orange,
                    valueBuilder: (v) => '${v.toStringAsFixed(1)} / 5',
                  ),
                  _DashboardCard<int>(
                    title: 'Phản hồi',
                    icon: Icons.reviews,
                    stream: _count('reviews'),
                    buttonText: 'Xem phản hồi',
                    onButtonTap: () => _openReviews(context),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 28),

          _SectionHeader(
            title: 'Booking mới nhất',
            actionText: 'XEM TẤT CẢ',
            onTap: () => onNavigate?.call(2),
          ),

          const SizedBox(height: 10),

          _LatestBookings(getDoc: _docData, onTap: () => onNavigate?.call(2)),
        ],
      ),
    );
  }

  static String _money(dynamic value) {
    final number = double.tryParse(value.toString()) ?? 0;
    return '${number.toStringAsFixed(0)}đ';
  }
}

class _WelcomeSection extends StatelessWidget {
  const _WelcomeSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bảng điều khiển',
          style: TextStyle(
            fontSize: 32,
            height: 1.2,
            fontWeight: FontWeight.bold,
            color: AdminDashboardScreen._primary,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Chào mừng trở lại, quản trị viên. Dưới đây là hiệu suất hệ thống hôm nay.',
          style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black54),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionText;
  final VoidCallback? onTap;

  const _SectionHeader({
    required this.title,
    required this.actionText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AdminDashboardScreen._primary,
            ),
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(
            actionText,
            style: const TextStyle(
              color: AdminDashboardScreen._primaryDark,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ],
    );
  }
}

class _DashboardCard<T> extends StatelessWidget {
  final String title;
  final IconData icon;
  final Stream<T> stream;
  final String Function(T value)? valueBuilder;
  final VoidCallback? onTap;
  final VoidCallback? onButtonTap;
  final String? buttonText;
  final String? badge;
  final Color? dotColor;
  final Color? iconColor;
  final bool borderLeft;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.stream,
    this.valueBuilder,
    this.onTap,
    this.onButtonTap,
    this.buttonText,
    this.badge,
    this.dotColor,
    this.iconColor,
    this.borderLeft = false,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseCard(
      onTap: onTap,
      borderLeft: borderLeft,
      child: StreamBuilder<T>(
        stream: stream,
        builder: (context, snapshot) {
          final value = snapshot.data;
          final text = value == null
              ? '0'
              : valueBuilder?.call(value) ?? value.toString();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardTop(
                title: title,
                icon: icon,
                badge: badge,
                dotColor: dotColor,
                iconColor: iconColor,
              ),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: value is double ? 24 : 28,
                    fontWeight: FontWeight.bold,
                    color: borderLeft
                        ? AdminDashboardScreen._primary
                        : AdminDashboardScreen._textDark,
                  ),
                ),
              ),
              if (dotColor == null) ...[
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54, fontSize: 14),
                ),
              ],
              if (buttonText != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 34,
                  child: ElevatedButton.icon(
                    onPressed: onButtonTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminDashboardScreen._primarySoft,
                      foregroundColor: const Color(0xFF005027),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: Text(
                      buttonText!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _CardTop extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? badge;
  final Color? dotColor;
  final Color? iconColor;

  const _CardTop({
    required this.title,
    required this.icon,
    this.badge,
    this.dotColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    if (dotColor != null) {
      return Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Icon(icon, color: iconColor ?? AdminDashboardScreen._primary, size: 28),
        const Spacer(),
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: AdminDashboardScreen._primarySoft.withOpacity(0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badge!,
              style: const TextStyle(
                color: AdminDashboardScreen._primaryDark,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}

class _LatestBookings extends StatelessWidget {
  final Future<Map<String, dynamic>?> Function(String collection, String? id)
  getDoc;
  final VoidCallback? onTap;

  const _LatestBookings({required this.getDoc, this.onTap});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _MessageBox(text: 'Lỗi tải booking: ${snapshot.error}');
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const _MessageBox(text: 'Chưa có booking nào');
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            return FutureBuilder<List<Map<String, dynamic>?>>(
              future: Future.wait([
                getDoc('users', data['userId']?.toString()),
                getDoc('addresses', data['addressId']?.toString()),
              ]),
              builder: (context, detailSnapshot) {
                if (detailSnapshot.connectionState == ConnectionState.waiting) {
                  return const _LoadingBookingCard();
                }

                final user = detailSnapshot.data?[0];
                final address = detailSnapshot.data?[1];

                return _LatestBookingCard(
                  name: user?['fullname']?.toString() ?? 'Không rõ khách',
                  address:
                      address?['fullAddress']?.toString() ?? 'Không có địa chỉ',
                  amount: AdminDashboardScreen._money(
                    data['price'] ?? data['amount'] ?? data['totalPrice'] ?? 0,
                  ),
                  status: data['status']?.toString().toUpperCase() ?? 'N/A',
                  onTap: onTap,
                );
              },
            );
          }).toList(),
        );
      },
    );
  }
}

class _LatestBookingCard extends StatelessWidget {
  final String name;
  final String address;
  final String amount;
  final String status;
  final VoidCallback? onTap;

  const _LatestBookingCard({
    required this.name,
    required this.address,
    required this.amount,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final badge = _statusBadge(status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _BaseCard(
        onTap: onTap,
        child: Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: AdminDashboardScreen._surface,
              child: Icon(Icons.person, color: AdminDashboardScreen._primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.25,
                      fontWeight: FontWeight.bold,
                      color: AdminDashboardScreen._textDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  style: const TextStyle(
                    color: AdminDashboardScreen._primary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                _StatusChip(text: badge.text, color: badge.color),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static ({String text, Color color}) _statusBadge(String status) {
    switch (status) {
      case 'COMPLETED':
        return (text: 'HOÀN THÀNH', color: AdminDashboardScreen._primary);
      case 'PENDING':
        return (text: 'ĐANG CHỜ', color: Colors.orange);
      case 'CANCELLED':
        return (text: 'ĐÃ HỦY', color: Colors.red);
      default:
        return (text: status, color: Colors.blueGrey);
    }
  }
}

class _ReviewFeedbackSheet extends StatelessWidget {
  final Future<Map<String, dynamic>?> Function(String collection, String? id)
  getDoc;

  const _ReviewFeedbackSheet({required this.getDoc});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              _SheetHandle(),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Phản hồi từ khách hàng',
                      style: TextStyle(
                        color: AdminDashboardScreen._primary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('reviews')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Lỗi tải phản hồi: ${snapshot.error}'),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return const Center(child: Text('Chưa có phản hồi nào'));
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        return _ReviewItem(data: data, getDoc: getDoc);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final Map<String, dynamic> data;
  final Future<Map<String, dynamic>?> Function(String collection, String? id)
  getDoc;

  const _ReviewItem({required this.data, required this.getDoc});

  @override
  Widget build(BuildContext context) {
    final userId = data['userId']?.toString();
    final employeeId = data['employeeId']?.toString();

    return FutureBuilder<List<Map<String, dynamic>?>>(
      future: Future.wait([
        getDoc('users', userId),
        getDoc('users', employeeId),
      ]),
      builder: (context, snapshot) {
        final user = snapshot.data?[0];
        final staff = snapshot.data?[1];

        final userName =
            user?['fullname']?.toString() ?? userId ?? 'Khách hàng';

        final staffName =
            staff?['fullname']?.toString() ?? employeeId ?? 'Nhân viên';

        final rating = data['rating']?.toString() ?? '0';
        final comment = data['comment']?.toString() ?? '';
        final bookingId = data['bookingId']?.toString() ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AdminDashboardScreen._primarySoft,
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 18),
                      const SizedBox(width: 2),
                      Text(
                        rating,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                comment.isNotEmpty ? comment : 'Không có nội dung phản hồi',
                style: TextStyle(
                  fontSize: 15,
                  color: comment.isNotEmpty ? null : Colors.black54,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Nhân viên: $staffName',
                style: const TextStyle(color: Colors.black54),
              ),
              if (bookingId.isNotEmpty)
                Text(
                  'Booking: $bookingId',
                  style: const TextStyle(color: Colors.black54),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _BaseCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool borderLeft;

  const _BaseCard({required this.child, this.onTap, this.borderLeft = false});

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(borderLeft: borderLeft),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class _LoadingBookingCard extends StatelessWidget {
  const _LoadingBookingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: const Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Đang tải địa chỉ...'),
        ],
      ),
    );
  }
}

class _MessageBox extends StatelessWidget {
  final String text;

  const _MessageBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Text(text),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

BoxDecoration _cardDecoration({bool borderLeft = false}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: borderLeft
        ? const Border(
            left: BorderSide(color: AdminDashboardScreen._primary, width: 4),
          )
        : null,
    boxShadow: [
      BoxShadow(
        color: AdminDashboardScreen._primary.withOpacity(0.08),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
