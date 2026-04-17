import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;

  final String title;
  final String content;

  final bool isRead;
  final Timestamp createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromDoc(String id, Map<String, dynamic> data) {
    return NotificationModel(
      id: id,
      userId: data["userId"] ?? "",
      title: data["title"] ?? "",
      content: data["content"] ?? "",
      isRead: data["isRead"] ?? false,
      createdAt: data["createdAt"] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "userId": userId,
      "title": title,
      "content": content,
      "isRead": isRead,
      "createdAt": createdAt,
    };
  }
}
