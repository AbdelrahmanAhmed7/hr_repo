import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/department_model.dart';

class DepartmentSelector extends StatelessWidget {
  final List<DepartmentModel> departments;
  final Set<int> selectedIds;
  final ValueChanged<int> onToggle;
  final bool isLoading;

  const DepartmentSelector({
    super.key,
    required this.departments,
    required this.selectedIds,
    required this.onToggle,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (isLoading) {
      content = Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('جاري تحميل الأقسام...'),
          ],
        ),
      );
    } else if (departments.isEmpty) {
      content = Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          'لا توجد أقسام متاحة',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    } else {
      content = Wrap(
        spacing: 8,
        runSpacing: 8,
        children: departments.map((department) {
          final selected = selectedIds.contains(department.id);
          return FilterChip(
            label: Text(department.name),
            labelStyle: AppTextStyles.labelMedium.copyWith(
              color: selected ? AppColors.primary : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            selected: selected,
            onSelected: (_) => onToggle(department.id),
            backgroundColor: Colors.white,
            selectedColor: AppColors.primaryTint,
            checkmarkColor: AppColors.primary,
            side: BorderSide(
              color: selected ? AppColors.primary : AppColors.border,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          );
        }).toList(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الأقسام المستهدفة *',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }
}