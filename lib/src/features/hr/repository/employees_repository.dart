import '../models/department_option.dart';
import '../models/employee.dart';
import '../models/employees_page_response.dart';
import '../models/employee_upsert_request.dart';
import '../models/job_title_option.dart';
import '../services/employees_api_service.dart';

class EmployeesRepository {
  final EmployeesApiService _service;

  EmployeesRepository(this._service);

  Future<List<DepartmentOption>> getDepartments({
    int pageNumber = 1,
    int pageSize = 10,
  }) {
    return _service.getDepartments(pageNumber: pageNumber, pageSize: pageSize);
  }

  Future<List<JobTitleOption>> getJobTitles() {
    return _service.getJobTitles();
  }

  Future<EmployeesPageResponse> getEmployees({
    int pageNumber = 1,
    int pageSize = 10,
    String? search,
    int? departmentId,
    int? branchId,
    int? jobId,
    bool? isActive,
  }) {
    return _service.getEmployees(
      pageNumber: pageNumber,
      pageSize: pageSize,
      search: search,
      departmentId: departmentId,
      branchId: branchId,
      jobId: jobId,
      isActive: isActive,
    );
  }

  Future<Employee> getEmployeeDetails(String id) {
    return _service.getEmployeeDetails(id);
  }

  Future<void> createEmployee(EmployeeUpsertRequest request) {
    return _service.createEmployee(request);
  }

  Future<Employee> updateEmployee({
    required String id,
    required EmployeeUpsertRequest request,
  }) {
    return _service.updateEmployee(id: id, request: request);
  }
}
