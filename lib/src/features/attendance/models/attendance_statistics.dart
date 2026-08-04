class AttendanceStatistics {
  final int totalDays;
  final int presentDays;
  final int absentDays;
  final int leaveDays;
  final double totalWorkHours;
  final double averageWorkHours;
  final int lateDays;
  final int onTimeDays;

  AttendanceStatistics({
    required this.totalDays,
    required this.presentDays,
    required this.absentDays,
    required this.leaveDays,
    required this.totalWorkHours,
    required this.averageWorkHours,
    required this.lateDays,
    required this.onTimeDays,
  });

  double get attendancePercentage {
    if (totalDays == 0) return 0;
    return (presentDays / totalDays) * 100;
  }


}















