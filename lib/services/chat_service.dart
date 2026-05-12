import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Future<String> getRoomId(
    String bookingId,
    String userId,
    String staffId,
  ) async {
    final members = [userId, staffId]..sort();
    final roomId = "${bookingId}_${members[0]}_${members[1]}";

    final ref = db.collection("chatroom").doc(roomId);
    final doc = await ref.get();

    if (!doc.exists) {
      await ref.set({
        "bookingId": bookingId,
        "userId": userId,
        "staffId": staffId,
        "members": members,
        "createdAt": FieldValue.serverTimestamp(),
      });
    } else {
      await ref.set({
        "bookingId": bookingId,
        "userId": userId,
        "staffId": staffId,
        "members": members,
      }, SetOptions(merge: true));
    }

    return roomId;
  }

  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    final roomRef = db.collection("chatroom").doc(roomId);

    await roomRef.collection("messages").add({
      "senderId": senderId,
      "senderName": senderName,
      "message": text,
      "type": "text",
      "createdAt": FieldValue.serverTimestamp(),
    });

    final roomDoc = await roomRef.get();
    if (!roomDoc.exists) return;

    final data = roomDoc.data()!;

    final members = List<String>.from(data["members"] ?? []);
    final bookingId = data["bookingId"] ?? "";

    for (final memberId in members) {
      if (memberId == senderId) continue;

      final userDoc = await db.collection("users").doc(memberId).get();
      if (!userDoc.exists) continue;

      final userData = userDoc.data() ?? {};
      final role = (userData["role"] ?? "CUSTOMER").toString().toUpperCase();

      final isStaff = role == "STAFF";

      await db.collection("notifications").add({
        "title": "Tin nhắn mới",
        "content": "$senderName: $text",
        "type": "chat",

        "target": isStaff ? "STAFF" : "USER",
        "role": role,

        "receiverId": memberId,

        "employeeId": isStaff ? memberId : null,
        "userId": isStaff ? null : memberId,

        "bookingId": bookingId,
        "roomId": roomId,

        "isRead": false,
        "createdAt": Timestamp.now(),
      });
    }
  }

  Stream<QuerySnapshot> getMessages(String roomId) {
    return db
        .collection("chatroom")
        .doc(roomId)
        .collection("messages")
        .orderBy("createdAt", descending: false)
        .snapshots();
  }
}
