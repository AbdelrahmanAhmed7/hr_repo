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

  const SAAttendanceDateNavigator({
    super.key,
    required this.selectedDate,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
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
      child: Row(
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
    );
  }
}
