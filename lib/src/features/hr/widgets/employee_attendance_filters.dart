import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../attendance/utils/attendance_formatters.dart';

class EmployeeAttendanceFilters extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime?, DateTime?) onFilterChanged;

  const EmployeeAttendanceFilters({
    super.key,
    this.startDate,
    this.endDate,
    required this.onFilterChanged,
  });

  @override
  State<EmployeeAttendanceFilters> createState() =>
      _EmployeeAttendanceFiltersState();
}

class _EmployeeAttendanceFiltersState
    extends State<EmployeeAttendanceFilters> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate;
    _endDate = widget.endDate;
  }

  @override
  void didUpdateWidget(EmployeeAttendanceFilters oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startDate != oldWidget.startDate ||
        widget.endDate != oldWidget.endDate) {
      _startDate = widget.startDate;
      _endDate = widget.endDate;
    }
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: _endDate ?? DateTime.now(),
      helpText: 'اختر تاريخ البداية',
      cancelText: 'إلغاء',
      confirmText: 'تأكيد',
    );
    if (picked != null) {
      setState(() => _startDate = picked);
      widget.onFilterChanged(_startDate, _endDate);
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'اختر تاريخ النهاية',
      cancelText: 'إلغاء',
      confirmText: 'تأكيد',
    );
    if (picked != null) {
      setState(() => _endDate = picked);
      widget.onFilterChanged(_startDate, _endDate);
    }
  }

  void _applyQuickFilter(String filter) {
    final now = DateTime.now();
    DateTime? start;
    DateTime? end = now;

    switch (filter) {
      case 'today':
        start = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        start = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'month':
        start = DateTime(now.year, now.month, 1);
        break;
      case 'lastMonth':
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        start = lastMonth;
        end = DateTime(now.year, now.month, 0);
        break;
      case 'last30Days':
        start = now.subtract(const Duration(days: 30));
        break;
      case 'last90Days':
        start = now.subtract(const Duration(days: 90));
        break;
    }

    setState(() {
      _startDate = start;
      _endDate = end;
    });
    widget.onFilterChanged(_startDate, _endDate);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'فلترة السجلات',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 16),

          // Date Range Picker
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _selectStartDate,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'من تاريخ',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _startDate != null
                                    ? formatDate(_startDate!)
                                    : 'اختر التاريخ',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _selectEndDate,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'إلى تاريخ',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _endDate != null
                                    ? formatDate(_endDate!)
                                    : 'اختر التاريخ',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Quick Filters
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickFilterButton('اليوم', () => _applyQuickFilter('today')),
              _buildQuickFilterButton('هذا الأسبوع', () => _applyQuickFilter('week')),
              _buildQuickFilterButton('هذا الشهر', () => _applyQuickFilter('month')),
              _buildQuickFilterButton('الشهر الماضي', () => _applyQuickFilter('lastMonth')),
              _buildQuickFilterButton('آخر 30 يوم', () => _applyQuickFilter('last30Days')),
              _buildQuickFilterButton('آخر 90 يوم', () => _applyQuickFilter('last90Days')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterButton(String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12,
        ),
      ),
    );
  }
}

