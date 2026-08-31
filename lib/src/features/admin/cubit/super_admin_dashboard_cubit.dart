import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../attendance/services/sa_attendance_service.dart';
import '../../../core/utils/app_exception.dart';
import '../repository/super_admin_dashboard_repository.dart';
import 'super_admin_dashboard_state.dart';

class SuperAdminDashboardCubit extends Cubit<SuperAdminDashboardState> {
  final SuperAdminDashboardRepository _repository;
  final SAAttendanceService _attendanceService;

  SuperAdminDashboardCubit(this._repository, this._attendanceService)
      : super(SuperAdminDashboardState.initial());

  Future<void> loadDashboard() async {
    final cached = _repository.cachedData;
    if (cached != null) {
      emit(state.copyWith(isLoading: false, data: cached));
      _loadSupplementaryData();
      return;
    }

    emit(state.copyWith(isLoading: true, error: null));
    try {
      final data = await _repository.getSuperAdminDashboard();
      emit(state.copyWith(isLoading: false, data: data));
      _loadSupplementaryData();
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: AppException.from(e).message));
    }
  }

  Future<void> refresh() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final data = await _repository.getSuperAdminDashboard(forceRefresh: true);
      emit(state.copyWith(isLoading: false, data: data));
      _loadSupplementaryData();
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: AppException.from(e).message));
    }
  }

  Future<void> _loadSupplementaryData() async {
    // Load today's attendance from the same API as the attendance screen
    _loadTodayAttendance();
    // Load yesterday's summary + pairs
    _loadYesterdayData();
  }

  Future<void> _loadTodayAttendance() async {
    try {
      final now = DateTime.now();
      final dateStr = DateFormat('MM-dd-yyyy').format(now);
      final result = await _attendanceService.getAllAttendance(
        startDate: dateStr,
        endDate: dateStr,
        pageNumber: 1,
        pageSize: 500,
      );
      emit(state.copyWith(todayAttendance: result));
    } catch (_) {
      // Silent fail
    }
  }

  Future<void> _loadYesterdayData() async {
    try {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final dateStr = DateFormat('MM-dd-yyyy').format(yesterday);
      final summaryResult = await _attendanceService.getPunchSummary(
        from: dateStr,
        to: dateStr,
        page: 1,
        pageSize: 200,
      );
      final pairsResult = await _attendanceService.getPunchPairs(
        from: dateStr,
        to: dateStr,
        page: 1,
        pageSize: 200,
      );
      emit(state.copyWith(
        yesterdaySummary: summaryResult.items,
        yesterdayPairs: pairsResult.items,
      ));
    } catch (_) {
      // Silent fail
    }
  }
}
