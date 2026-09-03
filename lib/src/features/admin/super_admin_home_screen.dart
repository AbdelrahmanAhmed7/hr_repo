import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../attendance/data/models/punch_pair_model.dart';
import '../attendance/data/models/punch_summary_model.dart';
import '../attendance/models/attendance_response_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../notifications/cubit/notifications_cubit.dart';
import '../notifications/cubit/notifications_state.dart';
import 'cubit/super_admin_dashboard_cubit.dart';
import 'cubit/super_admin_dashboard_state.dart';
import 'models/super_admin_dashboard_response.dart';
import 'super_admin_department_screen.dart';

// ─── Helpers: numbers from attendance API (matches attendance screen) ─────────

int _presentCount(SuperAdminDashboardState state) =>
    state.todayAttendance?.employeesWithAttendance ??
    state.data?.presentToday ??
    0;

int _totalEmployeesCount(SuperAdminDashboardState state) =>
    state.todayAttendance?.totalEmployees ?? state.data?.totalEmployees ?? 0;

double _attendanceRateValue(SuperAdminDashboardState state) {
  final total = _totalEmployeesCount(state);
  if (total == 0) return 0;
  return _presentCount(state) / total;
}

int _lateCount(SuperAdminDashboardState state) {
  final records = state.todayAttendance?.attendances;
  if (records == null) return state.data?.lateEmployees ?? 0;
  const cutoff = 9 * 3600 + 16 * 60; // 09:16 in seconds
  return records.where((r) {
    if (r.attendanceTime == null) return false;
    return _parseTime(r.attendanceTime!) > cutoff;
  }).length;
}

int _parseTime(String raw) {
  try {
    final clean = raw.split('.')[0];
    final parts = clean.split(':');
    if (parts.length >= 3) {
      return int.parse(parts[0]) * 3600 +
          int.parse(parts[1]) * 60 +
          int.parse(parts[2]);
    }
    if (parts.length == 2) {
      return int.parse(parts[0]) * 3600 + int.parse(parts[1]) * 60;
    }
  } catch (_) {}
  return 0;
}

String _formatHours(double hours) {
  final h = hours.floor();
  final m = ((hours - h) * 60).round();
  if (h == 0) return '$m دقيقة';
  if (m == 0) return '$h ساعة';
  return '$h ساعة و $m دقيقة';
}

String _formatTime(String raw) {
  try {
    final clean = raw.split('.')[0];
    final parts = clean.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }
  } catch (_) {}
  return raw;
}

class SuperAdminHomeScreen extends StatelessWidget {
  final VoidCallback? onRequestsTap;

  const SuperAdminHomeScreen({super.key, this.onRequestsTap});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SuperAdminDashboardCubit, SuperAdminDashboardState>(
      builder: (context, state) {
        if (state.isLoading && state.data == null) {
          return const Scaffold(
            backgroundColor: AppColors.backgroundSecondary,
            body: _SuperAdminShimmer(),
          );
        }

        final data = state.data;
        final activeDepartments =
            data?.departments.where((d) => d.employees.isNotEmpty).toList() ??
            [];

        return Scaffold(
          backgroundColor: AppColors.backgroundSecondary,
          body: RefreshIndicator(
            onRefresh: () => context.read<SuperAdminDashboardCubit>().refresh(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: BlocBuilder<NotificationsCubit, NotificationsState>(
                    builder: (context, notifState) => _SuperAdminHeader(
                      data: data,
                      dashboardState: state,
                      notificationCount: notifState.unreadCount,
                      onNotificationTap: () => context.push('/notifications'),
                      onRequestsTap: onRequestsTap,
                    ),
                  ),
                ),
                if (state.error != null && data == null)
                  SliverFillRemaining(
                    child: _ErrorView(
                      error: state.error!.replaceFirst('Exception: ', ''),
                      onRetry: () => context
                          .read<SuperAdminDashboardCubit>()
                          .loadDashboard(),
                    ),
                  )
                else if (data != null) ...[
                  // ── KPI Row (merged with attendance insights) ──
                  SliverToBoxAdapter(
                    child: _KpiRow(
                      data: data,
                      todayAttendance: state.todayAttendance,
                      onRequestsTap: onRequestsTap,
                    ),
                  ),

                  // ── Top Performers (yesterday) ──
                  if (state.yesterdaySummary.isNotEmpty ||
                      state.yesterdayPairs.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _TopPerformersCard(
                        summary: state.yesterdaySummary,
                        pairs: state.yesterdayPairs,
                        departments: activeDepartments,
                      ),
                    ),

                  // ── Quick Actions ──
                  SliverToBoxAdapter(
                    child: _SuperAdminQuickActions(
                      onSendNotification: () =>
                          context.push('/send-notification'),
                      onEmployeeOfMonth: () =>
                          context.push('/employee-of-month'),
                      onPayroll: () => context.push('/payroll'),
                      onPenalties: () => context.push('/penalties'),
                      onBonuses: () => context.push('/bonuses'),
                      onMeetings: () => context.pushNamed('superAdminMeetings'),
                    ),
                  ),

                  // ── Section Header: Departments ──
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _SectionHeader(
                        icon: Icons.business_rounded,
                        title: 'الأقسام',
                        count: activeDepartments.length,
                        countLabel: 'قسم',
                      ),
                    ),
                  ),

                  // ── Department Cards ──
                  if (activeDepartments.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: _EmptyCard(message: 'لا توجد أقسام'),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      sliver: SliverList.separated(
                        itemCount: activeDepartments.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) =>
                            _DepartmentCard(department: activeDepartments[i]),
                      ),
                    ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Alert Strip ─────────────────────────────────────────────────────────────

// ─── KPI Row ─────────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  final SuperAdminDashboardResponse data;
  final AttendanceResponseModel? todayAttendance;
  final VoidCallback? onRequestsTap;

  const _KpiRow({required this.data, this.todayAttendance, this.onRequestsTap});

  @override
  Widget build(BuildContext context) {
    final state = context.read<SuperAdminDashboardCubit>().state;
    final rate = (_attendanceRateValue(state) * 100).round();
    final present = _presentCount(state);
    final total = _totalEmployeesCount(state);
    final lateCount = _lateCount(state);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.border.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                _KpiCard(
                  icon: Icons.pie_chart_rounded,
                  label: 'نسبة الحضور',
                  value: '$rate%',
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                _KpiCard(
                  icon: Icons.people_rounded,
                  label: 'الحضور اليوم',
                  value: '$present/$total',
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                _KpiCard(
                  icon: Icons.assignment_rounded,
                  label: 'الطلبات المعلقة',
                  value: '${data.pendingRequests}',
                  color: AppColors.warning,
                  onTap: onRequestsTap,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _AttendanceMiniStat(
                  label: 'متأخرون',
                  count: lateCount,
                  color: AppColors.error,
                ),
                const SizedBox(width: 8),
                _AttendanceMiniStat(
                  label: 'الحضور',
                  count: present,
                  color: AppColors.success,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quick Actions: Send Notification + Employee of Month ─────────────────────

class _SuperAdminQuickActions extends StatelessWidget {
  final VoidCallback onSendNotification;
  final VoidCallback onEmployeeOfMonth;
  final VoidCallback onPayroll;
  final VoidCallback onPenalties;
  final VoidCallback onBonuses;
  final VoidCallback onMeetings;

  const _SuperAdminQuickActions({
    required this.onSendNotification,
    required this.onEmployeeOfMonth,
    required this.onPayroll,
    required this.onPenalties,
    required this.onBonuses,
    required this.onMeetings,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickActionData(
        icon: Icons.payments_rounded,
        title: 'كشف الرواتب',
        subtitle: 'حساب وعرض كشف رواتب الموظفين الشهري',
        color: AppColors.primary,
        onTap: onPayroll,
      ),
      _QuickActionData(
        icon: Icons.gavel_rounded,
        title: 'إدارة الجزاءات',
        subtitle: 'تسجيل ومتابعة جزاءات الموظفين',
        color: AppColors.error,
        onTap: onPenalties,
      ),
      _QuickActionData(
        icon: Icons.workspace_premium_rounded,
        title: 'إدارة المكافآت',
        subtitle: 'تسجيل ومتابعة مكافآت الموظفين',
        color: AppColors.success,
        onTap: onBonuses,
      ),
      _QuickActionData(
        icon: Icons.send_rounded,
        title: 'إرسال إشعار',
        subtitle: 'إرسال إشعار للموظفين',
        color: AppColors.primary,
        onTap: onSendNotification,
      ),
      _QuickActionData(
        icon: Icons.emoji_events_rounded,
        title: 'موظف الشهر',
        subtitle: 'إدارة وحساب الفائزين',
        color: const Color(0xFF1E3A8A),
        onTap: onEmployeeOfMonth,
      ),
      _QuickActionData(
        icon: Icons.groups_rounded,
        title: 'الاجتماعات',
        subtitle: 'إنشاء وإدارة اجتماعات الموظفين',
        color: const Color(0xFF7C3AED),
        onTap: onMeetings,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: actions
            .map(
              (action) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _QuickActionCard(action: action),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _QuickActionData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

class _QuickActionCard extends StatelessWidget {
  final _QuickActionData action;

  const _QuickActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.border.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(action.icon, color: action.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      action.subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inner = Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.border.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    return Expanded(
      child: onTap != null
          ? GestureDetector(onTap: onTap, child: inner)
          : inner,
    );
  }
}

class _AttendanceMiniStat extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _AttendanceMiniStat({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: color,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Top Performers Card ─────────────────────────────────────────────────────

class _TopPerformersCard extends StatelessWidget {
  final List<PunchSummaryModel> summary;
  final List<PunchPairModel> pairs;
  final List<SuperAdminDepartmentData> departments;

  const _TopPerformersCard({
    required this.summary,
    required this.pairs,
    required this.departments,
  });

  @override
  Widget build(BuildContext context) {
    // ── Section 1: Highest work hours ──
    final sortedByHours = List<PunchSummaryModel>.from(summary)
      ..sort((a, b) => b.workedHours.compareTo(a.workedHours));
    final topByHours = sortedByHours.take(3).toList();

    // ── Section 2: Most check-in/check-out pairs (expandable) ──
    final pairsByUser = <String, List<PunchPairModel>>{};
    for (final p in pairs) {
      pairsByUser.putIfAbsent(p.userId, () => []).add(p);
    }
    final sortedByPairs = pairsByUser.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    final topByPairs = sortedByPairs.take(3).toList();

    if (topByHours.isEmpty && topByPairs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.border.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Highest Hours ──
            if (topByHours.isNotEmpty) ...[
              _SectionTitle(
                icon: Icons.schedule_rounded,
                iconColor: AppColors.success,
                title: 'الأعلى ساعات عمل أمس',
              ),
              const SizedBox(height: 12),
              ...topByHours.map((e) {
                return _PerformerRow(
                  name: e.employeeName,
                  badge: _formatHours(e.workedHours),
                  badgeColor: AppColors.success,
                );
              }),
            ],

            // ── Most Active (show check-in / check-out times) ──
            if (topByHours.isNotEmpty && topByPairs.isNotEmpty)
              const SizedBox(height: 16),
            if (topByPairs.isNotEmpty) ...[
              _SectionTitle(
                icon: Icons.swap_vert_circle_rounded,
                iconColor: AppColors.primary,
                title: 'الأكثر دخولاً وخروجاً أمس',
              ),
              const SizedBox(height: 12),
              ...topByPairs.map((e) {
                final userPairs = e.value;
                final count = userPairs.length;
                final empName = userPairs.first.employeeName;
                return _ExpandablePerformerRow(
                  name: empName,
                  badge: '$count مرة',
                  badgeColor: AppColors.primary,
                  expandedChild: _PunchPairDetails(
                    pairs: userPairs,
                    formatTime: _formatTime,
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _PunchPairDetails extends StatelessWidget {
  final List<PunchPairModel> pairs;
  final String Function(String) formatTime;

  const _PunchPairDetails({required this.pairs, required this.formatTime});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تفاصيل مرات الدخول والخروج المسجلة أمس',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...pairs.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final pair = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: index == pairs.length ? 0 : 8),
              child: _PunchPairDetailRow(
                index: index,
                checkIn: formatTime(pair.checkIn),
                checkOut: pair.checkOut == null
                    ? 'لم يتم تسجيل خروج'
                    : formatTime(pair.checkOut!),
                hasCheckOut: pair.checkOut != null,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _PunchPairDetailRow extends StatelessWidget {
  final int index;
  final String checkIn;
  final String checkOut;
  final bool hasCheckOut;

  const _PunchPairDetailRow({
    required this.index,
    required this.checkIn,
    required this.checkOut,
    required this.hasCheckOut,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$index',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _PunchTimePill(
                icon: Icons.login_rounded,
                label: 'دخول',
                value: checkIn,
                color: AppColors.success,
              ),
              _PunchTimePill(
                icon: Icons.logout_rounded,
                label: 'خروج',
                value: checkOut,
                color: hasCheckOut ? AppColors.error : AppColors.warning,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PunchTimePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _PunchTimePill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;

  const _SectionTitle({
    required this.icon,
    required this.iconColor,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _PerformerRow extends StatelessWidget {
  final String name;
  final String badge;
  final Color badgeColor;

  const _PerformerRow({
    required this.name,
    required this.badge,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badge,
              style: AppTextStyles.labelSmall.copyWith(
                color: badgeColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandablePerformerRow extends StatefulWidget {
  final String name;
  final String badge;
  final Color badgeColor;
  final Widget expandedChild;

  const _ExpandablePerformerRow({
    required this.name,
    required this.badge,
    required this.badgeColor,
    required this.expandedChild,
  });

  @override
  State<_ExpandablePerformerRow> createState() =>
      _ExpandablePerformerRowState();
}

class _ExpandablePerformerRowState extends State<_ExpandablePerformerRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: widget.badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.badge,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: widget.badgeColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 32),
              child: widget.expandedChild,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Department Card ─────────────────────────────────────────────────────────

class _DepartmentCard extends StatelessWidget {
  final SuperAdminDepartmentData department;
  const _DepartmentCard({required this.department});

  @override
  Widget build(BuildContext context) {
    final hasPending = department.pendingRequestsCount > 0;
    final attendanceRate = department.employees.isEmpty
        ? 0.0
        : department.presentToday / department.employees.length;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SuperAdminDepartmentScreen(department: department),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.border.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.business_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        department.departmentName,
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${department.employees.length} موظف  •  ${department.presentToday} حاضر اليوم',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasPending)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '${department.pendingRequestsCount} معلق',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                  size: 22,
                ),
              ],
            ),
            if (department.employees.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: attendanceRate,
                  minHeight: 5,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    attendanceRate >= 0.8
                        ? AppColors.success
                        : attendanceRate >= 0.5
                        ? AppColors.warning
                        : AppColors.error,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'نسبة الحضور: ${(attendanceRate * 100).round()}%',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _SuperAdminHeader extends StatelessWidget {
  final SuperAdminDashboardResponse? data;
  final SuperAdminDashboardState dashboardState;
  final int notificationCount;
  final VoidCallback onNotificationTap;
  final VoidCallback? onRequestsTap;

  const _SuperAdminHeader({
    required this.data,
    required this.dashboardState,
    required this.notificationCount,
    required this.onNotificationTap,
    this.onRequestsTap,
  });

  String _timeGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'صباح الخير';
    if (h < 17) return 'مساء الخير';
    return 'مساء النور';
  }

  String _formatTime(String raw) {
    try {
      final parts = raw.split(':');
      if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    } catch (_) {}
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final greeting = (data?.greeting.isNotEmpty == true)
        ? data!.greeting
        : _timeGreeting();

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: data?.imageUrl != null
                        ? ClipOval(
                            child: Image.network(
                              data!.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data?.displayName ?? '...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.admin_panel_settings_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                data?.jobTitle ?? 'CEO',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onNotificationTap,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Icon(
                              Icons.notifications_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      if (notificationCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Center(
                              child: Text(
                                notificationCount > 9
                                    ? '9+'
                                    : '$notificationCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              if (data?.todayAttendanceTime != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.login_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'تسجيل الدخول: ${_formatTime(data!.todayAttendanceTime!)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (data != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    _StatChip(label: 'الأقسام', count: data!.totalDepartments),
                    const SizedBox(width: 8),
                    _StatChip(
                      label: 'الموظفون',
                      count: _totalEmployeesCount(dashboardState),
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      label: 'حضور اليوم',
                      count: _presentCount(dashboardState),
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      label: 'الطلبات',
                      count: data!.totalRequests,
                      onTap: onRequestsTap,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback? onTap;

  const _StatChip({required this.label, required this.count, this.onTap});

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    if (onTap == null) {
      return Expanded(child: chip);
    }

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: chip,
        ),
      ),
    );
  }
}

// ─── Shared widgets ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final String countLabel;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
    required this.countLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryTint,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryTint,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count $countLabel',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inbox_outlined,
            size: 40,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shimmer ─────────────────────────────────────────────────────────────────

class _SuperAdminShimmer extends StatelessWidget {
  const _SuperAdminShimmer();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 12,
                            width: 100,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 18,
                            width: 180,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                ),
                Row(
                  children: List.generate(
                    4,
                    (_) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                ),
                ...List.generate(
                  3,
                  (_) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
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
