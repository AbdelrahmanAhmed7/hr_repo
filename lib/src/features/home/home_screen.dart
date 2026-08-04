import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:go_router/go_router.dart';
import '../../core/services/attendance_handler.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/components/custom_toast.dart';
import '../../shared/widgets/shimmer_loading.dart';
import '../attendance/cubit/attendance_cubit.dart';
import '../attendance/cubit/attendance_state.dart';
import '../leaves/create_leave_request_screen.dart';
import '../auth/services/auth_storage_service.dart';
import '../requests/services/requests_refresh_service.dart';
import '../requests/widgets/create_permission_bottom_sheet.dart';
import 'cubit/home_cubit.dart';
import 'cubit/home_state.dart';
import 'models/attendance_status.dart';
import 'models/recent_activity.dart';
import 'widgets/employee_dashboard_sections.dart';
import 'widgets/recent_activity_card.dart';
import '../notifications/cubit/notifications_cubit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isProcessingAttendance = false;

  @override
  void initState() {
    super.initState();
    // Refresh notification badge count when home loads
    _refreshNotificationBadge();
  }

  void _refreshNotificationBadge() {
    try {
      context.read<NotificationsCubit>().refreshUnreadCount();
    } catch (_) {
      // NotificationsCubit not available in this context — ignore
    }
  }

  void _handleCheckInOut() async {
    if (!mounted || _isProcessingAttendance) return;

    setState(() => _isProcessingAttendance = true);

    try {
      final attendanceCubit = context.read<AttendanceCubit>();
      // Guard: if the day is already complete, don't attempt another action.
      if (attendanceCubit.state.todayAttendance.isCheckedOut) {
        CustomToast.showInfo('اليوم مكتمل بالفعل');
        return;
      }
      final isCheckIn = !attendanceCubit.state.todayAttendance.isCheckedIn;

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
      if (mounted) setState(() => _isProcessingAttendance = false);
    }
  }

  void _handleRequestLeave() => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const CreateLeaveRequestScreen()))
      .then((created) async {
        if (created == true && mounted) {
          // Update home + notify other request screens to refresh.
          try {
            getIt<RequestsRefreshService>().notify();
          } catch (_) {}

          final attendanceState = context.read<AttendanceCubit>().state;
          await context.read<HomeCubit>().refreshHomeData(
            attendance: attendanceState.todayAttendance,
          );
        }
      });

  Future<void> _handleSubmitRequest() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateExitPermissionBottomSheet(),
    );

    if (created == true && mounted) {
      final attendanceState = context.read<AttendanceCubit>().state;
      await context.read<HomeCubit>().refreshHomeData(
        attendance: attendanceState.todayAttendance,
      );
    }
  }

  void _handleViewOrganization() => context.push('/organization');
  void _handleViewNotifications() => context.push('/notifications');
  void _handleViewMissions() => context.push('/missions');

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, homeState) {
        // Show shimmer while loading OR while employeeInfo is not yet available
        if (homeState.isLoading || homeState.employeeInfo == null) {
          return const Scaffold(
            backgroundColor: AppColors.backgroundSecondary,
            body: HomeShimmerLoading(),
          );
        }

        // حالة الخطأ الكاملة - مفيش بيانات خالص (مفيش cache ومفيش API)
        if (homeState.hasError && homeState.employeeInfo == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: _HomeErrorState(
              onRetry: () {
                final attendanceState = context.read<AttendanceCubit>().state;
                context.read<HomeCubit>().loadHomeData(
                  attendance: attendanceState.todayAttendance,
                );
              },
            ),
          );
        }

        return BlocListener<AttendanceCubit, AttendanceState>(
          listenWhen: (previous, current) => current.isCheckInOutAction,
          listener: (context, attendanceState) {
            // After check-in/out we only need a lightweight refresh.
            // Silent mode prevents showing the full loading/shimmer again.
            context.read<HomeCubit>().loadHomeData(
              attendance: attendanceState.todayAttendance,
              silent: true,
            );
          },
          child: BlocBuilder<AttendanceCubit, AttendanceState>(
            builder: (context, attendanceState) {
              final attendanceInfo = _buildAttendanceInfo(
                homeState,
                attendanceState,
              );

              final notifState = context.watch<NotificationsCubit>().state;
              final badgeCount = notifState.unreadCount;

              return SafeArea(
                child: Scaffold(
                  backgroundColor: AppColors.background,
                  body: RefreshIndicator(
                    onRefresh: () async {
                      // Refresh attendance first so stale cached "today" state is cleared if backend is empty.
                      await context
                          .read<AttendanceCubit>()
                          .refreshTodayAttendance();
                      if (!context.mounted) return;

                      final latestAttendance = context
                          .read<AttendanceCubit>()
                          .state
                          .todayAttendance;
                      await context.read<HomeCubit>().refreshHomeData(
                        attendance: latestAttendance,
                      );
                      _refreshNotificationBadge();
                    },
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        // بانر خفيف لو البيانات من الـ cache
                        if (homeState.isOfflineMode)
                          SliverToBoxAdapter(
                            child: _OfflineModeBanner(
                              onRetry: () async {
                                await context.read<HomeCubit>().refreshHomeData(
                                  attendance: attendanceState.todayAttendance,
                                );
                                _refreshNotificationBadge();
                              },
                            ),
                          ),
                        if (homeState.employeeInfo != null)
                          SliverToBoxAdapter(
                            child: EmployeeImmersiveTopSection(
                              employeeInfo: homeState.employeeInfo!.copyWith(
                                notificationCount: badgeCount,
                              ),
                              attendanceInfo: attendanceInfo,
                              greeting: homeState.greeting,
                              isLoading:
                                  attendanceState.isLoading ||
                                  _isProcessingAttendance,
                              onCheckInOut: _handleCheckInOut,
                              onNotificationTap: _handleViewNotifications,
                              onMenuTap: _handleViewOrganization,
                            ),
                          ),
                        SliverToBoxAdapter(
                          child: _HomePrimaryActions(
                            onRequestLeave: _handleRequestLeave,
                            onSubmitPermission: _handleSubmitRequest,
                            onViewMissions: _handleViewMissions,
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: _HomeRecentRequests(
                            activities: homeState.recentActivities
                                .take(3)
                                .toList(),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 32)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  AttendanceInfo _buildAttendanceInfo(
    HomeState homeState,
    AttendanceState state,
  ) {
    final attendance = state.todayAttendance;
    final apiCheckIn = _parseApiTime(homeState.todayAttendanceTime);
    final apiCheckOut = _parseApiTime(homeState.todayDepartureTime);

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
}

class _HomePrimaryActions extends StatelessWidget {
  final VoidCallback onRequestLeave;
  final VoidCallback onSubmitPermission;
  final VoidCallback onViewMissions;

  const _HomePrimaryActions({
    required this.onRequestLeave,
    required this.onSubmitPermission,
    required this.onViewMissions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'إجراءات سريعة',
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  title: 'طلب إجازة',
                  icon: Icons.beach_access_outlined,
                  color: const Color(0xFF10B981),
                  onTap: onRequestLeave,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  title: 'إذن',
                  icon: Icons.output_outlined,
                  color: const Color(0xFFF59E0B),
                  onTap: onSubmitPermission,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  title: 'المأموريات',
                  icon: Icons.assignment_outlined,
                  color: AppColors.primary,
                  onTap: onViewMissions,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeRecentRequests extends StatelessWidget {
  final List<RecentActivity> activities;

  const _HomeRecentRequests({required this.activities});

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'آخر الطلبات',
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ...activities.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RecentActivityCard(activity: a),
            ),
          ),
        ],
      ),
    );
  }
}

/// شاشة الخطأ الكاملة - بتظهر لما مفيش بيانات خالص
class _HomeErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _HomeErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.errorTint,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  size: 48,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'تعذر تحميل البيانات',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'تأكد من اتصالك بالإنترنت وحاول مرة أخرى',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text(
                    'إعادة المحاولة',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// بانر خفيف بيظهر لو البيانات من الـ cache
class _OfflineModeBanner extends StatelessWidget {
  final VoidCallback onRetry;

  const _OfflineModeBanner({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 20,
            color: AppColors.warning.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'يتم عرض بيانات محفوظة مسبقاً',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'تحديث',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
