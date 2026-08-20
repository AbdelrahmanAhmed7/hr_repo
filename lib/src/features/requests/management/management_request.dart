import 'package:mediconsult_internal/src/features/home/models/recent_activity.dart';

enum ManagementRequestKind { leave, permission, assignment, overtime }

/// Unified typed model for the management `/all` request endpoints
/// (Leave/all, Permission/all, Assignment/all) which include the employee
/// name directly on every item.
class ManagementRequest {
  final String id;
  final ManagementRequestKind kind;
  final RequestStatus status;
  final String? userId;
  final String? userName;
  final String? reason;
  final DateTime? date;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? startTime;
  final String? endTime;
  final String? location;
  final String? leaveType;
  final String? deductionType;
  final String? medicalReportUrl;
  final String? rejectionReason;
  final DateTime createdAt;

  ManagementRequest({
    required this.id,
    required this.kind,
    required this.status,
    this.userId,
    this.userName,
    this.reason,
    this.date,
    this.startDate,
    this.endDate,
    this.startTime,
    this.endTime,
    this.location,
    this.leaveType,
    this.deductionType,
    this.medicalReportUrl,
    this.rejectionReason,
    required this.createdAt,
  });

  factory ManagementRequest.fromJson(
    Map<String, dynamic> json,
    ManagementRequestKind kind,
  ) {
    final statusRaw = (json['status']?.toString() ?? 'pending').toLowerCase();
    final status = switch (statusRaw) {
      'approved' || 'accepted' => RequestStatus.approved,
      'rejected' => RequestStatus.rejected,
      _ => RequestStatus.pending,
    };

    final nameAr = json['employeeNameAr']?.toString().trim() ?? '';
    final nameEn = json['employeeNameEn']?.toString().trim() ?? '';

    return ManagementRequest(
      id: json['id']?.toString() ?? '',
      kind: kind,
      status: status,
      userId: json['userId']?.toString(),
      userName: nameAr.isNotEmpty ? nameAr : (nameEn.isNotEmpty ? nameEn : null),
      reason: json['reason']?.toString(),
      date: DateTime.tryParse(json['date']?.toString() ?? ''),
      startDate: DateTime.tryParse(json['startDate']?.toString() ?? ''),
      endDate: DateTime.tryParse(json['endDate']?.toString() ?? ''),
      startTime: json['startTime']?.toString(),
      endTime: json['endTime']?.toString(),
      location: json['where']?.toString(),
      leaveType: json['leaveType']?.toString(),
      deductionType: json['deductionType']?.toString(),
      medicalReportUrl: json['medicalReportUrl']?.toString(),
      rejectionReason: json['rejectionReason']?.toString(),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  RequestType get requestType => switch (kind) {
    ManagementRequestKind.leave => RequestType.leave,
    ManagementRequestKind.permission => RequestType.permission,
    ManagementRequestKind.assignment => RequestType.assignment,
    ManagementRequestKind.overtime => RequestType.overtime,
  };

  String get title => switch (kind) {
    ManagementRequestKind.leave => 'إجازة',
    ManagementRequestKind.permission => 'إذن خروج',
    ManagementRequestKind.assignment => 'مأمورية',
    ManagementRequestKind.overtime => 'عمل إضافي',
  };

  DateTime get displayDate {
    final primaryDate = switch (kind) {
      ManagementRequestKind.leave => startDate ?? date,
      ManagementRequestKind.permission => date ?? startDate,
      ManagementRequestKind.assignment => startDate ?? date,
      ManagementRequestKind.overtime => date ?? startDate,
    };
    return primaryDate ?? createdAt;
  }

  String? buildDescription() {
    switch (kind) {
      case ManagementRequestKind.leave:
        if (startDate != null && endDate != null) {
          return 'من ${_formatDate(startDate!)} إلى ${_formatDate(endDate!)}';
        }
      case ManagementRequestKind.permission:
        if ((startTime?.trim().isNotEmpty ?? false) &&
            (endTime?.trim().isNotEmpty ?? false)) {
          return '${startTime!.trim()} - ${endTime!.trim()}';
        }
      case ManagementRequestKind.assignment:
        if (location?.trim().isNotEmpty ?? false) {
          return location!.trim();
        }
      case ManagementRequestKind.overtime:
        if ((startTime?.trim().isNotEmpty ?? false) &&
            (endTime?.trim().isNotEmpty ?? false)) {
          return '${startTime!.trim()} - ${endTime!.trim()}';
        }
    }
    return null;
  }

  RecentActivity toRecentActivity() {
    return RecentActivity(
      id: id,
      type: requestType,
      status: status,
      title: title,
      date: displayDate,
      description: buildDescription() ?? reason,
      userId: userId,
      userName: userName,
      reason: reason,
      startDate: startDate,
      endDate: endDate,
      startTime: startTime,
      endTime: endTime,
      location: location,
      leaveType: leaveType,
      rejectionReason: rejectionReason,
      deductionType: deductionType,
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}