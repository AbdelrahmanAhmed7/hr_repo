class PunchPairPermission {
  final int id;
  final String startTime;
  final String endTime;
  final String reason;

  const PunchPairPermission({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.reason,
  });

  factory PunchPairPermission.fromJson(Map<String, dynamic> json) {
    return PunchPairPermission(
      id: json['id'] as int? ?? 0,
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
    );
  }

  String get displayTime {
    try {
      final start = DateTime.parse(startTime);
      final end = DateTime.parse(endTime);
      return '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}

class PunchPairAssignment {
  final int id;
  final String startTime;
  final String endTime;
  final String reason;

  const PunchPairAssignment({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.reason,
  });

  factory PunchPairAssignment.fromJson(Map<String, dynamic> json) {
    return PunchPairAssignment(
      id: json['id'] as int? ?? 0,
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
    );
  }

  String get displayTime {
    try {
      final start = DateTime.parse(startTime);
      final end = DateTime.parse(endTime);
      return '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}

class PunchPairModel {
  final String userId;
  final String employeeName;
  final String date;
  final String checkIn;
  final String? checkOut;
  final List<PunchPairPermission> permissions;
  final List<PunchPairAssignment> assignments;

  const PunchPairModel({
    required this.userId,
    required this.employeeName,
    required this.date,
    required this.checkIn,
    this.checkOut,
    this.permissions = const [],
    this.assignments = const [],
  });

  factory PunchPairModel.fromJson(Map<String, dynamic> json) {
    return PunchPairModel(
      userId: json['userId'] as String? ?? '',
      employeeName: json['employeeName'] as String? ?? '',
      date: json['date'] as String? ?? '',
      checkIn: json['checkIn'] as String? ?? '',
      checkOut: json['checkOut'] as String?,
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((e) =>
                  PunchPairPermission.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      assignments: (json['assignments'] as List<dynamic>?)
              ?.map((e) =>
                  PunchPairAssignment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  bool get isOpen => checkOut == null;
  bool get hasPermissions => permissions.isNotEmpty;
  bool get hasAssignments => assignments.isNotEmpty;

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
