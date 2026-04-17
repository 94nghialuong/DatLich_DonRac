import 'package:cloud_firestore/cloud_firestore.dart';

class AddressModel {
  final String id;
  final String userId;
  final String receiverName;
  final String phone;
  final String label;
  final String fullAddress;
  final String province;
  final String district;
  final String ward;
  final GeoPoint location;
  final bool isDefault;
  final Timestamp createdAt;

  AddressModel({
    required this.id,
    required this.userId,
    required this.receiverName,
    required this.phone,
    required this.label,
    required this.fullAddress,
    required this.province,
    required this.district,
    required this.ward,
    required this.location,
    required this.isDefault,
    required this.createdAt,
  });
  factory AddressModel.fromDoc(String id, Map<String, dynamic> data) {
    return AddressModel(
      id: id,
      userId: data["userId"] ?? "",
      receiverName: data["receiverName"] ?? "",
      phone: data["phone"] ?? "",
      label: data["label"] ?? "",
      fullAddress: data["fullAddress"] ?? "",
      province: data["province"] ?? "",
      district: data["district"] ?? "",
      ward: data["ward"] ?? "",
      location: data["location"] ?? const GeoPoint(0, 0),
      isDefault: data["isDefault"] ?? false,
      createdAt: data["createdAt"] ?? Timestamp.now(),
    );
  }
  Map<String, dynamic> toMap() {
    return {
      "userId": userId,
      "receiverName": receiverName,
      "phone": phone,
      "label": label,
      "fullAddress": fullAddress,
      "province": province,
      "district": district,
      "ward": ward,
      "location": location,
      "isDefault": isDefault,
      "createdAt": createdAt,
    };
  }
}
