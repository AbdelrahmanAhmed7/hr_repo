import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/app_exception.dart';
import '../services/bonuses_api_service.dart';
import 'bonuses_state.dart';

class BonusesCubit extends Cubit<BonusesState> {
  final BonusesApiService _service;

  BonusesCubit(this._service) : super(const BonusesState());

  Future<void> selectEmployee(String id, String name) async {
    emit(state.copyWith(
      selectedEmployeeId: () => id,
      selectedEmployeeName: () => name,
      bonuses: const [],
      status: BonusesStatus.initial,
      error: () => null,
    ));
    await loadBonuses();
  }

  Future<void> loadBonuses() async {
    final userId = state.selectedEmployeeId;
    if (userId == null) return;

    emit(state.copyWith(status: BonusesStatus.loading));
    try {
      final bonuses = await _service.getBonusesByUser(userId);
      if (!isClosed) {
        emit(state.copyWith(
          bonuses: bonuses,
          status: BonusesStatus.loaded,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
          status: BonusesStatus.failure,
          error: () => AppException.from(e).message,
        ));
      }
    }
  }

  Future<bool> saveBonus({
    int? id,
    required double amount,
    required String bonusDate,
    required String reason,
  }) async {
    emit(state.copyWith(isSaving: true, saveError: () => null));
    try {
      final userId = state.selectedEmployeeId;
      if (id == null) {
        if (userId == null) throw Exception('لم يتم اختيار الموظف');
        await _service.createBonus(
          userId: userId,
          amount: amount,
          bonusDate: bonusDate,
          reason: reason,
        );
      } else {
        await _service.updateBonus(
          id: id,
          amount: amount,
          bonusDate: bonusDate,
          reason: reason,
        );
      }
      if (!isClosed) {
        emit(state.copyWith(isSaving: false));
      }
      await loadBonuses();
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
