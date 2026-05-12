import 'package:booking_don_rac/provider/notification_provider.dart';
import 'package:booking_don_rac/provider/tasks_provider.dart';
import 'package:booking_don_rac/screens/staff/booking_history_screen.dart';
import 'package:booking_don_rac/screens/staff/bookings_list_screens.dart';
import 'package:booking_don_rac/screens/staff/profile_screen.dart';
import 'package:booking_don_rac/screens/staff/tasks_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StaffHome extends StatefulWidget {
  final String employeeId;

  const StaffHome({super.key, required this.employeeId});

  @override
  State<StaffHome> createState() => _StaffHomeState();
}

class _StaffHomeState extends State<StaffHome> {
  static const Color _primary = Color(0xFF006D37);
  static const Color _selectedBg = Color(0xFFE9F6F7);

  int index = 0;

  late final List<Widget> screens;

  @override
  void initState() {
    super.initState();

    screens = [
      BookingList(employeeId: widget.employeeId),
      const TaskScreen(),
      const BookingHistoryScreen(),
      ProfileScreen(),
    ];

    Future.microtask(() {
      context.read<TaskProvider>().listenTasks(widget.employeeId);

      context.read<NotificationProvider>().listenNotifications(
        userId: widget.employeeId,
        role: 'STAFF',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: index, children: screens),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: Colors.green.withOpacity(0.08)),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E8449).withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Consumer<TaskProvider>(
            builder: (context, taskProvider, child) {
              final taskCount = taskProvider.taskCount;
              final taskReady = taskProvider.isReady;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    selected: index == 0,
                    icon: Icons.home,
                    activeIcon: Icons.home,
                    label: 'Home',
                    onTap: () => setState(() => index = 0),
                  ),
                  _NavItem(
                    selected: index == 1,
                    icon: Icons.assignment_outlined,
                    activeIcon: Icons.assignment,
                    label: 'Tasks',
                    badge: taskReady && taskCount > 0
                        ? (taskCount > 99 ? '99+' : '$taskCount')
                        : null,
                    onTap: () => setState(() => index = 1),
                  ),
                  _NavItem(
                    selected: index == 2,
                    icon: Icons.history,
                    activeIcon: Icons.history,
                    label: 'History',
                    onTap: () => setState(() => index = 2),
                  ),
                  _NavItem(
                    selected: index == 3,
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: 'Profile',
                    onTap: () => setState(() => index = 3),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String? badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.selected,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  static const Color _primary = Color(0xFF006D37);
  static const Color _selectedBg = Color(0xFFE9F6F7);

  @override
  Widget build(BuildContext context) {
    final color = selected ? _primary : _primary.withOpacity(0.35);

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 18 : 12,
          vertical: selected ? 7 : 5,
        ),
        decoration: BoxDecoration(
          color: selected ? _selectedBg : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(selected ? activeIcon : icon, color: color, size: 24),
                if (badge != null)
                  Positioned(
                    right: -9,
                    top: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Center(
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
