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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'اختر التواريخ',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Start Date
          _buildDateField(
            context,
            label: widget.isSingleDay ? 'تاريخ الإجازة' : 'تاريخ البداية',
            date: widget.startDate,
            onTap: () => _selectDate(context, widget.startDate, widget.onStartDateSelected),
          ),

          if (!widget.isSingleDay) ...[
            const SizedBox(height: 16),

            // End Date
            _buildDateField(
              context,
              label: 'تاريخ النهاية',
              date: widget.endDate,
              onTap: () =>
                  _selectDate(context, widget.endDate ?? widget.startDate, widget.onEndDateSelected),
            ),
          ],

          if (widget.startDate != null && (widget.isSingleDay || widget.endDate != null)) ...[
            const SizedBox(height: 24),
            // Days Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.primary.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  // Total Days
                  _buildSummaryRow(
                    context,
                    icon: Icons.calendar_month,
                    label: 'إجمالي الأيام',
                    value: widget.isSingleDay ? '1 يوم' : '$totalDays يوم',
                    color: AppColors.textSecondary,
                  ),
                  if (!widget.isSingleDay) ...[
                    const Divider(height: 16),
                    // Working Days
                    _buildSummaryRow(
                      context,
                      icon: Icons.work_history_outlined,
                      label: 'أيام العمل الفعلي',
                      value: _isCalculating ? 'جاري الحساب...' : '$_workingDays يوم',
                      color: AppColors.primary,
                    ),
                  ],
                  // Remaining Balance (if available)
                  if (widget.currentLeaveBalance != null && !_isCalculating) ...[
                    const Divider(height: 16),
                    _buildRemainingBalanceRow(context, _workingDays),
                  ],
                ],
              ),
            ),
            // Warning if balance is insufficient
            if (widget.currentLeaveBalance != null && !_isCalculating && _workingDays > widget.currentLeaveBalance!) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'رصيدك الحالي غير كافٍ لهذه الإجازة',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
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
        final holidayName = snapshot.data?['holidayName'] as String?;

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
                padding: const EdgeInsets.all(16),
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
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDate(date),
                            style: TextStyle(
                              color: date != null
                                  ? AppColors.textPrimary
                                  : AppColors.textTertiary,
                              fontSize: 16,
                            ),
                          ),
                          if (holidayName != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              holidayName,
                              style: TextStyle(
                                color: AppColors.warning,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ] else if (isWeeklyOff) ...[
                            const SizedBox(height: 4),
                            Text(
                              date.weekday == DateTime.friday
                                  ? 'إجازة أسبوعية - الجمعة'
                                  : 'إجازة أسبوعية - السبت',
                              style: TextStyle(
                                color: AppColors.warning,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
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

  Widget _buildSummaryRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isBold = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildRemainingBalanceRow(BuildContext context, int workingDays) {
    final remainingBalance = widget.currentLeaveBalance! - workingDays;
    final isNegative = remainingBalance < 0;
    final color = isNegative ? AppColors.error : AppColors.success;

    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.account_balance_wallet, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'الرصيد المتبقي',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$remainingBalance يوم',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'الرصيد الحالي: ${widget.currentLeaveBalance}',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                ' - ',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                ),
              ),
              Text(
                'أيام الإجازة: $workingDays',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}