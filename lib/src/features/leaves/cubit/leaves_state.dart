import 'package:equatable/equatable.dart';
import '../models/leave_request_model.dart';
import '../models/leave_type_model.dart';
import '../models/leave_balance_model.dart';

enum LeavesStatus { initial, loading, success, failure }
enum SubmissionStatus { initial, submitting, success, failure }

class LeavesState extends Equatable {
  final LeavesStatus status;
  final LeavesStatus leaveTypesStatus;
  final SubmissionStatus submissionStatus;
  final List<LeaveRequestModel> leaveRequests;
  final List<LeaveTypeModel> leaveTypes;
  final LeaveBalanceModel? leaveBalance;
  final String? errorMessage;
  final String? leaveTypesErrorMessage;
  final String? submissionErrorMessage;

  const LeavesState({
    this.status = LeavesStatus.initial,
    this.leaveTypesStatus = LeavesStatus.initial,
    this.submissionStatus = SubmissionStatus.initial,
    this.leaveRequests = const [],
    this.leaveTypes = const [],
    this.leaveBalance,
    this.errorMessage,
    this.leaveTypesErrorMessage,
    this.submissionErrorMessage,
  });

  LeavesState copyWith({
    LeavesStatus? status,
    LeavesStatus? leaveTypesStatus,
    SubmissionStatus? submissionStatus,
    List<LeaveRequestModel>? leaveRequests,
    List<LeaveTypeModel>? leaveTypes,
    LeaveBalanceModel? leaveBalance,
    String? errorMessage,
    String? leaveTypesErrorMessage,
    String? submissionErrorMessage,
  }) {
    return LeavesState(
      status: status ?? this.status,
      leaveTypesStatus: leaveTypesStatus ?? this.leaveTypesStatus,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      leaveRequests: leaveRequests ?? this.leaveRequests,
      leaveTypes: leaveTypes ?? this.leaveTypes,
      leaveBalance: leaveBalance ?? this.leaveBalance,
      errorMessage: errorMessage ?? this.errorMessage,
      leaveTypesErrorMessage:
          leaveTypesErrorMessage ?? this.leaveTypesErrorMessage,
      submissionErrorMessage:
          submissionErrorMessage ?? this.submissionErrorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        leaveTypesStatus,
        submissionStatus,
        leaveRequests,
        leaveTypes,
        leaveBalance,
        errorMessage,
        leaveTypesErrorMessage,
        submissionErrorMessage,
      ];
}
