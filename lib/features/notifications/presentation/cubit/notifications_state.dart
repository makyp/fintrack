part of 'notifications_cubit.dart';

class NotificationsState {
  final List<NotificationItem> items;
  final int unreadCount;

  const NotificationsState({
    this.items = const [],
    this.unreadCount = 0,
  });

  NotificationsState copyWith({
    List<NotificationItem>? items,
    int? unreadCount,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
