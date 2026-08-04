import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_picker_helper.dart';
import '../../core/utils/time_picker_helper.dart';

/// Widget for selecting date and time range (start and end)
class DateTimeRangePicker extends StatelessWidget {
  final DateTime? selectedDate;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final ValueChanged<DateTime?> onDateSelected;
  final ValueChanged<TimeOfDay?> onStartTimeSelected;
  final ValueChanged<TimeOfDay?> onEndTimeSelected;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? dateLabel;
  final String? startTimeLabel;
  final String? endTimeLabel;

  const DateTimeRangePicker({
    super.key,
    required this.selectedDate,
    required this.startTime,
    required this.endTime,
    required this.onDateSelected,
    required this.onStartTimeSelected,
    required this.onEndTimeSelected,
    this.firstDate,
    this.lastDate,
    this.dateLabel,
    this.startTimeLabel,
    this.endTimeLabel,
  });

  Future<void> _selectDate(BuildContext context) async {
    final picked = await DatePickerHelper.showDatePickerDialog(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime.now(),
      lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final picked = await TimePickerHelper.showStartTimePicker(
      context,
      initialTime: startTime,
    );
    if (picked != null) {
      onStartTimeSelected(picked);
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    if (startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اختر وقت البداية أولاً'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final picked = await TimePickerHelper.showEndTimePicker(
      context: context,
      startTime: startTime!,
      initialTime: endTime,
      onValidationError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.error,
          ),
        );
      },
    );
    if (picked != null) {
      onEndTimeSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Date Picker
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateLabel ?? 'التاريخ',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        selectedDate != null
                            ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                            : 'اختر التاريخ',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: selectedDate != null
                                  ? AppColors.textPrimary
                                  : AppColors.textTertiary,
                              fontSize: 16,
                            ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: AppColors.textSecondary, size: 24),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Start Time Picker
        GestureDetector(
          onTap: () => _selectStartTime(context),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_outlined,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        startTimeLabel ?? 'وقت البداية',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        startTime != null
                            ? TimePickerHelper.formatTime(startTime!)
                            : 'اختر وقت البداية',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: startTime != null
                                  ? AppColors.textPrimary
                                  : AppColors.textTertiary,
                              fontSize: 16,
                            ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: AppColors.textSecondary, size: 24),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // End Time Picker
        GestureDetector(
          onTap: () => _selectEndTime(context),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_filled_outlined,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        endTimeLabel ?? 'وقت النهاية',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        endTime != null
                            ? TimePickerHelper.formatTime(endTime!)
                            : 'اختر وقت النهاية',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: endTime != null
                                  ? AppColors.textPrimary
                                  : AppColors.textTertiary,
                              fontSize: 16,
                            ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: AppColors.textSecondary, size: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

