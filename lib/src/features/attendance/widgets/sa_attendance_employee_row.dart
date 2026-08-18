import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/attendance_record_model.dart';

class SAAttendanceEmployeeRow extends StatelessWidget {
  final AttendanceRecordModel record;
  final bool isExpanded;
  final VoidCallback onTap;

  const SAAttendanceEmployeeRow({
    super.key,
    required this.record,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusMedium),
        border: Border.all(
          color: isExpanded
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.border,
          width: isExpanded ? 1.5 : 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.border.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSizing.radiusMedium),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  _buildAvatar(),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _buildInfo()),
                  const SizedBox(width: AppSpacing.sm),
                  _buildStatus(),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textTertiary,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExpandedDetails(context),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final status = record.status;
    Color bgColor;
    Color textColor;

    switch (status) {
      case AttendanceStatus.present:
        bgColor = AppColors.successTint;
        textColor = AppColors.success;
        break;
      case AttendanceStatus.departed:
        bgColor = AppColors.primaryTint;
        textColor = AppColors.info;
        break;
      case AttendanceStatus.absent:
        bgColor = AppColors.errorTint;
        textColor = AppColors.error;
        break;
    }

    final initials = _getInitials(record.employeeName);

    return Container(
      width: AppSizing.avatarMedium,
      height: AppSizing.avatarMedium,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          record.employeeName,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          record.machineCode ?? record.dayOfWeek,
          style: AppTextStyles.labelSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStatus() {
    switch (record.status) {
      case AttendanceStatus.absent:
        return _StatusBadge(
          label: 'غائب',
          color: AppColors.error,
          bgColor: AppColors.errorTint,
        );
      case AttendanceStatus.present:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _deviceIcon(record.deviceType),
              size: 14,
              color: AppColors.success,
            ),
            const SizedBox(width: 4),
            Text(
              _formatTimeShort(record.attendanceTime!),
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            _StatusBadge(
              label: 'حاضر',
              color: AppColors.success,
              bgColor: AppColors.successTint,
            ),
          ],
        );
      case AttendanceStatus.departed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _deviceIcon(record.deviceType),
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              '${_formatTimeShort(record.attendanceTime!)} ← ${_formatTimeShort(record.departureTime!)}',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
    }
  }

  Widget _buildExpandedDetails(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        children: [
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _DetailItem(
                  icon: Icons.login_rounded,
                  label: 'وقت الدخول',
                  value: record.attendanceTime != null
                      ? _formatTimeFull(record.attendanceTime!)
                      : '—',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _DetailItem(
                  icon: Icons.logout_rounded,
                  label: 'وقت الانصراف',
                  value: record.departureTime != null
                      ? _formatTimeFull(record.departureTime!)
                      : 'لم ينصرف بعد',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _DetailItem(
                  icon: _deviceIcon(record.deviceType),
                  label: 'مصدر الحضور',
                  value: _deviceLabel(record.deviceType),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _DetailItem(
                  icon: Icons.access_time_rounded,
                  label: 'مدة العمل',
                  value: _workDuration(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0];
    return '${parts[0][0]}${parts[1][0]}';
  }

  String _formatTimeShort(String time) {
    final cleaned = time.split('.').first;
    final parts = cleaned.split(':');
    if (parts.length < 2) return time;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts[1].padLeft(2, '0');
    final period = hour >= 12 ? 'م' : 'ص';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String _formatTimeFull(String time) {
    final cleaned = time.split('.').first;
    final parts = cleaned.split(':');
    if (parts.length < 2) return time;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts[1].padLeft(2, '0');
    final period = hour >= 12 ? 'م' : 'ص';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String _workDuration() {
    if (record.attendanceTime == null) return '—';
    if (record.departureTime == null) return 'جارية...';

    final attend = _parseTime(record.attendanceTime!);
    final depart = _parseTime(record.departureTime!);
    if (attend == null || depart == null) return '—';

    final diff = depart.difference(attend);
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);

    if (hours == 0 && minutes == 0) return '—';
    return '$hours س $minutes د';
  }

  DateTime? _parseTime(String time) {
    final cleaned = time.split('.').first;
    final parts = cleaned.split(':');
    if (parts.length < 3) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final s = int.tryParse(parts[2]);
    if (h == null || m == null || s == null) return null;
    return DateTime(2026, 1, 1, h, m, s);
  }

  IconData _deviceIcon(int? deviceType) {
    if (deviceType == 2) return Icons.phone_android_rounded;
    if (deviceType == 3) return Icons.fingerprint_rounded;
    return Icons.device_unknown_rounded;
  }

  String _deviceLabel(int? deviceType) {
    if (deviceType == 2) return 'موبايل';
    if (deviceType == 3) return 'بصمة';
    return '—';
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const _StatusBadge({
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizing.radiusRound),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(AppSizing.radiusSmall),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textTertiary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.overline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
