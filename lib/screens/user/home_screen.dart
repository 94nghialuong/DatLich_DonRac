import 'package:booking_don_rac/provider/notification_provider.dart';
import 'package:booking_don_rac/screens/user/notification_screen.dart';
import 'package:booking_don_rac/screens/user/booking_create_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final db = FirebaseFirestore.instance;
  String searchText = "";

  String role = "user"; // 🔥 default

  @override
  void initState() {
    super.initState();
    _initNotification();
  }

  Future<void> _initNotification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 🔥 LẤY ROLE TỪ FIRESTORE
    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    role = userDoc.data()?["role"] ?? "user";

    // 🔥 LISTEN NOTIFICATION
    Provider.of<NotificationProvider>(
      context,
      listen: false,
    ).listenNotifications(userId: user.uid, role: role);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),

      // ================= APPBAR =================
      appBar: AppBar(
        title: Text(
          role == "staff" ? "Danh sách công việc" : "Dịch vụ dọn rác",
        ),

        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notiProvider, _) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NotificationScreen(
                            userId: uid,
                            role: role, // 🔥 truyền role
                          ),
                        ),
                      );
                    },
                  ),

                  // 🔴 BADGE
                  if (notiProvider.unreadCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          notiProvider.unreadCount > 99
                              ? "99+"
                              : "${notiProvider.unreadCount}",
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],

        // ================= SEARCH =================
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchText = value.toLowerCase().trim();
                });
              },
              decoration: InputDecoration(
                hintText: "Tìm kiếm dịch vụ...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),

      // ================= BODY =================
      body: StreamBuilder<QuerySnapshot>(
        stream: db.collection("services").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          final filtered = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data["name"] ?? "").toString().toLowerCase();
            return name.contains(searchText);
          }).toList();

          if (filtered.isEmpty) {
            return const Center(child: Text("Không tìm thấy dịch vụ"));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filtered.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemBuilder: (context, index) {
              final doc = filtered[index];
              final data = doc.data() as Map<String, dynamic>;

              final id = doc.id;
              final name = data["name"] ?? "";
              final description = data["description"] ?? "";
              final price = data["price"] ?? 0;
              final image = data["URL"] ?? "";

              return GestureDetector(
                onTap: () {
                  // 👷 STAFF KHÔNG ĐƯỢC BOOK
                  if (role == "staff") {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Nhân viên không thể đặt lịch"),
                      ),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingCreateScreen(
                        serviceId: id,
                        serviceName: name,
                        price: price,
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: image.isNotEmpty
                            ? Image.network(
                                image,
                                height: 110,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                height: 110,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image),
                              ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                "$price VNĐ",
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
