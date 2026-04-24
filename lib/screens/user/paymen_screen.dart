import 'package:booking_don_rac/services/payment_service.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PaymentScreen extends StatelessWidget {
  final String bookingId;

  PaymentScreen({super.key, required this.bookingId});

  final service = PaymentService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thanh toán QR")),

      body: StreamBuilder(
        stream: service.getByBooking(bookingId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          }

          final payments = snapshot.data ?? [];

          if (payments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Chưa có thanh toán"),
                  const SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: () async {
                      await service.createFromBooking(bookingId);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Đã tạo payment")),
                      );
                    },
                    child: const Text("Tạo payment"),
                  ),
                ],
              ),
            );
          }

          final payment = payments.first;

          // 🔥 QR DATA (có thể đổi format theo MoMo/ZaloPay sau)
          final qrData =
              "BOOKING:$bookingId|AMOUNT:${payment.amount}|PAYMENT:${payment.id}";

          return SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    Text(
                      "Số tiền cần thanh toán",
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),

                    Text(
                      "${payment.amount} đ",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ================= QR CODE =================
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 220,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      "Trạng thái: ${payment.status}",
                      style: TextStyle(
                        fontSize: 18,
                        color: payment.status == "PAID"
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 30),

                    if (payment.status != "PAID")
                      Column(
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 12,
                              ),
                            ),
                            icon: const Icon(Icons.qr_code),
                            onPressed: () async {
                              await service.pay(payment.id, bookingId);

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Thanh toán thành công"),
                                ),
                              );
                            },
                            label: const Text("Xác nhận đã thanh toán"),
                          ),

                          const SizedBox(height: 10),

                          const Text(
                            "Quét QR để thanh toán (demo)",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      )
                    else
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 80,
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
