import 'package:equatable/equatable.dart';

import '../../hr/models/department_option.dart';

enum SendNotificationTarget { all, department, user }

enum SendNotificationStatus { idle, loading, success, failure }

enum TargetsStatus { initial, loading, success, failure }

class NotificationRecipient {
  final String id;
  final String name;

  const NotificationRecipient({required this.id, required this.name});
}

class SendNotificationState extends Equatable {
  final SendNotificationTarget target;
  final SendNotificationStatus status;
  final String? errorMessage;
  final TargetsStatus departmentsStatus;
  final TargetsStatus employeesStatus;
  final List<DepartmentOption> departments;
  final List<NotificationRecipient> employees;
  final int? selectedDepartmentId;
  final String? selectedEmployeeId;

  const SendNotificationState({
    this.target = SendNotificationTarget.all,
    this.status = SendNotificationStatus.idle,
    this.errorMessage,
    this.departmentsStatus = TargetsStatus.initial,
    this.employeesStatus = TargetsStatus.initial,
    this.departments = const [],
    this.employees = const [],
    this.selectedDepartmentId,
    this.selectedEmployeeId,
  });

  factory SendNotificationState.initial() => const SendNotificationState();

  SendNotificationState copyWith({
    SendNotificationTarget? target,
    SendNotificationStatus? status,
    String? errorMessage,
    TargetsStatus? departmentsStatus,
    TargetsStatus? employeesStatus,
    List<DepartmentOption>? departments,
    List<NotificationRecipient>? employees,
    int? Function()? selectedDepartmentId,
    String? Function()? selectedEmployeeId,
    bool clearError = false,
  }) {
    return SendNotificationState(
      target: target ?? this.target,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      departmentsStatus: departmentsStatus ?? this.departmentsStatus,
      employeesStatus: employeesStatus ?? this.employeesStatus,
      departments: departments ?? this.departments,
      employees: employees ?? this.employees,
      selectedDepartmentId: selectedDepartmentId != null
          ? selectedDepartmentId()
          : this.selectedDepartmentId,
      selectedEmployeeId: selectedEmployeeId != null
          ? selectedEmployeeId()
          : this.selectedEmployeeId,
    );
  }

  @override
  List<Object?> get props => [
    target,
    status,
    errorMessage,
    departmentsStatus,
    employeesStatus,
    departments,
    employees,
    selectedDepartmentId,
    selectedEmployeeId,
  ];
}