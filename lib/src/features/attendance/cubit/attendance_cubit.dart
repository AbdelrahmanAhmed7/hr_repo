import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/service_locator.dart';
import '../../../core/utils/device_fingerprint.dart';
import '../../../core/utils/work_rules.dart';
import '../../permissions/models/permission_request.dart';
import '../../permissions/repository/permission_repository.dart';
import '../models/attendance_record.dart';
import '../models/today_attendance.dart';
import '../repository/attendance_repository.dart';
import 'attendance_state.dart';

/// Attendance Cubit
class AttendanceCubit extends Cubit<AttendanceState> {
  final AttendanceRepository _repository;

  AttendanceCubit(this._repository)
    : super(AttendanceState(todayAttendance: TodayAttendance())) {
    _loadAttendanceState();
  }

  static const String _keyTodayAttendance = 'attendance_today';

  /// Bumps when a check-in/out action starts so in-flight initial loads cannot
  /// overwrite fresher attendance state.
  int _stateGeneration = 0;

  /// Public refresh for today's attendance.
  /// Ensures local cached attendance is cleared if API has no record.
  Future<void> refreshTodayAttendance() async {
    await _loadAttendanceState();
  }

  /// Load saved attendance state from API
  Future<void> _loadAttendanceState() async {
    final generation = ++_stateGeneration;
    debugPrint('[Attendance] loadToday start (gen=$generation)');

    try {
      final record = await _repository.getTodayAttendance();
      final todayPermissions = await _loadTodayPermissions();

      if (generation != _stateGeneration) {
        debugPrint(
          '[Attendance] loadToday skipped stale emit (gen=$generation, current=$_stateGeneration)',
        );
        return;
      }

      if (record != null) {
        final attendance = _convertRecordToTodayAttendance(record);
        await _saveAttendanceState(attendance);
        emit(
          AttendanceState(
            todayAttendance: attendance,
            displayedAttendance: attendance,
            todayPermissions: todayPermissions,
          ),
        );
        debugPrint(
          '[Attendance] loadToday emitted isCheckedIn=${attendance.isCheckedIn}, '
          'isCheckedOut=${attendance.isCheckedOut}',
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyTodayAttendance);
      emit(
        AttendanceState(
          todayAttendance: TodayAttendance(),
          displayedAttendance: TodayAttendance(),
          todayPermissions: todayPermissions,
        ),
      );
      debugPrint('[Attendance] loadToday emitted empty state');
    } catch (_) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final attendanceJson = prefs.getString(_keyTodayAttendance);
        final todayPermissions = await _loadTodayPermissions();

        if (attendanceJson != null) {
          final data = jsonDecode(attendanceJson) as Map<String, dynamic>;
          final today = DateTime.now();
          final savedDate = data['date'] != null
              ? DateTime.parse(data['date'])
              : null;

          if (savedDate != null &&
              savedDate.year == today.year &&
              savedDate.month == today.month &&
              savedDate.day == today.day) {
            final attendance = TodayAttendance(
              checkInTime: data['checkInTime'] != null
                  ? DateTime.parse(data['checkInTime'])
                  : null,
              checkOutTime: data['checkOutTime'] != null
                  ? DateTime.parse(data['checkOutTime'])
                  : null,
              isCheckedIn: data['isCheckedIn'] ?? false,
              isCheckedOut: data['isCheckedOut'] ?? false,
              location: data['location'],
              currentWorkHours: data['currentWorkHours']?.toDouble(),
            );
            if (generation != _stateGeneration) return;

            emit(
              AttendanceState(
                todayAttendance: attendance,
                displayedAttendance: attendance,
                todayPermissions: todayPermissions,
              ),
            );
            debugPrint(
              '[Attendance] loadToday cache emitted isCheckedIn=${attendance.isCheckedIn}',
            );
            return;
          }
        }
      } catch (_) {}

      if (generation != _stateGeneration) return;

      emit(
        AttendanceState(
          todayAttendance: TodayAttendance(),
          displayedAttendance: TodayAttendance(),
        ),
      );
      debugPrint('[Attendance] loadToday fallback empty state');
    }
  }

  /// Load today's permissions from permission repository
  Future<List<PermissionRequest>> _loadTodayPermissions() async {
    try {
      final permissionRepo = getIt<PermissionRepository>();
      final allPermissions = await permissionRepo.getMyPermissions();
      final today = DateTime.now();
      return allPermissions
          .where(
            (p) =>
                p.date.year == today.year &&
                p.date.month == today.month &&
                p.date.day == today.day,
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Convert API AttendanceRecord to TodayAttendance model
  TodayAttendance _convertRecordToTodayAttendance(AttendanceRecord record) {
    DateTime? checkInTime;
    DateTime? checkOutTime;

    if (record.attendanceTime != null) {
      try {
        checkInTime = DateTime.parse('${record.date} ${record.attendanceTime}');
      } catch (_) {}
    }

    if (record.departureTime != null) {
      try {
        checkOutTime = DateTime.parse('${record.date} ${record.departureTime}');
      } catch (_) {}
    }

    double? workHours;
    if (checkInTime != null && checkOutTime != null) {
      workHours = WorkRules.workedHours(checkInTime, checkOutTime);
    }

    return TodayAttendance(
      checkInTime: checkInTime,
      checkOutTime: checkOutTime,
      isCheckedIn: record.hasCheckedIn,
      isCheckedOut: record.hasCheckedOut,
      location: record.location,
      currentWorkHours: workHours,
    );
  }

  /// Save attendance state to SharedPreferences
  Future<void> _saveAttendanceState(TodayAttendance attendance) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'date': DateTime.now().toIso8601String(),
        'checkInTime': attendance.checkInTime?.toIso8601String(),
        'checkOutTime': attendance.checkOutTime?.toIso8601String(),
        'isCheckedIn': attendance.isCheckedIn,
        'isCheckedOut': attendance.isCheckedOut,
        'location': attendance.location,
        'currentWorkHours': attendance.currentWorkHours,
      };
      await prefs.setString(_keyTodayAttendance, jsonEncode(data));
    } catch (_) {}
  }

  /// Check In with API
  Future<void> checkIn({
    String? location,
    String? userId,
    required double latitude,
    required double longitude,
  }) async {
    final actionGeneration = ++_stateGeneration;
    debugPrint('[Attendance] checkIn start (gen=$actionGeneration)');
    emit(state.copyWith(isLoading: true));

    try {
      final fingerprintKey = await DeviceFingerprintService().getFingerprint();

      final record = await _repository.checkIn(
        fingerprintKey: fingerprintKey,
        latitude: latitude,
        longitude: longitude,
      );
      debugPrint(
        '[Attendance] checkIn API response attendanceTime=${record.attendanceTime}',
      );

      final newAttendance = await _resolveTodayAttendanceAfterAction(
        fallbackRecord: record,
        isCheckIn: true,
      );
      await _saveAttendanceState(newAttendance);

      if (actionGeneration != _stateGeneration) {
        debugPrint('[Attendance] checkIn skipped stale emit');
        return;
      }

      emit(
        state.copyWith(
          todayAttendance: newAttendance,
          displayedAttendance: newAttendance,
          isLoading: false,
          isCheckInOutAction: true,
        ),
      );
      debugPrint(
        '[Attendance] checkIn emitted isCheckedIn=${newAttendance.isCheckedIn}, '
        'checkInTime=${newAttendance.checkInTime}',
      );
    } catch (e) {
      debugPrint('[Attendance] checkIn failed: $e');
      if (!isClosed) emit(state.copyWith(isLoading: false));
      rethrow;
    }
  }

  /// Check Out with API
  Future<void> checkOut({
    String? location,
    String? userId,
    required double latitude,
    required double longitude,
  }) async {
    final actionGeneration = ++_stateGeneration;
    debugPrint('[Attendance] checkOut start (gen=$actionGeneration)');
    emit(state.copyWith(isLoading: true));

    try {
      final fingerprintKey = await DeviceFingerprintService().getFingerprint();

      final record = await _repository.checkOut(
        fingerprintKey: fingerprintKey,
        latitude: latitude,
        longitude: longitude,
      );
      debugPrint(
        '[Attendance] checkOut API response departureTime=${record.departureTime}',
      );

      final newAttendance = await _resolveTodayAttendanceAfterAction(
        fallbackRecord: record,
        isCheckIn: false,
      );
      await _saveAttendanceState(newAttendance);

      if (actionGeneration != _stateGeneration) {
        debugPrint('[Attendance] checkOut skipped stale emit');
        return;
      }

      emit(
        state.copyWith(
          todayAttendance: newAttendance,
          displayedAttendance: newAttendance,
          isLoading: false,
          isCheckInOutAction: true,
        ),
      );
      debugPrint(
        '[Attendance] checkOut emitted isCheckedOut=${newAttendance.isCheckedOut}, '
        'checkOutTime=${newAttendance.checkOutTime}',
      );
    } catch (e) {
      debugPrint('[Attendance] checkOut failed: $e');
      if (!isClosed) emit(state.copyWith(isLoading: false));
      rethrow;
    }
  }

  /// Mobile check-in/out responses may omit times even when the record is saved.
  /// Re-fetch today's record, then fall back to an optimistic local update.
  Future<TodayAttendance> _resolveTodayAttendanceAfterAction({
    required AttendanceRecord fallbackRecord,
    required bool isCheckIn,
  }) async {
    final fromAction = _convertRecordToTodayAttendance(fallbackRecord);
    final actionReflected = isCheckIn
        ? fromAction.isCheckedIn
        : fromAction.isCheckedOut;

    if (actionReflected) {
      debugPrint('[Attendance] using action response for today state');
      return fromAction;
    }

    debugPrint('[Attendance] action response incomplete, re-fetching today');
    final today = await _repository.getTodayAttendance();
    if (today != null) {
      final refreshed = _convertRecordToTodayAttendance(today);
      final refreshedReflected = isCheckIn
          ? refreshed.isCheckedIn
          : refreshed.isCheckedOut;
      if (refreshedReflected) {
        debugPrint('[Attendance] re-fetch resolved today state');
        return refreshed;
      }
    }

    final now = DateTime.now();
    if (isCheckIn) {
      debugPrint('[Attendance] optimistic check-in fallback');
      return TodayAttendance(
        checkInTime: now,
        checkOutTime: state.todayAttendance.checkOutTime,
        isCheckedIn: true,
        isCheckedOut: state.todayAttendance.isCheckedOut,
        location: fallbackRecord.location ?? state.todayAttendance.location,
        currentWorkHours: state.todayAttendance.currentWorkHours,
      );
    }

    final checkInTime =
        state.todayAttendance.checkInTime ?? fromAction.checkInTime;
    debugPrint('[Attendance] optimistic check-out fallback');
    return TodayAttendance(
      checkInTime: checkInTime,
      checkOutTime: now,
      isCheckedIn: true,
      isCheckedOut: true,
      location: fallbackRecord.location ?? state.todayAttendance.location,
      currentWorkHours: checkInTime != null
          ? WorkRules.workedHours(checkInTime, now)
          : null,
    );
  }

  /// Load attendance for a specific date
  Future<void> loadAttendanceByDate(DateTime date) async {
    final loadGeneration = _stateGeneration;
    debugPrint(
      '[Attendance] loadByDate start date=$date (gen=$loadGeneration)',
    );
    emit(state.copyWith(isLoading: true));

    try {
      final record = await _repository.getAttendanceByDate(date);
      final isToday = _isSameDay(date, DateTime.now());

      if (loadGeneration != _stateGeneration) {
        debugPrint('[Attendance] loadByDate skipped stale emit');
        return;
      }

      if (record != null) {
        final attendance = _convertRecordToTodayAttendance(record);
        emit(
          state.copyWith(
            todayAttendance: isToday ? attendance : state.todayAttendance,
            displayedAttendance: attendance,
            isLoading: false,
          ),
        );
        debugPrint(
          '[Attendance] loadByDate emitted isCheckedIn=${attendance.isCheckedIn}',
        );
      } else {
        final preserveCheckedInToday =
            isToday && state.todayAttendance.isCheckedIn;
        emit(
          state.copyWith(
            todayAttendance: isToday
                ? (preserveCheckedInToday
                      ? state.todayAttendance
                      : TodayAttendance())
                : state.todayAttendance,
            displayedAttendance: TodayAttendance(),
            isLoading: false,
          ),
        );
        debugPrint(
          '[Attendance] loadByDate emitted empty/preserved '
          'preserveCheckedInToday=$preserveCheckedInToday',
        );
      }
    } catch (e) {
      debugPrint('[Attendance] loadByDate failed: $e');
      if (loadGeneration != _stateGeneration || isClosed) return;

      final isToday = _isSameDay(date, DateTime.now());
      final preserveCheckedInToday =
          isToday && state.todayAttendance.isCheckedIn;
      emit(
        state.copyWith(
          todayAttendance: isToday
              ? (preserveCheckedInToday
                    ? state.todayAttendance
                    : TodayAttendance())
              : state.todayAttendance,
          displayedAttendance: TodayAttendance(),
          isLoading: false,
        ),
      );
    }
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  // ─── Monthly Attendance PDF ────────────────────────────────────────────────

  void selectPdfMonth(int month) {
    emit(state.copyWith(selectedPdfMonth: month, clearPdfError: true));
  }

  void selectPdfYear(int year) {
    emit(state.copyWith(selectedPdfYear: year, clearPdfError: true));
  }

  /// Download the current user's monthly attendance PDF.
  /// Returns the saved file path on success.
  Future<String> downloadMonthlyAttendancePdf() async {
    emit(
      state.copyWith(
        pdfStatus: AttendancePdfStatus.downloading,
        clearPdfError: true,
      ),
    );

    try {
      final file = await _repository.downloadMonthlyAttendancePdf(
        month: state.selectedPdfMonth,
        year: state.selectedPdfYear,
      );

      if (file.bytes.isEmpty) {
        throw Exception('لم يتم العثور على ملف PDF لهذه الفترة.');
      }

      // Save to documents directory so it persists between sessions
      final directory = await getApplicationDocumentsDirectory();
      final savedFile = File('${directory.path}/${file.fileName}');
      await savedFile.writeAsBytes(file.bytes, flush: true);

      emit(state.copyWith(pdfStatus: AttendancePdfStatus.success));
      return savedFile.path;
    } on DioException catch (e) {
      final msg = _extractDioErrorMessage(e);
      emit(
        state.copyWith(
          pdfStatus: AttendancePdfStatus.failure,
          pdfErrorMessage: msg,
        ),
      );
      throw Exception(msg);
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      emit(
        state.copyWith(
          pdfStatus: AttendancePdfStatus.failure,
          pdfErrorMessage: msg,
        ),
      );
      rethrow;
    }
  }

  String _extractDioErrorMessage(DioException e) {
    if (e.response?.statusCode == 400) {
      return 'بيانات الطلب غير صحيحة. تأكد من الشهر والسنة المختارَين.';
    }
    if (e.response?.statusCode == 401) {
      return 'غير مصرح لك بالوصول. يرجى تسجيل الدخول مرة أخرى.';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة.';
    }
    try {
      final data = e.response?.data;
      if (data is Map) {
        return (data['message'] ?? data['title'] ?? 'تعذر تحميل ملف PDF.')
            .toString();
      }
    } catch (_) {}
    return 'تعذر تحميل ملف PDF. يرجى المحاولة مرة أخرى.';
  }
}
