enum AttendanceStatus {
  checkedIn,
  checkedOut,
  notCheckedIn,
}

class AttendanceInfo {
  final AttendanceStatus status;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final bool isUnknown;

  AttendanceInfo({
    required this.status,
    this.checkInTime,
    this.checkOutTime,
    this.isUnknown = false,
  });

  String get statusText {
    switch (status) {
      case AttendanceStatus.checkedIn:
        return 'تم تسجيل الدخول';
      case AttendanceStatus.checkedOut:
        return 'تم تسجيل الخروج';
      case AttendanceStatus.notCheckedIn:
        return 'لم يتم تسجيل الدخول';
    }
  }


}















