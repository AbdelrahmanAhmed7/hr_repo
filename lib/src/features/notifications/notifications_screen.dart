import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/components/custom_toast.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../auth/cubit/auth_cubit.dart';
import '../home/models/recent_activity.dart';
import '../requests/all_requests_screen.dart';
import '../requests/request_details_screen.dart';
import '../attendance/attendance_screen.dart';
import 'cubit/notifications_cubit.dart';
import 'cubit/notifications_state.dart';
import 'models/notification.dart';
import 'widgets/notification_card.dart';
import 'widgets/notifications_header.dart';

enum _NotificationFilter { all, unread, read }

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  _NotificationFilter _activeFilter = _NotificationFilter.all;

  @override
  void initState() {
    super.initState();
    context.read<NotificationsCubit>().loadNotifications();
  }

  List<NotificationModel> _filterNotifications(NotificationsState state) {
    switch (_activeFilter) {
      case _NotificationFilter.unread:
        return state.unreadNotifications;
      case _NotificationFilter.read:
        return state.readNotifications;
      case _NotificationFilter.all:
        return state.notifications;
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    context.read<NotificationsCubit>().markAsRead(notification.id);

    final authState = context.read<AuthCubit>().state;

    // ── Admin / Super Admin: display-only, no navigation ─────────────────
    if (authState.isAdmin || authState.isSuperAdmin) return;

    // ── Employee: navigate to request details or relevant screen ──────────
    if (notification.type == NotificationType.leave ||
        notification.type == NotificationType.permission ||
        notification.type == NotificationType.overtime ||
        notification.type == NotificationType.mission) {
      final request = RecentActivity.fromNotification(notification);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => RequestDetailsScreen(request: request),
        ),
      );
      return;
    }

    final requestTab = _resolveStatusTab(notification);
    final text = '${notification.title} ${notification.description ?? ''}'
        .toLowerCase();

    switch (notification.type) {
      case NotificationType.attendance:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const AttendanceScreen()),
        );
        break;
      case NotificationType.general:
        if (text.contains('طلب') || text.contains('pending')) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AllRequestsScreen(initialTab: requestTab),
            ),
          );
        }
        break;
      case NotificationType.system:
      default:
        break;
    }
  }

  int _resolveStatusTab(NotificationModel notification) {
    final text = '${notification.title} ${notification.description ?? ''}'
        .toLowerCase();

    if (text.contains('معلق') ||
        text.contains('قيد الانتظار') ||
        text.contains('pending')) {
      return 1;
    }
    if (text.contains('موافق') ||
        text.contains('accepted') ||
        text.contains('approved')) {
      return 2;
    }
    if (text.contains('مرفوض') || text.contains('rejected')) {
      return 3;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NotificationsCubit, NotificationsState>(
      listener: (context, state) {
        if (state.status == NotificationsStatus.failure &&
            state.errorMessage != null) {
          CustomToast.showError(state.errorMessage!);
        }
      },
      builder: (context, state) {
        final filteredNotifications = _filterNotifications(state);

        return Scaffold(
          backgroundColor: AppColors.backgroundSecondary,
          body: Column(
            children: [
              NotificationsHeader(
                unreadCount: state.unreadCount,
                onBack: () => Navigator.of(context).maybePop(),
                onMarkAllRead: state.unreadCount > 0
                    ? () {
                        context.read<NotificationsCubit>().markAllAsRead();
                        CustomToast.showSuccess(
                          'تم تحديد جميع الإشعارات كمقروءة',
                        );
                      }
                    : null,
              ),
              Expanded(
                child:
                    state.status == NotificationsStatus.loading &&
                        state.notifications.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : state.status == NotificationsStatus.failure &&
                          state.notifications.isEmpty
                    ? _buildErrorState(state)
                    : Column(
                        children: [
                          _NotificationsFilterBar(
                            currentFilter: _activeFilter,
                            allCount: state.notifications.length,
                            unreadCount: state.unreadNotifications.length,
                            readCount: state.readNotifications.length,
                            onChanged: (filter) {
                              setState(() => _activeFilter = filter);
                            },
                          ),
                          Expanded(
                            child: filteredNotifications.isEmpty
                                ? _buildEmptyState()
                                : RefreshIndicator(
                                    onRefresh: () => context
                                        .read<NotificationsCubit>()
                                        .loadNotifications(),
                                    child: ListView.separated(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      padding: EdgeInsets.fromLTRB(
                                        24,
                                        8,
                                        24,
                                        20 +
                                            MediaQuery.of(
                                              context,
                                            ).padding.bottom,
                                      ),
                                      itemCount: filteredNotifications.length,
                                      separatorBuilder: (context, index) =>
                                          const SizedBox(height: 14),
                                      itemBuilder: (context, index) {
                                        final notification =
                                            filteredNotifications[index];
                                        return NotificationCard(
                                          notification: notification,
                                          onTap: () => _handleNotificationTap(
                                            notification,
                                          ),
                                          onMarkAsUnread: notification.isRead
                                              ? () {
                                                  context
                                                      .read<
                                                        NotificationsCubit
                                                      >()
                                                      .markAsUnread(
                                                        notification.id,
                                                      );
                                                  CustomToast.showSuccess(
                                                    'تم تحديد الإشعار كغير مقروء',
                                                  );
                                                }
                                              : null,
                                        );
                                      },
                                    ),
                                  ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return EmptyStateWidget(
      icon: Icons.notifications_none_rounded,
      title: _activeFilter == _NotificationFilter.all
          ? 'لا توجد إشعارات'
          : 'لا توجد نتائج في هذا التصنيف',
      message: _activeFilter == _NotificationFilter.all
          ? 'ستظهر الإشعارات هنا عند وصولها'
          : 'جرّب تصنيفًا آخر أو حدّث الصفحة',
      iconColor: AppColors.primary,
    );
  }

  Widget _buildErrorState(NotificationsState state) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: 12),
          Text(
            state.errorMessage ?? 'حدث خطأ أثناء تحميل الإشعارات',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () =>
                context.read<NotificationsCubit>().loadNotifications(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}

class _NotificationsFilterBar extends StatelessWidget {
  final _NotificationFilter currentFilter;
  final int allCount;
  final int unreadCount;
  final int readCount;
  final ValueChanged<_NotificationFilter> onChanged;

  const _NotificationsFilterBar({
    required this.currentFilter,
    required this.allCount,
    required this.unreadCount,
    required this.readCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Row(
        children: [
          _FilterChip(
            label: 'الكل',
            count: allCount,
            isSelected: currentFilter == _NotificationFilter.all,
            onTap: () => onChanged(_NotificationFilter.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'غير مقروءة',
            count: unreadCount,
            isSelected: currentFilter == _NotificationFilter.unread,
            onTap: () => onChanged(_NotificationFilter.unread),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'مقروءة',
            count: readCount,
            isSelected: currentFilter == _NotificationFilter.read,
            onTap: () => onChanged(_NotificationFilter.read),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.18)
                      : AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isSelected ? Colors.white : AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
