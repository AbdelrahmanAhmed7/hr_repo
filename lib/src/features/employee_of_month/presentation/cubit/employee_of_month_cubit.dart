import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/app_exception.dart';
import '../../domain/repositories/employee_of_month_repository.dart';
import 'employee_of_month_state.dart';

// ─── Employee Cubit ───────────────────────────────────────────────────────────

class EmployeeOfMonthCubit extends Cubit<EmployeeOfMonthState> {
  final EmployeeOfMonthRepository _repository;

  EmployeeOfMonthCubit(this._repository)
    : super(EmployeeOfMonthState.initial());

  /// Previous month helper — handles January → December of previous year.
  static ({int month, int year}) _prevMonth(int month, int year) {
    if (month == 1) return (month: 12, year: year - 1);
    return (month: month - 1, year: year);
  }

  /// Load nominees, current-month vote status, and previous-month winners in
  /// parallel.
  Future<void> loadData() async {
    if (isClosed) return;
    emit(
      state.copyWith(status: EmployeeOfMonthStatus.loading, clearError: true),
    );

    final now = DateTime.now();
    final month = now.month;
    final year = now.year;
    final prev = _prevMonth(month, year);

    try {
      final results = await Future.wait([
        _repository.getNominees(),
        _repository.getMyVote(month: month, year: year),
        _repository.getWinners(month: prev.month, year: prev.year),
      ]);

      if (isClosed) return;

      final nominees = results[0] as dynamic;
      final myVote = results[1] as dynamic;
      final winners = results[2] as dynamic;

      emit(
        state.copyWith(
          status: EmployeeOfMonthStatus.success,
          nominees: nominees,
          winners: winners,
          hasVoted: myVote.hasVoted as bool,
          votedForUserId: myVote.nomineeUserId as String?,
          votedForName: myVote.nomineeName as String?,
          currentMonth: month,
          currentYear: year,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      final error = AppException.from(e, fallbackMessage: 'تعذر تحميل بيانات الموظف الشهري.');
      emit(
        state.copyWith(
          status: EmployeeOfMonthStatus.error,
          errorMessage: error.message,
        ),
      );
    }
  }

  /// Submit a vote and update state directly without reloading all data.
  Future<void> vote(String nomineeUserId) async {
    if (isClosed) return;
    emit(state.copyWith(voteStatus: VoteStatus.loading, clearError: true));

    try {
      await _repository.vote(
        nomineeUserId: nomineeUserId,
        month: state.currentMonth,
        year: state.currentYear,
      );

      if (isClosed) return;

      // Find the voted nominee name from the loaded list.
      final nominee = state.nominees.firstWhere(
        (n) => n.userId == nomineeUserId,
        orElse: () => state.nominees.first,
      );

      emit(
        state.copyWith(
          voteStatus: VoteStatus.success,
          hasVoted: true,
          votedForUserId: nomineeUserId,
          votedForName: nominee.fullNameAr,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      final error = AppException.from(e, fallbackMessage: 'تعذر إرسال التصويت.');
      emit(
        state.copyWith(
          voteStatus: VoteStatus.error,
          errorMessage: error.message,
        ),
      );
    }
  }
}

// ─── Super Admin Cubit ────────────────────────────────────────────────────────

class SuperAdminEmployeeOfMonthCubit
    extends Cubit<SuperAdminEmployeeOfMonthState> {
  final EmployeeOfMonthRepository _repository;

  SuperAdminEmployeeOfMonthCubit(this._repository)
    : super(SuperAdminEmployeeOfMonthState.initial());

  /// Load winners for the currently selected month/year.
  Future<void> loadWinners() async {
    if (isClosed) return;
    emit(
      state.copyWith(status: EmployeeOfMonthStatus.loading, clearError: true),
    );

    try {
      final winners = await _repository.getWinners(
        month: state.selectedMonth,
        year: state.selectedYear,
      );
      if (isClosed) return;
      emit(
        state.copyWith(status: EmployeeOfMonthStatus.success, winners: winners),
      );
    } catch (e) {
      if (isClosed) return;
      final error = AppException.from(e, fallbackMessage: 'تعذر تحميل الفائزين.');
      emit(
        state.copyWith(
          status: EmployeeOfMonthStatus.error,
          errorMessage: error.message,
        ),
      );
    }
  }

  /// Trigger winner calculation on the server, then reload winners.
  Future<void> calculateWinners() async {
    if (isClosed) return;
    emit(state.copyWith(calculateStatus: CalculateStatus.loading));

    try {
      await _repository.calculateWinners(
        month: state.selectedMonth,
        year: state.selectedYear,
      );
      if (isClosed) return;
      emit(state.copyWith(calculateStatus: CalculateStatus.success));
      await loadWinners();
    } catch (e) {
      if (isClosed) return;
      // The server rejects calculation when no votes exist for the month.
      final error = AppException.from(e, fallbackMessage: 'تعذر احتساب الفائزين.');
      final message =
          error.message.contains('No votes found')
              ? 'لا توجد أصوات لهذا الشهر حتى الآن.'
              : error.message;
      emit(
        state.copyWith(
          calculateStatus: CalculateStatus.error,
          errorMessage: message,
        ),
      );
    }
  }

  /// Change the selected month/year and reload winners.
  Future<void> changeMonth(int month, int year) async {
    if (isClosed) return;
    emit(state.copyWith(selectedMonth: month, selectedYear: year));
    await loadWinners();
  }
}
