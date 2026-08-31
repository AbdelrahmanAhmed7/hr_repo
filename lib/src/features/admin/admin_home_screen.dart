import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/attendance_handler.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/egyptian_holidays.dart';
import '../attendance/cubit/attendance_cubit.dart';
import '../attendance/cubit/attendance_state.dart';
import '../auth/services/auth_storage_service.dart';
import '../holidays/holidays_screen.dart';
import '../home/models/attendance_status.dart';
import '../home/widgets/quick_actions_section.dart';
import '../home/widgets/upcoming_leave_section.dart';
import '../leaves/create_leave_request_screen.dart';
import '../notifications/cubit/notifications_cubit.dart';
import '../notifications/cubit/notifications_state.dart';
import '../requests/widgets/create_permission_bottom_sheet.dart';
import 'admin_permissions_screen.dart';
import 'admin_leaves_screen.dart';
import 'admin_assignments_screen.dart';
import 'admin_employee_details_screen.dart';
import 'cubit/admin_dashboard_cubit.dart';
import 'cubit/admin_dashboard_state.dart';
import 'cubit/admin_permissions_cubit.dart';
import 'cubit/admin_leaves_cubit.dart';
import 'cubit/admin_assignments_cubit.dart';
import 'cubit/admin_requests_cubit.dart';
import 'cubit/admin_requests_state.dart';
import 'models/admin_dashboard_response.dart';
import 'models/admin_info.dart';
import 'reports/reports_screen.dart';
import 'widgets/admin_header_section.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AdminDashboardCubit>()..loadDashboard(),
      child: const _AdminHomeScreenContent(),
    );
  }
}

class _AdminHomeScreenContent extends StatefulWidget {
  const _AdminHomeScreenContent();

  @override
  State<_AdminHomeScreenContent> createState() =>
      _AdminHomeScreenContentState();
}

class _AdminHomeScreenContentState extends State<_AdminHomeScreenContent> {
  Holiday? _upcomingHoliday;

  @override
  void initState() {
    super.initState();
    _loadUpcomingHoliday();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminRequestsCubit>().loadRequests();
    });
  }

  Future<void> _loadUpcomingHoliday() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final all =
        [
              ...await EgyptianHolidays.getHolidaysForYear(now.year),
              ...await EgyptianHolidays.getHolidaysForYear(now.year + 1),
            ]
            .where(
              (h) => DateTime(
                h.date.year,
                h.date.month,
                h.date.day,
              ).isAfter(today.subtract(const Duration(days: 1))),
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    if (mounted) {
      setState(() => _upcomingHoliday = all.isEmpty ? null : all.first);
    }
  }

  void _handleCheckInOut() async {
    final cubit = context.read<AttendanceCubit>();
    final isCheckIn = !cubit.state.todayAttendance.isCheckedIn;
    debugPrint(
      '[AdminHome] checkInOut tapped isCheckIn=$isCheckIn, '
      'currentIsCheckedIn=${cubit.state.todayAttendance.isCheckedIn}',
    );

    await AttendanceHandler.handleAttendance(
      context: context,
      isCheckIn: isCheckIn,
      onSuccess: (isCheckIn, location, {String authMethod = 'fallback'}) async {
        if (!mounted || location == null) return;
        final userId = (await AuthStorageService.loadAuthState()).userId;
        if (isCheckIn) {
          await cubit.checkIn(
            userId: userId,
            latitude: location.latitude,
            longitude: location.longitude,
          );
        } else {
          await cubit.checkOut(
            userId: userId,
            latitude: location.latitude,
            longitude: location.longitude,
          );
        }
        if (!mounted) return;
        debugPrint(
          '[AdminHome] checkInOut success '
          'isCheckedIn=${cubit.state.todayAttendance.isCheckedIn}, '
          'isCheckedOut=${cubit.state.todayAttendance.isCheckedOut}',
        );
      },
    );
  }

  AttendanceInfo _buildAttendanceInfo(
    AdminDashboardResponse? data,
    AttendanceState attendanceState,
  ) {
    final attendance = attendanceState.todayAttendance;
    final apiCheckIn = _parseApiTime(data?.todayAttendanceTime);
    final apiCheckOut = _parseApiTime(data?.todayDepartureTime);

    final checkInTime = attendance.checkInTime ?? apiCheckIn;
    final checkOutTime = attendance.checkOutTime ?? apiCheckOut;
    final isCheckedOut = attendance.isCheckedOut || checkOutTime != null;
    final isCheckedIn = attendance.isCheckedIn || checkInTime != null;

    return AttendanceInfo(
      status: isCheckedOut
          ? AttendanceStatus.checkedOut
          : isCheckedIn
          ? AttendanceStatus.checkedIn
          : AttendanceStatus.notCheckedIn,
      checkInTime: checkInTime,
      checkOutTime: checkOutTime,
    );
  }

  DateTime? _parseApiTime(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    try {
      final parts = value.split(':');
      if (parts.length < 2) return null;

      final now = DateTime.now();
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      final second = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;

      return DateTime(now.year, now.month, now.day, hour, minute, second);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
      builder: (context, dashState) {
        // Full screen shimmer on first load (no cached data)
        if (dashState.isLoading && dashState.data == null) {
          return Scaffold(
            backgroundColor: AppColors.backgroundSecondary,
            body: const _AdminFullShimmer(),
          );
        }

        return BlocListener<AttendanceCubit, AttendanceState>(
          listenWhen: (previous, current) => current.isCheckInOutAction,
          listener: (context, attendanceState) {
            debugPrint(
              '[AdminHome] attendance action listener '
              'isCheckedIn=${attendanceState.todayAttendance.isCheckedIn}',
            );
            context.read<AdminDashboardCubit>().refresh();
          },
          child: BlocBuilder<AttendanceCubit, AttendanceState>(
            builder: (context, attState) {
              final data = dashState.data;
              final attendanceInfo = _buildAttendanceInfo(data, attState);
              debugPrint(
                '[AdminHome] rebuild status=${attendanceInfo.status}, '
                'isLoading=${attState.isLoading}',
              );

              // Build data from API response
              final adminInfo = data != null
                  ? AdminInfo(
                      name: data.displayName,
                      department: data.departmentName ?? '',
                      position: data.jobTitle ?? 'مدير قسم',
                      profileImageUrl: data.imageUrl,
                      notificationCount:
                          0, // Will be updated by NotificationsCubit
                    )
                  : AdminInfo(name: '', notificationCount: 0);

              return Scaffold(
                backgroundColor: AppColors.backgroundSecondary,
                body: RefreshIndicator(
                  onRefresh: () async {
                    await context
                        .read<AttendanceCubit>()
                        .refreshTodayAttendance();
                    if (!context.mounted) return;
                    await _loadUpcomingHoliday();
                    if (!context.mounted) return;
                    final dashCubit = context.read<AdminDashboardCubit>();
                    final reqCubit = context.read<AdminRequestsCubit>();
                    await dashCubit.refresh();
                    await reqCubit.loadRequests();
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Header
                      SliverToBoxAdapter(
                        child:
                            BlocBuilder<NotificationsCubit, NotificationsState>(
                              builder: (context, notifState) {
                                return AdminHeaderSection(
                                  adminInfo: adminInfo.copyWith(
                                    notificationCount: notifState.unreadCount,
                                  ),
                                  greeting: data?.greeting,
                                  attendanceTime: data?.todayAttendanceTime,
                                  departureTime: data?.todayDepartureTime,
                                  onNotificationTap: () =>
                                      context.push('/notifications'),
                                  onMenuTap: null,
                                );
                              },
                            ),
                      ),
                      SliverToBoxAdapter(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Quick Actions
                            QuickActionsSection(
                              attendanceInfo: attendanceInfo,
                              onCheckInOut: _handleCheckInOut,
                              onRequestLeave: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const CreateLeaveRequestScreen(),
                                ),
                              ),
                              onSubmitRequest: () => showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) =>
                                    const CreateExitPermissionBottomSheet(),
                              ),
                              onRequestOvertime: () =>
                                  context.push('/overtime'),
                              onViewMissions: () => context.push('/missions'),
                              onViewReports: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ReportsScreen(),
                                ),
                              ),
                              onViewOrganization: () =>
                                  context.push('/organization'),
                              onViewHolidays: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const HolidaysScreen(),
                                ),
                              ),
                              isLoading: attState.isLoading,
                              isAdmin: true,
                            ),
                            // Send Notification
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                              child: _AdminSendNotificationCard(
                                onTap: () => context.push('/send-notification'),
                              ),
                            ),
                            // Admin Management shortcuts
                            _AdminManagementSection(
                              onViewPermissions: () =>
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => BlocProvider(
                                        create: (_) =>
                                            getIt<AdminPermissionsCubit>(),
                                        child: const AdminPermissionsScreen(),
                                      ),
                                    ),
                                  ),
                              onViewLeaves: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => BlocProvider(
                                    create: (_) => getIt<AdminLeavesCubit>(),
                                    child: const AdminLeavesScreen(),
                                  ),
                                ),
                              ),
                              onViewAssignments: () =>
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => BlocProvider(
                                        create: (_) =>
                                            getIt<AdminAssignmentsCubit>(),
                                        child: const AdminAssignmentsScreen(),
                                      ),
                                    ),
                                  ),
                            ),
                            // Upcoming Holiday
                            UpcomingLeaveSection(
                              upcomingHoliday: _upcomingHoliday,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const HolidaysScreen(),
                                ),
                              ),
                            ),
                            // Dashboard content
                            if (dashState.isLoading && data == null)
                              const Padding(
                                padding: EdgeInsets.all(32),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (data != null) ...[
                              _EmployeesSection(employees: data.employees),
                              _RequestsSection(
                                allRequests: data.allRequests,
                                pendingRequests: data.pendingRequests,
                                acceptedRequests: data.acceptedRequests,
                                rejectedRequests: data.rejectedRequests,
                              ),
                            ] else if (dashState.error != null)
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  'خطأ: ${dashState.error}',
                                  style: const TextStyle(
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ─── Employees Section ────────────────────────────────────────────────────────

class _EmployeesSection extends StatelessWidget {
  final List<AdminEmployee> employees;
  const _EmployeesSection({required this.employees});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.people_rounded,
            title: 'موظفو القسم',
            count: employees.length,
            countLabel: 'موظف',
          ),
          const SizedBox(height: 12),
          if (employees.isEmpty)
            _EmptyCard(message: 'لا يوجد موظفون في القسم')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: employees.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _EmployeeCard(employee: employees[i]),
            ),
        ],
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final AdminEmployee employee;
  const _EmployeeCard({required this.employee});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AdminEmployeeDetailsScreen(employee: employee),
        ),
      ),
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
        child: Row(
          children: [
            // Avatar
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryTint,
              ),
              child: employee.imageUrl != null
                  ? ClipOval(
                      child: Image.network(
                        employee.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.person_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : const Icon(Icons.person_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee.fullNameAr,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    employee.jobTitleName ?? 'موظف',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Employment mode badge
            if (employee.employmentModeName != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  employee.employmentModeName!,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Requests Section ─────────────────────────────────────────────────────────

class _RequestsSection extends StatefulWidget {
  final List<AdminRequest> allRequests;
  final List<AdminRequest> pendingRequests;
  final List<AdminRequest> acceptedRequests;
  final List<AdminRequest> rejectedRequests;

  const _RequestsSection({
    required this.allRequests,
    required this.pendingRequests,
    required this.acceptedRequests,
    required this.rejectedRequests,
  });

  @override
  State<_RequestsSection> createState() => _RequestsSectionState();
}

class _RequestsSectionState extends State<_RequestsSection> {
  int _tab = 0;

  List<AdminRequest> get _current {
    switch (_tab) {
      case 1:
        return widget.pendingRequests;
      case 2:
        return widget.acceptedRequests;
      case 3:
        return widget.rejectedRequests;
      default:
        return widget.allRequests;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.assignment_rounded,
            title: 'اخر طلبات ',
            count: widget.allRequests.length,
            countLabel: 'طلب',
          ),
          const SizedBox(height: 12),
          // Filter tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'الكل',
                  count: widget.allRequests.length,
                  selected: _tab == 0,
                  onTap: () => setState(() => _tab = 0),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'معلقة',
                  count: widget.pendingRequests.length,
                  selected: _tab == 1,
                  onTap: () => setState(() => _tab = 1),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'مقبولة',
                  count: widget.acceptedRequests.length,
                  selected: _tab == 2,
                  onTap: () => setState(() => _tab = 2),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'مرفوضة',
                  count: widget.rejectedRequests.length,
                  selected: _tab == 3,
                  onTap: () => setState(() => _tab = 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_current.isEmpty)
            _EmptyCard(message: 'لا توجد طلبات في هذا القسم')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _current.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _RequestCard(request: _current[i]),
            ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final AdminRequest request;
  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    // Type
    final typeInfo = _typeInfo(request.type);
    // Status
    final statusInfo = _statusInfo(request.status);
    // Date/time description
    final desc = _buildDesc();

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: typeInfo.$2.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(typeInfo.$1, color: typeInfo.$2, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  typeInfo.$3,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusInfo.$1.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusInfo.$1.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  statusInfo.$2,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: statusInfo.$1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (desc != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  desc,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
          // Created at timestamp
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 14,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                _formatCreatedAt(request.createdAt),
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          if (request.reason != null && request.reason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.notes_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      request.reason!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Action buttons for pending requests
          if (request.status.toLowerCase() == 'pending') ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            BlocBuilder<AdminRequestsCubit, AdminRequestsState>(
              builder: (context, state) {
                final isLoading = state.isLoading;
                return Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isLoading ? null : () => _reject(context),
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('رفض'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          textStyle: AppTextStyles.labelMedium,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : () => _approve(context),
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('قبول'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          textStyle: AppTextStyles.labelMedium,
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  String? _buildDesc() {
    final type = request.type.toLowerCase();
    if (type == 'leave' &&
        request.startDate != null &&
        request.endDate != null) {
      return 'من ${request.startDate} إلى ${request.endDate}';
    }
    if ((type == 'permission' || type == 'overtime') &&
        request.startTime != null &&
        request.endTime != null) {
      return 'من ${_trimSeconds(request.startTime!)} إلى ${_trimSeconds(request.endTime!)}';
    }
    return request.date;
  }

  String _trimSeconds(String time) {
    final parts = time.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return time;
  }

  String _formatCreatedAt(String createdAt) {
    try {
      final dt = DateTime.parse(createdAt);
      return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return createdAt;
    }
  }

  (IconData, Color, String) _typeInfo(String type) {
    switch (type.toLowerCase()) {
      case 'leave':
        return (Icons.beach_access_rounded, const Color(0xFF9C27B0), 'إجازة');
      case 'permission':
        return (Icons.exit_to_app_rounded, AppColors.primary, 'إذن خروج');
      case 'overtime':
        return (Icons.more_time_rounded, AppColors.warning, 'عمل إضافي');
      case 'assignment':
        return (Icons.assignment_rounded, const Color(0xFFFF9800), 'مأمورية');
      default:
        return (Icons.help_outline_rounded, AppColors.textSecondary, type);
    }
  }

  (Color, String) _statusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'accepted':
        return (AppColors.success, 'مقبول');
      case 'rejected':
        return (AppColors.error, 'مرفوض');
      default:
        return (AppColors.warning, 'معلق');
    }
  }

  Future<void> _approve(BuildContext context) async {
    final cubit = context.read<AdminRequestsCubit>();
    final ok = await cubit.approveRequest(request.id.toString());
    if (!context.mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم قبول الطلب'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _reject(BuildContext context) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رفض الطلب'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'سبب الرفض (اختياري)',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final cubit = context.read<AdminRequestsCubit>();
    final ok = await cubit.rejectRequest(
      request.id.toString(),
      rejectReason: reasonController.text.trim().isEmpty
          ? null
          : reasonController.text.trim(),
    );
    if (!context.mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم رفض الطلب'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

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

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        '$label $count',
        style: AppTextStyles.labelLarge.copyWith(
          color: selected ? Colors.white : AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
      selected: selected,
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      onSelected: (_) => onTap(),
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

// ─── Send Notification Card ──────────────────────────────────────────────────

class _AdminSendNotificationCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AdminSendNotificationCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إرسال إشعار',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'إرسال إشعار للموظفين',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
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

// ─── Admin Management Section ─────────────────────────────────────────────────

class _AdminManagementSection extends StatelessWidget {
  final VoidCallback onViewPermissions;
  final VoidCallback onViewLeaves;
  final VoidCallback onViewAssignments;

  const _AdminManagementSection({
    required this.onViewPermissions,
    required this.onViewLeaves,
    required this.onViewAssignments,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.manage_accounts_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'إدارة القسم',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ManagementCard(
            icon: Icons.exit_to_app_rounded,
            color: AppColors.primary,
            title: 'أذونات الموظفين',
            subtitle: 'عرض وإدارة طلبات الأذونات',
            onTap: onViewPermissions,
          ),
          const SizedBox(height: 10),
          _ManagementCard(
            icon: Icons.beach_access_rounded,
            color: const Color(0xFF9C27B0),
            title: 'إجازات الموظفين',
            subtitle: 'عرض وإدارة طلبات الإجازات',
            onTap: onViewLeaves,
          ),
          const SizedBox(height: 10),
          _ManagementCard(
            icon: Icons.assignment_rounded,
            color: const Color(0xFFFF9800),
            title: 'مأموريات الموظفين',
            subtitle: 'عرض وإدارة طلبات المأموريات',
            onTap: onViewAssignments,
          ),
        ],
      ),
    );
  }
}

class _ManagementCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ManagementCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shimmer ──────────────────────────────────────────────────────────────────

class _AdminFullShimmer extends StatelessWidget {
  const _AdminFullShimmer();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          // Header shimmer
          Container(
            height: 164,
            decoration: BoxDecoration(
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
          // Content shimmer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: List.generate(
                4,
                (i) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
