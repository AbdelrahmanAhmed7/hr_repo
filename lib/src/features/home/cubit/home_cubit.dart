import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mediconsult_internal/src/features/home/models/home_notification.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../shared/components/custom_toast.dart';
import '../../attendance/models/today_attendance.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/services/auth_storage_service.dart';
import '../models/employee_bonus.dart';
import '../models/employee_info.dart';
import '../models/employee_penalty.dart';
import '../models/home_statistics.dart';
import '../models/recent_activity.dart';
import '../repository/home_repository.dart';
import '../services/home_notification_service.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final HomeRepository _repository;
  final HomeNotificationService _notificationService;

  HomeCubit(this._repository, {HomeNotificationService? notificationService})
    : _notificationService = notificationService ?? HomeNotificationService(),
      super(HomeState.initial()) {
    loadHomeData();
    loadDistanceFromOffice();
  }

  Future<void> loadHomeData({
    TodayAttendance? attendance,
    bool awaitSupplementary = false,
    bool silent = false, // Add silent mode for background updates
  }) async {
    if (isClosed) return;

    // Don't show full loading if silent refresh and we already have data
    final shouldShowLoading = !silent || state.employeeInfo == null;
    emit(state.copyWith(isLoading: shouldShowLoading, error: null));

    try {
      // Fetch data from API
      final response = await _repository.getHomeData();

      // Load stored employee info or create from API data
      var employeeInfo = await EmployeeInfo.loadFromStorage();

      // Use name from API if available, otherwise use stored or default
      final nameFromApi = response.fullNameAr ?? response.fullNameEn;
      String? cleanImageUrl(String? url) {
        if (url == null) return null;
        // Remove all backticks and trim whitespace
        final cleaned = url.replaceAll('`', '').trim();
        if (kDebugMode) {
          print('Original image URL: "$url"');
        }
        if (kDebugMode) {
          print('Cleaned image URL: "$cleaned"');
        }
        return cleaned.isEmpty ? null : cleaned;
      }

      final imageFromApi = cleanImageUrl(response.imageUrl);

      if (employeeInfo == null) {
        employeeInfo = EmployeeInfo(
          name: nameFromApi ?? 'موظف',
          department: response.departmentName ?? 'غير محدد',
          position: response.jobTitle ?? 'غير محدد',
          profileImageUrl: imageFromApi,
        );
      } else {
        employeeInfo = employeeInfo.copyWith(
          name: nameFromApi ?? employeeInfo.name,
          department: response.departmentName ?? employeeInfo.department,
          position: response.jobTitle ?? employeeInfo.position,
          profileImageUrl: imageFromApi ?? employeeInfo.profileImageUrl,
        );
      }

      // Save updated employee info
      await employeeInfo.saveToStorage();

      // Convert all requests to recent activities (show up to 10 for tabs)
      final recentActivities = response.allRequests
          .take(10)
          .map((item) => RecentActivity.fromHomeRequestItem(item))
          .toList();

      final pendingActivities = response.pendingRequests
          .take(10)
          .map((item) => RecentActivity.fromHomeRequestItem(item))
          .toList();

      final acceptedActivities = response.acceptedRequests
          .take(10)
          .map((item) => RecentActivity.fromHomeRequestItem(item))
          .toList();

      final rejectedActivities = response.rejectedRequests
          .take(10)
          .map((item) => RecentActivity.fromHomeRequestItem(item))
          .toList();

      final statistics = HomeStatistics(
        remainingLeaves: null,
        workHours: null,
        pendingRequests: null, // Will be loaded by _loadFullStatistics
        acceptedRequests: null,
        rejectedRequests: null,
        totalLeaves: null,
        totalPermissions: null,
        totalMissions: null,
        attendanceDays: null,
      );

      // Generate notifications
      final notifications = attendance != null
          ? _notificationService.generateNotifications(
              homeData: response,
              attendance: attendance,
            )
          : <HomeNotification>[];

      // Emit state first without holiday (for faster UI)
      if (!isClosed) {
        emit(
          state.copyWith(
            employeeInfo: employeeInfo,
            statistics: statistics,
            recentActivities: recentActivities,
            pendingActivities: pendingActivities,
            acceptedActivities: acceptedActivities,
            rejectedActivities: rejectedActivities,
            notifications: notifications,
            greeting: response.greeting,
            todayAttendanceTime: response.todayAttendanceTime,
            todayDepartureTime: response.todayDepartureTime,
            isLoading: false,
          ),
        );
      }

      if (awaitSupplementary) {
        await _loadSupplementaryData();
      } else {
        _loadSupplementaryData();
      }
    } on DioException catch (e) {
      if (isClosed) return;

      // Check for "User not found" error
      if (e.response?.statusCode == 400) {
        final responseData = e.response?.data;
        final title = responseData['title']?.toString().toLowerCase();
        if (title != null && title.contains('user not found')) {
          // Clear auth state and redirect to login
          final authCubit = getIt<AuthCubit>();
          await authCubit.logout();

          // Show error message
          final context =
              AppRouter.router.routerDelegate.navigatorKey.currentContext;
          if (context != null && context.mounted) {
            CustomToast.showError(
              'المستخدم غير موجود. يرجى تسجيل الدخول مرة أخرى.',
            );
          }

          // Redirect to login
          AppRouter.router.go('/login');
          return;
        }
      }

      // Fallback: try to load cached employee info
      await _emitWithCachedFallback(e.toString());
    } catch (e) {
      if (isClosed) return;
      // Fallback: try to load cached employee info
      await _emitWithCachedFallback(e.toString());
    }
  }

  /// Tries to load cached employee data as a fallback when the API fails.
  /// This ensures the user always sees their basic info even without internet.
  Future<void> _emitWithCachedFallback(String errorMessage) async {
    if (isClosed) return;

    // If we already have employeeInfo in state, keep it
    if (state.employeeInfo != null) {
      emit(state.copyWith(isLoading: false, error: errorMessage));
      return;
    }

    // Try loading cached data from storage
    final cachedInfo = await EmployeeInfo.loadFromStorage();
    if (cachedInfo != null) {
      emit(
        state.copyWith(
          isLoading: false,
          employeeInfo: cachedInfo,
          error: errorMessage,
        ),
      );
    } else {
      // No cached data available — show error state
      emit(state.copyWith(isLoading: false, error: errorMessage));
    }
  }

  Future<void> refreshHomeData({TodayAttendance? attendance}) async {
    await loadHomeData(attendance: attendance, awaitSupplementary: true);
    await loadDistanceFromOffice();
  }

  Future<void> loadDistanceFromOffice() async {
    try {
      // التحقق من إذن الموقع (بدون طلب تلقائي)
      final status = await Permission.locationWhenInUse.status;
      final hasPermission = status.isGranted || status.isLimited;

      if (!hasPermission) {
        // لا نعرض شيئاً إذا لم يكن الإذن متاحاً
        return;
      }

      // الحصول على الموقع الحالي مباشرة (بما أننا تأكدنا من الإذن)
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // حساب المسافة
      final distance = LocationService.calculateDistance(
        position.latitude,
        position.longitude,
        LocationService.officeLatitude,
        LocationService.officeLongitude,
      );

      emit(state.copyWith(distanceFromOffice: distance));
    } catch (e) {
      // لا نعرض شيئاً في حالة الخطأ
    }
  }

  Future<void> _loadSupplementaryData() async {
    final results = await Future.wait([
      _safeLoadFullStatistics(),
      _safeLoadBonuses(),
      _safeLoadPenalties(),
    ]);

    if (isClosed) return;

    emit(
      state.copyWith(
        statistics: results[0] as HomeStatistics,
        bonuses: results[1] as List<EmployeeBonus>,
        penalties: results[2] as List<EmployeePenalty>,
      ),
    );
  }

  Future<HomeStatistics> _safeLoadFullStatistics() async {
    try {
      final dio = getIt<DioClient>().dio;

      final results = await Future.wait([
        dio.get('/api/Leave/my'),
        dio.get('/api/Permission/my'),
        dio.get('/api/Assignment/my'),
      ]);

      final leavesList = results[0].data as List? ?? [];
      final permissionsList = results[1].data as List? ?? [];
      final assignmentsList = results[2].data as List? ?? [];

      int pending = 0;
      int accepted = 0;
      int rejected = 0;

      void countStatuses(List list) {
        for (var item in list) {
          final status = item['status']?.toString().toLowerCase();
          if (status == 'pending') {
            pending++;
          } else if (status == 'approved' || status == 'accepted') {
            accepted++;
          } else if (status == 'rejected') {
            rejected++;
          }
        }
      }

      countStatuses(leavesList);
      countStatuses(permissionsList);
      countStatuses(assignmentsList);

      final currentStats = state.statistics;

      return HomeStatistics(
        remainingLeaves: currentStats?.remainingLeaves,
        workHours: currentStats?.workHours,
        attendanceDays: currentStats?.attendanceDays,
        pendingRequests: pending,
        acceptedRequests: accepted,
        rejectedRequests: rejected,
        totalLeaves: leavesList.length,
        totalPermissions: permissionsList.length,
        totalMissions: assignmentsList.length,
      );
    } catch (e) {
      return state.statistics ?? HomeStatistics();
    }
  }

  Future<List<EmployeeBonus>> _safeLoadBonuses() async {
    try {
      final employeeId = await _resolveEmployeeId();
      if (employeeId == null) return state.bonuses;

      final bonuses = await _repository.getEmployeeBonuses(employeeId);
      bonuses.sort((a, b) {
        final first =
            a.bonusDate ??
            a.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final second =
            b.bonusDate ??
            b.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return second.compareTo(first);
      });
      return bonuses.where((item) => item.userId == employeeId).toList();
    } catch (_) {
      return state.bonuses;
    }
  }

  Future<List<EmployeePenalty>> _safeLoadPenalties() async {
    try {
      final employeeId = await _resolveEmployeeId();
      if (employeeId == null) return state.penalties;

      final penalties = await _repository.getEmployeePenalties(employeeId);
      penalties.sort((a, b) {
        final first =
            a.penaltyDate ??
            a.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final second =
            b.penaltyDate ??
            b.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return second.compareTo(first);
      });
      return penalties.where((item) => item.userId == employeeId).toList();
    } catch (_) {
      return state.penalties;
    }
  }

  Future<String?> _resolveEmployeeId() async {
    final authCubit = getIt<AuthCubit>();
    final userId = authCubit.state.userId;
    if (userId != null && userId.trim().isNotEmpty) {
      return userId;
    }

    final authState = await AuthStorageService.loadAuthState();
    final storedUserId = authState.userId;
    if (storedUserId == null || storedUserId.trim().isEmpty) {
      return null;
    }
    return storedUserId;
  }
}
