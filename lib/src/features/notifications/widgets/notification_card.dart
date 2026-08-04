import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/notification.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsUnread;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.onMarkAsUnread,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onMarkAsUnread,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: notification.isUnread
                  ? notification.typeColor.withValues(alpha: 0.28)
                  : AppColors.border,
              width: notification.isUnread ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: notification.typeColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  notification.typeIcon,
                  color: notification.typeColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: notification.isUnread
                                      ? FontWeight.w800
                                      : FontWeight.w700,
                                  height: 1.35,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (notification.isUnread)
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(top: 6),
                            decoration: BoxDecoration(
                              color: notification.typeColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if (notification.description != null &&
                        notification.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        notification.description!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaChip(
                          icon: Icons.access_time_rounded,
                          label: notification.timeAgo,
                          color: AppColors.textTertiary,
                          background: AppColors.backgroundSecondary,
                        ),
                        _MetaChip(
                          icon: notification.typeIcon,
                          label: notification.typeText,
                          color: notification.typeColor,
                          background:
                              notification.typeColor.withValues(alpha: 0.10),
                        ),
                        _MetaChip(
                          icon: notification.isUnread
                              ? Icons.mark_chat_unread_rounded
                              : Icons.done_all_rounded,
                          label: notification.isUnread ? 'غير مقروء' : 'مقروء',
                          color: notification.isUnread
                              ? AppColors.primary
                              : AppColors.success,
                          background: notification.isUnread
                              ? AppColors.primaryTint
                              : AppColors.successTint,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color background;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
