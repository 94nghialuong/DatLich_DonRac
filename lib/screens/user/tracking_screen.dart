import 'package:booking_don_rac/screens/staff/chat_screen.dart';
import 'package:booking_don_rac/services/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class BookingTrackingScreen extends StatefulWidget {
  final String bookingId;

  const BookingTrackingScreen({super.key, required this.bookingId});

  @override
  State<BookingTrackingScreen> createState() => _BookingTrackingScreenState();
}

class _BookingTrackingScreenState extends State<BookingTrackingScreen> {
  final db = FirebaseFirestore.instance;
  final chatService = ChatService();
  final user = FirebaseAuth.instance.currentUser!;

  Map<String, dynamic>? booking;
  Map<String, dynamic>? tracking;

  @override
  void initState() {
    super.initState();

    // ================= BOOKING STREAM =================
    db.collection("bookings").doc(widget.bookingId).snapshots().listen((event) {
      if (!mounted) return;
      setState(() {
        booking = event.data();
      });
    });

    // ================= TRACKING STREAM =================
    db.collection("tracking").doc(widget.bookingId).snapshots().listen((event) {
      if (!mounted) return;
      setState(() {
        tracking = event.data();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = booking?["status"] ?? "PENDING";

    final staffId = (tracking?["employeeId"] ?? "").toString();

    final location = tracking?["location"];

    final isAssigned = staffId.isNotEmpty;

    LatLng? staffPos;

    if (location is GeoPoint) {
      staffPos = LatLng(location.latitude, location.longitude);
    }

    final markers = <Marker>{};

    if (staffPos != null) {
      markers.add(
        Marker(
          markerId: const MarkerId("staff"),
          position: staffPos,
          infoWindow: const InfoWindow(title: "Nhân viên"),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Theo dõi nhân viên")),

      body: Column(
        children: [
          // ================= STATUS =================
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              "Trạng thái: $status",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          // ================= MAP =================
          Expanded(child: _buildMap(staffPos, markers)),

          // ================= CHAT =================
          if (isAssigned)
            Padding(
              padding: const EdgeInsets.all(10),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final roomId = await chatService.getRoomId(
                      widget.bookingId,
                      user.uid,
                      staffId,
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          roomId: roomId,
                          myId: user.uid,
                          myName: user.email ?? "User",
                        ),
                      ),
                    );
                  },
                  child: const Text("Chat với nhân viên"),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ================= SAFE MAP BUILDER =================
  Widget _buildMap(LatLng? staffPos, Set<Marker> markers) {
    // 🔥 FIX CRASH WINDOW.DART
    if (kIsWeb) {
      return const Center(
        child: Text(
          "Tracking map chỉ hỗ trợ Android / iOS",
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    if (staffPos == null) {
      return const Center(
        child: Text(
          "Chưa có vị trí nhân viên",
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: staffPos, zoom: 16),
      markers: markers,
      myLocationEnabled: false,
      zoomControlsEnabled: true,
    );
  }
}
