import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingCreateScreen extends StatefulWidget {
  final String serviceId;
  final String serviceName;
  final int price;

  const BookingCreateScreen({
    super.key,
    required this.serviceId,
    required this.serviceName,
    required this.price,
  });

  @override
  State<BookingCreateScreen> createState() => _BookingCreateScreenState();
}

class _BookingCreateScreenState extends State<BookingCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  // ================= ADDRESS =================
  final receiverName = TextEditingController();
  final phone = TextEditingController();
  final province = TextEditingController();
  final district = TextEditingController();
  final ward = TextEditingController();
  final fullAddress = TextEditingController();
  final label = TextEditingController();

  bool isDefault = false;

  // ================= DATE =================
  DateTime? selectedDateTime;

  @override
  void initState() {
    super.initState();
    loadDefaultAddress();
  }

  // ================= LOAD DEFAULT ADDRESS =================
  Future<void> loadDefaultAddress() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final snap = await FirebaseFirestore.instance
        .collection("addresses")
        .where("userId", isEqualTo: uid)
        .where("isDefault", isEqualTo: true)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      final data = snap.docs.first.data();

      setState(() {
        receiverName.text = data["receiverName"] ?? "";
        phone.text = data["phone"] ?? "";
        province.text = data["province"] ?? "";
        district.text = data["district"] ?? "";
        ward.text = data["ward"] ?? "";
        fullAddress.text = data["fullAddress"] ?? "";
        label.text = data["label"] ?? "";
        isDefault = true;
      });
    }
  }

  // ================= PICK DATE =================
  Future<void> pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    setState(() {
      selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  // ================= CREATE BOOKING =================
  Future<void> createBooking() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedDateTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Chọn ngày giờ")));
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final db = FirebaseFirestore.instance;

    try {
      // ================= FIX DEFAULT ADDRESS =================
      if (isDefault) {
        final oldDefaults = await db
            .collection("addresses")
            .where("userId", isEqualTo: uid)
            .where("isDefault", isEqualTo: true)
            .get();

        for (var doc in oldDefaults.docs) {
          await doc.reference.update({"isDefault": false});
        }
      }

      // ================= CREATE ADDRESS =================
      final addressRef = await db.collection("addresses").add({
        "userId": uid,
        "receiverName": receiverName.text.trim(),
        "phone": phone.text.trim(),
        "province": province.text.trim(),
        "district": district.text.trim(),
        "ward": ward.text.trim(),
        "fullAddress": fullAddress.text.trim(),
        "label": label.text.trim(),
        "isDefault": isDefault,
        "location": const GeoPoint(0, 0),
        "createdAt": Timestamp.now(),
      });

      // ================= CREATE BOOKING =================
      final bookingRef = await db.collection("bookings").add({
        "userId": uid,
        "serviceId": widget.serviceId,
        "serviceName": widget.serviceName,
        "price": widget.price,
        "addressId": addressRef.id,
        "time": Timestamp.fromDate(selectedDateTime!),
        "status": "PENDING",
        "paymentStatus": "UNPAID",
        "createdAt": Timestamp.now(),
      });

      // ================= NOTIFICATION =================
      await db.collection("notifications").add({
        "title": "Đặt lịch thành công",
        "content": "Bạn đã đặt dịch vụ ${widget.serviceName}",
        "userId": uid,
        "bookingId": bookingRef.id,
        "type": "booking",
        "isRead": false,
        "createdAt": Timestamp.now(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("✅ Đặt lịch thành công")));

      Navigator.pop(context);
    } catch (e) {
      print("ERROR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tạo booking")),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // ================= SERVICE =================
              Text(
                "Dịch vụ: ${widget.serviceName}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text("Giá: ${widget.price} VNĐ"),

              const SizedBox(height: 20),

              // ================= ADDRESS =================
              TextFormField(
                controller: receiverName,
                decoration: const InputDecoration(labelText: "Người nhận"),
                validator: (v) => v!.isEmpty ? "Nhập tên" : null,
              ),

              TextFormField(
                controller: phone,
                decoration: const InputDecoration(labelText: "SĐT"),
                validator: (v) =>
                    !RegExp(r'^\d{10,11}$').hasMatch(v!) ? "Sai SĐT" : null,
              ),

              TextFormField(
                controller: province,
                decoration: const InputDecoration(labelText: "Tỉnh"),
              ),

              TextFormField(
                controller: district,
                decoration: const InputDecoration(labelText: "Quận"),
              ),

              TextFormField(
                controller: ward,
                decoration: const InputDecoration(labelText: "Phường"),
              ),

              TextFormField(
                controller: fullAddress,
                decoration: const InputDecoration(labelText: "Địa chỉ"),
              ),

              TextFormField(
                controller: label,
                decoration: const InputDecoration(labelText: "Nhãn"),
              ),

              // ================= DEFAULT SWITCH =================
              SwitchListTile(
                title: const Text("Đặt làm mặc định"),
                value: isDefault,
                onChanged: (v) => setState(() => isDefault = v),
              ),

              const SizedBox(height: 20),

              // ================= DATE =================
              ElevatedButton(
                onPressed: pickDateTime,
                child: const Text("Chọn ngày giờ"),
              ),

              if (selectedDateTime != null) Text("$selectedDateTime"),

              const SizedBox(height: 20),

              // ================= BUTTON =================
              ElevatedButton(
                onPressed: createBooking,
                child: const Text("Đặt lịch"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
