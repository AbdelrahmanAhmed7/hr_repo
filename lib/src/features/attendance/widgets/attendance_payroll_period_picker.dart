import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/payroll_period.dart';
import '../utils/attendance_formatters.dart';

class AttendancePayrollPeriodPicker extends StatelessWidget {
  final List<PayrollPeriod> periods;
  final PayrollPeriod selected;
  final ValueChanged<PayrollPeriod> onChanged;

  const AttendancePayrollPeriodPicker({
    super.key,
    required this.periods,
    required this.selected,
    required this.onChanged,
  });

  String _formatPayrollLabel(PayrollPeriod p) {
    final monthName = kArMonths[p.end.month - 1];
    return '$monthName ${p.end.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.filter_alt_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<PayrollPeriod>(
                isExpanded: true,
                value: selected,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary),
                items: periods.map((p) {
                  return DropdownMenuItem<PayrollPeriod>(
                    value: p,
                    child: Text(
                      _formatPayrollLabel(p),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  onChanged(value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
