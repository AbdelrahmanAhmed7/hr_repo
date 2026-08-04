import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/egyptian_holidays.dart';

class UpcomingLeaveSection extends StatelessWidget {
  final Holiday? upcomingHoliday;
  final VoidCallback? onTap;

  const UpcomingLeaveSection({
    super.key,
    this.upcomingHoliday,
    this.onTap,
  });

  int _daysUntilHoliday(DateTime holidayDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final holiday = DateTime(holidayDate.year, holidayDate.month, holidayDate.day);
    return holiday.difference(today).inDays;
  }

  Color _getAlertColor(int daysUntil) {
    if (daysUntil <= 1) return AppColors.error;
    if (daysUntil <= 3) return AppColors.warning;
    return AppColors.primary;
  }

  String _getAlertText(int daysUntil) {
    if (daysUntil == 0) {
      return '\u0625\u062c\u0627\u0632\u062a\u0643 \u062a\u0628\u062f\u0623 \u0627\u0644\u064a\u0648\u0645';
    } else if (daysUntil == 1) {
      return '\u0625\u062c\u0627\u0632\u062a\u0643 \u062a\u0628\u062f\u0623 \u063a\u062f\u064b\u0627';
    } else if (daysUntil <= 3) {
      return '\u062a\u0628\u062f\u0623 \u062e\u0644\u0627\u0644 $daysUntil \u0623\u064a\u0627\u0645';
    } else {
      return '\u0628\u0639\u062f $daysUntil \u064a\u0648\u0645';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (upcomingHoliday == null) {
      return const SizedBox.shrink();
    }

    final holiday = upcomingHoliday!;
    final daysUntil = _daysUntilHoliday(holiday.date);
    final accentColor = _getAlertColor(daysUntil);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            eyebrow: '\u0645\u0648\u0639\u062f \u0642\u0627\u062f\u0645',
            title: '\u0627\u0644\u0625\u062c\u0627\u0632\u0629 \u0627\u0644\u0631\u0633\u0645\u064a\u0629',
            icon: _getHolidayIcon(holiday),
          ),
          const SizedBox(height: 10),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(24),
              child: Ink(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: accentColor.withValues(alpha: 0.24)),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.07),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            _getHolidayIcon(holiday),
                            color: accentColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                holiday.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  _getAlertText(daysUntil),
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: accentColor,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textTertiary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _InfoPill(
                          icon: Icons.calendar_today_rounded,
                          label: '\u0627\u0644\u062a\u0627\u0631\u064a\u062e',
                          value: _formatDate(holiday.date),
                          color: AppColors.primary,
                        ),
                        _InfoPill(
                          icon: Icons.category_rounded,
                          label: '\u0627\u0644\u0646\u0648\u0639',
                          value: holiday.isFixed
                              ? '\u0625\u062c\u0627\u0632\u0629 \u062b\u0627\u0628\u062a\u0629'
                              : '\u0625\u062c\u0627\u0632\u0629 \u062f\u064a\u0646\u064a\u0629',
                          color:
                              holiday.isFixed ? AppColors.primary : AppColors.warning,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  IconData _getHolidayIcon(Holiday holiday) {
    if (holiday.name.contains('\u0639\u064a\u062f \u0627\u0644\u0641\u0637\u0631') ||
        holiday.name.contains('\u0639\u064a\u062f \u0627\u0644\u0623\u0636\u062d\u0649')) {
      return Icons.celebration_rounded;
    }
    if (holiday.name.contains('\u0648\u0642\u0641\u0629 \u0639\u0631\u0641\u0629')) {
      return Icons.mosque_rounded;
    }
    if (holiday.name.contains('\u0645\u0648\u0644\u062f')) {
      return Icons.star_rounded;
    }
    if (holiday.name.contains('\u0633\u0646\u0629')) {
      return Icons.calendar_today_rounded;
    }
    return holiday.isFixed ? Icons.event_rounded : Icons.mosque_rounded;
  }
}

class _SectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final IconData icon;

  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primaryTint,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 138),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
