import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/daily_attendance_record.dart';
import '../utils/attendance_formatters.dart';

class DailyAttendanceRecordCard extends StatelessWidget {
  final DailyAttendanceRecord record;
  final VoidCallback? onTap;

  const DailyAttendanceRecordCard({
    super.key,
    required this.record,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateText = '${record.date.day}/${record.date.month}/${record.date.year}';
    final dayName = getArDayName(record.date.weekday);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: record.statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _statusIcon(record.status),
                  color: record.statusColor,
                  size: 22,
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dayName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateText,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (record.checkInTime != null ||
                        record.checkOutTime != null ||
                        record.workHours != null ||
                        record.deductionFraction > 0 ||
                        record.overtimeHours > 0) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (record.checkInTime != null)
                            _InfoChip(
                              icon: Icons.login_rounded,
                              label: formatTime(record.checkInTime),
                            ),
                          if (record.checkOutTime != null)
                            _InfoChip(
                              icon: Icons.logout_rounded,
                              label: formatTime(record.checkOutTime),
                            ),
                          if (record.workHours != null)
                            _InfoChip(
                              icon: Icons.access_time_rounded,
                              label: formatWorkHours(record.regularHours, short: true),
                            ),
                          if (record.overtimeHours > 0)
                            _InfoChip(
                              icon: Icons.more_time_rounded,
                              label: 'إضافي: ${formatWorkHours(record.overtimeHours, short: true)}',
                              foreground: AppColors.warning,
                              background: AppColors.warning.withValues(alpha: 0.10),
                            ),
                          if (record.deductionFraction > 0)
                            _InfoChip(
                              icon: Icons.money_off_csred_rounded,
                              label: record.deductionFraction == 0.25
                                  ? 'خصم ربع يوم'
                                  : (record.deductionFraction == 0.5
                                      ? 'خصم نصف يوم'
                                      : 'خصم يوم كامل'),
                              foreground: AppColors.error,
                              background: AppColors.error.withValues(alpha: 0.10),
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

  IconData _statusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check_circle_rounded;
      case AttendanceStatus.absent:
        return Icons.cancel_rounded;
      case AttendanceStatus.leave:
        return Icons.calendar_month_rounded;
      case AttendanceStatus.late:
        return Icons.schedule_rounded;
      case AttendanceStatus.halfDay:
        return Icons.access_time_rounded;
      case AttendanceStatus.weeklyOff:
        return Icons.weekend_rounded;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color foreground;
  final Color? background;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.foreground = AppColors.textSecondary,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final bg = background ?? AppColors.backgroundSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
