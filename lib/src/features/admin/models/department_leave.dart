class DepartmentLeave {
  final int id;
  final String userId;
  final String employeeNameAr;
  final String employeeNameEn;
  final String startDate;
  final String endDate;
  final String reason;
  final String createdAt;
  final String status;
  final String? rejectionReason;
  final String leaveType;
  final String? medicalReportUrl;

  DepartmentLeave({
    required this.id,
    required this.userId,
    required this.employeeNameAr,
    required this.employeeNameEn,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.createdAt,
    required this.status,
    this.rejectionReason,
    required this.leaveType,
    this.medicalReportUrl,
  });

  factory DepartmentLeave.fromJson(Map<String, dynamic> json) {
    return DepartmentLeave(
      id: json['id'] as int,
      userId: json['userId'] as String,
      employeeNameAr: json['employeeNameAr'] as String,
      employeeNameEn: json['employeeNameEn'] as String,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
      reason: json['reason'] as String,
      createdAt: json['createdAt'] as String,
      status: json['status'] as String,
      rejectionReason: json['rejectionReason'] as String?,
      leaveType: json['leaveType'] as String? ?? 'Annual',
      medicalReportUrl: json['medicalReportUrl'] as String?,
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

  String get leaveTypeAr {
    switch (leaveType.toLowerCase()) {
      case 'annual': return 'سنوية';
      case 'sick': return 'مرضية';
      case 'casual': return 'عارضة';
      case 'unpaid': return 'بدون راتب';
      default: return leaveType;
    }
  }
}
