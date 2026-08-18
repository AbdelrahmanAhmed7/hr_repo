import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class SAAttendanceStatsStrip extends StatelessWidget {
  final int presentCount;
  final int absentCount;
  final double percentage;

  const SAAttendanceStatsStrip({
    super.key,
    required this.presentCount,
    required this.absentCount,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          _StatItem(
            label: 'حاضر',
            value: '$presentCount',
            color: AppColors.success,
          ),
          const _Divider(),
          _StatItem(
            label: 'غائب',
            value: '$absentCount',
            color: AppColors.error,
          ),
          const _Divider(),
          _StatItem(
            label: 'نسبة',
            value: '${percentage.toStringAsFixed(0)}%',
            color: AppColors.info,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      color: AppColors.border,
    );
  }
}
