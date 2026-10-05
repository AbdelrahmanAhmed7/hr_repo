import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/services/service_locator.dart';
import '../../../core/time/server_clock.dart';
import '../../../core/utils/app_exception.dart';
import '../../../core/utils/device_fingerprint.dart';
import '../../../core/utils/work_rules.dart';
import '../../permissions/models/permission_request.dart';
import '../../permissions/repository/permission_repository.dart';
import '../models/attendance_record.dart';
import '../models/today_attendance.dart';
import '../repository/attendance_repository.dart';
import '../utils/attendance_shift_resolver.dart';
import 'attendance_state.dart';

/// Attendance Cubit
class AttendanceCubit extends Cubit<AttendanceState> {
  final AttendanceRepository _repository;
  final ServerClock _serverClock;

  AttendanceCubit(this._repository, {ServerClock? serverClock})
    : _serverClock = serverClock ?? ServerClock.instance,
      super(AttendanceState(todayAttendance: TodayAttendance())) {
    _loadAttendanceState();
  }

  static const String todayCacheKey = 'attendance_today';

  /// Bumps when a check-in/out action starts so in-flight initial loads cannot
  /// overwrite fresher attendance state.
  int _stateGeneration = 0;

  /// Public refresh for today's attendance.
  Future<void> refreshTodayAttendance() async {
    await _loadAttendanceState();
  }

  void _emitUnknown(int generation) {
    if (generation != _stateGeneration || isClosed) return;
    emit(
      state.copyWith(todayAttendance: const TodayAttendance(isUnknown: true)),
    );
  }

  /// Resolves today's punch state from today+yesterday records using the
  /// server clock. Any failure (unsynced clock, either request failing)
  /// yields unknown — never a default that could disable punch wrongly.
  /// Displayed (history browsing) state is left untouched here.
  Future<void> _loadAttendanceState() async {
    final generation = ++_stateGeneration;
    debugPrint('[Attendance] loadToday start (gen=$generation)');

    final synced = await _serverClock.waitForSync();
    final now = _serverClock.tryCairoNow();
    if (!synced || now == null) {
      debugPrint('[Attendance] loadToday unsynced clock -> unknown');
      _emitUnknown(generation);
      return;
    }

    try {
      final records = await _repository.getTodayAndYesterdayRecords(
        cairoNow: now,
      );
      final todayPermissions = await _loadTodayPermissions(now);

      if (generation != _stateGeneration || isClosed) {
        debugPrint('[Attendance] loadToday skipped stale emit');
        return;
      }

      final resolved = resolveAttendanceState(records: records, now: now);
      for (final warning in resolved.warnings) {
        debugPrint('[Attendance] $warning');
      }
      switch (resolved.status) {
        case AttendanceShiftStatus.checkedInActive:
          final checkIn = resolved.checkInDateTime!;
          emit(
            AttendanceState(
              todayAttendance: TodayAttendance(
                checkInTime: checkIn,
                isCheckedIn: true,
                currentWorkHours: WorkRules.workedHours(checkIn, now),
              ),
              displayedAttendance: state.displayedAttendance,
              todayPermissions: todayPermissions,
            ),
          );
        case AttendanceShiftStatus.completed:
          final checkIn = resolved.checkInDateTime!;
          final departure = resolved.departureDateTime!;
          emit(
            AttendanceState(
              todayAttendance: TodayAttendance(
                checkInTime: checkIn,
                checkOutTime: departure,
                isCheckedIn: true,
                isCheckedOut: true,
                currentWorkHours: WorkRules.workedHours(checkIn, departure),
              ),
              displayedAttendance: state.displayedAttendance,
              todayPermissions: todayPermissions,
            ),
          );
        case AttendanceShiftStatus.staleOpen:
          debugPrint(
            '[Attendance] stale open shift, check-in stays available',
          );
          emit(
            AttendanceState(
              todayAttendance: TodayAttendance(),
              displayedAttendance: state.displayedAttendance,
              todayPermissions: todayPermissions,
            ),
          );
        case AttendanceShiftStatus.noRecord:
          emit(
            AttendanceState(
              todayAttendance: TodayAttendance(),
              displayedAttendance: state.displayedAttendance,
              todayPermissions: todayPermissions,
            ),
          );
        case AttendanceShiftStatus.unknown:
          _emitUnknown(generation);
      }
      debugPrint(
        '[Attendance] loadToday resolved status=${resolved.status}',
      );
    } catch (_) {
      debugPrint('[Attendance] loadToday failed -> unknown');
      _emitUnknown(generation);
    }
  }

  /// Load today's permissions from permission repository
  Future<List<PermissionRequest>> _loadTodayPermissions(DateTime now) async {
    try {
      final permissionRepo = getIt<PermissionRepository>();
      final allPermissions = await permissionRepo.getMyPermissions();
      return allPermissions
          .where(
            (p) =>
                p.date.year == now.year &&
                p.date.month == now.month &&
                p.date.day == now.day,
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
  /// Re-resolves from today+yesterday records, then falls back to an
  /// optimistic local update stamped with the server clock.
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

    final serverNow = _serverClock.tryCairoNow();
    if (serverNow != null) {
      try {
        final records = await _repository.getTodayAndYesterdayRecords(
          cairoNow: serverNow,
        );
        final resolved = resolveAttendanceState(
          records: records,
          now: serverNow,
        );
        final checkIn = resolved.checkInDateTime;
        if (resolved.status == AttendanceShiftStatus.checkedInActive &&
            checkIn != null) {
          return TodayAttendance(
            checkInTime: checkIn,
            isCheckedIn: true,
            currentWorkHours: WorkRules.workedHours(checkIn, serverNow),
          );
        }
        final departure = resolved.departureDateTime;
        if (resolved.status == AttendanceShiftStatus.completed &&
            checkIn != null &&
            departure != null) {
          return TodayAttendance(
            checkInTime: checkIn,
            checkOutTime: departure,
            isCheckedIn: true,
            isCheckedOut: true,
            currentWorkHours: WorkRules.workedHours(checkIn, departure),
          );
        }
      } catch (_) {}
    }

    debugPrint('[Attendance] optimistic fallback without server time');
    if (isCheckIn) {
      return TodayAttendance(
        checkInTime: serverNow,
        checkOutTime: state.todayAttendance.checkOutTime,
        isCheckedIn: true,
        isCheckedOut: state.todayAttendance.isCheckedOut,
        location: fallbackRecord.location ?? state.todayAttendance.location,
        currentWorkHours: state.todayAttendance.currentWorkHours,
      );
    }

    final checkInTime =
        state.todayAttendance.checkInTime ?? fromAction.checkInTime;
    return TodayAttendance(
      checkInTime: checkInTime,
      checkOutTime: serverNow,
      isCheckedIn: true,
      isCheckedOut: true,
      location: fallbackRecord.location ?? state.todayAttendance.location,
      currentWorkHours: checkInTime != null && serverNow != null
          ? WorkRules.workedHours(checkInTime, serverNow)
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

    final serverToday = _serverClock.tryCairoNow();

    try {
      final record = await _repository.getAttendanceByDate(date);
      final isToday = serverToday != null && _isSameDay(date, serverToday);

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

      final isToday =
          serverToday != null && _isSameDay(date, serverToday);
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
      final msg = AppException.from(e).message;
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
