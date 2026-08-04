import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/public_holiday_model.dart';
import '../models/holiday_exception_model.dart';
import '../repository/public_holiday_repository.dart';

part 'holidays_cubit_state.dart';

class HolidaysCubit extends Cubit<HolidaysState> {
  final PublicHolidayRepository _repository;

  HolidaysCubit(this._repository) : super(HolidaysInitial());

  /// Load holidays for a specific year
  Future<void> loadHolidays(int year) async {
    emit(HolidaysLoading());
    try {
      final holidays = await _repository.getHolidaysForYear(year);
      emit(HolidaysLoaded(holidays: holidays, selectedYear: year));
    } catch (e) {
      emit(HolidaysError('فشل في تحميل الإجازات: $e'));
    }
  }

  /// Load all holidays
  Future<void> loadAllHolidays() async {
    emit(HolidaysLoading());
    try {
      final holidays = await _repository.getAllHolidays();
      emit(HolidaysLoaded(holidays: holidays, selectedYear: DateTime.now().year));
    } catch (e) {
      emit(HolidaysError('فشل في تحميل الإجازات: $e'));
    }
  }

  /// Create new holiday
  Future<void> createHoliday(PublicHolidayModel holiday) async {
    final currentState = state;
    if (currentState is HolidaysLoaded) {
      emit(HolidayActionLoading(currentState));
      try {
        await _repository.createHoliday(holiday);
        await loadHolidays(currentState.selectedYear);
      } catch (e) {
        emit(HolidaysError('فشل في إنشاء الإجازة: $e'));
      }
    }
  }

  /// Update holiday
  Future<void> updateHoliday(int id, PublicHolidayModel holiday) async {
    final currentState = state;
    if (currentState is HolidaysLoaded) {
      emit(HolidayActionLoading(currentState));
      try {
        await _repository.updateHoliday(id, holiday);
        await loadHolidays(currentState.selectedYear);
      } catch (e) {
        emit(HolidaysError('فشل في تحديث الإجازة: $e'));
      }
    }
  }

  /// Delete holiday
  Future<void> deleteHoliday(int id) async {
    final currentState = state;
    if (currentState is HolidaysLoaded) {
      emit(HolidayActionLoading(currentState));
      try {
        await _repository.deleteHoliday(id);
        await loadHolidays(currentState.selectedYear);
      } catch (e) {
        emit(HolidaysError('فشل في حذف الإجازة: $e'));
      }
    }
  }

  /// Load exceptions for a holiday
  Future<void> loadHolidayExceptions(int holidayId) async {
    final currentState = state;
    if (currentState is HolidaysLoaded) {
      emit(HolidayExceptionsLoading(currentState, holidayId));
      try {
        final exceptions = await _repository.getHolidayExceptions(holidayId);
        emit(HolidayExceptionsLoaded(
          holidays: currentState.holidays,
          selectedYear: currentState.selectedYear,
          holidayId: holidayId,
          exceptions: exceptions,
        ));
      } catch (e) {
        emit(HolidaysError('فشل في تحميل الاستثناءات: $e'));
      }
    }
  }

  /// Add exception to a holiday
  Future<void> addHolidayException(int holidayId, HolidayExceptionModel exception) async {
    final currentState = state;
    if (currentState is HolidaysLoaded) {
      emit(HolidayActionLoading(currentState));
      try {
        await _repository.addHolidayException(holidayId, exception);
        await loadHolidayExceptions(holidayId);
      } catch (e) {
        emit(HolidaysError('فشل في إضافة الاستثناء: $e'));
      }
    }
  }

  /// Delete exception
  Future<void> deleteHolidayException(int exceptionId, int holidayId) async {
    final currentState = state;
    if (currentState is HolidaysLoaded) {
      emit(HolidayActionLoading(currentState));
      try {
        await _repository.deleteHolidayException(exceptionId);
        await loadHolidayExceptions(holidayId);
      } catch (e) {
        emit(HolidaysError('فشل في حذف الاستثناء: $e'));
      }
    }
  }

  /// Refresh holidays
  Future<void> refresh() async {
    final currentState = state;
    if (currentState is HolidaysLoaded) {
      await loadHolidays(currentState.selectedYear);
    } else {
      await loadAllHolidays();
    }
  }

  /// Change selected year
  Future<void> changeYear(int year) async {
    await loadHolidays(year);
  }
}
