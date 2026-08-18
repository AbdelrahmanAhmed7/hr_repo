import 'package:flutter_bloc/flutter_bloc.dart';

import '../../hr/repository/employees_repository.dart';
import '../repository/sa_attendance_repository.dart';
import 'punch_pairs_state.dart';

class PunchPairsCubit extends Cubit<PunchPairsState> {
  final SAAttendanceRepository _repository;
  final EmployeesRepository _employeesRepository;

  PunchPairsCubit(this._repository, this._employeesRepository)
      : super(PunchPairsState.initial());

  /// Load the employee list for the dropdown (runs once)
  Future<void> loadEmployeeOptions() async {
    emit(state.copyWith(isLoadingEmployees: true));
    try {
      // Fetch all employees (up to 500) to populate dropdown
      var page = 1;
      const pageSize = 100;
      int totalPages = 1;
      final allOptions = <EmployeeOption>[];

      do {
        final response = await _employeesRepository.getEmployees(
          pageNumber: page,
          pageSize: pageSize,
          isActive: true,
        );
        totalPages = response.totalPages;
        for (final emp in response.items) {
          allOptions.add(
            EmployeeOption(userId: emp.id, name: emp.fullName),
          );
        }
        page++;
      } while (page <= totalPages && allOptions.length < 500);

      // Sort alphabetically
      allOptions.sort((a, b) => a.name.compareTo(b.name));

      emit(state.copyWith(employeeOptions: allOptions, isLoadingEmployees: false));
    } catch (_) {
      emit(state.copyWith(isLoadingEmployees: false));
    }
  }

  /// Load first page (called on init and filter changes)
  Future<void> load({int page = 1}) async {
    emit(state.copyWith(status: PunchPairsStatus.loading, pageNumber: page, clearError: true));
    try {
      final response = await _repository.getPunchPairs(
        userId: state.selectedUserId,
        from: state.fromDate,
        to: state.toDate,
        page: page,
        pageSize: state.pageSize,
      );
      emit(state.copyWith(
        status: PunchPairsStatus.success,
        items: response.items,
        pageNumber: response.pageNumber,
        pageSize: response.pageSize,
        totalCount: response.totalCount,
        totalPages: response.totalPages,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PunchPairsStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  void selectEmployee(String? userId, String? name) {
    emit(state.copyWith(
      selectedUserId: userId,
      selectedEmployeeName: name,
      clearUserId: userId == null,
    ));
    load();
  }

  void setFromDate(DateTime? date) {
    emit(state.copyWith(fromDate: date, clearFromDate: date == null));
    load();
  }

  void setToDate(DateTime? date) {
    emit(state.copyWith(toDate: date, clearToDate: date == null));
    load();
  }

  void clearFilters() {
    emit(state.copyWith(
      clearUserId: true,
      clearFromDate: true,
      clearToDate: true,
    ));
    load();
  }

  void goToPage(int page) {
    if (page < 1 || page > state.totalPages) return;
    load(page: page);
  }

  void nextPage() => goToPage(state.pageNumber + 1);
  void prevPage() => goToPage(state.pageNumber - 1);
}
