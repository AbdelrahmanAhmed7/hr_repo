class TodayAttendance {
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final bool isCheckedIn;
  final bool isCheckedOut;
  final String? location;
  final double? currentWorkHours;

  TodayAttendance({
    this.checkInTime,
    this.checkOutTime,
    this.isCheckedIn = false,
    this.isCheckedOut = false,
    this.location,
    this.currentWorkHours,
  });

  String get statusText {
    if (isCheckedOut) {
      return 'تم تسجيل الخروج';
    } else if (isCheckedIn) {
      return 'تم تسجيل الدخول';
    } else {
      return 'لم يتم تسجيل الدخول';
    }
  }

  String? get checkInTimeText {
    if (checkInTime == null) return null;
    return '${checkInTime!.hour.toString().padLeft(2, '0')}:${checkInTime!.minute.toString().padLeft(2, '0')}';
  }

  String? get checkOutTimeText {
    if (checkOutTime == null) return null;
    return '${checkOutTime!.hour.toString().padLeft(2, '0')}:${checkOutTime!.minute.toString().padLeft(2, '0')}';
  }


}















