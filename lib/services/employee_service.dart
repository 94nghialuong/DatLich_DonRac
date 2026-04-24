import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeeSyncService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 🔥 Sync user → employee nếu role = STAFF
  Future<void> syncIfStaff({
    required String uid,
    required String role,
    String? fullname,
  }) async {
    final empRef = _db.collection("employees").doc(uid);

    // ❌ không phải STAFF → xóa employee nếu tồn tại
    if (role != "STAFF") {
      await empRef.delete();
      return;
    }

    final snap = await empRef.get();

    final data = {
      "userId": uid,
      "area": "Huế",
      "isAvailable": true,
      "rating": 0,
      "role": "STAFF",
      "fullname": fullname ?? "",
      "createdAt": FieldValue.serverTimestamp(),
    };

    if (!snap.exists) {
      // 🔥 CREATE
      await empRef.set(data);
    } else {
      // 🔥 UPDATE
      await empRef.update({
        "area": data["area"],
        "isAvailable": data["isAvailable"],
        "role": "STAFF",
        "fullname": data["fullname"],
      });
    }
  }
}
