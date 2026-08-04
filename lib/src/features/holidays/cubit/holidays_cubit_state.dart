part of 'holidays_cubit.dart';

abstract class HolidaysState {
  const HolidaysState();
}

class HolidaysInitial extends HolidaysState {}

class HolidaysLoading extends HolidaysState {}

class HolidaysLoaded extends HolidaysState {
  final List<PublicHolidayModel> holidays;
  final int selectedYear;

  const HolidaysLoaded({
    required this.holidays,
    required this.selectedYear,
  });
}

class HolidayActionLoading extends HolidaysState {
  final HolidaysLoaded previousState;

  const HolidayActionLoading(this.previousState);
}

class HolidayExceptionsLoading extends HolidaysState {
  final HolidaysLoaded previousState;
  final int holidayId;

  const HolidayExceptionsLoading(this.previousState, this.holidayId);
}

class HolidayExceptionsLoaded extends HolidaysState {
  final List<PublicHolidayModel> holidays;
  final int selectedYear;
  final int holidayId;
  final List<HolidayExceptionModel> exceptions;

  const HolidayExceptionsLoaded({
    required this.holidays,
    required this.selectedYear,
    required this.holidayId,
    required this.exceptions,
  });
}

class HolidaysError extends HolidaysState {
  final String message;

  const HolidaysError(this.message);
}
