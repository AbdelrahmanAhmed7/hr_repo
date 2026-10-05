import 'package:flutter_test/flutter_test.dart';
import 'package:mediconsult_internal/src/features/admin/department_requests/cubit/department_requests_state.dart';
import 'package:mediconsult_internal/src/features/admin/department_requests/models/department_requests_response.dart';

const _pendingLeave = EmployeeLeave(
  id: 1,
  statusText: 'pending',
  leaveType: 'annual',
  startDate: '2026/10/01',
  endDate: '2026/10/02',
);

const _approvedLeave = EmployeeLeave(
  id: 2,
  statusText: 'approved',
  leaveType: 'sick',
  startDate: '2026/10/03',
  endDate: '2026/10/03',
);

const _rejectedPermission = EmployeePermission(
  id: 3,
  statusText: 'rejected',
  date: '2026/10/04',
);

const _ahmed = DepartmentEmployee(
  userId: 'u1',
  employeeName: 'أحمد محمد',
  leaves: [_pendingLeave, _approvedLeave],
  permissions: [],
  assignments: [],
  totalRequests: 2,
);

const _mona = DepartmentEmployee(
  userId: 'u2',
  employeeName: 'منى علي',
  leaves: [],
  permissions: [_rejectedPermission],
  assignments: [],
  totalRequests: 1,
);

const _dept = DepartmentRequestsItem(
  departmentId: 1,
  departmentName: 'تقنية المعلومات',
  employees: [_ahmed, _mona],
  totalRequests: 3,
);

DepartmentRequestsState _state({
  DeptRequestStatus? statusFilter,
  String searchQuery = '',
}) =>
    DepartmentRequestsState(
      status: DepartmentRequestsStatus.success,
      departments: const [_dept],
      selectedYear: 2026,
      statusFilter: statusFilter,
      searchQuery: searchQuery,
    );

void main() {
  group('DepartmentRequestsState.visibleDepartments', () {
    test('no filters returns everything', () {
      final visible = _state().visibleDepartments;

      expect(visible, hasLength(1));
      expect(visible.single.employees, hasLength(2));
      expect(_state().visibleTotalRequests, 3);
    });

    test('status filter keeps only matching requests', () {
      final visible =
          _state(statusFilter: DeptRequestStatus.pending).visibleDepartments;

      expect(visible, hasLength(1));
      expect(visible.single.employees, hasLength(1));
      expect(visible.single.employees.single.employeeName, 'أحمد محمد');
      expect(visible.single.totalRequests, 1);
    });

    test('status filter with no matches hides the department', () {
      final state = DepartmentRequestsState(
        status: DepartmentRequestsStatus.success,
        departments: const [
          DepartmentRequestsItem(
            departmentId: 2,
            departmentName: 'المالية',
            employees: [_mona],
            totalRequests: 1,
          ),
        ],
        selectedYear: 2026,
        statusFilter: DeptRequestStatus.approved,
      );

      expect(state.visibleDepartments, isEmpty);
      expect(state.visibleTotalRequests, 0);
    });

    test('search matches employee name', () {
      final visible = _state(searchQuery: 'منى').visibleDepartments;

      expect(visible, hasLength(1));
      expect(visible.single.employees, hasLength(1));
      expect(visible.single.employees.single.employeeName, 'منى علي');
    });

    test('search with no matches returns empty', () {
      expect(_state(searchQuery: 'zzz').visibleDepartments, isEmpty);
    });

    test('copyWith clearStatusFilter resets the filter', () {
      const state = DepartmentRequestsState(selectedYear: 2026);

      final filtered = state.copyWith(
        statusFilter: DeptRequestStatus.pending,
      );
      expect(filtered.statusFilter, DeptRequestStatus.pending);

      final cleared = filtered.copyWith(clearStatusFilter: true);
      expect(cleared.statusFilter, isNull);
      expect(cleared.hasActiveFilters, isFalse);
    });
  });
}
