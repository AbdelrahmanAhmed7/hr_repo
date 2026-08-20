import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/app_exception.dart';
import '../../hr/repository/employees_repository.dart';
import '../repository/notifications_repository.dart';
import 'send_notification_state.dart';

class SendNotificationCubit extends Cubit<SendNotificationState> {
  final NotificationsRepository _notificationsRepository;
  final EmployeesRepository _employeesRepository;

  /// targetType values used by the broadcast API.
  /// ⚠️ Verify these against the backend enum (assumed: 1 = All, 2 = Department).
  static const int targetTypeAll = 1;
  static const int targetTypeDepartment = 2;

  SendNotificationCubit(
    this._notificationsRepository,
    this._employeesRepository,
  ) : super(SendNotificationState.initial());

  Future<void> loadTargets() async {
    if (isClosed) return;
    emit(state.copyWith(
      departmentsStatus: TargetsStatus.loading,
      employeesStatus: TargetsStatus.loading,
      clearError: true,
    ));

    await Future.wait([_loadDepartments(), _loadEmployees()]);
  }

  Future<void> _loadDepartments() async {
    try {
      final departments = await _employeesRepository.getDepartments(
        pageNumber: 1,
        pageSize: 50,
      );
      if (isClosed) return;
      emit(state.copyWith(
        departments: departments,
        departmentsStatus: TargetsStatus.success,
      ));
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(departmentsStatus: TargetsStatus.failure));
    }
  }

  Future<void> _loadEmployees() async {
    try {
      var page = 1;
      const pageSize = 100;
      var totalPages = 1;
      final recipients = <NotificationRecipient>[];

      do {
        final response = await _employeesRepository.getEmployees(
          pageNumber: page,
          pageSize: pageSize,
          isActive: true,
        );
        totalPages = response.totalPages;
        for (final employee in response.items) {
          recipients.add(
            NotificationRecipient(id: employee.id, name: employee.fullName),
          );
        }
        page++;
      } while (page <= totalPages && recipients.length < 500);

      recipients.sort((a, b) => a.name.compareTo(b.name));

      if (isClosed) return;
      emit(state.copyWith(
        employees: recipients,
        employeesStatus: TargetsStatus.success,
      ));
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(employeesStatus: TargetsStatus.failure));
    }
  }

  void setTarget(SendNotificationTarget target) {
    if (isClosed) return;
    emit(state.copyWith(target: target, clearError: true));
  }

  void selectDepartment(int? id) {
    if (isClosed) return;
    emit(state.copyWith(
      selectedDepartmentId: () => id,
      clearError: true,
    ));
  }

  void selectEmployee(String? id) {
    if (isClosed) return;
    emit(state.copyWith(
      selectedEmployeeId: () => id,
      clearError: true,
    ));
  }

  Future<bool> send({
    required String title,
    required String message,
  }) async {
    if (isClosed) return false;

    final state = this.state;

    if (state.target == SendNotificationTarget.department &&
        state.selectedDepartmentId == null) {
      emit(state.copyWith(
        status: SendNotificationStatus.failure,
        errorMessage: 'اختر القسم المستهدف أولاً.',
      ));
      return false;
    }

    if (state.target == SendNotificationTarget.user &&
        state.selectedEmployeeId == null) {
      emit(state.copyWith(
        status: SendNotificationStatus.failure,
        errorMessage: 'اختر الموظف المستهدف أولاً.',
      ));
      return false;
    }

    emit(state.copyWith(
      status: SendNotificationStatus.loading,
      clearError: true,
    ));

    try {
      switch (state.target) {
        case SendNotificationTarget.all:
          await _notificationsRepository.sendBroadcastNotification(
            targetType: targetTypeAll,
            title: title,
            message: message,
          );
        case SendNotificationTarget.department:
          await _notificationsRepository.sendBroadcastNotification(
            targetType: targetTypeDepartment,
            targetDepartmentId: state.selectedDepartmentId,
            title: title,
            message: message,
          );
        case SendNotificationTarget.user:
          await _notificationsRepository.sendDirectNotification(
            recipientUserId: state.selectedEmployeeId!,
            title: title,
            message: message,
          );
      }

      if (isClosed) return false;
      emit(state.copyWith(
        status: SendNotificationStatus.success,
        clearError: true,
      ));
      return true;
    } catch (e) {
      if (isClosed) return false;
      final error =
          AppException.from(e, fallbackMessage: 'تعذر إرسال الإشعار.');
      emit(state.copyWith(
        status: SendNotificationStatus.failure,
        errorMessage: error.message,
      ));
      return false;
    }
  }
}