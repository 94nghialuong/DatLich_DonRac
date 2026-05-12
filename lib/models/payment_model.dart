class PaymentModel {
  final String id;
  final String bookingId;
  final double amount;
  final String method;
  final String status;

  // NEW
  final String? paymentUrl;
  final String? qrContent;

  PaymentModel({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.method,
    required this.status,

    // NEW
    this.paymentUrl,
    this.qrContent,
  });

  factory PaymentModel.fromDoc(String id, Map<String, dynamic> data) {
    return PaymentModel(
      id: id,
      bookingId: data["bookingId"] ?? "",
      amount: (data["amount"] ?? 0).toDouble(),
      method: data["method"] ?? "",
      status: data["status"] ?? "PENDING",

      // NEW
      paymentUrl: data["paymentUrl"],
      qrContent: data["qrContent"],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "bookingId": bookingId,
      "amount": amount,
      "method": method,
      "status": status,

      // NEW
      "paymentUrl": paymentUrl,
      "qrContent": qrContent,
    };
  }
}
