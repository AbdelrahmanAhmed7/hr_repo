import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/components/custom_button.dart';

/// Action buttons section for employee profile screen
class EmployeeProfileActions extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onSave;
  final VoidCallback? onViewAttendanceReport;

  const EmployeeProfileActions({
    super.key,
    this.isLoading = false,
    this.onSave,
    this.onViewAttendanceReport,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (onSave != null) ...[
          PrimaryButton(
            text: 'حفظ التعديلات',
            isLoading: isLoading,
            onPressed: onSave,
          ),
          if (onViewAttendanceReport != null) const SizedBox(height: 16),
        ],
        if (onViewAttendanceReport != null)
          OutlinedButton.icon(
            onPressed: onViewAttendanceReport,
            icon: const Icon(Icons.calendar_month_outlined),
            label: const Text('تقرير الحضور'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppColors.primary, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
      ],
    );
  }
}

