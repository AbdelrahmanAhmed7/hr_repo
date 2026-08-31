import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Single gradient card with all stats displayed prominently.
class SAAttendanceStatsStrip extends StatelessWidget {
  final int totalCount;
  final int presentCount;
  final int absentCount;
  final double percentage;

  const SAAttendanceStatsStrip({
    super.key,
    required this.totalCount,
    required this.presentCount,
    required this.absentCount,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: AlignmentDirectional.centerStart,
            end: AlignmentDirectional.centerEnd,
            colors: [
              Color(0xFF1E3A8A),
              Color(0xFF3B6BF5),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _StatBlock(
              label: 'الإجمالي',
              value: '$totalCount',
              color: Colors.white,
            ),
            const _Divider(),
            _StatBlock(
              label: 'حاضر',
              value: '$presentCount',
              color: const Color(0xFF6EE7B7),
            ),
            const _Divider(),
            _StatBlock(
              label: 'غائب',
              value: '$absentCount',
              color: const Color(0xFFFCA5A5),
            ),
            const _Divider(),
            _StatBlock(
              label: 'نسبة',
              value: '${percentage.toStringAsFixed(0)}%',
              color: const Color(0xFFBFDBFE),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBlock({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.2,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color.withValues(alpha: 0.85),
              height: 1.3,
            ),
            overflow: TextOverflow.ellipsis,
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
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.white.withValues(alpha: 0.2),
    );
  }
}
