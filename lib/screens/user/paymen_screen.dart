import 'package:booking_don_rac/models/payment_model.dart';
import 'package:booking_don_rac/services/payment_service.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PaymentScreen extends StatefulWidget {
  final String bookingId;

  const PaymentScreen({super.key, required this.bookingId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService service = PaymentService();

  bool _isCreatingPayment = false;
  bool _createdPayment = false;

  Future<void> _autoCreatePayment() async {
    if (_isCreatingPayment || _createdPayment) return;

    setState(() {
      _isCreatingPayment = true;
    });

    try {
      await service.createFromBooking(
        bookingId: widget.bookingId,
        method: "MOMO",
      );

      _createdPayment = true;
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi tạo thanh toán: $e")));
    } finally {
      if (!mounted) return;

      setState(() {
        _isCreatingPayment = false;
      });
    }
  }

  Color getMethodColor(String method) {
    switch (method) {
      case "MOMO":
        return const Color(0xFFD82D8B);
      case "ZALOPAY":
        return const Color(0xFF0068FF);
      default:
        return Colors.green;
    }
  }

  String getMethodLogo(String method) {
    switch (method) {
      case "MOMO":
        return "assets/images/momo.png";
      case "ZALOPAY":
        return "assets/images/zalopay.png";
      default:
        return "";
    }
  }

  String formatMoney(double amount) {
    return "${amount.toStringAsFixed(0)} đ";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6FD),
      appBar: AppBar(
        title: const Text("Thanh toán QR"),
        backgroundColor: const Color(0xFFFDF6FD),
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: StreamBuilder<List<PaymentModel>>(
        stream: service.getByBooking(widget.bookingId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          }

          final payments = snapshot.data ?? [];

          if (payments.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _autoCreatePayment();
            });

            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text("Hệ thống đang tạo thanh toán cho khách..."),
                ],
              ),
            );
          }

          final payment = payments.first;
          final color = getMethodColor(payment.method);

          final qrData =
              payment.qrContent ??
              "BOOKING:${widget.bookingId}|AMOUNT:${payment.amount}|PAYMENT:${payment.id}";

          final isPaid = payment.status == "PAID";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                const SizedBox(height: 10),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: color.withOpacity(0.12),
                        child: Icon(
                          Icons.account_balance_wallet,
                          color: color,
                          size: 36,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        "Thanh toán qua ${payment.method}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        formatMoney(payment.amount),
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: color, width: 1.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 230,
                        ),
                      ),

                      const SizedBox(height: 18),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: isPaid
                              ? Colors.green.withOpacity(0.12)
                              : Colors.orange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          isPaid ? "Đã thanh toán" : "Đang chờ thanh toán",
                          style: TextStyle(
                            color: isPaid ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hướng dẫn thanh toán",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text("1. Mở ứng dụng ví điện tử hoặc ngân hàng."),
                      Text("2. Chọn quét mã QR."),
                      Text("3. Kiểm tra số tiền và xác nhận."),
                      Text("4. Bấm xác nhận đã thanh toán trong app."),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                if (!isPaid)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_outline),
                      onPressed: () async {
                        await service.pay(payment.id, widget.bookingId);

                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Thanh toán thành công"),
                          ),
                        );
                      },
                      label: const Text(
                        "Xác nhận đã thanh toán",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else
                  const Column(
                    children: [
                      Icon(Icons.verified, color: Colors.green, size: 76),
                      SizedBox(height: 8),
                      Text(
                        "Cảm ơn bạn đã thanh toán",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
