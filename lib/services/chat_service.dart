import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  /// =========================
  /// 🔥 CREATE / GET ROOM
  /// =========================
  Future<String> getRoomId(
    String bookingId,
    String userId,
    String staffId,
  ) async {
    // 🔥 FIX: sort để tránh lệch id
    final members = [userId, staffId]..sort();
    final roomId = "${bookingId}_${members[0]}_${members[1]}";

    final ref = db.collection("chatroom").doc(roomId);
    final doc = await ref.get();

    if (!doc.exists) {
      await ref.set({
        "bookingId": bookingId,
        "members": members,
        "createdAt": FieldValue.serverTimestamp(),
      });
    }

    return roomId;
  }

  /// =========================
  /// 📤 SEND MESSAGE
  /// =========================
  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    final roomRef = db.collection("chatroom").doc(roomId);

    // ================= SAVE MESSAGE =================
    await roomRef.collection("messages").add({
      "senderId": senderId,
      "senderName": senderName,
      "message": text,
      "type": "text",
      "createdAt": FieldValue.serverTimestamp(),
    });

    // ================= GET ROOM =================
    final roomDoc = await roomRef.get();

    if (!roomDoc.exists) return;

    final data = roomDoc.data()!;

    final members = List<String>.from(data["members"] ?? []);

    // ================= SEND NOTIFICATION =================
    for (var memberId in members) {
      if (memberId == senderId) continue;

      final userDoc = await db.collection("users").doc(memberId).get();

      if (!userDoc.exists) continue;

      final role = userDoc.data()?["role"] ?? "user";

      await db.collection("notifications").add({
        "receiverId": memberId,
        "role": role.toUpperCase(),
        "type": "chat",
        "title": senderName,
        "content": text,
        "roomId": roomId,
        "isRead": false,
        "createdAt": Timestamp.now(),
      });
    }
  }

  /// =========================
  /// 🔥 STREAM MESSAGE (REALTIME)
  /// =========================
  Stream<QuerySnapshot> getMessages(String roomId) {
    return db
        .collection("chatroom")
        .doc(roomId)
        .collection("messages")
        .orderBy("createdAt", descending: false) // 👈 CŨNG PHẢI TĂNG DẦN
        .snapshots();
  }
}
