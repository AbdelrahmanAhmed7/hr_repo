import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/time_picker_helper.dart';

/// Unified time picker field widget
class TimePickerField extends StatelessWidget {
  final String label;
  final TimeOfDay? value;
  final ValueChanged<TimeOfDay?> onTimeSelected;
  final IconData icon;
  final bool show12HourFormat;

  const TimePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onTimeSelected,
    this.icon = Icons.access_time_outlined,
    this.show12HourFormat = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await TimePickerHelper.showTimePickerDialog(
          context: context,
          initialTime: value,
        );
        if (picked != null) {
          onTimeSelected(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value != null
                        ? (show12HourFormat
                            ? TimePickerHelper.formatTime12Hour(value!)
                            : TimePickerHelper.formatTime(value!))
                        : 'اختر الوقت',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: value != null
                              ? AppColors.textPrimary
                              : AppColors.textTertiary,
                          fontSize: 16,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 24),
          ],
        ),
      ),
    );
  }
}

