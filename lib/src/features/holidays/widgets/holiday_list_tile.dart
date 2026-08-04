import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/public_holiday_model.dart';

class HolidayListTile extends StatelessWidget {
  final PublicHolidayModel holiday;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onManageExceptions;

  const HolidayListTile({
    super.key,
    required this.holiday,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onManageExceptions,
  });

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _getDayName(DateTime date) {
    final days = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    return days[date.weekday - 1];
  }

  IconData _getHolidayIcon() {
    final name = holiday.nameAr.toLowerCase();
    if (name.contains('فطر') || name.contains('أضحى')) {
      return Icons.celebration;
    } else if (name.contains('وقفة') || name.contains('عرفة')) {
      return Icons.mosque;
    } else if (name.contains('مولد')) {
      return Icons.star;
    } else if (name.contains('سنة') || name.contains('رأس')) {
      return Icons.calendar_today;
    } else if (name.contains('ثورة') || name.contains('تحرير')) {
      return Icons.flag;
    } else if (name.contains('عمال')) {
      return Icons.work;
    } else {
      return Icons.event;
    }
  }

  Color _getHolidayColor() {
    final name = holiday.nameAr.toLowerCase();
    if (name.contains('فطر') || name.contains('أضحى')) {
      return const Color(0xFF10B981);
    } else if (name.contains('مولد')) {
      return const Color(0xFFF59E0B);
    } else if (name.contains('ثورة') || name.contains('تحرير')) {
      return const Color(0xFF3B82F6);
    } else if (name.contains('عمال')) {
      return const Color(0xFF8B5CF6);
    } else {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isToday = holiday.date.year == DateTime.now().year &&
        holiday.date.month == DateTime.now().month &&
        holiday.date.day == DateTime.now().day;
    final isPast = holiday.date.isBefore(DateTime.now());
    final color = _getHolidayColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isToday ? color : AppColors.border,
          width: isToday ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isToday
                ? color.withValues(alpha: 0.15)
                : AppColors.border.withValues(alpha: 0.1),
            blurRadius: isToday ? 12 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color,
                        color.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(_getHolidayIcon(), color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              holiday.nameAr,
                              style: AppTextStyles.titleSmall.copyWith(
                                fontWeight: FontWeight.w800,
                                color: isPast ? AppColors.textTertiary : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (isToday)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'اليوم',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatDate(holiday.date),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.access_time_outlined,
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getDayName(holiday.date),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions
                if (onEdit != null || onDelete != null || onManageExceptions != null)
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: AppColors.textTertiary,
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit?.call();
                          break;
                        case 'delete':
                          onDelete?.call();
                          break;
                        case 'exceptions':
                          onManageExceptions?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      if (onManageExceptions != null)
                        PopupMenuItem(
                          value: 'exceptions',
                          child: Row(
                            children: [
                              Icon(Icons.person_off_outlined, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              const Text('إدارة الاستثناءات'),
                            ],
                          ),
                        ),
                      if (onEdit != null)
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              const Text('تعديل'),
                            ],
                          ),
                        ),
                      if (onDelete != null)
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                              const SizedBox(width: 8),
                              const Text('حذف', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                    ],
                  )
                else
                  Icon(
                    Icons.chevron_left,
                    color: AppColors.textTertiary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
