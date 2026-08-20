import 'package:flutter/material.dart';

import '../../requests/request_details_screen.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/components/custom_toast.dart';
import '../../leaves/repository/leaves_repository.dart';
import '../../missions/repository/assignment_repository.dart';
import '../../permissions/repository/permission_repository.dart';
import '../models/recent_activity.dart';

class RecentActivityCard extends StatelessWidget {
  final RecentActivity activity;

  const RecentActivityCard({
    super.key,
    required this.activity,
  });

  IconData _getActivityIcon(RequestType type) {
    switch (type) {
      case RequestType.leave:
        return Icons.calendar_month_rounded;
      case RequestType.permission:
        return Icons.access_time_rounded;
      case RequestType.overtime:
        return Icons.schedule_rounded;
      case RequestType.assignment:
        return Icons.directions_rounded;
      case RequestType.other:
        return Icons.description_rounded;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '\u0627\u0644\u064a\u0648\u0645';
    } else if (difference.inDays == 1) {
      return '\u0623\u0645\u0633';
    } else if (difference.inDays < 7) {
      return '\u0645\u0646\u0630 ${difference.inDays} \u0623\u064a\u0627\u0645';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => RequestDetailsScreen(request: activity),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: activity.statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _getActivityIcon(activity.type),
                  color: activity.statusColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            activity.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleSmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusPill(activity: activity),
                      ],
                    ),
                    if (activity.description != null &&
                        activity.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        activity.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaChip(
                          icon: Icons.layers_outlined,
                          label: activity.typeText,
                        ),
                        _MetaChip(
                          icon: Icons.schedule_rounded,
                          label: _formatDate(activity.date),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _QuickRemindIcon(activity: activity),
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickRemindIcon extends StatefulWidget {
  final RecentActivity activity;

  const _QuickRemindIcon({required this.activity});

  @override
  State<_QuickRemindIcon> createState() => _QuickRemindIconState();
}

class _QuickRemindIconState extends State<_QuickRemindIcon> {
  bool _isLoading = false;

  RecentActivity get activity => widget.activity;

  bool get _canRemind {
    if (activity.status != RequestStatus.pending) return false;
    if (activity.type == RequestType.leave) return true;
    if (activity.type == RequestType.permission) return true;
    if (activity.type == RequestType.assignment) return true;
    return false;
  }

  Future<void> _handleRemind() async {
    if (_isLoading || !_canRemind) return;

    final id = int.tryParse(activity.id);
    if (id == null) {
      CustomToast.showError('تعذر إرسال التذكير: رقم الطلب غير صحيح');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final message = switch (activity.type) {
        RequestType.leave =>
          (await getIt<LeavesRepository>().remindLeave(id: id)).message,
        RequestType.permission =>
          (await getIt<PermissionRepository>().remindPermission(id: id)).message,
        RequestType.assignment =>
          (await getIt<AssignmentRepository>().remindAssignment(id: id)).message,
        RequestType.overtime => null,
        RequestType.other => null,
      };

      if (!mounted) return;
      CustomToast.showSuccess(message ?? 'تم إرسال التذكير بنجاح');
    } catch (_) {
      if (!mounted) return;
      CustomToast.showError('تعذر إرسال التذكير الآن. حاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_canRemind) return const SizedBox.shrink();

    return SizedBox(
      width: 38,
      height: 38,
      child: IconButton(
        padding: EdgeInsets.zero,
        splashRadius: 22,
        tooltip: 'تذكير',
        onPressed: _isLoading ? null : _handleRemind,
        icon: _isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                Icons.notifications_active_outlined,
                size: 20,
                color: AppColors.warning.withValues(alpha: 0.95),
              ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final RecentActivity activity;

  const _StatusPill({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: activity.statusColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        activity.statusText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.labelSmall.copyWith(
          color: activity.statusColor,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
