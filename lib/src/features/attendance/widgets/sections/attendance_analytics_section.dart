import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../attendance_screen_controller.dart';
import '../../models/attendance_list_response.dart';
import 'attendance_daily_overview_section.dart';

class AttendanceMonthlyAnalyticsSection extends StatelessWidget {
  final AttendanceListResponse data;

  const AttendanceMonthlyAnalyticsSection({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final completeDays = data.attendances.where((a) => a.isComplete).length;
    final checkedInDays = data.attendances.where((a) => a.hasCheckedIn).length;
    final completionRate =
        checkedInDays == 0 ? 0 : (completeDays / checkedInDays * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'لوحة الشهر',
            style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'ملخص سريع لفترة الشهر الحالية ونسبة اكتمال الأيام.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AttendanceFactCard(
                  title: 'أيام بها حضور',
                  value: '$checkedInDays',
                  color: AppColors.primary,
                  icon: Icons.calendar_month_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AttendanceFactCard(
                  title: 'أيام مكتملة',
                  value: '$completeDays',
                  color: AppColors.success,
                  icon: Icons.check_circle_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AttendanceFactCard(
                  title: 'نسبة الاكتمال',
                  value: '$completionRate%',
                  color: AppColors.warning,
                  icon: Icons.donut_large_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AttendanceMonthlyRecordsDeskSection extends StatelessWidget {
  final AttendanceListResponse data;

  const AttendanceMonthlyRecordsDeskSection({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...data.attendances]..sort((a, b) => b.date.compareTo(a.date));
    final visible = sorted.take(8).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
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
                      'جدول الفترة',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'آخر السجلات في الشهر الحالي مع أوقات الدخول والخروج.',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${visible.length} صفوف',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(1.6),
                1: FlexColumnWidth(1.2),
                2: FlexColumnWidth(1.2),
                3: FlexColumnWidth(1.2),
              },
              children: [
                _tableHeader(),
                ...visible.map((item) => _buildRow(item)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TableRow _tableHeader() {
    return const TableRow(
      decoration: BoxDecoration(color: Color(0xFFF8FAFC)),
      children: [
        _HeaderCell(label: 'اليوم'),
        _HeaderCell(label: 'الدخول'),
        _HeaderCell(label: 'الخروج'),
        _HeaderCell(label: 'الحالة'),
      ],
    );
  }

  TableRow _buildRow(AttendanceItem item) {
    final isComplete = item.isComplete;
    final statusLabel =
        !item.hasCheckedIn ? 'لا يوجد' : (isComplete ? 'مكتمل' : 'غير مكتمل');
    final statusColor = !item.hasCheckedIn
        ? AppColors.textTertiary
        : isComplete
            ? AppColors.success
            : AppColors.warning;

    return TableRow(
      decoration: const BoxDecoration(color: Colors.white),
      children: [
        _BodyCell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatApiDate(item.date),
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(item.dayOfWeek ?? '--', style: AppTextStyles.labelSmall),
            ],
          ),
        ),
        _BodyCell(child: Text(item.attendanceTime ?? '--:--')),
        _BodyCell(child: Text(item.departureTime ?? '--:--')),
        _BodyCell(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              statusLabel,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSmall.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatApiDate(String value) {
    try {
      final date = DateTime.parse(value);
      return '${date.day}/${date.month}';
    } catch (_) {
      return value;
    }
  }
}

class AttendanceRangeSection extends StatelessWidget {
  final AttendanceListResponse data;
  final VoidCallback onOpenHistory;

  const AttendanceRangeSection({
    super.key,
    required this.data,
    required this.onOpenHistory,
  });

  @override
  Widget build(BuildContext context) {
    final records = mapAttendanceItems(data.attendances);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.date_range_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'عرض مدة زمنية',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'شاهد الحضور على مستوى أسبوع أو شهر كامل بدل يوم واحد فقط.',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: records.isEmpty ? null : onOpenHistory,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('عرض الكل'),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;

  const _HeaderCell({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  final Widget child;

  const _BodyCell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: child,
    );
  }
}

