import 'package:flutter/material.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _service = ChatService();

  Future<void> sendMessage(String roomId, Map<String, dynamic> data) async {
    await _service.sendMessage(roomId, data);
  }
}
