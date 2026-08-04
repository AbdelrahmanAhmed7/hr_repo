import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/attendance_status.dart';

class QuickActionsSection extends StatelessWidget {
  final AttendanceInfo attendanceInfo;
  final VoidCallback? onCheckInOut;
  final VoidCallback? onRequestLeave;
  final VoidCallback? onSubmitRequest;
  final VoidCallback? onRequestOvertime;
  final VoidCallback? onViewMissions;
  final VoidCallback? onViewReports;
  final VoidCallback? onViewOrganization;
  final VoidCallback? onViewHolidays;
  final bool isLoading;
  final bool isAdmin;

  const QuickActionsSection({
    super.key,
    required this.attendanceInfo,
    this.onCheckInOut,
    this.onRequestLeave,
    this.onSubmitRequest,
    this.onRequestOvertime,
    this.onViewMissions,
    this.onViewReports,
    this.onViewOrganization,
    this.onViewHolidays,
    this.isLoading = false,
    this.isAdmin = false,
  });

  Color _darken(Color color, [int amount = 20]) {
    final r = ((color.r * 255.0).round() - amount).clamp(0, 255);
    final g = ((color.g * 255.0).round() - amount).clamp(0, 255);
    final b = ((color.b * 255.0).round() - amount).clamp(0, 255);
    final a = (color.a * 255.0).round().clamp(0, 255);
    return Color.fromARGB(a, r, g, b);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '\u0625\u062c\u0631\u0627\u0621\u0627\u062a \u0633\u0631\u064a\u0639\u0629',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCheckInOutCard(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.calendar_month_rounded,
                  title: '\u0637\u0644\u0628 \u0625\u062c\u0627\u0632\u0629',
                  subtitle:
                      '\u062a\u0642\u062f\u064a\u0645 \u0625\u062c\u0627\u0632\u0629 \u062c\u062f\u064a\u062f\u0629',
                  color: AppColors.success,
                  onTap: onRequestLeave,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.description_rounded,
                  title: '\u0637\u0644\u0628 \u0625\u0630\u0646',
                  subtitle: '\u062a\u0633\u062c\u064a\u0644 \u0625\u0630\u0646',
                  color: AppColors.warning,
                  onTap: onSubmitRequest,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.schedule_rounded,
                  title: 'Overtime',
                  subtitle:
                      '\u062a\u0633\u062c\u064a\u0644 \u0639\u0645\u0644 \u0625\u0636\u0627\u0641\u064a',
                  color: const Color(0xFFEC4899),
                  onTap: onRequestOvertime,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.assignment_rounded,
                  title:
                      '\u0627\u0644\u0645\u0623\u0645\u0648\u0631\u064a\u0627\u062a',
                  subtitle: '\u0639\u0631\u0636 \u0648\u062a\u062a\u0628\u0639',
                  color: AppColors.primaryLight,
                  onTap: onViewMissions,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (onViewOrganization != null) ...[
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.account_tree_rounded,
                    title: 'الهيكل',
                    subtitle: 'التنظيمي',
                    color: const Color(0xFF0EA5E9),
                    onTap: onViewOrganization,
                  ),
                ),
              ] else ...[
                const Expanded(child: SizedBox.shrink()),
              ],
              const SizedBox(width: 12),
              if (onViewHolidays != null) ...[
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.celebration_outlined,
                    title: 'الإجازات',
                    subtitle: 'الرسمية',
                    color: const Color(0xFF8B5CF6),
                    onTap: onViewHolidays,
                  ),
                ),
              ] else ...[
                const Expanded(child: SizedBox.shrink()),
              ],
            ],
          ),
          if (isAdmin && onViewOrganization != null) ...[],
        ],
      ),
    );
  }

  Widget _buildCheckInOutCard() {
    final bool isCheckedIn =
        attendanceInfo.status == AttendanceStatus.checkedIn;
    final bool isCheckedOut =
        attendanceInfo.status == AttendanceStatus.checkedOut;
    final String buttonText = isCheckedIn
        ? '\u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062e\u0631\u0648\u062c'
        : '\u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062f\u062e\u0648\u0644';
    final String effectiveButtonText = isCheckedOut
        ? '\u0627\u0644\u064a\u0648\u0645 \u0645\u0643\u062a\u0645\u0644'
        : buttonText;
    final IconData icon = isCheckedOut
        ? Icons.check_rounded
        : (isCheckedIn ? Icons.logout_rounded : Icons.fingerprint_rounded);
    final Color backgroundColor = isCheckedOut
        ? Colors.grey.shade700
        : (isCheckedIn ? AppColors.error : AppColors.primary);
    final String timeText = isCheckedOut
        ? _formatRange(attendanceInfo.checkInTime, attendanceInfo.checkOutTime)
        : (attendanceInfo.checkInTime != null
              ? '${attendanceInfo.checkInTime!.hour.toString().padLeft(2, '0')}:${attendanceInfo.checkInTime!.minute.toString().padLeft(2, '0')}'
              : '');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: (isLoading || isCheckedOut) ? null : onCheckInOut,
        borderRadius: BorderRadius.circular(24),
        child: Opacity(
          opacity: (isLoading || isCheckedOut) ? 0.55 : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [backgroundColor, _darken(backgroundColor)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: backgroundColor.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.surface,
                            ),
                          ),
                        )
                      : Icon(icon, color: AppColors.surface, size: 32),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLoading
                            ? '\u062c\u0627\u0631\u064a \u0627\u0644\u062a\u062d\u0642\u0642 \u0645\u0646 \u0627\u0644\u0645\u0648\u0642\u0639...'
                            : effectiveButtonText,
                        style: const TextStyle(
                          color: AppColors.surface,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            isLoading
                                ? Icons.location_on_rounded
                                : Icons.access_time_rounded,
                            size: 14,
                            color: AppColors.surface.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isLoading
                                ? '\u0628\u0631\u062c\u0627\u0621 \u0627\u0644\u0627\u0646\u062a\u0638\u0627\u0631...'
                                : (timeText.isNotEmpty
                                      ? '\u062a\u0645 \u0627\u0644\u062f\u062e\u0648\u0644 \u0641\u064a $timeText'
                                      : attendanceInfo.statusText),
                            style: TextStyle(
                              color: AppColors.surface.withValues(alpha: 0.8),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isLoading)
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.surface,
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) return '';
    final s = start == null
        ? '--:--'
        : '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final e = end == null
        ? '--:--'
        : '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    return '$s - $e';
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
