import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/egyptian_holidays.dart';
import '../../../core/utils/date_utils.dart';

class LeaveDateRangePicker extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime) onStartDateSelected;
  final Function(DateTime) onEndDateSelected;
  final int? currentLeaveBalance; // الرصيد الحالي
  final bool isSingleDay; // إضافة خاصية لليوم الواحد

  const LeaveDateRangePicker({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onStartDateSelected,
    required this.onEndDateSelected,
    this.currentLeaveBalance,
    this.isSingleDay = false,
  });

  @override
  State<LeaveDateRangePicker> createState() => _LeaveDateRangePickerState();
}

class _LeaveDateRangePickerState extends State<LeaveDateRangePicker> {
  int _workingDays = 0;
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    _calculateWorkingDaysAsync();
  }

  @override
  void didUpdateWidget(LeaveDateRangePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startDate != widget.startDate || oldWidget.endDate != widget.endDate) {
      _calculateWorkingDaysAsync();
    }
  }

  Future<void> _calculateWorkingDaysAsync() async {
    if (widget.startDate == null || widget.endDate == null) {
      setState(() {
        _workingDays = 0;
        _isCalculating = false;
      });
      return;
    }

    setState(() => _isCalculating = true);

    int workingDays = 0;
    DateTime current = widget.startDate!;

    while (current.isBefore(widget.endDate!) || current.isAtSameMomentAs(widget.endDate!)) {
      if (!AppDateUtils.isWeeklyOff(current) &&
          !(await EgyptianHolidays.isHoliday(current))) {
        workingDays++;
      }
      current = current.add(const Duration(days: 1));
    }

    if (mounted) {
      setState(() {
        _workingDays = workingDays;
        _isCalculating = false;
      });
    }
  }

  Future<void> _selectDate(
    BuildContext context,
    DateTime? initialDate,
    Function(DateTime) onSelected,
  ) async {
    FocusScope.of(context).unfocus();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ar'),
      builder: AppTheme.getDatePickerThemeBuilder(),
    );

    if (picked != null) {
      // Check if selected date is a holiday or weekly off
      final isHoliday = await EgyptianHolidays.isHoliday(picked);
      final isWeeklyOff = AppDateUtils.isWeeklyOff(picked);

      if (isHoliday || isWeeklyOff) {
        final holidayName = await EgyptianHolidays.getHolidayName(picked);
        final dayName = isWeeklyOff
            ? (picked.weekday == DateTime.friday ? 'الجمعة' : 'السبت')
            : null;

        final message = holidayName != null
            ? 'هذا اليوم إجازة رسمية: $holidayName'
            : 'هذا اليوم إجازة أسبوعية: $dayName';

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }

      onSelected(picked);
    }

    await Future.delayed(const Duration(milliseconds: 100));
    if (context.mounted) {
      FocusScope.of(context).unfocus();
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'اختر التاريخ';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final totalDays = widget.startDate != null && widget.endDate != null
        ? widget.endDate!.difference(widget.startDate!).inDays + 1
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildDateField(
                context,
                label: widget.isSingleDay ? 'تاريخ الإجازة' : 'من',
                date: widget.startDate,
                onTap: () =>
                    _selectDate(context, widget.startDate, widget.onStartDateSelected),
              ),
            ),
            if (!widget.isSingleDay) ...[
              const SizedBox(width: 10),
              Expanded(
                child: _buildDateField(
                  context,
                  label: 'إلى',
                  date: widget.endDate,
                  onTap: () => _selectDate(
                    context,
                    widget.endDate ?? widget.startDate,
                    widget.onEndDateSelected,
                  ),
                ),
              ),
            ],
          ],
        ),

        if (widget.startDate != null && (widget.isSingleDay || widget.endDate != null)) ...[
          const SizedBox(height: 10),
          _buildSummaryRow(context, totalDays),
          if (widget.currentLeaveBalance != null &&
              !_isCalculating &&
              _workingDays > widget.currentLeaveBalance!) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.error,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'رصيدك الحالي غير كافٍ لهذه الإجازة',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildSummaryRow(BuildContext context, int totalDays) {
    final isOverBalance = widget.currentLeaveBalance != null &&
        !_isCalculating &&
        _workingDays > widget.currentLeaveBalance!;

    final summaryParts = <String>[
      widget.isSingleDay ? 'يوم واحد' : '$totalDays أيام',
      if (!widget.isSingleDay)
        _isCalculating ? 'جاري الحساب...' : '$_workingDays يوم عمل',
      if (widget.currentLeaveBalance != null && !_isCalculating)
        'الرصيد بعد: ${widget.currentLeaveBalance! - _workingDays} يوم',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isOverBalance
            ? AppColors.error.withValues(alpha: 0.08)
            : AppColors.primaryTint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isOverBalance ? Icons.warning_amber_rounded : Icons.calendar_month,
            size: 16,
            color: isOverBalance ? AppColors.error : AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              summaryParts.join(' · '),
              style: TextStyle(
                color: isOverBalance ? AppColors.error : AppColors.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(
    BuildContext context, {
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return FutureBuilder<Map<String, dynamic>>(
      future: date != null ? _getDateInfo(date) : Future.value({}),
      builder: (context, snapshot) {
        final isHoliday = snapshot.data?['isHoliday'] ?? false;
        final isWeeklyOff = date != null && AppDateUtils.isWeeklyOff(date);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (isHoliday || isWeeklyOff)
                        ? AppColors.warning
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      color: AppColors.textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatDate(date),
                        style: TextStyle(
                          color: date != null
                              ? AppColors.textPrimary
                              : AppColors.textTertiary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getDateInfo(DateTime date) async {
    final isHoliday = await EgyptianHolidays.isHoliday(date);
    final holidayName = isHoliday ? await EgyptianHolidays.getHolidayName(date) : null;
    return {
      'isHoliday': isHoliday,
      'holidayName': holidayName,
    };
  }
}