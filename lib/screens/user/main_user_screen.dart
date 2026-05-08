import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'my_booking_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  // ⚠️ KHÔNG dùng const để tránh lỗi rebuild + null issues
  late final List<Widget> screens = [
    const HomeScreen(),
    const MyBookingScreen(),
    const Placeholder(), // Tracking (tạm)
    const ProfileScreen(),
  ];

  void onTap(int index) {
    if (index < 0 || index >= screens.length) return;
    setState(() => currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,

      // ❌ FIX: tránh padding ảo + khoảng trắng bottom
      resizeToAvoidBottomInset: false,

      body: IndexedStack(index: currentIndex, children: screens),

      // ================= BOTTOM NAV FIXED =================
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
            border: Border(
              top: BorderSide(color: const Color(0xFF1E8449).withOpacity(0.1)),
            ),
          ),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _bottomItem(Icons.home, "Home", 0),
              _bottomItem(Icons.add_circle, "Booking", 1),
              _bottomItem(Icons.location_on, "Tracking", 2),
              _bottomItem(Icons.person, "Profile", 3),
            ],
          ),
        ),
      ),
    );
  }

  // ================= BOTTOM ITEM =================
  Widget _bottomItem(IconData icon, String label, int index) {
    final isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),

        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),

        transform: Matrix4.identity()..scale(isActive ? 1.08 : 1.0),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isActive ? 28 : 24,
              color: isActive
                  ? const Color(0xFF1E8449)
                  : const Color(0xFF7F8C8D),
            ),

            const SizedBox(height: 3),

            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? const Color(0xFF1E8449)
                    : const Color(0xFF7F8C8D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
