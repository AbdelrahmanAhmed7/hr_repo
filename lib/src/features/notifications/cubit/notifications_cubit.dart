import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/app_exception.dart';
import '../models/notification.dart';
import '../repository/notifications_repository.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final NotificationsRepository _repository;

  NotificationsCubit(this._repository) : super(const NotificationsState());

  /// Load notifications and unread count from API.
  Future<void> loadNotifications() async {
    emit(state.copyWith(status: NotificationsStatus.loading));

    try {
      final results = await Future.wait([
        _repository.getNotifications(),
        _repository.getUnreadCount(),
      ]);

      final notifications = results[0] as List<NotificationModel>;
      final unreadCount = results[1] as int;

      if (isClosed) return;
      emit(state.copyWith(
        status: NotificationsStatus.success,
        notifications: notifications,
        unreadCount: unreadCount,
      ));
    } catch (e) {
      if (isClosed) return;
      final error = AppException.from(e, fallbackMessage: 'تعذر تحميل الإشعارات.');
      emit(state.copyWith(
        status: NotificationsStatus.failure,
        errorMessage: error.message,
      ));
    }
  }

  /// Refresh only the unread count (lightweight call, used by Home badge).
  Future<void> refreshUnreadCount() async {
    try {
      final count = await _repository.getUnreadCount();
      if (isClosed) return;
      emit(state.copyWith(unreadCount: count));
    } catch (_) {
      // Silent fail — badge just shows stale count
    }
  }

  /// Mark a single notification as read (optimistic update).
  void markAsRead(String id) {
    final updated = state.notifications.map((n) {
      if (n.id == id && n.isUnread) {
        return NotificationModel(
          id: n.id,
          type: n.type,
          status: NotificationStatus.read,
          title: n.title,
          description: n.description,
          date: n.date,
          actionId: n.actionId,
        );
      }
      return n;
    }).toList();

    final newUnread = updated.where((n) => n.isUnread).length;
    emit(state.copyWith(notifications: updated, unreadCount: newUnread));

    // Fire-and-forget API call
    _repository.markAsRead(id).then((_) => refreshUnreadCount()).catchError((e) {
      if (kDebugMode) print('Failed to mark notification $id as read: $e');
    });
  }

  /// Mark a single notification as unread (optimistic update, local only).
  void markAsUnread(String id) {
    final updated = state.notifications.map((n) {
      if (n.id == id && n.isRead) {
        return NotificationModel(
          id: n.id,
          type: n.type,
          status: NotificationStatus.unread,
          title: n.title,
          description: n.description,
          date: n.date,
          actionId: n.actionId,
        );
      }
      return n;
    }).toList();

    final newUnread = updated.where((n) => n.isUnread).length;
    emit(state.copyWith(notifications: updated, unreadCount: newUnread));
  }

  /// Mark all notifications as read (optimistic update).
  void markAllAsRead() {
    final updated = state.notifications
        .map((n) => NotificationModel(
              id: n.id,
              type: n.type,
              status: NotificationStatus.read,
              title: n.title,
              description: n.description,
              date: n.date,
              actionId: n.actionId,
            ))
        .toList();

    emit(state.copyWith(notifications: updated, unreadCount: 0));

    // Fire-and-forget API call
    _repository.markAllAsRead().then((_) => refreshUnreadCount()).catchError((e) {
      if (kDebugMode) print('Failed to mark all notifications as read: $e');
    });
  }

  /// Delete a notification locally.
  void deleteNotification(String id) {
    final updated = state.notifications.where((n) => n.id != id).toList();
    final newUnread = updated.where((n) => n.isUnread).length;
    emit(state.copyWith(notifications: updated, unreadCount: newUnread));
  }
}
