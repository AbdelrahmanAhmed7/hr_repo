class DepartmentAssignment {
  final int id;
  final String userId;
  final String employeeNameAr;
  final String employeeNameEn;
  final String where;
  final String startDate;
  final String endDate;
  final String startTime;
  final String endTime;
  final String reason;
  final String createdAt;
  final String status;
  final String? rejectionReason;

  DepartmentAssignment({
    required this.id,
    required this.userId,
    required this.employeeNameAr,
    required this.employeeNameEn,
    required this.where,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.reason,
    required this.createdAt,
    required this.status,
    this.rejectionReason,
  });

  factory DepartmentAssignment.fromJson(Map<String, dynamic> json) {
    return DepartmentAssignment(
      id: json['id'] as int,
      userId: json['userId'] as String,
      employeeNameAr: json['employeeNameAr'] as String,
      employeeNameEn: json['employeeNameEn'] as String,
      where: json['where'] as String? ?? '',
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      reason: json['reason'] as String,
      createdAt: json['createdAt'] as String,
      status: json['status'] as String,
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  String get shortNameAr {
    final parts = employeeNameAr.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length <= 2) return employeeNameAr;
    return '${parts[0]} ${parts[1]}';
  }

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';

  bool get isSingleDay => startDate == endDate;
}
