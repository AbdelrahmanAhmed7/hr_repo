import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/app_exception.dart';
import '../repository/super_admin_dashboard_repository.dart';
import 'super_admin_dashboard_state.dart';

class SuperAdminDashboardCubit extends Cubit<SuperAdminDashboardState> {
  final SuperAdminDashboardRepository _repository;

  SuperAdminDashboardCubit(this._repository) : super(SuperAdminDashboardState.initial());

  Future<void> loadDashboard() async {
    // Show cached data immediately if available
    final cached = _repository.cachedData;
    if (cached != null) {
      emit(state.copyWith(isLoading: false, data: cached));
      return;
    }

    emit(state.copyWith(isLoading: true, error: null));
    try {
      final data = await _repository.getSuperAdminDashboard();
      emit(state.copyWith(isLoading: false, data: data));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: AppException.from(e).message));
    }
  }

  Future<void> refresh() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final data = await _repository.getSuperAdminDashboard(forceRefresh: true);
      emit(state.copyWith(isLoading: false, data: data));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: AppException.from(e).message));
    }
  }
}
