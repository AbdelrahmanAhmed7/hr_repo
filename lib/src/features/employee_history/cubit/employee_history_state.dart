import '../models/employee_history_response.dart';
import '../models/employee_history_summary.dart';

enum EmployeeHistoryStatus {
  initial,
  loading,
  success,
  failure,
}

class EmployeeHistoryState {
  final EmployeeHistoryStatus status;
  final EmployeeHistorySummary? summary;
  final EmployeeHistoryResponse? historyResponse;
  final String? errorMessage;

  const EmployeeHistoryState({
    this.status = EmployeeHistoryStatus.initial,
    this.summary,
    this.historyResponse,
    this.errorMessage,
  });

  EmployeeHistoryState copyWith({
    EmployeeHistoryStatus? status,
    EmployeeHistorySummary? summary,
    EmployeeHistoryResponse? historyResponse,
    String? errorMessage,
    bool clearError = false,
  }) {
    return EmployeeHistoryState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      historyResponse: historyResponse ?? this.historyResponse,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
