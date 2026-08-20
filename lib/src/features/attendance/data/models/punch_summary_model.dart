class PunchSummaryModel {
  final String userId;
  final String employeeName;
  final String date;
  final double breakHours;
  final double workedHours;

  const PunchSummaryModel({
    required this.userId,
    required this.employeeName,
    required this.date,
    required this.breakHours,
    required this.workedHours,
  });

  factory PunchSummaryModel.fromJson(Map<String, dynamic> json) {
    return PunchSummaryModel(
      userId: json['userId'] as String? ?? '',
      employeeName: json['employeeName'] as String? ?? '',
      date: json['date'] as String? ?? '',
      breakHours: (json['breakHours'] as num?)?.toDouble() ?? 0.0,
      workedHours: (json['workedHours'] as num?)?.toDouble() ?? 0.0,
    );
  }

  String _formatHours(double totalHours) {
    if (totalHours <= 0) return '0 د';
    final hours = totalHours.truncate();
    final minutes = ((totalHours - hours) * 60).round();

    if (hours > 0 && minutes > 0) return '$hours س $minutes د';
    if (hours > 0) return '$hours س';
    return '$minutes د';
  }

  String get workedFormatted => _formatHours(workedHours);
  String get breakFormatted => _formatHours(breakHours);
}
