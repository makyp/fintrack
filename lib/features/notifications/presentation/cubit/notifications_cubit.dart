import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/notification_item.dart';

part 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final FirebaseFirestore _db;
  StreamSubscription<QuerySnapshot>? _sub;

  NotificationsCubit(this._db) : super(const NotificationsState());

  void watch(String userId) {
    _sub?.cancel();
    if (userId.isEmpty) return;

    _sub = _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen(
      (snap) {
        final items = snap.docs
            .map((d) => NotificationItem.fromFirestore(
                d.data(), d.id))
            .toList();
        emit(state.copyWith(
          items: items,
          unreadCount: items.where((n) => !n.read).length,
        ));
      },
      onError: (_) {},
    );
  }

  Future<void> markRead(String userId, String notifId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notifId)
        .update({'read': true});
  }

  Future<void> markAllRead(String userId) async {
    final snap = await _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
