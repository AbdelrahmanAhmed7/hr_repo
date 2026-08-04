import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/daily_attendance_record.dart';
import '../utils/attendance_formatters.dart';
import 'attendance_mini_pill.dart';
import 'attendance_summary_tile.dart';

class AttendanceRecordsSummaryCard extends StatelessWidget {
  final String rangeText;
  final List<DailyAttendanceRecord> records;

  const AttendanceRecordsSummaryCard({
    super.key,
    required this.rangeText,
    required this.records,
  });

  ({
    int present,
    int absent,
    int leave,
    int weeklyOff,
    double regular,
    double overtime,
    int quarter,
    int half,
    int full,
  }) _aggregate(List<DailyAttendanceRecord> records) {
    int present = 0, absent = 0, leave = 0, weeklyOff = 0;
    double regular = 0, overtime = 0;
    int quarter = 0, half = 0, full = 0;

    for (final r in records) {
      switch (r.status) {
        case AttendanceStatus.present:
          present++;
          break;
        case AttendanceStatus.absent:
          absent++;
          break;
        case AttendanceStatus.leave:
          leave++;
          break;
        case AttendanceStatus.weeklyOff:
          weeklyOff++;
          break;
        case AttendanceStatus.late:
          present++;
          break;
        case AttendanceStatus.halfDay:
          present++;
          break;
      }

      if (r.workHours != null) {
        regular += r.regularHours;
        overtime += r.overtimeHours;
      }

      if (r.deductionFraction == 0.25) quarter++;
      if (r.deductionFraction == 0.5) half++;
      if (r.deductionFraction == 1.0) full++;
    }

    return (
      present: present,
      absent: absent,
      leave: leave,
      weeklyOff: weeklyOff,
      regular: regular,
      overtime: overtime,
      quarter: quarter,
      half: half,
      full: full,
    );
  }

  Widget _miniPill({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return AttendanceMiniPill(
      icon: icon,
      label: label,
      value: value,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = _aggregate(records);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الملخص',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rangeText,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${records.length} سجل',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AttendanceSummaryTile(
                  title: 'حضور',
                  value: '${a.present}',
                  icon: Icons.event_available_rounded,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AttendanceSummaryTile(
                  title: 'غياب',
                  value: '${a.absent}',
                  icon: Icons.event_busy_rounded,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AttendanceSummaryTile(
                  title: 'إجازة',
                  value: '${a.leave}',
                  icon: Icons.calendar_month_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AttendanceSummaryTile(
                  title: 'راحة أسبوعية',
                  value: '${a.weeklyOff}',
                  icon: Icons.weekend_rounded,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _miniPill(
                  icon: Icons.access_time_rounded,
                  label: 'ساعات',
                  value: formatWorkHours(a.regular, short: true),
                  color: AppColors.primaryDark,
                ),
                if (a.overtime > 0)
                  _miniPill(
                    icon: Icons.more_time_rounded,
                    label: 'إضافي',
                    value: formatWorkHours(a.overtime, short: true),
                    color: AppColors.warning,
                  ),
                if (a.quarter > 0)
                  _miniPill(
                    icon: Icons.money_off_csred_rounded,
                    label: 'خصم ربع',
                    value: '${a.quarter}',
                    color: AppColors.error,
                  ),
                if (a.half > 0)
                  _miniPill(
                    icon: Icons.money_off_csred_rounded,
                    label: 'خصم نصف',
                    value: '${a.half}',
                    color: AppColors.error,
                  ),
                if (a.full > 0)
                  _miniPill(
                    icon: Icons.money_off_csred_rounded,
                    label: 'خصم يوم',
                    value: '${a.full}',
                    color: AppColors.error,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
