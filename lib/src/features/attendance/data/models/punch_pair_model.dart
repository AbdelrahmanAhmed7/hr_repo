class PunchPairModel {
  final String userId;
  final String employeeName;
  final String date;
  final String checkIn;
  final String? checkOut;

  const PunchPairModel({
    required this.userId,
    required this.employeeName,
    required this.date,
    required this.checkIn,
    this.checkOut,
  });

  factory PunchPairModel.fromJson(Map<String, dynamic> json) {
    return PunchPairModel(
      userId: json['userId'] as String? ?? '',
      employeeName: json['employeeName'] as String? ?? '',
      date: json['date'] as String? ?? '',
      checkIn: json['checkIn'] as String? ?? '',
      checkOut: json['checkOut'] as String?,
    );
  }

  bool get isOpen => checkOut == null;

  String _calcDuration(String start, String? end) {
    if (end == null) return 'مفتوح';
    try {
      final sParts = start.split('.')[0].split(':');
      final eParts = end.split('.')[0].split(':');
      
      final s = Duration(
        hours: int.parse(sParts[0]),
        minutes: int.parse(sParts[1]),
        seconds: int.parse(sParts[2]),
      );
      final e = Duration(
        hours: int.parse(eParts[0]),
        minutes: int.parse(eParts[1]),
        seconds: int.parse(eParts[2]),
      );
      
      final diff = e - s;
      final hrs = diff.inHours;
      final mins = diff.inMinutes.remainder(60);
      
      if (hrs > 0 && mins > 0) return '$hrs س $mins د';
      if (hrs > 0) return '$hrs س';
      return '$mins د';
    } catch (_) {
      return '—';
    }
  }

  String get duration => _calcDuration(checkIn, checkOut);
}
