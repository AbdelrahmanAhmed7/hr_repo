import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../models/department_option.dart';
import '../models/employee.dart';
import '../models/employees_page_response.dart';
import '../models/employee_upsert_request.dart';
import '../models/employee_payslip.dart';
import '../models/job_title_option.dart';
import '../models/salary_calculation.dart';

class EmployeesApiService {
  final DioClient _dioClient;

  EmployeesApiService(this._dioClient);

  Future<List<DepartmentOption>> getDepartments({
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    final departments = <DepartmentOption>[];
    var currentPage = pageNumber;
    var totalPages = 1;

    do {
      final response = await _dioClient.dio.get(
        '/api/Department',
        queryParameters: {'pageNumber': currentPage, 'pageSize': pageSize},
      );

      final data = _asMap(response.data);
      final items = (data['items'] as List<dynamic>? ?? const [])
          .map(
            (item) => DepartmentOption.fromJson(item as Map<String, dynamic>),
          )
          .toList();

      departments.addAll(items);
      totalPages = data['totalPages'] as int? ?? 1;
      currentPage++;
    } while (currentPage <= totalPages);

    return departments;
  }

  Future<List<JobTitleOption>> getJobTitles() async {
    final response = await _dioClient.dio.get('/api/JobTitle');
    final rawList = _asList(response.data);
    final items = (rawList)
        .map((item) => JobTitleOption.fromJson(item as Map<String, dynamic>))
        .toList();
    return items;
  }

  Future<EmployeesPageResponse> getEmployees({
    int pageNumber = 1,
    int pageSize = 10,
    String? search,
    int? departmentId,
    int? branchId,
    int? jobId,
    bool? isActive,
  }) async {
    final queryParameters = <String, dynamic>{
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      'departmentId': ?departmentId,
      'branchId': ?branchId,
      'jobId': ?jobId,
      'isActive': ?isActive,
    };

    final response = await _dioClient.dio.get(
      '/api/Auth/users',
      queryParameters: queryParameters,
    );

    return EmployeesPageResponse.fromJson(_asMap(response.data));
  }

  Future<Employee> getEmployeeDetails(String id) async {
    final response = await _dioClient.dio.get('/api/Auth/employee/$id');
    return Employee.fromEmployeeDetailsApiJson(_asMap(response.data));
  }

  /// GET /api/Attendance/calculate-salary/{id}?month={month}&year={year}
  Future<SalaryCalculation> calculateSalary({
    required String employeeId,
    required int month,
    required int year,
  }) async {
    final response = await _dioClient.dio.get(
      '/api/Attendance/calculate-salary/$employeeId',
      queryParameters: {'month': month, 'year': year},
    );
    return SalaryCalculation.fromJson(_asMap(response.data));
  }

  /// GET /api/Payslip/employee/{id}?month={month}&year={year}
  Future<EmployeePayslip> getPayslip({
    required String employeeId,
    required int month,
    required int year,
  }) async {
    final response = await _dioClient.dio.get(
      '/api/Payslip/employee/$employeeId',
      queryParameters: {'month': month, 'year': year},
    );
    return EmployeePayslip.fromJson(_asMap(response.data));
  }

  Future<void> createEmployee(EmployeeUpsertRequest request) async {
    final formData = FormData.fromMap(request.toFormMap());
    await _dioClient.dio.post('/api/Auth/addemployee', data: formData);
  }

  Future<Employee> updateEmployee({
    required String id,
    required EmployeeUpsertRequest request,
  }) async {
    final formData = FormData.fromMap(request.toFormMap());
    final response = await _dioClient.dio.put(
      '/api/Auth/employee/$id',
      data: formData,
    );

    return Employee.fromEmployeeDetailsApiJson(_asMap(response.data));
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    throw const FormatException('Invalid response format');
  }

  List<dynamic> _asList(dynamic data) {
    if (data is List) return data;
    if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is List) return decoded;
    }
    return const [];
  }
}
