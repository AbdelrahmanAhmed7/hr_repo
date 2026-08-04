import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/attendance_handler.dart';
import '../auth/cubit/auth_cubit.dart';
import 'all_attendance_records_screen.dart';
import 'cubit/attendance_cubit.dart';
import 'models/attendance_list_response.dart';
import 'models/daily_attendance_record.dart';
import 'widgets/sections/attendance_scope_switcher.dart';

class AttendanceScreenController extends ChangeNotifier {
  bool isProcessingAttendance = false;
  DateTime selectedDate = DateTime.now();
  AttendancePeriodScope selectedScope = AttendancePeriodScope.month;

  bool isToday() {
    final now = DateTime.now();
    return selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
  }

  void setScope(AttendancePeriodScope scope) {
    selectedScope = scope;
    notifyListeners();
  }

  void initialize(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<AttendanceCubit>();

      cubit.loadAttendanceByDate(selectedDate);
    });
  }

  Future<void> refresh(BuildContext context, {required bool mounted}) async {
    final attendanceCubit = context.read<AttendanceCubit>();

    await attendanceCubit.loadAttendanceByDate(selectedDate);
    if (!mounted) return;
  }

  void onDateChanged(BuildContext context, DateTime newDate) {
    selectedDate = newDate;
    notifyListeners();

    context.read<AttendanceCubit>().loadAttendanceByDate(newDate);
  }

  void openAttendanceHistory(BuildContext context) {
    final monthlyData = context.read<AttendanceCubit>().state.monthlyData;
    if (monthlyData == null || monthlyData.attendances.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AllAttendanceRecordsScreen(
          records: mapAttendanceItems(monthlyData.attendances),
          initialDate: selectedDate,
        ),
      ),
    );
  }

  Future<void> handleCheckIn(
    BuildContext context, {
    required bool mounted,
  }) async {
    if (!mounted || isProcessingAttendance) return;
    isProcessingAttendance = true;
    notifyListeners();

    try {
      final attendanceCubit = context.read<AttendanceCubit>();
      final authCubit = context.read<AuthCubit>();
      final userId = authCubit.state.userId;

      await AttendanceHandler.handleAttendance(
        context: context,
        isCheckIn: true,
        onSuccess:
            (isCheckIn, location, {String authMethod = 'fallback'}) async {
              if (!mounted || location == null) return;
              await attendanceCubit.checkIn(
                userId: userId,
                latitude: location.latitude,
                longitude: location.longitude,
              );
            },
      );
    } finally {
      if (mounted) {
        isProcessingAttendance = false;
        notifyListeners();
      }
    }
  }

  Future<void> handleCheckOut(
    BuildContext context, {
    required bool mounted,
  }) async {
    if (!mounted || isProcessingAttendance) return;
    isProcessingAttendance = true;
    notifyListeners();

    try {
      final attendanceCubit = context.read<AttendanceCubit>();
      final authCubit = context.read<AuthCubit>();
      final userId = authCubit.state.userId;

      await AttendanceHandler.handleAttendance(
        context: context,
        isCheckIn: false,
        onSuccess:
            (isCheckIn, location, {String authMethod = 'fallback'}) async {
              if (!mounted || location == null) return;
              await attendanceCubit.checkOut(
                userId: userId,
                latitude: location.latitude,
                longitude: location.longitude,
              );
            },
      );
    } finally {
      if (mounted) {
        isProcessingAttendance = false;
        notifyListeners();
      }
    }
  }
}

List<DailyAttendanceRecord> mapAttendanceItems(List<AttendanceItem> items) {
  final mapped = items.map((item) {
    final date = DateTime.tryParse(item.date) ?? DateTime.now();
    final checkIn = combineDateAndTime(item.date, item.attendanceTime);
    final checkOut = combineDateAndTime(item.date, item.departureTime);

    AttendanceStatus status;
    if (!item.hasCheckedIn) {
      status = AttendanceStatus.absent;
    } else if (item.isComplete) {
      status = AttendanceStatus.present;
    } else {
      status = AttendanceStatus.halfDay;
    }

    return DailyAttendanceRecord(
      id: item.id.toString(),
      date: date,
      checkInTime: checkIn,
      checkOutTime: checkOut,
      status: status,
      location: item.location,
    );
  }).toList()..sort((a, b) => b.date.compareTo(a.date));

  return mapped;
}

DateTime? combineDateAndTime(String dateValue, String? timeValue) {
  if (timeValue == null || timeValue.isEmpty) return null;

  try {
    final date = DateTime.parse(dateValue);
    final parts = timeValue.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final second = parts.length > 2 ? int.parse(parts[2]) : 0;
    return DateTime(date.year, date.month, date.day, hour, minute, second);
  } catch (_) {
    return null;
  }
}
