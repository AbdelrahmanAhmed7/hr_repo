import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../home/models/recent_activity.dart';
import '../request_details_screen.dart';

class RequestCard extends StatelessWidget {
  final RecentActivity request;

  const RequestCard({
    super.key,
    required this.request,
  });

  IconData _getTypeIcon() {
    switch (request.type) {
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
      return 'اليوم';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String? _extraDetails() {
    final parts = <String>[
      if (request.leaveType?.trim().isNotEmpty == true) 'نوع الإجازة: ${request.leaveType}',
      if (request.location?.trim().isNotEmpty == true) 'المكان: ${request.location}',
      if (request.startTime?.trim().isNotEmpty == true &&
          request.endTime?.trim().isNotEmpty == true)
        'الوقت: ${request.startTime} - ${request.endTime}',
      if (request.deductionType?.trim().isNotEmpty == true)
        'الخصم: ${request.deductionType}',
      if (request.totalHours != null) 'عدد الساعات: ${request.totalHours}',
      if (request.amount != null) 'القيمة: ${request.amount} EGP',
      if (request.rejectionReason?.trim().isNotEmpty == true)
        'سبب الرفض: ${request.rejectionReason}',
    ];
    if (parts.isEmpty) return null;
    return parts.join(' | ');
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => RequestDetailsScreen(request: request),
            ),
          );
        },
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.05),
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
                  color: request.statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getTypeIcon(),
                  color: request.statusColor,
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
                            request.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleSmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusPill(request: request),
                      ],
                    ),
                    if (request.description != null &&
                        request.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        request.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (request.userName?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 6),
                      Text(
                        'مقدم الطلب: ${request.userName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    if (_extraDetails() != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _extraDetails()!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
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
                          label: request.typeText,
                        ),
                        _MetaChip(
                          icon: Icons.schedule_rounded,
                          label: _formatDate(request.date),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final RecentActivity request;

  const _StatusPill({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: request.statusColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        request.statusText,
        style: AppTextStyles.labelSmall.copyWith(
          color: request.statusColor,
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
