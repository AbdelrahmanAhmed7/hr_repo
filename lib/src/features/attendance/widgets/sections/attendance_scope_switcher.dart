import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

enum AttendancePeriodScope {
  day,
  week,
  month,
}

class AttendanceScopeSwitcher extends StatelessWidget {
  final AttendancePeriodScope selectedScope;
  final ValueChanged<AttendancePeriodScope> onScopeChanged;

  const AttendanceScopeSwitcher({
    super.key,
    required this.selectedScope,
    required this.onScopeChanged,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      (scope: AttendancePeriodScope.day, label: 'Ø§Ù„ÙŠÙˆÙ…'),
      (scope: AttendancePeriodScope.week, label: 'Ø§Ù„Ø£Ø³Ø¨ÙˆØ¹'),
      (scope: AttendancePeriodScope.month, label: 'Ø§Ù„Ø´Ù‡Ø±'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((item) {
          final isSelected = item.scope == selectedScope;
          return ChoiceChip(
            label: Text(
              item.label,
              style: AppTextStyles.labelLarge.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            selected: isSelected,
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.backgroundSecondary,
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            onSelected: (_) => onScopeChanged(item.scope),
          );
        }).toList(),
      ),
    );
  }
}

