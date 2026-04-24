import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _service = ChatService();

  /// =========================
  /// 📤 SEND MESSAGE
  /// =========================
  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    await _service.sendMessage(
      roomId: roomId,
      senderId: senderId,
      senderName: senderName,
      text: text,
    );
  }

  /// =========================
  /// 🔥 STREAM MESSAGE
  /// =========================
  Stream<QuerySnapshot> messages(String roomId) {
    return _service.getMessages(roomId);
  }
}
