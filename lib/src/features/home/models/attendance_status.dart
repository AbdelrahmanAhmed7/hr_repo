enum AttendanceStatus {
  checkedIn,
  checkedOut,
  notCheckedIn,
}

class AttendanceInfo {
  final AttendanceStatus status;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;

  AttendanceInfo({
    required this.status,
    this.checkInTime,
    this.checkOutTime,
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















