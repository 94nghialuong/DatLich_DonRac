import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationProvider extends ChangeNotifier {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  List<DocumentSnapshot> notifications = [];
  int unreadCount = 0;
  bool isLoading = false;

  final List<StreamSubscription<QuerySnapshot>> _subs = [];
  final Map<int, List<DocumentSnapshot>> _queryDocs = {};

  void listenNotifications({required String userId, required String role}) {
    clear(notify: false);

    if (userId.trim().isEmpty) return;

    isLoading = true;
    notifyListeners();

    final userRole = role.toUpperCase();

    final queries = <Query>[
      db.collection('notifications').where('receiverId', isEqualTo: userId),
    ];

    // Backward compatibility for older documents.
    if (userRole == 'STAFF') {
      queries.add(
        db.collection('notifications').where('employeeId', isEqualTo: userId),
      );
    } else {
      queries.add(
        db.collection('notifications').where('userId', isEqualTo: userId),
      );
    }

    for (int i = 0; i < queries.length; i++) {
      final sub = queries[i].snapshots().listen(
        (snapshot) {
          _queryDocs[i] = snapshot.docs;
          _rebuildMergedList(role: userRole);
        },
        onError: (e) {
          debugPrint('❌ NOTIFICATION STREAM ERROR: $e');
          isLoading = false;
          notifyListeners();
        },
      );

      _subs.add(sub);
    }
  }

  void _rebuildMergedList({required String role}) {
    final map = <String, DocumentSnapshot>{};

    for (final docs in _queryDocs.values) {
      for (final doc in docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        final target = (data['target'] ?? '').toString().toUpperCase();
        final receiverRole = (data['receiverRole'] ?? '').toString().toUpperCase();

        // Keep old documents that do not have target/receiverRole.
        if (target.isNotEmpty && target != role && target != 'USER') {
          continue;
        }
        if (receiverRole.isNotEmpty &&
            receiverRole != role &&
            !(role == 'CUSTOMER' && receiverRole == 'USER')) {
          continue;
        }

        map[doc.id] = doc;
      }
    }

    final docs = map.values.toList();

    docs.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>? ?? {};
      final bData = b.data() as Map<String, dynamic>? ?? {};
      final aTime = aData['createdAt'];
      final bTime = bData['createdAt'];

      if (aTime is Timestamp && bTime is Timestamp) {
        return bTime.compareTo(aTime);
      }
      if (aTime is Timestamp) return -1;
      if (bTime is Timestamp) return 1;
      return 0;
    });

    notifications = docs;
    unreadCount = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      return data['isRead'] != true;
    }).length;
    isLoading = false;

    notifyListeners();
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await db.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ MARK READ ERROR: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final unread = notifications.where((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        return data['isRead'] != true;
      }).toList();

      if (unread.isEmpty) return;

      final batch = db.batch();

      for (final doc in unread) {
        batch.update(db.collection('notifications').doc(doc.id), {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('❌ MARK ALL ERROR: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await db.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      debugPrint('❌ DELETE ERROR: $e');
    }
  }

  Future<void> deleteAllNotifications() async {
    try {
      if (notifications.isEmpty) return;

      final batch = db.batch();

      for (final doc in notifications) {
        batch.delete(db.collection('notifications').doc(doc.id));
      }

      await batch.commit();
    } catch (e) {
      debugPrint('❌ DELETE ALL ERROR: $e');
    }
  }

  void clear({bool notify = true}) {
    for (final sub in _subs) {
      sub.cancel();
    }

    _subs.clear();
    _queryDocs.clear();
    notifications.clear();
    unreadCount = 0;
    isLoading = false;

    if (notify) notifyListeners();
  }

  @override
  void dispose() {
    clear(notify: false);
    super.dispose();
  }
}
