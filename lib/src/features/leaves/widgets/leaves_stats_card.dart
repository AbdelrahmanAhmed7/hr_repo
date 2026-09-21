import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/leave_statistics.dart';

/// Compact white summary strip (replaces the legacy gradient hero).
class LeavesStatsCard extends StatelessWidget {
  final LeaveStatistics statistics;

  const LeavesStatsCard({super.key, required this.statistics});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatCell(
              value: '${statistics.remainingLeaves}',
              unit: 'يوم',
              label: 'الرصيد',
              color: AppColors.success,
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _StatCell(
              value: '${statistics.usedLeaves}',
              unit: 'يوم',
              label: 'المستخدم',
              color: AppColors.warning,
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _StatCell(
              value: '${statistics.totalLeaves}',
              unit: 'يوم',
              label: 'الإجمالي',
              color: AppColors.primary,
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _StatCell(
              value: '${statistics.pendingRequests}',
              unit: 'طلب',
              label: 'معلقة',
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 26, color: AppColors.border);
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String unit;
  final String label;
  final Color color;

  const _StatCell({
    required this.value,
    required this.unit,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              unit,
              style: TextStyle(
                color: color.withValues(alpha: 0.65),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}