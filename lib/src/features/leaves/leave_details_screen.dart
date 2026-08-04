import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'models/leave_request_model.dart';

class LeaveDetailsScreen extends StatelessWidget {
  final LeaveRequestModel leaveRequest;

  const LeaveDetailsScreen({
    super.key,
    required this.leaveRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            expandedHeight: 220,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _LeaveHero(leaveRequest: leaveRequest),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              child: Column(
                children: [
                  _DetailSection(
                    title: 'ملخص سريع',
                    icon: Icons.dashboard_customize_rounded,
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _MetricTile(
                          icon: Icons.calendar_today_rounded,
                          label: 'بداية الإجازة',
                          value: _formatDate(leaveRequest.startDateDateTime),
                        ),
                        _MetricTile(
                          icon: Icons.event_rounded,
                          label: 'نهاية الإجازة',
                          value: _formatDate(leaveRequest.endDateDateTime),
                        ),
                        _MetricTile(
                          icon: Icons.timelapse_rounded,
                          label: 'المدة',
                          value: '${leaveRequest.numberOfDays} يوم',
                        ),
                        _MetricTile(
                          icon: Icons.send_rounded,
                          label: 'تاريخ التقديم',
                          value: _formatDateTime(leaveRequest.submittedDate),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _DetailSection(
                    title: 'الخط الزمني',
                    icon: Icons.route_rounded,
                    child: Column(
                      children: [
                        _TimelineRow(
                          title: 'تم تقديم الطلب',
                          subtitle: _formatDateTime(leaveRequest.submittedDate),
                          color: AppColors.primary,
                          isDone: true,
                        ),
                        _TimelineRow(
                          title: 'فترة الإجازة',
                          subtitle: leaveRequest.dateRangeText,
                          color: AppColors.warning,
                          isDone: true,
                        ),
                        _TimelineRow(
                          title: 'الحالة الحالية',
                          subtitle: leaveRequest.statusText,
                          color: leaveRequest.statusColor,
                          isDone: leaveRequest.status.toLowerCase() != 'pending',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _DetailSection(
                    title: 'السبب',
                    icon: Icons.notes_rounded,
                    child: Text(
                      leaveRequest.reason?.trim().isNotEmpty == true
                          ? leaveRequest.reason!
                          : 'لم يتم إضافة سبب لهذا الطلب.',
                      style: AppTextStyles.bodyMedium.copyWith(height: 1.7),
                    ),
                  ),
                  if (leaveRequest.rejectionReason?.trim().isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: _DetailSection(
                        title: 'ملاحظة الإدارة',
                        icon: Icons.info_outline_rounded,
                        borderColor: AppColors.error.withValues(alpha: 0.20),
                        backgroundColor:
                            AppColors.error.withValues(alpha: 0.05),
                        child: Text(
                          leaveRequest.rejectionReason!,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.error,
                            height: 1.7,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static String _formatDateTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day}/${date.month}/${date.year} - $hour:$minute';
  }
}

class _LeaveHero extends StatelessWidget {
  final LeaveRequestModel leaveRequest;

  const _LeaveHero({required this.leaveRequest});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 76, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0B1734),
            const Color(0xFF12306A),
            leaveRequest.statusColor.withValues(alpha: 0.88),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  leaveRequest.typeIcon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  leaveRequest.typeText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroChip(
                icon: Icons.flag_rounded,
                label: leaveRequest.statusText,
              ),
              _HeroChip(
                icon: Icons.timelapse_rounded,
                label: '${leaveRequest.numberOfDays} يوم',
              ),
              _HeroChip(
                icon: Icons.date_range_rounded,
                label: leaveRequest.dateRangeText,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Color? backgroundColor;
  final Color? borderColor;

  const _DetailSection({
    required this.title,
    required this.icon,
    required this.child,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor ?? AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final availableWidth = MediaQuery.of(context).size.width - 58;
    final cardWidth = availableWidth > 360 ? availableWidth / 2 : availableWidth;

    return SizedBox(
      width: cardWidth,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(height: 10),
            Text(
              label,
              style: AppTextStyles.labelMedium,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final bool isDone;
  final bool isLast;

  const _TimelineRow({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isDone,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isDone ? color : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: isDone
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 12)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 38,
                color: AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
