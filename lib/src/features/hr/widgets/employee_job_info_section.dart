import 'package:flutter/material.dart';
import 'dart:collection';
import '../../../core/theme/app_colors.dart';
import '../../../shared/components/custom_text_field.dart';
import '../../../shared/widgets/date_picker_field.dart';
import '../../attendance/utils/attendance_formatters.dart';

/// Job information section for employee forms
class EmployeeJobInfoSection extends StatelessWidget {
  final String? selectedDepartment;
  final List<String> departments;
  final ValueChanged<String?> onDepartmentChanged;
  final TextEditingController positionController;
  final DateTime? hireDate;
  final VoidCallback onHireDateSelected;
  final bool isReadOnly;

  const EmployeeJobInfoSection({
    super.key,
    required this.selectedDepartment,
    required this.departments,
    required this.onDepartmentChanged,
    required this.positionController,
    required this.hireDate,
    required this.onHireDateSelected,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final uniqueDepartments = LinkedHashSet<String>.from(
      departments.map((department) => department.trim()).where((name) => name.isNotEmpty),
    ).toList();
    final dropdownValue = uniqueDepartments.contains(selectedDepartment)
        ? selectedDepartment
        : null;

    return Column(
      children: [
        // Department Dropdown
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'القسم',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: dropdownValue,
              isExpanded: true,
              decoration: InputDecoration(
                hintText: 'اختر القسم',
                prefixIcon: Icon(
                  Icons.business_outlined,
                  color: isReadOnly ? AppColors.textSecondary : AppColors.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                filled: true,
                fillColor: isReadOnly
                    ? AppColors.backgroundSecondary.withValues(alpha: 0.5)
                    : AppColors.backgroundSecondary,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text(
                    'اختر القسم',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
                ...uniqueDepartments.map((dept) {
                  return DropdownMenuItem<String?>(
                    value: dept,
                    child: Text(
                      dept,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  );
                }),
              ],
              onChanged: isReadOnly ? null : onDepartmentChanged,
            ),
          ],
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'المنصب',
          placeholder: 'أدخل المنصب',
          prefixIcon: Icons.work_outline,
          controller: positionController,
          textInputAction: TextInputAction.next,
          nextFocusNode: FocusNode(),
          readOnly: isReadOnly,
        ),
        const SizedBox(height: 16),
        DatePickerField(
          label: 'تاريخ التعيين',
          value: hireDate != null ? formatDate(hireDate!) : null,
          onTap: onHireDateSelected,
          icon: Icons.calendar_today_outlined,
          enabled: !isReadOnly,
        ),
      ],
    );
  }
}

