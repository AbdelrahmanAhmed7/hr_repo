import 'package:flutter/material.dart';

enum NotificationType {
  success,
  warning,
  error,
  info,
}

enum NotificationPriority {
  high,
  medium,
  low,
}

class HomeNotification {
  final String id;
  final NotificationType type;
  final NotificationPriority priority;
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final String? actionLabel;
  final VoidCallback? onTap;
  final DateTime createdAt;

  HomeNotification({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    this.actionLabel,
    this.onTap,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Color get backgroundColor {
    return color.withValues(alpha: 0.1);
  }

  Color get borderColor {
    return color.withValues(alpha: 0.3);
  }
}
