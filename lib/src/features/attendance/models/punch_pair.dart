class PunchPair {
  final String userId;
  final String employeeName;
  final String date;
  final String? checkIn;
  final String? checkOut;

  const PunchPair({
    required this.userId,
    required this.employeeName,
    required this.date,
    this.checkIn,
    this.checkOut,
  });

  factory PunchPair.fromJson(Map<String, dynamic> json) {
    return PunchPair(
      userId: json['userId']?.toString() ?? '',
      employeeName: json['employeeName']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      checkIn: json['checkIn']?.toString(),
      checkOut: json['checkOut']?.toString(),
    );
  }

  bool get hasCheckIn => checkIn != null && checkIn!.trim().isNotEmpty;
  bool get hasCheckOut => checkOut != null && checkOut!.trim().isNotEmpty;
  bool get isComplete => hasCheckIn && hasCheckOut;

  /// Duration worked (null if incomplete)
  Duration? get workedDuration {
    if (!isComplete) return null;
    try {
      final inParts = checkIn!.split(':');
      final outParts = checkOut!.split(':');
      final inMinutes =
          int.parse(inParts[0]) * 60 + int.parse(inParts[1]);
      final outMinutes =
          int.parse(outParts[0]) * 60 + int.parse(outParts[1]);
      final diff = outMinutes - inMinutes;
      if (diff <= 0) return null;
      return Duration(minutes: diff);
    } catch (_) {
      return null;
    }
  }

  String get workedDurationLabel {
    final d = workedDuration;
    if (d == null) return '--';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '$h س $m د';
    return '$m د';
  }
}

class PunchPairsResponse {
  final List<PunchPair> items;
  final int pageNumber;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  const PunchPairsResponse({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  factory PunchPairsResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return PunchPairsResponse(
      items: rawItems
          .map((e) => PunchPair.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      pageNumber: _toInt(json['pageNumber'], fallback: 1),
      pageSize: _toInt(json['pageSize'], fallback: 10),
      totalCount: _toInt(json['totalCount']),
      totalPages: _toInt(json['totalPages'], fallback: 1),
    );
  }

  static int _toInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? fallback;
  }
}
