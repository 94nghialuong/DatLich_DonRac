import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final CollectionReference chatRooms = FirebaseFirestore.instance.collection(
    "chatroom",
  );

  Future<String> createChatRoom(Map<String, dynamic> data) async {
    final doc = await chatRooms.add(data);
    return doc.id;
  }

  Stream<QuerySnapshot> getMessages(String chatRoomId) {
    return chatRooms
        .doc(chatRoomId)
        .collection("messages")
        .orderBy("createdAt")
        .snapshots();
  }

  Future<void> sendMessage(String chatRoomId, Map<String, dynamic> data) async {
    await chatRooms.doc(chatRoomId).collection("messages").add(data);
  }
}
