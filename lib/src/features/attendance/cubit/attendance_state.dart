import 'package:equatable/equatable.dart';
import '../../permissions/models/permission_request.dart';
import '../models/today_attendance.dart';
import '../models/attendance_list_response.dart';

enum AttendancePdfStatus { initial, downloading, success, failure }

/// Attendance State
class AttendanceState extends Equatable {
  final TodayAttendance todayAttendance;
  final TodayAttendance displayedAttendance;
  final List<PermissionRequest> todayPermissions;
  final bool isLoading;
  final AttendanceListResponse? monthlyData;
  final String? errorMessage;

  /// True only after a real check-in or check-out action (not initial load)
  final bool isCheckInOutAction;

  // PDF download state
  final AttendancePdfStatus pdfStatus;
  final String? pdfErrorMessage;
  final int selectedPdfMonth;
  final int selectedPdfYear;

  AttendanceState({
    required this.todayAttendance,
    TodayAttendance? displayedAttendance,
    this.todayPermissions = const [],
    this.isLoading = false,
    this.monthlyData,
    this.errorMessage,
    this.isCheckInOutAction = false,
    this.pdfStatus = AttendancePdfStatus.initial,
    this.pdfErrorMessage,
    int? selectedPdfMonth,
    int? selectedPdfYear,
  }) : displayedAttendance = displayedAttendance ?? todayAttendance,
       selectedPdfMonth = selectedPdfMonth ?? DateTime.now().month,
       selectedPdfYear = selectedPdfYear ?? DateTime.now().year;

  AttendanceState copyWith({
    TodayAttendance? todayAttendance,
    TodayAttendance? displayedAttendance,
    List<PermissionRequest>? todayPermissions,
    bool? isLoading,
    AttendanceListResponse? monthlyData,
    String? errorMessage,
    bool? isCheckInOutAction,
    AttendancePdfStatus? pdfStatus,
    String? pdfErrorMessage,
    int? selectedPdfMonth,
    int? selectedPdfYear,
    bool clearPdfError = false,
  }) {
    return AttendanceState(
      todayAttendance: todayAttendance ?? this.todayAttendance,
      displayedAttendance: displayedAttendance ?? this.displayedAttendance,
      todayPermissions: todayPermissions ?? this.todayPermissions,
      isLoading: isLoading ?? this.isLoading,
      monthlyData: monthlyData ?? this.monthlyData,
      errorMessage: errorMessage,
      isCheckInOutAction: isCheckInOutAction ?? false,
      pdfStatus: pdfStatus ?? this.pdfStatus,
      pdfErrorMessage: clearPdfError
          ? null
          : (pdfErrorMessage ?? this.pdfErrorMessage),
      selectedPdfMonth: selectedPdfMonth ?? this.selectedPdfMonth,
      selectedPdfYear: selectedPdfYear ?? this.selectedPdfYear,
    );
  }

  @override
  List<Object?> get props => [
    todayAttendance,
    displayedAttendance,
    todayPermissions,
    isLoading,
    monthlyData,
    errorMessage,
    isCheckInOutAction,
    pdfStatus,
    pdfErrorMessage,
    selectedPdfMonth,
    selectedPdfYear,
  ];
}
