import '../../../core/network/dio_client.dart';
import '../../../core/utils/app_exception.dart';
import '../models/notification.dart';

class NotificationsRepository {
  final DioClient _dioClient;

  NotificationsRepository(this._dioClient);

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await _dioClient.dio.get('/api/Notification');
      final data = response.data;

      List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map<String, dynamic> && data['data'] is List) {
        list = data['data'] as List<dynamic>;
      } else {
        list = [];
      }

      return NotificationModel.fromApiList(list);
    } catch (e) {
      throw AppException.from(e, fallbackMessage: 'تعذر تحميل الإشعارات.');
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _dioClient.dio.get('/api/Notification/unread-count');
      final data = response.data;

      if (data is Map<String, dynamic>) {
        final value = data['count'];
        if (value is int) return value;
        if (value is String) return int.tryParse(value) ?? 0;
      } else if (data is int) {
        return data;
      }

      return 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _dioClient.dio.put('/api/Notification/$id/read');
    } catch (e) {
      throw AppException.from(e, fallbackMessage: 'تعذر تحديث حالة الإشعار.');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _dioClient.dio.put('/api/Notification/read-all');
    } catch (e) {
      throw AppException.from(e, fallbackMessage: 'تعذر تحديث حالة جميع الإشعارات.');
    }
  }

  /// Send a notification to a single employee.
  Future<void> sendDirectNotification({
    required String recipientUserId,
    required String title,
    required String message,
  }) async {
    try {
      await _dioClient.dio.post('/api/Notification/direct', data: {
        'recipientUserId': recipientUserId,
        'title': title,
        'message': message,
      });
    } catch (e) {
      throw AppException.from(e, fallbackMessage: 'تعذر إرسال الإشعار.');
    }
  }

  /// Send a broadcast notification to all employees or a specific department.
  ///
  /// [targetType]: 1 => all employees, 2 => specific department.
  Future<void> sendBroadcastNotification({
    required int targetType,
    String? targetUserId,
    int? targetDepartmentId,
    required String title,
    required String message,
  }) async {
    try {
      await _dioClient.dio.post('/api/Notification/broadcast', data: {
        'targetType': targetType,
        'targetUserId': targetUserId,
        'targetDepartmentId': targetDepartmentId ?? 0,
        'title': title,
        'message': message,
      });
    } catch (e) {
      throw AppException.from(e, fallbackMessage: 'تعذر إرسال الإشعار.');
    }
  }
}
