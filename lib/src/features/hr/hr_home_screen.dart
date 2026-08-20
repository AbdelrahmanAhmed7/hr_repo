import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mediconsult_internal/src/features/attendance/cubit/attendance_state.dart';

import '../../core/services/attendance_handler.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/egyptian_holidays.dart';
import '../attendance/cubit/attendance_cubit.dart';
import '../auth/services/auth_storage_service.dart';
import '../home/models/attendance_status.dart';
import '../home/models/recent_activity.dart';
import '../home/widgets/recent_activity_section.dart';
import '../home/widgets/upcoming_leave_section.dart';
import 'cubit/hr_home_cubit.dart';
import 'cubit/hr_home_state.dart';
import 'models/hr_home_response.dart';
import 'widgets/hr_dashboard_sections.dart';
import 'widgets/hr_header_section.dart';

class HRHomeScreen extends StatelessWidget {
  const HRHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<HrHomeCubit>(),
      child: const _HRHomeScreenContent(),
    );
  }
}

class _HRHomeScreenContent extends StatefulWidget {
  const _HRHomeScreenContent();

  @override
  State<_HRHomeScreenContent> createState() => _HRHomeScreenContentState();
}

class _HRHomeScreenContentState extends State<_HRHomeScreenContent> {
  bool _isProcessingAttendance = false;
  Holiday? _upcomingHoliday;

  @override
  void initState() {
    super.initState();
    _loadUpcomingHoliday();
  }

  Future<void> _loadUpcomingHoliday() async {
    _upcomingHoliday = await _getUpcomingHoliday();
    if (mounted) {
      setState(() {});
    }
  }

  Future<Holiday?> _getUpcomingHoliday() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentYearHolidays = await EgyptianHolidays.getHolidaysForYear(
      now.year,
    );
    final nextYearHolidays = await EgyptianHolidays.getHolidaysForYear(
      now.year + 1,
    );
    final allHolidays = [...currentYearHolidays, ...nextYearHolidays];

    final upcomingHolidays = allHolidays.where((holiday) {
      final holidayDate = DateTime(
        holiday.date.year,
        holiday.date.month,
        holiday.date.day,
      );
      return holidayDate.isAfter(today.subtract(const Duration(days: 1)));
    }).toList();

    if (upcomingHolidays.isEmpty) return null;

    upcomingHolidays.sort((a, b) => a.date.compareTo(b.date));
    return upcomingHolidays.first;
  }

  void _handleCheckInOut() async {
    if (!mounted || _isProcessingAttendance) return;

    setState(() => _isProcessingAttendance = true);

    try {
      final attendanceCubit = context.read<AttendanceCubit>();
      final currentAttendance = attendanceCubit.state.todayAttendance;
      final isCheckIn = !currentAttendance.isCheckedIn;

      await AttendanceHandler.handleAttendance(
        context: context,
        isCheckIn: isCheckIn,
        onSuccess:
            (isCheckIn, location, {String authMethod = 'fallback'}) async {
              if (!mounted) return;
              final authState = await AuthStorageService.loadAuthState();
              final userId = authState.userId;
              if (location == null) return;
              if (isCheckIn) {
                await attendanceCubit.checkIn(
                  userId: userId,
                  latitude: location.latitude,
                  longitude: location.longitude,
                );
              } else {
                await attendanceCubit.checkOut(
                  userId: userId,
                  latitude: location.latitude,
                  longitude: location.longitude,
                );
              }
            },
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessingAttendance = false);
      }
    }
  }

  void _handleNotificationTap() => context.push('/notifications');
  void _handleMenuTap() => context.push('/organization');
  void _handleViewAllActivities() => context.push('/requests');
  void _handleViewAllRequests() => context.push('/admin/requests');
  void _handleViewEmployees() => context.push('/hr/employees');
  void _handleViewDepartments() => context.push('/hr/departments');
  void _handleViewOrganizationChart() => context.push('/organization');
  void _handleViewMissions() => context.push('/missions');
  void _handleViewHolidays() => context.push('/holidays');

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HrHomeCubit, HrHomeState>(
      builder: (context, hrState) {
        return BlocBuilder<AttendanceCubit, AttendanceState>(
          builder: (context, attendanceState) {
            final todayAttendance = attendanceState.todayAttendance;
            final attendanceInfo = AttendanceInfo(
              status: todayAttendance.isCheckedOut
                  ? AttendanceStatus.checkedOut
                  : todayAttendance.isCheckedIn
                  ? AttendanceStatus.checkedIn
                  : AttendanceStatus.notCheckedIn,
              checkInTime: todayAttendance.checkInTime,
              checkOutTime: todayAttendance.checkOutTime,
            );

            final recentActivities =
                hrState.data?.allRequests
                    .map((item) => RecentActivity.fromHrRequestItem(item))
                    .toList() ??
                const <RecentActivity>[];
            final pendingActivities =
                hrState.data?.pendingRequests
                    .map((item) => RecentActivity.fromHrRequestItem(item))
                    .toList() ??
                const <RecentActivity>[];
            final acceptedActivities =
                hrState.data?.acceptedRequests
                    .map((item) => RecentActivity.fromHrRequestItem(item))
                    .toList() ??
                const <RecentActivity>[];
            final rejectedActivities =
                hrState.data?.rejectedRequests
                    .map((item) => RecentActivity.fromHrRequestItem(item))
                    .toList() ??
                const <RecentActivity>[];

            return Scaffold(
              backgroundColor: AppColors.backgroundSecondary,
              body: RefreshIndicator(
                onRefresh: () async {
                  await context.read<HrHomeCubit>().refresh();
                  await _loadUpcomingHoliday();
                },
                child: hrState.isLoading && hrState.data == null
                    ? const Center(child: CircularProgressIndicator())
                    : CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: HRHeaderSection(
                              onNotificationTap: _handleNotificationTap,
                              onMenuTap: _handleMenuTap,
                              greeting: hrState.data?.greeting ?? 'أهلًا بك',
                              departmentName:
                                  hrState.data?.departmentName ??
                                  'الموارد البشرية',
                              employeeCount:
                                  hrState.data?.statistics.totalEmployees ?? 0,
                              departmentCount:
                                  hrState.data?.statistics.totalDepartments ??
                                  0,
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Column(
                              children: [
                                HrDashboardHero(
                                  data: hrState.data,
                                  attendanceInfo: attendanceInfo,
                                  isLoading:
                                      attendanceState.isLoading ||
                                      _isProcessingAttendance,
                                  onCheckInOut: _handleCheckInOut,
                                ),
                                _HrAttendanceTimesCard(data: hrState.data),
                                _HrEmployeeOverview(data: hrState.data),
                                HrAttentionQueue(data: hrState.data),
                                HrPrimaryActions(
                                  onViewEmployees: _handleViewEmployees,
                                  onViewDepartments: _handleViewDepartments,
                                  onViewOrganization:
                                      _handleViewOrganizationChart,
                                  onViewMissions: _handleViewMissions,
                                  onViewAllRequests: _handleViewAllRequests,
                                  onViewHolidays: _handleViewHolidays,
                                ),
                                HrDepartmentSnapshot(data: hrState.data),
                                if (_upcomingHoliday != null)
                                  UpcomingLeaveSection(
                                    upcomingHoliday: _upcomingHoliday!,
                                    onTap: () => context.push('/holidays'),
                                  ),
                                RecentActivitySection(
                                  activities: recentActivities,
                                  pendingActivities: pendingActivities,
                                  acceptedActivities: acceptedActivities,
                                  rejectedActivities: rejectedActivities,
                                  onViewAll: _handleViewAllActivities,
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            );
          },
        );
      },
    );
  }
}

class _HrEmployeeOverview extends StatelessWidget {
  final HrHomeResponse? data;

  const _HrEmployeeOverview({required this.data});

  @override
  Widget build(BuildContext context) {
    final stats = data?.statistics;
    final employees = stats?.totalEmployees ?? 0;
    final activeDepartments =
        stats?.employeesPerDepartment
            .where((item) => item.employeeCount > 0)
            .length ??
        0;
    final averageLoad = activeDepartments == 0
        ? 0
        : (employees / activeDepartments).round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مؤشرات الموظفين',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            childAspectRatio: 4.3,
            children: [
              _OverviewStatCard(
                title: 'إجمالي الموظفين',
                value: '$employees',
                color: AppColors.primary,
                tint: AppColors.primaryTint,
              ),
              _OverviewStatCard(
                title: 'الأقسام الفعالة',
                value: '$activeDepartments',
                color: const Color(0xFF0EA5E9),
                tint: const Color(0xFFE0F2FE),
              ),
              _OverviewStatCard(
                title: 'متوسط القسم',
                value: '$averageLoad',
                color: AppColors.success,
                tint: AppColors.successTint,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HrAttendanceTimesCard extends StatelessWidget {
  final HrHomeResponse? data;

  const _HrAttendanceTimesCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final attendanceTime = data?.todayAttendanceTime ?? '--:--';
    final departureTime = data?.todayDepartureTime ?? '--:--';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: _TimeInfoCard(
              label: 'وقت الحضور',
              value: attendanceTime,
              icon: Icons.login_rounded,
              color: AppColors.success,
              tint: AppColors.successTint,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _TimeInfoCard(
              label: 'وقت الانصراف',
              value: departureTime,
              icon: Icons.logout_rounded,
              color: AppColors.warning,
              tint: AppColors.warning.withValues(alpha: 0.14),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewStatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final Color tint;

  const _OverviewStatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeInfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color tint;

  const _TimeInfoCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.tint,
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
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
