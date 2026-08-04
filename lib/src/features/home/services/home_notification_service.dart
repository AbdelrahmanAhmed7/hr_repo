import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../attendance/models/today_attendance.dart';
import '../models/home_api_response.dart';
import '../models/home_notification.dart';

class HomeNotificationService {
  /// Generate local notifications based on home data
  List<HomeNotification> generateNotifications({
    required HomeApiResponse homeData,
    required TodayAttendance attendance,
  }) {
    final notifications = <HomeNotification>[];

    // 1. تنبيه الطلبات المعلقة
    _checkPendingRequests(homeData, notifications);

    // 2. تنبيه الحضور والانصراف
    _checkAttendance(homeData, attendance, notifications);

    // 3. تنبيه الطلبات المقبولة/المرفوضة حديثاً
    _checkRecentRequestUpdates(homeData, notifications);

    // ترتيب حسب الأولوية
    notifications.sort((a, b) {
      final priorityOrder = {
        NotificationPriority.high: 0,
        NotificationPriority.medium: 1,
        NotificationPriority.low: 2,
      };
      return priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!);
    });

    return notifications;
  }

  void _checkPendingRequests(
    HomeApiResponse data,
    List<HomeNotification> notifications,
  ) {
    final pendingCount = data.pendingRequests.length;

    if (pendingCount >= 3) {
      notifications.add(HomeNotification(
        id: 'pending_requests',
        type: NotificationType.warning,
        priority: NotificationPriority.medium,
        title: 'لديك $pendingCount طلبات معلقة',
        message: 'يرجى مراجعة حالة طلباتك',
        icon: Icons.pending_actions,
        color: AppColors.warning,
        actionLabel: 'عرض الطلبات',
      ));
    } else if (pendingCount > 0) {
      notifications.add(HomeNotification(
        id: 'pending_requests',
        type: NotificationType.info,
        priority: NotificationPriority.low,
        title: 'لديك $pendingCount ${pendingCount == 1 ? "طلب معلق" : "طلبات معلقة"}',
        message: 'في انتظار الموافقة',
        icon: Icons.hourglass_empty,
        color: AppColors.primary,
        actionLabel: 'عرض',
      ));
    }
  }

  void _checkAttendance(
    HomeApiResponse data,
    TodayAttendance attendance,
    List<HomeNotification> notifications,
  ) {
    final now = DateTime.now();

    // تحقق إذا كان بعد ساعات العمل ولم يسجل انصراف
    if (attendance.isCheckedIn && !attendance.isCheckedOut && now.hour >= 17) {
      notifications.add(HomeNotification(
        id: 'missing_checkout',
        type: NotificationType.warning,
        priority: NotificationPriority.high,
        title: 'لم تسجل انصرافك بعد',
        message: 'لا تنسى تسجيل وقت الانصراف',
        icon: Icons.logout,
        color: AppColors.error,
        actionLabel: 'تسجيل الآن',
      ));
    }

    // تحقق إذا كان وقت العمل ولم يسجل حضور
    if (!attendance.isCheckedIn && now.hour >= 9 && now.hour < 12) {
      notifications.add(HomeNotification(
        id: 'missing_checkin',
        type: NotificationType.warning,
        priority: NotificationPriority.high,
        title: 'لم تسجل حضورك بعد',
        message: 'لا تنسى تسجيل وقت الحضور',
        icon: Icons.login,
        color: AppColors.error,
        actionLabel: 'تسجيل الآن',
      ));
    }

    // تنبيه ساعات العمل الطويلة
    if (attendance.isCheckedIn && !attendance.isCheckedOut) {
      final workHours = _calculateWorkHours(attendance.checkInTime!);
      if (workHours >= 9) {
        notifications.add(HomeNotification(
          id: 'long_work_hours',
          type: NotificationType.info,
          priority: NotificationPriority.low,
          title: 'لقد عملت ${workHours.toStringAsFixed(1)} ساعات اليوم',
          message: 'وقت جيد لأخذ استراحة!',
          icon: Icons.coffee,
          color: AppColors.primary,
        ));
      }
    }
  }

  void _checkRecentRequestUpdates(
    HomeApiResponse data,
    List<HomeNotification> notifications,
  ) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    // تحقق من الطلبات المقبولة حديثاً
    final recentAccepted = data.acceptedRequests.where((req) {
      try {
        final createdAt = DateTime.parse(req.createdAt);
        return createdAt.isAfter(yesterday);
      } catch (e) {
        return false;
      }
    }).toList();

    if (recentAccepted.isNotEmpty) {
      final count = recentAccepted.length;
      notifications.add(HomeNotification(
        id: 'request_accepted',
        type: NotificationType.success,
        priority: NotificationPriority.medium,
        title: 'تم الموافقة على ${count == 1 ? "طلبك" : "$count طلبات"}',
        message: 'يمكنك الآن الاطلاع على التفاصيل',
        icon: Icons.check_circle,
        color: AppColors.success,
        actionLabel: 'عرض',
      ));
    }

    // تحقق من الطلبات المرفوضة حديثاً
    final recentRejected = data.rejectedRequests.where((req) {
      try {
        final createdAt = DateTime.parse(req.createdAt);
        return createdAt.isAfter(yesterday);
      } catch (e) {
        return false;
      }
    }).toList();

    if (recentRejected.isNotEmpty) {
      final count = recentRejected.length;
      notifications.add(HomeNotification(
        id: 'request_rejected',
        type: NotificationType.error,
        priority: NotificationPriority.high,
        title: 'تم رفض ${count == 1 ? "طلبك" : "$count طلبات"}',
        message: 'يرجى الاطلاع على التفاصيل لمعرفة سبب الرفض',
        icon: Icons.cancel,
        color: AppColors.error,
        actionLabel: 'عرض',
      ));
    }
  }

  double _calculateWorkHours(DateTime checkInTime) {
    final now = DateTime.now();
    final difference = now.difference(checkInTime);
    return difference.inMinutes / 60.0;
  }
}
