import 'package:booking_don_rac/provider/tasks_provider.dart';
import 'package:booking_don_rac/provider/notification_provider.dart';
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
  int index = 0;

  late final List<Widget> screens;

  @override
  void initState() {
    super.initState();

    // ✅ FIX: truyền employeeId vào BookingList
    screens = [
      BookingList(employeeId: widget.employeeId),
      const TaskScreen(),
      const BookingHistoryScreen(),
      ProfileScreen(),
    ];

    // 🔥 TASK LISTENER
    Future.microtask(() {
      context.read<TaskProvider>().listenTasks(widget.employeeId);
    });

    // 🔥 NOTIFICATION LISTENER
    Future.microtask(() {
      context.read<NotificationProvider>().listenNotifications(
        userId: widget.employeeId,
        role: "staff",
      );
    });
  }

  @override
  void dispose() {
    // ✅ OPTIONAL: nếu provider có stop listener thì gọi
    // context.read<TaskProvider>().disposeListener();
    // context.read<NotificationProvider>().disposeListener();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ================= BODY =================
      body: IndexedStack(index: index, children: screens),

      // ================= BOTTOM NAV =================
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
        ),
        child: Consumer<TaskProvider>(
          builder: (context, taskProvider, child) {
            final count = taskProvider.taskCount;
            final ready = taskProvider.isReady;

            return BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.black,
              elevation: 0,
              selectedItemColor: Colors.greenAccent,
              unselectedItemColor: Colors.grey,
              currentIndex: index,
              onTap: (i) => setState(() => index = i),

              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.list),
                  label: "Bookings",
                ),

                BottomNavigationBarItem(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.work),

                      // 🔴 TASK BADGE
                      if (ready && count > 0)
                        Positioned(
                          right: -6,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              count > 99 ? "99+" : "$count",
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  label: "Tasks",
                ),

                const BottomNavigationBarItem(
                  icon: Icon(Icons.history),
                  label: "History",
                ),

                const BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: "Profile",
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
