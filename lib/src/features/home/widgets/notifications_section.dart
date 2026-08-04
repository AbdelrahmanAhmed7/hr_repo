import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/home_notification.dart';

class NotificationsSection extends StatelessWidget {
  final List<HomeNotification> notifications;
  final VoidCallback? onViewAll;
  final VoidCallback? onOpenPendingRequests;
  final VoidCallback? onOpenAcceptedRequests;
  final VoidCallback? onOpenRejectedRequests;
  final VoidCallback? onCheckInOut;

  const NotificationsSection({
    super.key,
    required this.notifications,
    this.onViewAll,
    this.onOpenPendingRequests,
    this.onOpenAcceptedRequests,
    this.onOpenRejectedRequests,
    this.onCheckInOut,
  });

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return const SizedBox.shrink();
    }

    final visibleItems = notifications.take(3).toList();
    final urgentCount = notifications
        .where((item) => item.priority == NotificationPriority.high)
        .length;
    final followUpCount = notifications
        .where((item) => item.priority == NotificationPriority.medium)
        .length;
    final primaryNotification = notifications.first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            eyebrow: '\u064a\u062d\u062a\u0627\u062c \u0645\u062a\u0627\u0628\u0639\u0629',
            title: '\u0627\u0644\u062a\u0646\u0628\u064a\u0647\u0627\u062a',
            icon: Icons.notifications_active_rounded,
            actionLabel: notifications.length > 3
                ? '\u0639\u0631\u0636 \u0627\u0644\u0643\u0644'
                : null,
            onAction: notifications.length > 3 ? onViewAll : null,
          ),
          const SizedBox(height: 10),
          _NotificationOverview(
            urgentCount: urgentCount,
            followUpCount: followUpCount,
            totalCount: notifications.length,
          ),
          const SizedBox(height: 10),
          _PrimaryNotificationCard(
            notification: primaryNotification,
            onTap: () => _handleNotificationTap(context, primaryNotification),
          ),
          if (visibleItems.length > 1) ...[
            const SizedBox(height: 10),
            ...visibleItems.skip(1).map(
              (notification) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _NotificationCard(
                  notification: notification,
                  compact: true,
                  onTap: () => _handleNotificationTap(context, notification),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _handleNotificationTap(
    BuildContext context,
    HomeNotification notification,
  ) {
    switch (notification.id) {
      case 'pending_requests':
        onOpenPendingRequests?.call();
        break;
      case 'request_accepted':
        onOpenAcceptedRequests?.call();
        break;
      case 'request_rejected':
        onOpenRejectedRequests?.call();
        break;
      case 'missing_checkout':
      case 'missing_checkin':
        onCheckInOut?.call();
        break;
      default:
        notification.onTap?.call();
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primaryTint,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel!,
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final HomeNotification notification;
  final VoidCallback? onTap;
  final bool compact;

  const _NotificationCard({
    required this.notification,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: EdgeInsets.all(compact ? 12 : 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: notification.borderColor),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: compact ? 40 : 44,
                height: compact ? 40 : 44,
                decoration: BoxDecoration(
                  color: notification.backgroundColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  notification.icon,
                  color: notification.color,
                  size: compact ? 20 : 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleSmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _PriorityPill(notification: notification),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.message,
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (notification.actionLabel != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            notification.actionLabel!,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: notification.color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: notification.color,
                            size: 18,
                          ),
                        ],
                      ),
                    ],
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

class _PrimaryNotificationCard extends StatelessWidget {
  final HomeNotification notification;
  final VoidCallback? onTap;

  const _PrimaryNotificationCard({
    required this.notification,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                notification.color.withValues(alpha: 0.12),
                Colors.white,
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: notification.borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: notification.backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  notification.icon,
                  color: notification.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _PriorityPill(notification: notification),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          notification.actionLabel ?? 'متابعة الآن',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: notification.color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: notification.color,
                          size: 18,
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

class _NotificationOverview extends StatelessWidget {
  final int urgentCount;
  final int followUpCount;
  final int totalCount;

  const _NotificationOverview({
    required this.urgentCount,
    required this.followUpCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _OverviewPill(
          label: 'الكل',
          value: '$totalCount',
          color: AppColors.primary,
        ),
        _OverviewPill(
          label: 'عاجل',
          value: '$urgentCount',
          color: AppColors.error,
        ),
        _OverviewPill(
          label: 'متابعة',
          value: '$followUpCount',
          color: AppColors.warning,
        ),
      ],
    );
  }
}

class _OverviewPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _OverviewPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label $value',
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PriorityPill extends StatelessWidget {
  final HomeNotification notification;

  const _PriorityPill({required this.notification});

  @override
  Widget build(BuildContext context) {
    final label = switch (notification.priority) {
      NotificationPriority.high => '\u0639\u0627\u062c\u0644',
      NotificationPriority.medium => '\u0645\u0647\u0645',
      NotificationPriority.low => '\u0639\u0627\u062f\u064a',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: notification.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: notification.color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
