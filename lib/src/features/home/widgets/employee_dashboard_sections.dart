import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/services/auth_storage_service.dart';
import '../models/attendance_status.dart';
import '../models/employee_bonus.dart';
import '../models/employee_info.dart';
import '../models/employee_penalty.dart';
import '../models/home_statistics.dart';

/// Helper function to calculate work hours between check-in and check-out
String _calculateWorkHours(DateTime checkIn, DateTime checkOut) {
  final duration = checkOut.difference(checkIn);
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  if (hours > 0 && minutes > 0) {
    return '$hours ساعة و $minutes دقيقة';
  } else if (hours > 0) {
    return '$hours ساعة';
  } else if (minutes > 0) {
    return '$minutes دقيقة';
  }
  return '--';
}

class EmployeeImmersiveTopSection extends StatelessWidget {
  final EmployeeInfo employeeInfo;
  final AttendanceInfo attendanceInfo;
  final String greeting;
  final bool isLoading;
  final VoidCallback? onCheckInOut;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onMenuTap;

  const EmployeeImmersiveTopSection({
    super.key,
    required this.employeeInfo,
    required this.attendanceInfo,
    required this.greeting,
    required this.isLoading,
    required this.onCheckInOut,
    required this.onNotificationTap,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCheckedIn = attendanceInfo.status == AttendanceStatus.checkedIn;
    final isCheckedOut = attendanceInfo.status == AttendanceStatus.checkedOut;
    final actionColor = isCheckedOut
        ? Colors.grey.shade600
        : (isCheckedIn ? AppColors.error : AppColors.success);
    final actionLabel = isCheckedOut
        ? 'اليوم مكتمل'
        : (isCheckedIn
              ? '\u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u0627\u0646\u0635\u0631\u0627\u0641'
              : '\u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062d\u0636\u0648\u0631');
    final jobTitle = employeeInfo.position.trim();
    final department = employeeInfo.department.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B1734), Color(0xFF12306A), Color(0xFF2152A3)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B1E4A).withValues(alpha: 0.18),
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -44,
              right: -8,
              child: _GlowOrb(size: 132, opacity: 0.10),
            ),
            const Positioned(
              bottom: -54,
              left: -14,
              child: _GlowOrb(size: 110, opacity: 0.08),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopActionsRow(
                    notificationCount: employeeInfo.notificationCount,
                    onNotificationTap: onNotificationTap,
                    onMenuTap: onMenuTap,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.14),
                                ),
                              ),
                              child: Text(
                                greeting.trim().isEmpty ? '--' : greeting,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              employeeInfo.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.headlineMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              jobTitle.isNotEmpty
                                  ? jobTitle
                                  : (department.isNotEmpty ? department : '--'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white.withValues(alpha: 0.82),
                              ),
                            ),
                            if (jobTitle.isNotEmpty &&
                                department.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                department,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.white.withValues(alpha: 0.70),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      _AvatarBadge(
                        name: employeeInfo.name,
                        imageUrl: employeeInfo.profileImageUrl,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _HeroStatCard(
                                label: '\u0627\u0644\u062d\u0636\u0648\u0631',
                                value:
                                    _StatusPanel._formatTime(
                                      attendanceInfo.checkInTime,
                                    ) ??
                                    '--:--',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _HeroStatCard(
                                label:
                                    '\u0627\u0644\u0627\u0646\u0635\u0631\u0627\u0641',
                                value:
                                    _StatusPanel._formatTime(
                                      attendanceInfo.checkOutTime,
                                    ) ??
                                    '--:--',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Work hours row - shows total hours worked
                        if (attendanceInfo.checkInTime != null &&
                            attendanceInfo.checkOutTime != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'ساعات العمل:',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _calculateWorkHours(
                                    attendanceInfo.checkInTime!,
                                    attendanceInfo.checkOutTime!,
                                  ),
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: (isLoading || isCheckedOut) ? null : onCheckInOut,
                      borderRadius: BorderRadius.circular(20),
                      child: Ink(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: actionColor,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: isLoading
                                  ? const Padding(
                                      padding: EdgeInsets.all(11),
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      isCheckedIn
                                          ? Icons.logout_rounded
                                          : Icons.fingerprint_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    actionLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.titleSmall.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isCheckedIn
                                        ? '\u0623\u0646\u0647\u0650 \u0627\u0644\u064a\u0648\u0645 \u0628\u062a\u0623\u0643\u064a\u062f \u0627\u0644\u0627\u0646\u0635\u0631\u0627\u0641'
                                        : '\u0627\u0628\u062f\u0623 \u064a\u0648\u0645\u0643 \u0628\u062a\u0623\u0643\u064a\u062f \u0627\u0644\u062d\u0636\u0648\u0631',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: actionColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmployeeActionCommandDeck extends StatelessWidget {
  final VoidCallback? onRequestLeave;
  final VoidCallback? onSubmitRequest;
  final VoidCallback? onRequestOvertime;
  final VoidCallback? onViewMissions;
  final VoidCallback? onViewOrganization;
  final VoidCallback? onViewPayslip;
  final VoidCallback? onViewHolidays;

  const EmployeeActionCommandDeck({
    super.key,
    this.onRequestLeave,
    this.onSubmitRequest,
    this.onRequestOvertime,
    this.onViewMissions,
    this.onViewOrganization,
    this.onViewPayslip,
    this.onViewHolidays,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\u0645\u0631\u0643\u0632 \u0627\u0644\u0625\u062c\u0631\u0627\u0621\u0627\u062a',
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '\u0623\u0647\u0645 \u0627\u0644\u0625\u062c\u0631\u0627\u0621\u0627\u062a \u0627\u0644\u064a\u0648\u0645\u064a\u0629 \u0641\u064a \u0645\u0643\u0627\u0646 \u0648\u0627\u062d\u062f',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.88,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _CommandTileBalanced(
                title: '\u0637\u0644\u0628 \u0625\u062c\u0627\u0632\u0629',
                subtitle:
                    '\u0642\u062f\u0651\u0645 \u0627\u0644\u0637\u0644\u0628 \u0628\u0633\u0631\u0639\u0629',
                icon: Icons.beach_access_outlined,
                color: const Color(0xFF10B981),
                onTap: onRequestLeave,
              ),
              _CommandTileBalanced(
                title: '\u0625\u0630\u0646 \u062e\u0631\u0648\u062c',
                subtitle:
                    '\u0625\u0646\u0634\u0627\u0621 \u0625\u0630\u0646 \u0633\u0631\u064a\u0639',
                icon: Icons.output_outlined,
                color: const Color(0xFFF59E0B),
                onTap: onSubmitRequest,
              ),
              _CommandTileBalanced(
                title: 'طلب overtime',
                subtitle: 'سجل ساعات العمل الإضافي وتابع حالتها',
                icon: Icons.more_time_outlined,
                color: const Color(0xFFEC4899),
                onTap: onRequestOvertime,
              ),
              _CommandTileBalanced(
                title:
                    '\u0627\u0644\u0645\u0623\u0645\u0648\u0631\u064a\u0627\u062a',
                subtitle:
                    '\u0645\u062a\u0627\u0628\u0639\u0629 \u0627\u0644\u0645\u0647\u0627\u0645 \u0648\u0627\u0644\u0627\u0646\u062a\u062f\u0627\u0628\u0627\u062a',
                icon: Icons.assignment_outlined,
                color: const Color(0xFF2563EB),
                onTap: onViewMissions,
              ),
              _CommandTileBalanced(
                title:
                    '\u0628\u064a\u0627\u0646 \u0627\u0644\u0645\u0631\u062a\u0628',
                subtitle:
                    '\u0627\u0639\u0631\u0636 \u0627\u0644\u0645\u0633\u064a\u0631 \u0648\u062a\u062d\u0645\u064a\u0644 PDF',
                icon: Icons.receipt_long_outlined,
                color: const Color(0xFF14B8A6),
                onTap: onViewPayslip,
              ),
              _CommandTileBalanced(
                title:
                    '\u0627\u0644\u0647\u064a\u0643\u0644 \u0627\u0644\u062a\u0646\u0638\u064a\u0645\u064a',
                subtitle:
                    '\u0639\u0631\u0636 \u0627\u0644\u0625\u062f\u0627\u0631\u0627\u062a \u0648\u0627\u0644\u0641\u0631\u0642',
                icon: Icons.account_tree_outlined,
                color: const Color(0xFF0EA5E9),
                onTap: onViewOrganization,
              ),
              _CommandTileBalanced(
                title:
                    '\u0627\u0644\u0625\u062c\u0627\u0632\u0627\u062a \u0627\u0644\u0639\u0627\u0645\u0629',
                subtitle:
                    '\u0639\u0631\u0636 \u0627\u0644\u0625\u062c\u0627\u0632\u0627\u062a \u0627\u0644\u0631\u0633\u0645\u064a\u0629',
                icon: Icons.celebration_outlined,
                color: const Color(0xFF8B5CF6),
                onTap: onViewHolidays,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class EmployeeInsightBoard extends StatelessWidget {
  final HomeStatistics statistics;

  const EmployeeInsightBoard({super.key, required this.statistics});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _InsightItem(
        label: '\u0623\u064a\u0627\u0645 \u0627\u0644\u062d\u0636\u0648\u0631',
        value: '${statistics.attendanceDays ?? 0}',
        color: const Color(0xFF1D4ED8),
      ),
      _InsightItem(
        label: '\u0637\u0644\u0628\u0627\u062a \u0645\u0639\u0644\u0642\u0629',
        value: '${statistics.pendingRequests ?? 0}',
        color: const Color(0xFFF59E0B),
      ),
      _InsightItem(
        label:
            '\u0637\u0644\u0628\u0627\u062a \u0645\u0642\u0628\u0648\u0644\u0629',
        value: '${statistics.acceptedRequests ?? 0}',
        color: const Color(0xFF10B981),
      ),
      _InsightItem(
        label: '\u0627\u0644\u0645\u0623\u0645\u0648\u0631\u064a\u0627\u062a',
        value: '${statistics.totalMissions ?? 0}',
        color: const Color(0xFF7C3AED),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\u0644\u0648\u062d\u0629 \u0627\u0644\u0645\u062a\u0627\u0628\u0639\u0629',
            style: AppTextStyles.titleLarge,
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.22,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [for (final card in cards) _InsightStat(card: card)],
          ),
        ],
      ),
    );
  }
}

class EmployeeRewardsPenaltiesSection extends StatelessWidget {
  final List<EmployeeBonus> bonuses;
  final List<EmployeePenalty> penalties;

  const EmployeeRewardsPenaltiesSection({
    super.key,
    required this.bonuses,
    required this.penalties,
  });

  @override
  Widget build(BuildContext context) {
    final totalBonus = bonuses.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final totalPenalty = penalties.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'المكافآت والجزاءات',
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'يعرض آخر القرارات المرتبطة بملفك الوظيفي فقط.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _FinanceSummaryCard(
                  title: 'إجمالي المكافآت',
                  value: _formatCurrency(totalBonus),
                  countLabel: '${bonuses.length} عنصر',
                  color: const Color(0xFF10B981),
                  icon: Icons.workspace_premium_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FinanceSummaryCard(
                  title: 'إجمالي الجزاءات',
                  value: _formatCurrency(totalPenalty),
                  countLabel: '${penalties.length} عنصر',
                  color: const Color(0xFFEF4444),
                  icon: Icons.gavel_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _FinanceTimelineCard<EmployeeBonus>(
            title: 'آخر المكافآت',
            emptyTitle: 'لا توجد مكافآت مسجلة',
            emptySubtitle: 'ستظهر هنا المكافآت الجديدة فور إضافتها على حسابك.',
            items: bonuses.take(3).toList(),
            accentColor: const Color(0xFF10B981),
            icon: Icons.card_giftcard_rounded,
            itemBuilder: (bonus) => _FinanceListTile(
              title: bonus.reason.trim().isEmpty ? 'مكافأة' : bonus.reason,
              subtitle: _formatDate(bonus.bonusDate ?? bonus.createdAt),
              trailing: _formatCurrency(bonus.amount),
              accentColor: const Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 10),
          _FinanceTimelineCard<EmployeePenalty>(
            title: 'آخر الجزاءات',
            emptyTitle: 'لا توجد جزاءات مسجلة',
            emptySubtitle: 'سيتم عرض أي جزاء يخصك هنا عند إضافته.',
            items: penalties.take(3).toList(),
            accentColor: const Color(0xFFEF4444),
            icon: Icons.report_problem_rounded,
            itemBuilder: (penalty) => _FinanceListTile(
              title: penalty.reason.trim().isEmpty
                  ? _penaltyTypeLabel(penalty)
                  : penalty.reason,
              subtitle: _buildPenaltySubtitle(penalty),
              trailing: penalty.amount > 0
                  ? _formatCurrency(penalty.amount)
                  : '${penalty.days} يوم',
              accentColor: const Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopActionsRow extends StatelessWidget {
  final int notificationCount;
  final VoidCallback? onNotificationTap;

  const _TopActionsRow({
    required this.notificationCount,
    required this.onNotificationTap,
    VoidCallback? onMenuTap, // kept for API compatibility, unused
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Spacer(),
        Stack(
          clipBehavior: Clip.none,
          children: [
            _GlassButton(
              icon: Icons.notifications_none_rounded,
              onTap: onNotificationTap,
            ),
            if (notificationCount > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4D6D),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFF0E2760),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      notificationCount > 9 ? '9+' : '$notificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _FinanceSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String countLabel;
  final Color color;
  final IconData icon;

  const _FinanceSummaryCard({
    required this.title,
    required this.value,
    required this.countLabel,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            countLabel,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceTimelineCard<T> extends StatelessWidget {
  final String title;
  final String emptyTitle;
  final String emptySubtitle;
  final List<T> items;
  final Color accentColor;
  final IconData icon;
  final Widget Function(T item) itemBuilder;

  const _FinanceTimelineCard({
    required this.title,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.items,
    required this.accentColor,
    required this.icon,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    emptyTitle,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    emptySubtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            ...items.map(itemBuilder),
        ],
      ),
    );
  }
}

class _FinanceListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailing;
  final Color accentColor;

  const _FinanceListTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            trailing,
            style: AppTextStyles.labelLarge.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  final AttendanceInfo attendanceInfo;
  final bool isLoading;
  final Color actionColor;
  final VoidCallback? onCheckInOut;

  const _StatusPanel({
    required this.attendanceInfo,
    required this.isLoading,
    required this.actionColor,
    required this.onCheckInOut,
  });

  @override
  Widget build(BuildContext context) {
    final isCheckedIn = attendanceInfo.status == AttendanceStatus.checkedIn;
    final isCheckedOut = attendanceInfo.status == AttendanceStatus.checkedOut;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniInfoTile(
                label: '\u0627\u0644\u062d\u0636\u0648\u0631',
                value: _formatTime(attendanceInfo.checkInTime) ?? '--:--',
              ),
              _MiniInfoTile(
                label: '\u0627\u0644\u0627\u0646\u0635\u0631\u0627\u0641',
                value: _formatTime(attendanceInfo.checkOutTime) ?? '--:--',
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (isCheckedOut)
            Opacity(
              opacity: 0.55,
              child: IgnorePointer(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade600,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'اليوم مكتمل',
                          style: AppTextStyles.titleSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: (isLoading || isCheckedOut) ? null : onCheckInOut,
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: actionColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: actionColor.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: actionColor,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(9),
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                isCheckedIn
                                    ? Icons.logout_rounded
                                    : Icons.fingerprint_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isCheckedIn
                              ? '\u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u0627\u0646\u0635\u0631\u0627\u0641'
                              : '\u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062d\u0636\u0648\u0631',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: actionColor),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String? _formatTime(DateTime? time) {
    if (time == null) return null;
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _GlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  final String name;
  final String? imageUrl;

  const _AvatarBadge({required this.name, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    // Clean the image URL first
    String? cleanUrl = imageUrl?.replaceAll('`', '').trim();
    if (cleanUrl != null && cleanUrl.isEmpty) cleanUrl = null;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFBFDBFE), Color(0xFF93C5FD)],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: cleanUrl != null
            ? FutureBuilder<String?>(
                future: AuthStorageService.getToken(),
                builder: (context, snapshot) {
                  final headers = <String, String>{};
                  if (snapshot.hasData && snapshot.data != null) {
                    headers['Authorization'] = 'Bearer ${snapshot.data}';
                  }
                  return CachedNetworkImage(
                    imageUrl: cleanUrl!,
                    httpHeaders: headers,
                    fit: BoxFit.cover,
                    placeholder: (context, imageUrl) =>
                        _InitialsFallback(name: name),
                    errorWidget: (context, imageUrl, error) {
                      if (kDebugMode) {
                        debugPrint('Image load error for $cleanUrl: $error');
                      }
                      return _InitialsFallback(name: name);
                    },
                  );
                },
              )
            : _InitialsFallback(name: name),
      ),
    );
  }

  static String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'E';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}

class _InitialsFallback extends StatelessWidget {
  final String name;

  const _InitialsFallback({required this.name});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        _AvatarBadge._initials(name),
        style: const TextStyle(
          color: Color(0xFF0B1E49),
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final double opacity;

  const _GlowOrb({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

class _HeroStatCard extends StatelessWidget {
  final String label;
  final String value;

  const _HeroStatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniInfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _MiniInfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 96),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommandTileBalanced extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _CommandTileBalanced({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 124),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '\u0627\u0641\u062a\u062d',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, size: 18, color: color),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InsightItem {
  final String label;
  final String value;
  final Color color;

  const _InsightItem({
    required this.label,
    required this.value,
    required this.color,
  });
}

String _formatCurrency(double value) {
  final formatter = NumberFormat.currency(
    locale: 'ar_EG',
    symbol: 'ج.م',
    decimalDigits: 0,
  );
  return formatter.format(value);
}

String _formatDate(DateTime? value) {
  if (value == null) return 'تاريخ غير متاح';
  return DateFormat('dd/MM/yyyy', 'ar').format(value);
}

String _buildPenaltySubtitle(EmployeePenalty penalty) {
  final details = <String>[
    _formatDate(penalty.penaltyDate ?? penalty.createdAt),
  ];
  if (penalty.amount > 0) {
    details.add('خصم مالي');
  } else if (penalty.days > 0) {
    details.add('${penalty.days} يوم');
  }
  return details.join(' - ');
}

String _penaltyTypeLabel(EmployeePenalty penalty) {
  switch (penalty.penaltyType) {
    case 1:
      return 'جزاء';
    case 2:
      return 'إنذار';
    default:
      return 'إجراء تأديبي';
  }
}

class _InsightStat extends StatelessWidget {
  final _InsightItem card;

  const _InsightStat({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 118),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: card.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.insights_rounded, color: card.color, size: 18),
            ),
            const SizedBox(height: 14),
            Text(
              card.label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              card.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
