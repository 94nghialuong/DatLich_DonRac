import 'package:flutter/material.dart';
import '../services/booking_service.dart';

class BookingProvider extends ChangeNotifier {
  final BookingService _service = BookingService();

  bool isLoading = false;

  Future<void> _run(Future<void> Function() action) async {
    try {
      isLoading = true;
      notifyListeners();

      await action();
    } catch (e) {
      print("BOOKING ERROR: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createBooking(Map<String, dynamic> data) async {
    await _run(() => _service.createBooking(data));
  }

  Future<void> acceptBooking(String bookingId, String employeeId) async {
    await _run(() => _service.acceptBooking(bookingId, employeeId));
  }

  Future<void> completeBooking(String bookingId) async {
    await _run(() => _service.completeBooking(bookingId));
  }
}
