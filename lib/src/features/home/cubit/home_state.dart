import 'package:equatable/equatable.dart';
import '../models/employee_bonus.dart';
import '../models/employee_info.dart';
import '../models/employee_penalty.dart';
import '../models/home_statistics.dart';
import '../models/recent_activity.dart';
import '../models/home_notification.dart';

class HomeState extends Equatable {
  final EmployeeInfo? employeeInfo;
  final HomeStatistics? statistics;
  final List<RecentActivity> recentActivities;
  final List<RecentActivity> pendingActivities;
  final List<RecentActivity> acceptedActivities;
  final List<RecentActivity> rejectedActivities;
  final List<HomeNotification> notifications;
  final List<EmployeeBonus> bonuses;
  final List<EmployeePenalty> penalties;
  final double? distanceFromOffice;
  final bool isLoading;
  final String? error;

  final String greeting;
  final String? todayAttendanceTime;
  final String? todayDepartureTime;

  const HomeState({
    this.employeeInfo,
    this.statistics,
    this.recentActivities = const [],
    this.pendingActivities = const [],
    this.acceptedActivities = const [],
    this.rejectedActivities = const [],
    this.notifications = const [],
    this.bonuses = const [],
    this.penalties = const [],
    this.distanceFromOffice,
    this.isLoading = false,
    this.error,
    this.greeting = '',
    this.todayAttendanceTime,
    this.todayDepartureTime,
  });

  factory HomeState.initial() {
    return const HomeState(
      employeeInfo: null,
      statistics: null,
      recentActivities: [],
      pendingActivities: [],
      acceptedActivities: [],
      rejectedActivities: [],
      notifications: [],
      bonuses: [],
      penalties: [],
      distanceFromOffice: null,
      isLoading: true,
      error: null,
      greeting: '',
      todayAttendanceTime: null,
      todayDepartureTime: null,
    );
  }

  HomeState copyWith({
    EmployeeInfo? employeeInfo,
    HomeStatistics? statistics,
    List<RecentActivity>? recentActivities,
    List<RecentActivity>? pendingActivities,
    List<RecentActivity>? acceptedActivities,
    List<RecentActivity>? rejectedActivities,
    List<HomeNotification>? notifications,
    List<EmployeeBonus>? bonuses,
    List<EmployeePenalty>? penalties,
    double? distanceFromOffice,
    bool? isLoading,
    String? error,
    String? greeting,
    String? todayAttendanceTime,
    String? todayDepartureTime,
  }) {
    return HomeState(
      employeeInfo: employeeInfo ?? this.employeeInfo,
      statistics: statistics ?? this.statistics,
      recentActivities: recentActivities ?? this.recentActivities,
      pendingActivities: pendingActivities ?? this.pendingActivities,
      acceptedActivities: acceptedActivities ?? this.acceptedActivities,
      rejectedActivities: rejectedActivities ?? this.rejectedActivities,
      notifications: notifications ?? this.notifications,
      bonuses: bonuses ?? this.bonuses,
      penalties: penalties ?? this.penalties,
      distanceFromOffice: distanceFromOffice ?? this.distanceFromOffice,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      greeting: greeting ?? this.greeting,
      todayAttendanceTime: todayAttendanceTime ?? this.todayAttendanceTime,
      todayDepartureTime: todayDepartureTime ?? this.todayDepartureTime,
    );
  }

  /// Whether there's an active error
  bool get hasError => error != null && error!.isNotEmpty;

  /// Whether we're showing cached data due to an error
  bool get isOfflineMode => hasError && employeeInfo != null;

  @override
  List<Object?> get props => [
        employeeInfo,
        statistics,
        recentActivities,
        pendingActivities,
        acceptedActivities,
        rejectedActivities,
        notifications,
        bonuses,
        penalties,
        distanceFromOffice,
        isLoading,
        error,
        greeting,
        todayAttendanceTime,
        todayDepartureTime,
      ];
}
