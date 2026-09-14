import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class SAAttendanceStatsStrip extends StatelessWidget {
  final int totalCount;
  final int presentCount;
  final int absentCount;
  final int departedCount;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final List<DailyBreakdown>? dailyBreakdown;

  const SAAttendanceStatsStrip({
    super.key,
    required this.totalCount,
    required this.presentCount,
    required this.absentCount,
    required this.departedCount,
    this.rangeStart,
    this.rangeEnd,
    this.dailyBreakdown,
  });

  bool get isRange => rangeStart != null && rangeEnd != null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: AlignmentDirectional.centerStart,
                end: AlignmentDirectional.centerEnd,
                colors: [Color(0xFF1E3A8A), Color(0xFF3B6BF5)],
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
            child: Column(
              children: [
                if (isRange)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.date_range_rounded, size: 14, color: Colors.white.withValues(alpha: 0.7)),
                        const SizedBox(width: 6),
                        Text(
                          '${rangeStart!.day}/${rangeStart!.month}/${rangeStart!.year} — ${rangeEnd!.day}/${rangeEnd!.month}/${rangeEnd!.year}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    _StatBlock(label: 'الإجمالي', value: '$totalCount', color: Colors.white),
                    const _Divider(),
                    _StatBlock(label: 'حاضر', value: '$presentCount', color: const Color(0xFF6EE7B7)),
                    const _Divider(),
                    _StatBlock(label: 'منصرف', value: '$departedCount', color: const Color(0xFFBFDBFE)),
                    const _Divider(),
                    _StatBlock(label: 'غائب', value: '$absentCount', color: const Color(0xFFFCA5A5)),
                  ],
                ),
              ],
            ),
          ),
          if (isRange && dailyBreakdown != null && dailyBreakdown!.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: dailyBreakdown!.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final day = dailyBreakdown![index];
                  return _DaySummaryCard(day: day);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class DailyBreakdown {
  final DateTime date;
  final int present;
  final int absent;
  final int departed;

  const DailyBreakdown({
    required this.date,
    required this.present,
    required this.absent,
    required this.departed,
  });
}

class _DaySummaryCard extends StatelessWidget {
  final DailyBreakdown day;

  const _DaySummaryCard({required this.day});

  @override
  Widget build(BuildContext context) {
    final dayLabel = DateFormat('EEE d', 'ar').format(day.date);

    return Container(
      width: 88,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            dayLabel,
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(color: AppColors.success, count: day.present),
                const SizedBox(width: 3),
                _Dot(color: AppColors.error, count: day.absent),
                const SizedBox(width: 3),
                _Dot(color: AppColors.primary.withValues(alpha: 0.5), count: day.departed),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final int count;

  const _Dot({required this.color, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 2),
        Text(
          '$count',
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBlock({required this.label, required this.value, required this.color});

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
