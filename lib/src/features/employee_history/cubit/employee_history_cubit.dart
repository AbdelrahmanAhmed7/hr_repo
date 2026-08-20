import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/app_exception.dart';

import '../models/employee_history_response.dart';
import '../models/employee_history_summary.dart';
import '../repository/employee_history_repository.dart';
import 'employee_history_state.dart';

class EmployeeHistoryCubit extends Cubit<EmployeeHistoryState> {
  final EmployeeHistoryRepository _repository;

  EmployeeHistoryCubit(this._repository) : super(const EmployeeHistoryState());

  Future<void> load() async {
    emit(
      state.copyWith(
        status: EmployeeHistoryStatus.loading,
        clearError: true,
      ),
    );

    try {
      final results = await Future.wait<dynamic>([
        _repository.getMySummary(),
        _repository.getMyHistory(),
      ]);

      final summary = results[0] as EmployeeHistorySummary;
      final history = results[1] as EmployeeHistoryResponse;

      emit(
        state.copyWith(
          status: EmployeeHistoryStatus.success,
          summary: summary,
          historyResponse: history,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: EmployeeHistoryStatus.failure,
          errorMessage: AppException.from(e).message,
        ),
      );
    }
  }
}
