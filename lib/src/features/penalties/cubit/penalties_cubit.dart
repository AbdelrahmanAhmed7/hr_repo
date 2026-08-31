import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/app_exception.dart';
import '../services/penalties_api_service.dart';
import 'penalties_state.dart';

class PenaltiesCubit extends Cubit<PenaltiesState> {
  final PenaltiesApiService _service;

  PenaltiesCubit(this._service) : super(const PenaltiesState());

  Future<void> loadTypes() async {
    if (state.typesLoaded) return;
    try {
      final types = await _service.getPenaltyTypes();
      if (!isClosed) {
        emit(state.copyWith(types: types, typesLoaded: true));
      }
    } catch (_) {}
  }

  Future<void> selectEmployee(String id, String name) async {
    emit(state.copyWith(
      selectedEmployeeId: () => id,
      selectedEmployeeName: () => name,
      penalties: const [],
      status: PenaltiesStatus.initial,
      error: () => null,
    ));
    await loadPenalties();
  }

  Future<void> loadPenalties() async {
    final userId = state.selectedEmployeeId;
    if (userId == null) return;

    emit(state.copyWith(status: PenaltiesStatus.loading));
    try {
      final penalties = await _service.getPenaltiesByUser(userId);
      if (!isClosed) {
        emit(state.copyWith(
          penalties: penalties,
          status: PenaltiesStatus.loaded,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
          status: PenaltiesStatus.failure,
          error: () => AppException.from(e).message,
        ));
      }
    }
  }

  Future<bool> savePenalty({
    int? id,
    required int penaltyType,
    required int days,
    required double amount,
    required String penaltyDate,
    required String reason,
  }) async {
    emit(state.copyWith(isSaving: true, saveError: () => null));
    try {
      final userId = state.selectedEmployeeId;
      if (id == null) {
        if (userId == null) throw Exception('لم يتم اختيار الموظف');
        await _service.createPenalty(
          userId: userId,
          penaltyType: penaltyType,
          days: days,
          amount: amount,
          penaltyDate: penaltyDate,
          reason: reason,
        );
      } else {
        await _service.updatePenalty(
          id: id,
          penaltyType: penaltyType,
          days: days,
          amount: amount,
          penaltyDate: penaltyDate,
          reason: reason,
        );
      }
      if (!isClosed) {
        emit(state.copyWith(isSaving: false));
      }
      await loadPenalties();
      return true;
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
          isSaving: false,
          saveError: () => AppException.from(e).message,
        ));
      }
      return false;
    }
  }

  void clearSaveState() {
    emit(state.copyWith(
      isSaving: false,
      saveError: () => null,
    ));
  }

  void clearError() => emit(state.copyWith(error: () => null));
}
