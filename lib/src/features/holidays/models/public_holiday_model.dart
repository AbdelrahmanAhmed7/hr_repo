class PublicHolidayModel {
  final int id;
  final DateTime fromDate;
  final DateTime toDate;
  final String name;
  final String nameAr;
  final bool isActive;
  final List<dynamic> exceptions;

  PublicHolidayModel({
    required this.id,
    DateTime? date,
    DateTime? fromDate,
    DateTime? toDate,
    required this.name,
    required this.nameAr,
    required this.isActive,
    required this.exceptions,
  })  : fromDate = fromDate ?? date ?? toDate ?? DateTime.now(),
        toDate = toDate ?? date ?? fromDate ?? DateTime.now();

  DateTime get date => toDate;
  int get year => toDate.year;

  factory PublicHolidayModel.fromJson(Map<String, dynamic> json) {
    final parsedFromDate = _parseDate(json['fromDate'] ?? json['date']);
    final parsedToDate = _parseDate(json['toDate'] ?? json['date']);

    return PublicHolidayModel(
      id: _parseInt(json['id']),
      fromDate: parsedFromDate,
      toDate: parsedToDate ?? parsedFromDate,
      name: json['name']?.toString() ?? '',
      nameAr: json['nameAr']?.toString() ?? json['name']?.toString() ?? '',
      isActive: json['isActive'] as bool? ?? true,
      exceptions: json['exceptions'] as List<dynamic>? ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fromDate': _formatDate(fromDate),
      'toDate': _formatDate(toDate),
      'name': name,
      'nameAr': nameAr,
      'isActive': isActive,
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _formatDate(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }
}
