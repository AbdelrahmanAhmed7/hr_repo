import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/daily_attendance_record.dart';
import '../utils/attendance_formatters.dart';

class AttendanceRecordsTable extends StatelessWidget {
  final List<DailyAttendanceRecord> records;

  const AttendanceRecordsTable({
    super.key,
    required this.records,
  });

  String _deductionText(double fraction) {
    if (fraction == 0) return '-';
    if (fraction == 0.25) return 'ربع يوم';
    if (fraction == 0.5) return 'نصف يوم';
    return 'يوم كامل';
  }

  String _fmtNum(double? n) {
    if (n == null || n == 0) return '-';
    return formatWorkHours(n, short: true);
  }

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.event_note_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'لا توجد سجلات لهذه الفلترة',
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'جرّب تغيير الحالة أو الفترة لعرض سجلات الحضور المناسبة.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final rows = records.map((r) {
      return DataRow(
        cells: [
          DataCell(Text(formatDate(r.date))),
          DataCell(Text(getArDayName(r.date.weekday))),
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: r.statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: r.statusColor.withValues(alpha: 0.20)),
              ),
              child: Text(
                r.statusText,
                style: TextStyle(
                  fontSize: 11,
                  color: r.statusColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          DataCell(Text(formatTime(r.checkInTime))),
          DataCell(Text(formatTime(r.checkOutTime))),
          DataCell(Text(_fmtNum(r.regularHours))),
          DataCell(Text(_fmtNum(r.overtimeHours))),
          DataCell(Text(_deductionText(r.deductionFraction))),
        ],
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'الجدول التفصيلي',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${records.length} يوم',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 42,
              dataRowMinHeight: 44,
              dataRowMaxHeight: 60,
              columnSpacing: 18,
              columns: const [
                DataColumn(label: Text('التاريخ')),
                DataColumn(label: Text('اليوم')),
                DataColumn(label: Text('الحالة')),
                DataColumn(label: Text('دخول')),
                DataColumn(label: Text('خروج')),
                DataColumn(label: Text('ساعات')),
                DataColumn(label: Text('إضافي')),
                DataColumn(label: Text('خصم')),
              ],
              rows: rows,
            ),
          ),
        ],
      ),
    );
  }
}
