import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/app_exception.dart';
import '../models/hr_home_response.dart';
import 'hr_home_state.dart';
import '../models/employees_page_response.dart';
import '../repository/employees_repository.dart';
import '../repository/hr_home_repository.dart';

class HrHomeCubit extends Cubit<HrHomeState> {
  final HrHomeRepository _repository;
  final EmployeesRepository _employeesRepository;

  HrHomeCubit(this._repository, this._employeesRepository)
      : super(HrHomeState.initial()) {
    loadHrHomeData();
  }

  Future<void> loadHrHomeData() async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final results = await Future.wait<dynamic>([
        _repository.getHrHomeData(),
        _employeesRepository.getEmployees(pageNumber: 1, pageSize: 5),
      ]);

      final data = results[0] as HrHomeResponse;
      final employeesPage = results[1] as EmployeesPageResponse;
      emit(
        state.copyWith(
          isLoading: false,
          data: data,
          featuredEmployees: employeesPage.items,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: AppException.from(e).message));
    }
  }

  Future<void> refresh() async {
    await loadHrHomeData();
  }
}
