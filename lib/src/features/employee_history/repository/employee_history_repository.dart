import '../models/employee_history_response.dart';
import '../models/employee_history_summary.dart';
import '../services/employee_history_service.dart';

class EmployeeHistoryRepository {
  final EmployeeHistoryService _service;

  EmployeeHistoryRepository(this._service);

  Future<EmployeeHistorySummary> getMySummary() {
    return _service.getMySummary();
  }

  Future<EmployeeHistoryResponse> getMyHistory({
    int pageNumber = 1,
    int pageSize = 50,
  }) {
    return _service.getMyHistory(
      pageNumber: pageNumber,
      pageSize: pageSize,
    );
  }
}
