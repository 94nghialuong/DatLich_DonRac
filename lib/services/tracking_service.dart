import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class TrackingService {
  final db = FirebaseFirestore.instance;

  StreamSubscription<Position>? _sub;

  Future<bool> _checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<void> startRealtimeTracking({
    required String bookingId,
    required String employeeId,
  }) async {
    final ok = await _checkPermission();
    if (!ok) {
      throw Exception("Chưa cấp quyền GPS");
    }

    await _sub?.cancel();

    _sub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        ).listen((Position pos) async {
          await db.collection("tracking").doc(bookingId).set({
            "bookingId": bookingId,
            "employeeId": employeeId,
            "location": GeoPoint(pos.latitude, pos.longitude),
            "lat": pos.latitude,
            "lng": pos.longitude,
            "speed": pos.speed,
            "heading": pos.heading,
            "accuracy": pos.accuracy,
            "isTracking": true,
            "updatedAt": Timestamp.now(),
          }, SetOptions(merge: true));

          await db.collection("bookings").doc(bookingId).update({
            "employeeId": employeeId,
            "trackingStatus": "LIVE",
          });
        });
  }

  Future<void> stopRealtimeTracking({required String bookingId}) async {
    await _sub?.cancel();
    _sub = null;

    await db.collection("tracking").doc(bookingId).set({
      "isTracking": false,
      "updatedAt": Timestamp.now(),
    }, SetOptions(merge: true));

    await db.collection("bookings").doc(bookingId).update({
      "trackingStatus": "STOPPED",
    });
  }

  void dispose() {
    _sub?.cancel();
  }
}
