import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../models/leave_statistics.dart';

class LeavesHeader extends StatelessWidget {
  final LeaveStatistics statistics;

  const LeavesHeader({super.key, required this.statistics});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F1F46), Color(0xFF173C7A), Color(0xFF2354A5)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.16),
                      ),
                    ),
                    child: const Icon(
                      Icons.beach_access_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'الإجازات',
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _HeaderStat(
                    icon: Icons.beach_access_outlined,
                    color: const Color(0xFF7CE0A0),
                    value: '${statistics.remainingLeaves}',
                    unit: 'يوم',
                    label: 'الرصيد',
                  ),
                  const SizedBox(width: 8),
                  _HeaderStat(
                    icon: Icons.check_circle_outline_rounded,
                    color: const Color(0xFFFBBF24),
                    value: '${statistics.usedLeaves}',
                    unit: 'يوم',
                    label: 'المستخدم',
                  ),
                  const SizedBox(width: 8),
                  _HeaderStat(
                    icon: Icons.calendar_month_outlined,
                    color: const Color(0xFF93C5FD),
                    value: '${statistics.totalLeaves}',
                    unit: 'يوم',
                    label: 'الإجمالي',
                  ),
                  const SizedBox(width: 8),
                  _HeaderStat(
                    icon: Icons.pending_actions_outlined,
                    color: const Color(0xFFFCA5A5),
                    value: '${statistics.pendingRequests}',
                    unit: 'طلب',
                    label: 'معلقة',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String unit;
  final String label;

  const _HeaderStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.unit,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 13),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: Colors.white.withValues(alpha: 0.72),
              ),
            ),
          ],
        ),
      ),
    );
  }
}