import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/app_exception.dart';
import '../repository/admin_dashboard_repository.dart';
import 'admin_dashboard_state.dart';

class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  final AdminDashboardRepository _repository;

  AdminDashboardCubit(this._repository) : super(AdminDashboardState.initial());

  Future<void> loadDashboard() async {
    // If we have cached data, emit it immediately without showing loading
    final cached = _repository.cachedData;
    if (cached != null) {
      emit(state.copyWith(isLoading: false, data: cached));
      return;
    }

    emit(state.copyWith(isLoading: true, error: null));
    try {
      final data = await _repository.getAdminDashboard();
      emit(state.copyWith(isLoading: false, data: data));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: AppException.from(e).message));
    }
  }

  Future<void> refresh() async {
    // Force refresh - bypass cache
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final data = await _repository.getAdminDashboard(forceRefresh: true);
      emit(state.copyWith(isLoading: false, data: data));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: AppException.from(e).message));
    }
  }
}
