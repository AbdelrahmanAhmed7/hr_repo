import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../permissions/models/permission_request.dart';
import '../../models/today_attendance.dart';
import '../../utils/attendance_formatters.dart';

class AttendanceDailyOverviewSection extends StatelessWidget {
  final TodayAttendance attendance;
  final bool isToday;
  final DateTime selectedDate;
  final List<PermissionRequest> todayPermissions;

  const AttendanceDailyOverviewSection({
    super.key,
    required this.attendance,
    required this.isToday,
    required this.selectedDate,
    this.todayPermissions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final hasRecord = attendance.isCheckedIn || attendance.isCheckedOut;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.timeline_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isToday ? 'ملخص اليوم' : 'ملخص اليوم المختار',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (!hasRecord && todayPermissions.isEmpty)
            _EmptyDayCard(isToday: isToday)
          else ...[
            if (hasRecord) ...[
              _TimelineBar(attendance: attendance),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AttendanceFactCard(
                      title: 'الدخول',
                      value: attendance.checkInTimeText ?? '--:--',
                      color: AppColors.primary,
                      icon: Icons.login_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AttendanceFactCard(
                      title: 'الخروج',
                      value: attendance.checkOutTimeText ?? '--:--',
                      color: AppColors.error,
                      icon: Icons.logout_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AttendanceFactCard(
                      title: 'الساعات',
                      value: formatWorkHours(attendance.currentWorkHours, short: true),
                      color: AppColors.success,
                      icon: Icons.timelapse_rounded,
                    ),
                  ),
                ],
              ),
            ],
            if (todayPermissions.isNotEmpty) ...[
              if (hasRecord) const SizedBox(height: 16),
              _PermissionsSection(permissions: todayPermissions),
            ],
          ],
        ],
      ),
    );
  }
}

class _PermissionsSection extends StatelessWidget {
  final List<PermissionRequest> permissions;

  const _PermissionsSection({required this.permissions});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.access_time_rounded,
              color: AppColors.warning,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'أذونات اليوم',
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${permissions.length}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...permissions.map((permission) => _PermissionItem(permission: permission)),
      ],
    );
  }
}

class _PermissionItem extends StatelessWidget {
  final PermissionRequest permission;

  const _PermissionItem({required this.permission});

  @override
  Widget build(BuildContext context) {
    final startTimeStr =
        '${permission.startTime.hour.toString().padLeft(2, '0')}:${permission.startTime.minute.toString().padLeft(2, '0')}';
    final endTimeStr =
        '${permission.endTime.hour.toString().padLeft(2, '0')}:${permission.endTime.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.access_time_filled_rounded,
              color: AppColors.warning,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إذن خروج',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$startTimeStr - $endTimeStr',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: permission.statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              permission.statusText,
              style: AppTextStyles.labelSmall.copyWith(
                color: permission.statusColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AttendanceFactCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const AttendanceFactCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 10),
          Text(title, style: AppTextStyles.labelMedium),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.titleSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDayCard extends StatelessWidget {
  final bool isToday;

  const _EmptyDayCard({required this.isToday});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.event_busy_rounded,
            color: AppColors.textTertiary,
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            isToday ? 'لا يوجد سجل حضور لهذا اليوم' : 'لا يوجد سجل حضور لهذا اليوم',
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isToday
                ? 'يمكنك تسجيل الحضور من القسم العلوي عند بدء يوم العمل.'
                : 'جرّب تغيير التاريخ أو راجع سجل الشهر بالأسفل.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _TimelineBar extends StatelessWidget {
  final TodayAttendance attendance;

  const _TimelineBar({required this.attendance});

  @override
  Widget build(BuildContext context) {
    final steps = [
      (
        title: 'تسجيل الدخول',
        subtitle: attendance.checkInTimeText ?? '--:--',
        active: attendance.isCheckedIn,
        color: AppColors.primary,
      ),
      (
        title: 'ساعات العمل',
        subtitle: attendance.currentWorkHours != null
            ? formatWorkHours(attendance.currentWorkHours)
            : 'قيد المتابعة',
        active: attendance.isCheckedIn,
        color: AppColors.warning,
      ),
      (
        title: 'تسجيل الخروج',
        subtitle: attendance.checkOutTimeText ?? '--:--',
        active: attendance.isCheckedOut,
        color: AppColors.success,
      ),
    ];

    return Column(
      children: List.generate(steps.length, (index) {
        final item = steps[index];
        final isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: item.active
                        ? item.color
                        : item.color.withValues(alpha: 0.20),
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 42,
                    color: AppColors.border,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(item.subtitle, style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
