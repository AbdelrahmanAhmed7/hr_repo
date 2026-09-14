import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class DayCardsSection extends StatelessWidget {
  final DateTime selectedDate;
  final List<DayCardData> days;
  final ValueChanged<DateTime> onDaySelected;

  const DayCardsSection({
    super.key,
    required this.selectedDate,
    required this.days,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: days.length,
        separatorBuilder: (_, a) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = DateUtils.isSameDay(day.date, selectedDate);
          return GestureDetector(
            onTap: () => onDaySelected(day.date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 72,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.border,
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE', 'ar').format(day.date),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.2)
                          : AppColors.primaryTint,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${day.date.day}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? Colors.white : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _MiniDot(
                        color: const Color(0xFF6EE7B7),
                        active: isSelected,
                        count: day.present,
                      ),
                      const SizedBox(width: 3),
                      _MiniDot(
                        color: const Color(0xFFFCA5A5),
                        active: isSelected,
                        count: day.absent,
                      ),
                      const SizedBox(width: 3),
                      _MiniDot(
                        color: const Color(0xFFBFDBFE),
                        active: isSelected,
                        count: day.departed,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MiniDot extends StatelessWidget {
  final Color color;
  final bool active;
  final int count;

  const _MiniDot({
    required this.color,
    required this.active,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: active ? Colors.white.withValues(alpha: 0.8) : color,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

class DayCardData {
  final DateTime date;
  final int present;
  final int absent;
  final int departed;

  const DayCardData({
    required this.date,
    required this.present,
    required this.absent,
    required this.departed,
  });
}
