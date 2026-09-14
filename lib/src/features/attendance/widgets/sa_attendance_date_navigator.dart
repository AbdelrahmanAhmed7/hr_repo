import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class SAAttendanceDateNavigator extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final ValueChanged<DateTime>? onDatePicked;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final ValueChanged<DateTime?>? onRangeStartChanged;
  final ValueChanged<DateTime?>? onRangeEndChanged;

  const SAAttendanceDateNavigator({
    super.key,
    required this.selectedDate,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    this.onDatePicked,
    this.rangeStart,
    this.rangeEnd,
    this.onRangeStartChanged,
    this.onRangeEndChanged,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = DateUtils.isSameDay(selectedDate, now);
    final isFuture = selectedDate.isAfter(now);
    final arabicFormat = DateFormat('EEEE، d MMMM yyyy', 'ar');

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onPrevious,
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  size: 28,
                ),
                color: AppColors.primary,
              ),
              Expanded(
                child: GestureDetector(
                  onTap: onDatePicked != null
                      ? () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: now,
                            locale: const Locale('ar'),
                          );
                          if (picked != null) {
                            onDatePicked!(picked);
                          }
                        }
                      : null,
                  child: Column(
                    children: [
                      Text(
                        arabicFormat.format(selectedDate),
                        style: AppTextStyles.titleSmall,
                        textAlign: TextAlign.center,
                      ),
                      if (!isToday) ...[
                        const SizedBox(height: 2),
                        GestureDetector(
                          onTap: onToday,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTint,
                              borderRadius:
                                  BorderRadius.circular(AppSizing.radiusRound),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              'اليوم',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: isToday || isFuture ? null : onNext,
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  size: 28,
                ),
                color: isToday || isFuture
                    ? AppColors.textTertiary.withValues(alpha: 0.4)
                    : AppColors.primary,
              ),
            ],
          ),
          if (onRangeStartChanged != null && onRangeEndChanged != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _RangeDatePickerField(
                    label: 'من',
                    value: rangeStart,
                    lastDate: rangeEnd ?? now,
                    onPicked: onRangeStartChanged!,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _RangeDatePickerField(
                    label: 'إلى',
                    value: rangeEnd,
                    firstDate: rangeStart,
                    lastDate: now,
                    onPicked: onRangeEndChanged!,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RangeDatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<DateTime?> onPicked;

  const _RangeDatePickerField({
    required this.label,
    required this.value,
    this.firstDate,
    this.lastDate,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = value != null
        ? '${value!.day}/${value!.month}/${value!.year}'
        : null;

    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: firstDate ?? DateTime(2020),
          lastDate: lastDate ?? DateTime.now(),
          locale: const Locale('ar'),
        );
        onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: value != null
              ? AppColors.primaryTint
              : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: value != null
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 14,
              color: value != null ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                displayText ?? label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: value != null
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontWeight: value != null ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (value != null)
              GestureDetector(
                onTap: () => onPicked(null),
                child: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
