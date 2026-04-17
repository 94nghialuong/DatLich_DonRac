import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String message;
  final String type; // text, image, file
  final Timestamp createdAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.message,
    required this.type,
    required this.createdAt,
  });

  factory MessageModel.fromDoc(String id, Map<String, dynamic> data) {
    return MessageModel(
      id: id,
      senderId: data["senderId"] ?? "",
      message: data["message"] ?? "",
      type: data["type"] ?? "text",
      createdAt: data["createdAt"] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "senderId": senderId,
      "message": message,
      "type": type,
      "createdAt": createdAt,
    };
  }
}
