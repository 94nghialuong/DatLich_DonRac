import 'package:booking_don_rac/screens/admin/admin_bookings_screen.dart';
import 'package:booking_don_rac/screens/admin/admin_dashboard_screen.dart';
import 'package:booking_don_rac/screens/admin/admin_notifycation_screen.dart';
import 'package:booking_don_rac/screens/admin/admin_services_screen.dart';
import 'package:booking_don_rac/screens/admin/admin_users_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int currentIndex = 0;
  int reloadKey = 0;

  static const Color bgColor = Color(0xFFEAF7EF);
  static const Color primaryColor = Color(0xFF1E8449);
  static const Color primaryDark = Color(0xFF005027);
  static const Color selectedBg = Color(0xFF2ECC71);
  static const Color navBg = Color(0xFFE3F0F1);

  final List<String> titles = const [
    'Tổng quan',
    'Người dùng',
    'Booking',
    'Dịch vụ',
  ];

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  void openTab(int index) {
    if (index < 0 || index > 3) return;
    setState(() => currentIndex = index);
  }

  void reloadPage() {
    setState(() {
      reloadKey++;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã tải lại ${titles[currentIndex]}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void openSystemNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminNotificationsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      AdminDashboardScreen(
        key: ValueKey('dashboard_$reloadKey'),
        onNavigate: openTab,
      ),
      AdminUsersScreen(key: ValueKey('users_$reloadKey')),
      AdminBookingsScreen(key: ValueKey('bookings_$reloadKey')),
      AdminServicesScreen(key: ValueKey('services_$reloadKey')),
    ];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 2,
        shadowColor: Colors.green.withOpacity(0.12),
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,
        titleSpacing: 16,
        title: Row(
          children: [
            const Icon(Icons.eco, color: primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Admin - ${titles[currentIndex]}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
          ],
        ),
        actions: [
          _NotificationButton(onTap: openSystemNotifications),
          IconButton(
            tooltip: 'Tải lại',
            onPressed: reloadPage,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: logout,
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(child: screens[currentIndex]),
      bottomNavigationBar: _AdminBottomNav(
        currentIndex: currentIndex,
        onTap: openTab,
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final VoidCallback onTap;

  const _NotificationButton({required this.onTap});

  static const Color primaryColor = Color(0xFF1E8449);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final unread = snapshot.data?.docs.length ?? 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: 'Thông báo hệ thống',
              onPressed: onTap,
              icon: const Icon(Icons.notifications, color: primaryColor),
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
                    color: Colors.red,
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
    );
  }
}

class _AdminBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _AdminBottomNav({required this.currentIndex, required this.onTap});

  static const Color selectedBg = Color(0xFF2ECC71);
  static const Color navBg = Color(0xFFE3F0F1);

  @override
  Widget build(BuildContext context) {
    final items = const [
      _NavItemData(Icons.dashboard, 'Tổng quan'),
      _NavItemData(Icons.group, 'Người dùng'),
      _NavItemData(Icons.event_note, 'Booking'),
      _NavItemData(Icons.eco, 'Dịch vụ'),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: BoxDecoration(
        color: navBg,
        border: Border(top: BorderSide(color: Colors.green.withOpacity(0.15))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final selected = currentIndex == index;
            final item = items[index];

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => onTap(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? selectedBg : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          color: selected
                              ? const Color(0xFF005027)
                              : Colors.black54,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: selected
                                ? const Color(0xFF005027)
                                : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;

  const _NavItemData(this.icon, this.label);
}
