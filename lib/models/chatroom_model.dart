import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  final String id;
  final String bookingId;
  final List<String> members;
  final Timestamp createdAt;
  final String? lastMessage;
  final Timestamp? lastMessageTime;

  ChatRoomModel({
    required this.id,
    required this.bookingId,
    required this.members,
    required this.createdAt,
    this.lastMessage,
    this.lastMessageTime,
  });

  factory ChatRoomModel.fromDoc(String id, Map<String, dynamic> data) {
    return ChatRoomModel(
      id: id,
      bookingId: data["bookingId"] ?? "",
      members: List<String>.from(data["members"] ?? []),
      createdAt: data["createdAt"] ?? Timestamp.now(),
      lastMessage: data["lastMessage"],
      lastMessageTime: data["lastMessageTime"],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "bookingId": bookingId,
      "members": members,
      "createdAt": createdAt,
      "lastMessage": lastMessage,
      "lastMessageTime": lastMessageTime,
    };
  }
}
