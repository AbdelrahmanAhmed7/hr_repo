import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

enum NotificationType {
  leave,
  permission,
  attendance,
  overtime,
  mission,
  general,
  system,
}

enum NotificationStatus { unread, read }

class NotificationModel {
  final String id;
  final NotificationType type;
  final NotificationStatus status;
  final String title;
  final String? description;
  final DateTime date;
  final String? actionId; // ID of related item (leave request, etc.)
  final String? userId; // User ID of the employee (for admin notifications)

  NotificationModel({
    required this.id,
    required this.type,
    required this.status,
    required this.title,
    this.description,
    required this.date,
    this.actionId,
    this.userId,
  });

  bool get isRead => status == NotificationStatus.read;
  bool get isUnread => status == NotificationStatus.unread;

  String get typeText {
    switch (type) {
      case NotificationType.leave:
        return 'إجازة';
      case NotificationType.permission:
        return 'إذن';
      case NotificationType.attendance:
        return 'حضور';
      case NotificationType.overtime:
        return 'عمل إضافي';
      case NotificationType.mission:
        return 'مهمة';
      case NotificationType.general:
        return 'عام';
      case NotificationType.system:
        return 'نظام';
    }
  }

  IconData get typeIcon {
    switch (type) {
      case NotificationType.leave:
        return Icons.calendar_today_rounded;
      case NotificationType.permission:
        return Icons.access_time_rounded;
      case NotificationType.attendance:
        return Icons.login_rounded;
      case NotificationType.overtime:
        return Icons.schedule_rounded;
      case NotificationType.mission:
        return Icons.work_outline_rounded;
      case NotificationType.general:
        return Icons.notifications_rounded;
      case NotificationType.system:
        return Icons.settings_rounded;
    }
  }

  Color get typeColor {
    switch (type) {
      case NotificationType.leave:
        return AppColors.primary;
      case NotificationType.permission:
        return AppColors.warning;
      case NotificationType.attendance:
        return AppColors.success;
      case NotificationType.overtime:
        return AppColors.primaryDark;
      case NotificationType.mission:
        return AppColors.primaryLight;
      case NotificationType.general:
        return AppColors.textSecondary;
      case NotificationType.system:
        return AppColors.textTertiary;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'الآن';
        }
        return 'منذ ${difference.inMinutes} دقيقة';
      }
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String get timeAgo => _formatDate(date);

  static NotificationType _mapType(String? type) {
    final value = type?.toLowerCase().trim() ?? '';
    switch (value) {
      case 'leave':
        return NotificationType.leave;
      case 'permission':
        return NotificationType.permission;
      case 'attendance':
        return NotificationType.attendance;
      case 'overtime':
        return NotificationType.overtime;
      case 'mission':
        return NotificationType.mission;
      case 'general':
        return NotificationType.general;
      case 'system':
        return NotificationType.system;
      default:
        return NotificationType.general;
    }
  }

  static NotificationStatus _mapStatus(bool? isRead) {
    return isRead == true ? NotificationStatus.read : NotificationStatus.unread;
  }

  factory NotificationModel.fromApi(Map<String, dynamic> json) {
    final createdAtRaw = json['createdAt'] as String?;
    DateTime dateTime;
    if (createdAtRaw != null) {
      try {
        dateTime = DateTime.parse(createdAtRaw);
      } catch (_) {
        dateTime = DateTime.now();
      }
    } else {
      dateTime = DateTime.now();
    }

    final messageRaw = json['message'] as String?;
    final message = messageRaw?.trim() ?? '';

    return NotificationModel(
      id: json['id']?.toString() ?? '',
      type: _mapType(json['type'] as String?),
      status: _mapStatus(json['isRead'] as bool?),
      title: message.isNotEmpty ? message : 'إشعار جديد',
      description: null,
      date: dateTime,
      actionId: json['requestId']?.toString(),
      userId: json['userId']?.toString(),
    );
  }

  static List<NotificationModel> fromApiList(List<dynamic> list) {
    return list
        .whereType<Map<String, dynamic>>()
        .map(NotificationModel.fromApi)
        .toList();
  }
}
