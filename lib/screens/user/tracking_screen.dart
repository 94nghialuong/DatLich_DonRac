import 'dart:async';

import 'package:booking_don_rac/screens/staff/chat_screen.dart';
import 'package:booking_don_rac/services/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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

  GoogleMapController? mapController;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? bookingSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? trackingSub;

  @override
  void initState() {
    super.initState();
    listenBooking();
    listenTracking();
  }

  void listenBooking() {
    bookingSub = db
        .collection("bookings")
        .doc(widget.bookingId)
        .snapshots()
        .listen((event) {
          if (!mounted) return;

          setState(() {
            booking = event.data();
          });
        });
  }

  void listenTracking() {
    trackingSub = db
        .collection("tracking")
        .doc(widget.bookingId)
        .snapshots()
        .listen((event) {
          if (!mounted) return;

          final data = event.data();

          setState(() {
            tracking = data;
          });

          final location = data?["location"];

          if (location is GeoPoint && mapController != null) {
            final pos = LatLng(location.latitude, location.longitude);

            mapController!.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(target: pos, zoom: 16),
              ),
            );
          }
        });
  }

  @override
  void dispose() {
    bookingSub?.cancel();
    trackingSub?.cancel();
    mapController?.dispose();
    super.dispose();
  }

  String getAddress(Map<String, dynamic>? data) {
    if (data == null) return "Không có địa chỉ";

    return (data["address"] ??
            data["fullAddress"] ??
            data["pickupAddress"] ??
            data["userAddress"] ??
            data["locationText"] ??
            "Không có địa chỉ")
        .toString();
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "PENDING":
        return Colors.orange;
      case "ACCEPTED":
        return Colors.blue;
      case "IN_PROGRESS":
        return Colors.green;
      case "DONE":
        return Colors.teal;
      case "CANCELLED":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String formatTime(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();

      return "${date.day}/${date.month}/${date.year} "
          "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    }

    return "Chưa cập nhật";
  }

  Future<void> openChat(String staffId) async {
    final roomId = await chatService.getRoomId(
      widget.bookingId,
      user.uid,
      staffId,
    );

    if (!mounted) return;

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
  }

  Future<void> openGoogleMaps(LatLng staffPos) async {
    final uri = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=${staffPos.latitude},${staffPos.longitude}",
    );

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Không thể mở Google Maps")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = (booking?["status"] ?? "PENDING").toString();
    final address = getAddress(booking);

    final staffId = (tracking?["employeeId"] ?? booking?["employeeId"] ?? "")
        .toString();

    final location = tracking?["location"];
    final updatedAt = tracking?["updatedAt"];
    final isTracking = tracking?["isTracking"] == true;

    LatLng? staffPos;

    if (location is GeoPoint) {
      staffPos = LatLng(location.latitude, location.longitude);
    }

    final isAssigned = staffId.isNotEmpty;

    final markers = <Marker>{};

    if (staffPos != null) {
      markers.add(
        Marker(
          markerId: const MarkerId("staff"),
          position: staffPos,
          infoWindow: const InfoWindow(title: "Nhân viên đang ở đây"),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Theo dõi nhân viên"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: getStatusColor(status).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.local_shipping,
                        color: getStatusColor(status),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Trạng thái đơn",
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          Text(
                            status,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: getStatusColor(status),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isTracking
                            ? Colors.green.withOpacity(0.12)
                            : Colors.red.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        isTracking ? "LIVE" : "OFF",
                        style: TextStyle(
                          color: isTracking ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        address,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.person, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isAssigned
                            ? "Nhân viên: $staffId"
                            : "Chưa có nhân viên nhận đơn",
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.access_time, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Cập nhật: ${formatTime(updatedAt)}",
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: staffPos == null
                ? const Center(
                    child: Text(
                      "Chưa có vị trí nhân viên",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : kIsWeb
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.map,
                            size: 80,
                            color: Color(0xFF1E8449),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Tracking trên trình duyệt",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Bấm nút bên dưới để mở vị trí nhân viên trên Google Maps.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E8449),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            icon: const Icon(Icons.open_in_new),
                            label: const Text("Mở Google Maps"),
                            onPressed: () async {
                              await openGoogleMaps(staffPos!);
                            },
                          ),
                        ],
                      ),
                    ),
                  )
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: staffPos,
                      zoom: 16,
                    ),
                    markers: markers,
                    myLocationEnabled: false,
                    zoomControlsEnabled: true,
                    mapType: MapType.normal,
                    onMapCreated: (controller) {
                      mapController = controller;
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              if (staffPos != null)
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E8449),
                      side: const BorderSide(color: Color(0xFF1E8449)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    icon: const Icon(Icons.map),
                    label: const Text(
                      "Mở Maps",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      await openGoogleMaps(staffPos!);
                    },
                  ),
                ),
              if (staffPos != null && isAssigned) const SizedBox(width: 10),
              if (isAssigned)
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E8449),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    icon: const Icon(Icons.chat),
                    label: const Text(
                      "Chat",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      await openChat(staffId);
                    },
                  ),
                ),
              if (staffPos == null && !isAssigned)
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      "Đang chờ nhân viên nhận đơn",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
