import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/service_locator.dart';
import '../../../../core/utils/app_exception.dart';
import '../../../../shared/components/custom_toast.dart';
import '../../../leaves/repository/leaves_repository.dart';
import '../../../missions/repository/assignment_repository.dart';
import '../../../permissions/repository/permission_repository.dart';
import '../department_requests_service.dart';
import 'department_requests_state.dart';

enum DeptRequestKind { leave, permission, assignment }

class DepartmentRequestsCubit extends Cubit<DepartmentRequestsState> {
  final DepartmentRequestsService _service;
  final LeavesRepository _leavesRepository;
  final PermissionRepository _permissionRepository;
  final AssignmentRepository _assignmentRepository;

  DepartmentRequestsCubit({
    DepartmentRequestsService? service,
    LeavesRepository? leavesRepository,
    PermissionRepository? permissionRepository,
    AssignmentRepository? assignmentRepository,
  })  : _service = service ?? getIt<DepartmentRequestsService>(),
        _leavesRepository = leavesRepository ?? getIt<LeavesRepository>(),
        _permissionRepository =
            permissionRepository ?? getIt<PermissionRepository>(),
        _assignmentRepository =
            assignmentRepository ?? getIt<AssignmentRepository>(),
        super(DepartmentRequestsState(selectedYear: DateTime.now().year));

  Future<void> load() async {
    if (isClosed) return;
    emit(
      state.copyWith(
        status: DepartmentRequestsStatus.loading,
        errorMessage: null,
      ),
    );

    try {
      final departments = await _service.getDepartmentRequests(
        month: state.selectedMonth == 0 ? null : state.selectedMonth,
        year: state.selectedYear,
      );

      if (isClosed) return;
      emit(
        state.copyWith(
          status: DepartmentRequestsStatus.success,
          departments: departments,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: DepartmentRequestsStatus.error,
          errorMessage: AppException.from(e).message,
        ),
      );
    }
  }

  Future<void> changeMonth(int? month) async {
    if (isClosed) return;
    emit(state.copyWith(selectedMonth: month ?? 0));
    await load();
  }

  Future<void> changeYear(int year) async {
    if (isClosed) return;
    emit(state.copyWith(selectedYear: year));
    await load();
  }

  Future<void> refresh() => load();

  /// status: 1 = pending, 2 = approved, 3 = rejected (same as AdminRequestsCubit).
  Future<bool> updateRequestStatus({
    required DeptRequestKind kind,
    required int id,
    required int status,
    String? rejectionReason,
  }) async {
    final key = requestKey(kind, id);
    if (isClosed || state.updatingRequestKey != null) return false;

    emit(state.copyWith(updatingRequestKey: key, errorMessage: null));

    try {
      switch (kind) {
        case DeptRequestKind.leave:
          await _leavesRepository.setLeaveStatus(
            id: id,
            status: status,
            rejectionReason: rejectionReason,
          );
          break;
        case DeptRequestKind.permission:
          await _permissionRepository.setPermissionStatus(
            id: id,
            status: status,
            rejectionReason: rejectionReason,
          );
          break;
        case DeptRequestKind.assignment:
          await _assignmentRepository.setAssignmentStatus(
            id: id,
            status: status,
            rejectionReason: rejectionReason,
          );
          break;
      }

      if (isClosed) return true;
      emit(state.copyWith(clearUpdatingKey: true));
      await load();
      return true;
    } catch (e) {
      if (isClosed) return false;
      emit(state.copyWith(clearUpdatingKey: true));
      CustomToast.showError(AppException.from(e).message);
      return false;
    }
  }
}

String requestKey(DeptRequestKind kind, int id) => '${kind.name}_$id';
