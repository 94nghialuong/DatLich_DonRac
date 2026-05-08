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

  final receiverName = TextEditingController();
  final phone = TextEditingController();
  final province = TextEditingController();
  final district = TextEditingController();
  final ward = TextEditingController();
  final fullAddress = TextEditingController();
  final label = TextEditingController();

  bool isDefault = false;
  DateTime? selectedDateTime;

  @override
  void initState() {
    super.initState();
    loadDefaultAddress();
  }

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

  Future<void> pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
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

  Future<void> createBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedDateTime == null) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final db = FirebaseFirestore.instance;

    try {
      final addressRef = await db.collection("addresses").add({
        "userId": uid,
        "receiverName": receiverName.text,
        "phone": phone.text,
        "province": province.text,
        "district": district.text,
        "ward": ward.text,
        "fullAddress": fullAddress.text,
        "label": label.text,
        "isDefault": isDefault,
        "createdAt": Timestamp.now(),
      });

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

      await db.collection("notifications").add({
        "title": "Đặt lịch thành công",
        "content": widget.serviceName,
        "userId": uid,
        "bookingId": bookingRef.id,
        "isRead": false,
        "createdAt": Timestamp.now(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Đặt lịch thành công")));

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Có lỗi xảy ra")));
    }
  }

  // ================= UI INPUT =================
  Widget pillInput(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? type,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.green.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.green),
          hintText: label,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        validator: (v) => v == null || v.isEmpty ? "Không được để trống" : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF7EF),

      appBar: AppBar(
        backgroundColor: const Color(0xFFEAF7EF),
        elevation: 0,
        title: const Text(
          "Tạo booking",
          style: TextStyle(
            color: Color(0xFF1E8449),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1E8449)),
      ),

      // ================= BODY =================
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SERVICE CARD
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.1),
                      blurRadius: 12,
                    ),
                  ],
                  border: Border(
                    left: BorderSide(color: Colors.green, width: 4),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Dịch vụ đã chọn",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        Text(
                          widget.serviceName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "${widget.price} VNĐ",
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Thông tin địa chỉ",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),

              const SizedBox(height: 10),

              pillInput(receiverName, "Người nhận", Icons.person),
              pillInput(
                phone,
                "Số điện thoại",
                Icons.phone,
                type: TextInputType.phone,
              ),
              pillInput(province, "Tỉnh / Thành", Icons.location_city),
              pillInput(district, "Quận / Huyện", Icons.map),
              pillInput(ward, "Phường / Xã", Icons.place),
              pillInput(fullAddress, "Địa chỉ chi tiết", Icons.home),
              pillInput(label, "Nhãn (nhà riêng, văn phòng...)", Icons.label),

              const SizedBox(height: 10),

              // SWITCH
              SwitchListTile(
                title: const Text("Đặt làm mặc định"),
                value: isDefault,
                activeColor: Colors.green,
                onChanged: (v) => setState(() => isDefault = v),
              ),

              const SizedBox(height: 10),

              // DATE PICKER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Thời gian"),
                    const SizedBox(height: 8),
                    Text(
                      selectedDateTime == null
                          ? "Chưa chọn"
                          : selectedDateTime.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: pickDateTime,
                      icon: const Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "Chọn ngày giờ",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),

      // ================= BOTTOM BUTTON =================
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: ElevatedButton(
          onPressed: createBooking,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            "Đặt lịch ngay",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
