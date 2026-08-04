class DepartmentPermission {
  final int id;
  final String userId;
  final String employeeNameAr;
  final String employeeNameEn;
  final String date;
  final String startTime;
  final String endTime;
  final String reason;
  final String createdAt;
  final String status;
  final String? rejectionReason;

  DepartmentPermission({
    required this.id,
    required this.userId,
    required this.employeeNameAr,
    required this.employeeNameEn,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.reason,
    required this.createdAt,
    required this.status,
    this.rejectionReason,
  });

  factory DepartmentPermission.fromJson(Map<String, dynamic> json) {
    return DepartmentPermission(
      id: json['id'] as int,
      userId: json['userId'] as String,
      employeeNameAr: json['employeeNameAr'] as String,
      employeeNameEn: json['employeeNameEn'] as String,
      date: json['date'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      reason: json['reason'] as String,
      createdAt: json['createdAt'] as String,
      status: json['status'] as String,
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  /// Get short name (first + second name only)
  String get shortNameAr {
    final parts = employeeNameAr.trim().split(' ')
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length <= 2) return employeeNameAr;
    return '${parts[0]} ${parts[1]}';
  }

  String get shortNameEn {
    final parts = employeeNameEn.trim().split(' ')
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length <= 2) return employeeNameEn;
    return '${parts[0]} ${parts[1]}';
  }

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';
}
