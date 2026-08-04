import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../attendance_screen_controller.dart';
import '../../models/attendance_list_response.dart';
import '../../utils/attendance_formatters.dart';
import 'attendance_daily_overview_section.dart';
import 'attendance_scope_switcher.dart';

class AttendancePeriodSnapshotSection extends StatelessWidget {
  final AttendanceListResponse data;
  final DateTime selectedDate;
  final AttendancePeriodScope scope;

  const AttendancePeriodSnapshotSection({
    super.key,
    required this.data,
    required this.selectedDate,
    required this.scope,
  });

  @override
  Widget build(BuildContext context) {
    final items = _filterItems(data.attendances, selectedDate, scope);
    final checkedInDays = items.where((item) => item.hasCheckedIn).length;
    final completeDays = items.where((item) => item.isComplete).length;
    final pendingCheckout =
        items.where((item) => item.hasCheckedIn && !item.isComplete).length;
    final averageHours = _calculateAverageHours(items);

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
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.date_range_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titleForScope(scope),
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _rangeText(selectedDate, scope),
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AttendanceFactCard(
                  title: 'أيام حضور',
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
                  title: 'خروج ناقص',
                  value: '$pendingCheckout',
                  color: AppColors.warning,
                  icon: Icons.error_outline_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.timelapse_rounded,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    averageHours == null
                        ? 'لا توجد ساعات كافية لحساب متوسط الفترة المختارة.'
                        : 'متوسط ساعات العمل في الفترة: ${formatWorkHours(averageHours)}',
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<AttendanceItem> _filterItems(
    List<AttendanceItem> items,
    DateTime selectedDate,
    AttendancePeriodScope scope,
  ) {
    final normalizedSelected =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    switch (scope) {
      case AttendancePeriodScope.day:
        return items.where((item) {
          final parsed = DateTime.tryParse(item.date);
          if (parsed == null) return false;
          return parsed.year == normalizedSelected.year &&
              parsed.month == normalizedSelected.month &&
              parsed.day == normalizedSelected.day;
        }).toList();
      case AttendancePeriodScope.week:
        final start = normalizedSelected.subtract(
          Duration(days: normalizedSelected.weekday - DateTime.monday),
        );
        final end = start.add(const Duration(days: 6));
        return items.where((item) {
          final parsed = DateTime.tryParse(item.date);
          if (parsed == null) return false;
          final normalized = DateTime(parsed.year, parsed.month, parsed.day);
          return !normalized.isBefore(start) && !normalized.isAfter(end);
        }).toList();
      case AttendancePeriodScope.month:
        return items.where((item) {
          final parsed = DateTime.tryParse(item.date);
          if (parsed == null) return false;
          return parsed.year == normalizedSelected.year &&
              parsed.month == normalizedSelected.month;
        }).toList();
    }
  }

  double? _calculateAverageHours(List<AttendanceItem> items) {
    final complete = items.where((item) => item.isComplete).toList();
    if (complete.isEmpty) return null;

    var totalHours = 0.0;
    for (final item in complete) {
      final checkIn = combineDateAndTime(item.date, item.attendanceTime);
      final checkOut = combineDateAndTime(item.date, item.departureTime);
      if (checkIn != null && checkOut != null) {
        totalHours += checkOut.difference(checkIn).inMinutes / 60;
      }
    }

    return totalHours == 0 ? null : totalHours / complete.length;
  }

  String _titleForScope(AttendancePeriodScope scope) {
    switch (scope) {
      case AttendancePeriodScope.day:
        return 'ملخص اليوم المحدد';
      case AttendancePeriodScope.week:
        return 'ملخص الأسبوع';
      case AttendancePeriodScope.month:
        return 'ملخص الشهر';
    }
  }

  String _rangeText(DateTime selectedDate, AttendancePeriodScope scope) {
    switch (scope) {
      case AttendancePeriodScope.day:
        return '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';
      case AttendancePeriodScope.week:
        final start = selectedDate.subtract(
          Duration(days: selectedDate.weekday - DateTime.monday),
        );
        final end = start.add(const Duration(days: 6));
        return '${start.day}/${start.month} - ${end.day}/${end.month}';
      case AttendancePeriodScope.month:
        return 'شهر ${selectedDate.month}/${selectedDate.year}';
    }
  }
}
