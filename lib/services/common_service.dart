import 'package:cloud_firestore/cloud_firestore.dart';

class CommonService {
  final db = FirebaseFirestore.instance;

  // ===============================
  // 🔥 GENERIC
  // ===============================

  Future<Map<String, dynamic>?> getById(String collection, String id) async {
    final doc = await db.collection(collection).doc(id).get();
    return doc.data();
  }

  Stream<QuerySnapshot> streamCollection(String collection) {
    return db.collection(collection).snapshots();
  }

  // ===============================
  // 📦 SERVICES
  // ===============================

  Future<Map<String, dynamic>?> getService(String id) {
    return getById("services", id);
  }

  Stream<QuerySnapshot> getServices() {
    return streamCollection("services");
  }

  // ===============================
  // 📍 ADDRESSES
  // ===============================

  Future<Map<String, dynamic>?> getAddress(String id) {
    return getById("addresses", id);
  }

  Stream<QuerySnapshot> getAddresses() {
    return streamCollection("addresses");
  }

  // ===============================
  // 📘 BOOKINGS
  // ===============================

  Future<Map<String, dynamic>?> getBooking(String id) {
    return getById("bookings", id);
  }

  Stream<QuerySnapshot> getBookings() {
    return streamCollection("bookings");
  }

  // ===============================
  // 🧾 BOOKING HISTORY
  // ===============================

  Stream<QuerySnapshot> getBookingHistory() {
    return streamCollection("bookinghistory");
  }

  // ===============================
  // 🧑‍🔧 EMPLOYEES
  // ===============================

  Future<Map<String, dynamic>?> getEmployee(String id) {
    return getById("employees", id);
  }

  Stream<QuerySnapshot> getEmployees() {
    return streamCollection("employees");
  }

  // ===============================
  // 📋 TASKS
  // ===============================

  Future<Map<String, dynamic>?> getTask(String id) {
    return getById("tasks", id);
  }

  Stream<QuerySnapshot> getTasks() {
    return streamCollection("tasks");
  }

  // ===============================
  // 💰 PAYMENTS
  // ===============================

  Stream<QuerySnapshot> getPayments() {
    return streamCollection("payments");
  }

  // ===============================
  // ⭐ REVIEWS
  // ===============================

  Stream<QuerySnapshot> getReviews() {
    return streamCollection("reviews");
  }

  // ===============================
  // 🔔 NOTIFICATIONS
  // ===============================

  Stream<QuerySnapshot> getNotifications() {
    return streamCollection("notifications");
  }

  // ===============================
  // 💬 CHAT ROOMS
  // ===============================

  Stream<QuerySnapshot> getChatRooms() {
    return streamCollection("chatRooms");
  }

  Stream<QuerySnapshot> getMessages(String roomId) {
    return db
        .collection("chatroom")
        .doc(roomId)
        .collection("messages")
        .orderBy("createdAt")
        .snapshots();
  }

  // ===============================
  // 📍 TRACKING (REALTIME LOCATION)
  // ===============================

  Stream<QuerySnapshot> getTracking() {
    return streamCollection("tracking");
  }

  // ===============================
  // 👤 USERS
  // ===============================

  Future<Map<String, dynamic>?> getUser(String id) {
    return getById("users", id);
  }

  Stream<QuerySnapshot> getUsers() {
    return streamCollection("users");
  }
}
