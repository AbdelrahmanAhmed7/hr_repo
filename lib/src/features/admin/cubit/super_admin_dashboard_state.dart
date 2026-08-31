import 'package:equatable/equatable.dart';

import '../../attendance/data/models/punch_pair_model.dart';
import '../../attendance/data/models/punch_summary_model.dart';
import '../../attendance/models/attendance_response_model.dart';
import '../models/super_admin_dashboard_response.dart';

class SuperAdminDashboardState extends Equatable {
  final bool isLoading;
  final String? error;
  final SuperAdminDashboardResponse? data;
  final List<PunchSummaryModel> yesterdaySummary;
  final List<PunchPairModel> yesterdayPairs;
  final AttendanceResponseModel? todayAttendance;

  const SuperAdminDashboardState({
    this.isLoading = false,
    this.error,
    this.data,
    this.yesterdaySummary = const [],
    this.yesterdayPairs = const [],
    this.todayAttendance,
  });

  SuperAdminDashboardState copyWith({
    bool? isLoading,
    String? error,
    SuperAdminDashboardResponse? data,
    List<PunchSummaryModel>? yesterdaySummary,
    List<PunchPairModel>? yesterdayPairs,
    AttendanceResponseModel? todayAttendance,
  }) {
    return SuperAdminDashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      data: data ?? this.data,
      yesterdaySummary: yesterdaySummary ?? this.yesterdaySummary,
      yesterdayPairs: yesterdayPairs ?? this.yesterdayPairs,
      todayAttendance: todayAttendance ?? this.todayAttendance,
    );
  }

  @override
  List<Object?> get props => [isLoading, error, data, yesterdaySummary, yesterdayPairs, todayAttendance];

  factory SuperAdminDashboardState.initial() =>
      const SuperAdminDashboardState();
}
