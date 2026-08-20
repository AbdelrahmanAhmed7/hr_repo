import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/service_locator.dart';
import '../../../core/utils/app_exception.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../home/models/recent_activity.dart';
import '../../leaves/repository/leaves_repository.dart';
import '../../missions/repository/assignment_repository.dart';
import '../../overtime/repository/overtime_repository.dart';
import '../../permissions/repository/permission_repository.dart';
import '../../requests/management/management_requests_repository.dart';
import '../models/admin_dashboard_response.dart';
import '../repository/admin_dashboard_repository.dart';
import 'admin_requests_state.dart';

class AdminRequestsCubit extends Cubit<AdminRequestsState> {
  final AdminDashboardRepository _adminDashboardRepository;
  final PermissionRepository _permissionRepository;
  final AssignmentRepository _assignmentRepository;
  final LeavesRepository _leavesRepository;
  final OvertimeRepository _overtimeRepository;
  final ManagementRequestsRepository _managementRequestsRepository;

  AdminRequestsCubit({
    AdminDashboardRepository? adminDashboardRepository,
    PermissionRepository? permissionRepository,
    AssignmentRepository? assignmentRepository,
    LeavesRepository? leavesRepository,
    OvertimeRepository? overtimeRepository,
    ManagementRequestsRepository? managementRequestsRepository,
  }) : _adminDashboardRepository =
           adminDashboardRepository ?? getIt<AdminDashboardRepository>(),
       _permissionRepository =
           permissionRepository ?? getIt<PermissionRepository>(),
       _assignmentRepository =
           assignmentRepository ?? getIt<AssignmentRepository>(),
       _leavesRepository = leavesRepository ?? getIt<LeavesRepository>(),
       _overtimeRepository = overtimeRepository ?? getIt<OvertimeRepository>(),
       _managementRequestsRepository =
           managementRequestsRepository ??
           getIt<ManagementRequestsRepository>(),
       super(const AdminRequestsState());

  Future<void> loadRequests() async {
    if (isClosed) return;
    final authState = getIt<AuthCubit>().state;
    final canManage =
        authState.isAdmin || authState.isSuperAdmin || authState.isHR;

    if (!canManage) {
      if (isClosed) return;
      emit(
        state.copyWith(
          allRequests: const [],
          isLoading: false,
          clearError: true,
        ),
      );
      return;
    }

    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final requests = authState.isSuperAdmin
          ? await _loadSuperAdminRequests()
          : await _loadAdminRequests();

      requests.sort((a, b) => b.date.compareTo(a.date));
      if (isClosed) return;

      emit(
        state.copyWith(
          allRequests: requests,
          isLoading: false,
          clearError: true,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isLoading: false,
          error: AppException.from(e).message,
        ),
      );
    }
  }

  Future<bool> approveRequest(String requestId) {
    return _updateRequestStatus(requestId: requestId, status: 2);
  }

  Future<bool> rejectRequest(String requestId, {String? rejectReason}) {
    return _updateRequestStatus(
      requestId: requestId,
      status: 3,
      rejectionReason: rejectReason,
    );
  }

  Future<bool> _updateRequestStatus({
    required String requestId,
    required int status,
    String? rejectionReason,
  }) async {
    if (isClosed) return false;
    try {
      emit(state.copyWith(isLoading: true, clearError: true));
      final request = state.allRequests.firstWhere(
        (item) => item.id == requestId,
      );
      final parsedId = int.parse(request.id);

      switch (request.type) {
        case RequestType.leave:
          await _leavesRepository.setLeaveStatus(
            id: parsedId,
            status: status,
            rejectionReason: rejectionReason,
          );
          break;
        case RequestType.permission:
          await _permissionRepository.setPermissionStatus(
            id: parsedId,
            status: status,
            rejectionReason: rejectionReason,
          );
          break;
        case RequestType.overtime:
          await _overtimeRepository.setOvertimeStatus(
            id: parsedId,
            status: status,
            rejectionReason: rejectionReason,
          );
          break;
        case RequestType.assignment:
          await _assignmentRepository.setAssignmentStatus(
            id: parsedId,
            status: status,
            rejectionReason: rejectionReason,
          );
          break;
        case RequestType.other:
          break;
      }

      await loadRequests();
      return true;
    } catch (e) {
      if (isClosed) return false;
      emit(
        state.copyWith(
          isLoading: false,
          error: AppException.from(e).message,
        ),
      );
      return false;
    }
  }

  Future<List<RecentActivity>> _loadAdminRequests() async {
    final dashboard = await _adminDashboardRepository.getAdminDashboard();
    return _mapRequests([
      ...dashboard.adminRequests,
      ...dashboard.departmentUsersRequests,
    ]);
  }

  Future<List<RecentActivity>> _loadSuperAdminRequests() async {
    return _managementRequestsRepository.getAllRequests();
  }

  List<RecentActivity> _mapRequests(List<AdminRequest> requests) {
    final mapped = <String, RecentActivity>{};

    for (final request in requests) {
      final activity = _toRecentActivity(request);
      mapped['${request.type}_${request.id}'] = activity;
    }

    return mapped.values.toList();
  }

  RecentActivity _toRecentActivity(AdminRequest request) {
    final normalizedType = request.type.toLowerCase();

    var type = RequestType.other;
    var title = request.type;
    String? description = request.reason;

    if (normalizedType == 'leave') {
      type = RequestType.leave;
      title = 'إجازة';
      if (request.startDate != null && request.endDate != null) {
        description = 'من ${request.startDate} إلى ${request.endDate}';
      }
    } else if (normalizedType == 'permission') {
      type = RequestType.permission;
      title = 'إذن خروج';
      if (request.startTime != null && request.endTime != null) {
        description = 'من ${request.startTime} إلى ${request.endTime}';
      }
    } else if (normalizedType == 'overtime') {
      type = RequestType.overtime;
      title = 'عمل إضافي';
      if (request.startTime != null && request.endTime != null) {
        description = 'من ${request.startTime} إلى ${request.endTime}';
      }
    } else if (normalizedType == 'assignment') {
      type = RequestType.assignment;
      title = 'مأمورية';
      description = request.where ?? request.reason;
    }

    final statusText = request.status.toLowerCase();
    final status = statusText == 'approved' || statusText == 'accepted'
        ? RequestStatus.approved
        : statusText == 'rejected'
        ? RequestStatus.rejected
        : RequestStatus.pending;

    final date =
        DateTime.tryParse(
          request.date ?? request.startDate ?? request.createdAt,
        ) ??
        DateTime.now();

    return RecentActivity(
      id: request.id.toString(),
      type: type,
      status: status,
      title: title,
      date: date,
      description: description,
      userId: request.userId,
      reason: request.reason,
    );
  }
}
