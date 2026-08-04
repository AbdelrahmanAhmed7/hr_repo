import 'package:flutter_bloc/flutter_bloc.dart';

import '../repository/overtime_repository.dart';
import 'overtime_state.dart';

class OvertimeCubit extends Cubit<OvertimeState> {
  final OvertimeRepository _overtimeRepository;

  OvertimeCubit(this._overtimeRepository) : super(const OvertimeState());

  Future<void> loadData() async {
    if (isClosed) return;
    emit(
      state.copyWith(
        loadStatus: OvertimeLoadStatus.loading,
        errorMessage: null,
      ),
    );

    try {
      final requests = await _overtimeRepository.getMyOvertimeRequests();
      if (isClosed) return;

      emit(
        state.copyWith(
          loadStatus: OvertimeLoadStatus.success,
          requests: requests,
          errorMessage: null,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          loadStatus: OvertimeLoadStatus.failure,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> refresh() async {
    await loadData();
  }

  void setFilter(String value) {
    if (isClosed) return;
    emit(state.copyWith(selectedFilter: value));
  }

  void clearSubmissionState() {
    if (isClosed) return;
    emit(
      state.copyWith(
        submissionStatus: OvertimeSubmissionStatus.initial,
        submissionErrorMessage: null,
      ),
    );
  }

  Future<void> createOvertime({
    required DateTime date,
    required String startTime,
    required String endTime,
    required String reason,
  }) async {
    if (isClosed) return;
    emit(
      state.copyWith(
        submissionStatus: OvertimeSubmissionStatus.submitting,
        submissionErrorMessage: null,
      ),
    );

    try {
      await _overtimeRepository.createOvertime(
        date: date,
        startTime: startTime,
        endTime: endTime,
        reason: reason,
      );
      if (isClosed) return;

      emit(
        state.copyWith(
          submissionStatus: OvertimeSubmissionStatus.success,
          submissionErrorMessage: null,
        ),
      );

      await loadData();
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          submissionStatus: OvertimeSubmissionStatus.failure,
          submissionErrorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }
}
