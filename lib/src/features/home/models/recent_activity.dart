import 'package:flutter/material.dart';
import '../../admin/models/super_admin_dashboard_response.dart';
import '../../notifications/models/notification.dart';
import '../../permissions/models/permission_request.dart' as domain;

enum RequestType {
  leave,
  permission,
  overtime,
  assignment,
  other,
}

enum RequestStatus {
  pending,
  approved,
  rejected,
}

class RecentActivity {
  final String id;
  final RequestType type;
  final RequestStatus status;
  final String title;
  final DateTime date;
  final String? description;
  final String? userId;
  final String? userName;
  final int? remainingVacationBalance;
  final String? reason;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? startTime;
  final String? endTime;
  final String? location;
  final String? leaveType;
  final String? rejectionReason;
  final double? totalHours;
  final double? amount;
  final String? deductionType;

  RecentActivity({
    required this.id,
    required this.type,
    required this.status,
    required this.title,
    required this.date,
    this.description,
    this.userId,
    this.userName,
    this.remainingVacationBalance,
    this.reason,
    this.startDate,
    this.endDate,
    this.startTime,
    this.endTime,
    this.location,
    this.leaveType,
    this.rejectionReason,
    this.totalHours,
    this.amount,
    this.deductionType,
  });

  String get typeText {
    switch (type) {
      case RequestType.leave:
        return 'إجازة';
      case RequestType.permission:
        return 'إذن';
      case RequestType.overtime:
        return 'عمل إضافي';
      case RequestType.assignment:
        return 'مأمورية';
      case RequestType.other:
        return 'طلب آخر';
    }
  }

  String get statusText {
    switch (status) {
      case RequestStatus.pending:
        return 'قيد الانتظار';
      case RequestStatus.approved:
        return 'موافق عليه';
      case RequestStatus.rejected:
        return 'مرفوض';
    }
  }

  Color get statusColor {
    switch (status) {
      case RequestStatus.pending:
        return const Color(0xFFD97706); // warning
      case RequestStatus.approved:
        return const Color(0xFF0F7D3E); // success
      case RequestStatus.rejected:
        return const Color(0xFFC41E3A); // error
    }
  }



  /// Convert PermissionRequest to RecentActivity
  factory RecentActivity.fromPermissionRequest(
    domain.PermissionRequest permission,
  ) {
    final RequestStatus status;
    switch (permission.status) {
      case domain.PermissionStatus.pending:
        status = RequestStatus.pending;
        break;
      case domain.PermissionStatus.approved:
        status = RequestStatus.approved;
        break;
      case domain.PermissionStatus.rejected:
        status = RequestStatus.rejected;
        break;
    }

    return RecentActivity(
      id: permission.id,
      type: RequestType.permission,
      status: status,
      title: 'إذن خروج',
      date: permission.date,
      description: permission.durationText,
      reason: permission.reason,
    );
  }

  /// Convert HomeRequestItem from API to RecentActivity
  factory RecentActivity.fromHomeRequestItem(dynamic item) {
    // Parse type
    RequestType type;
    String title;
    switch (item.type.toString().toLowerCase()) {
      case 'leave':
        type = RequestType.leave;
        title = 'إجازة';
        break;
      case 'permission':
        type = RequestType.permission;
        title = 'إذن خروج';
        break;
      case 'overtime':
        type = RequestType.overtime;
        title = 'عمل إضافي';
        break;
      case 'assignment':
        type = RequestType.assignment;
        title = 'مأمورية';
        break;
      default:
        type = RequestType.other;
        title = item.type.toString();
    }

    // Parse status
    RequestStatus status;
    switch (item.status.toString().toLowerCase()) {
      case 'pending':
        status = RequestStatus.pending;
        break;
      case 'approved':
      case 'accepted':
        status = RequestStatus.approved;
        break;
      case 'rejected':
        status = RequestStatus.rejected;
        break;
      default:
        status = RequestStatus.pending;
    }

    // Build description based on type
    String? description;
    if (item.type.toString().toLowerCase() == 'leave') {
      if (item.startDate != null && item.endDate != null) {
        description = 'من ${item.startDate} إلى ${item.endDate}';
      }
    } else if (item.type.toString().toLowerCase() == 'permission') {
      if (item.startTime != null && item.endTime != null) {
        description = 'من ${item.startTime} إلى ${item.endTime}';
      }
    } else if (item.type.toString().toLowerCase() == 'assignment') {
      if (item.where != null) {
        description = item.where;
      }
    } else if (item.type.toString().toLowerCase() == 'overtime') {
      if (item.startTime != null && item.endTime != null) {
        description = 'From ${item.startTime} to ${item.endTime}';
      }
    }

    final date = _resolveRequestDate(item);
    final startDate = _tryParseDate(item.startDate?.toString());
    final endDate = _tryParseDate(item.endDate?.toString());

    final employeeNameAr = _readOptionalString(item, ['employeeNameAr']);
    final employeeNameEn = _readOptionalString(item, ['employeeNameEn']);
    final leaveType = _readOptionalString(item, ['leaveType']);
    final rejectionReason = _readOptionalString(item, ['rejectionReason']);
    final totalHoursValue = _readDynamicField(item, 'totalHours');
    final amountValue = _readDynamicField(item, 'amount');
    final deductionType = _readOptionalString(item, ['deductionType']);

    return RecentActivity(
      id: item.id.toString(),
      type: type,
      status: status,
      title: title,
      date: date,
      description: description ?? item.reason,
      reason: item.reason,
      userId: item.userId?.toString(),
      userName: employeeNameAr ?? employeeNameEn,
      startDate: startDate,
      endDate: endDate,
      startTime: item.startTime?.toString(),
      endTime: item.endTime?.toString(),
      location: item.where?.toString(),
      leaveType: leaveType,
      rejectionReason: rejectionReason,
      totalHours: _toDouble(totalHoursValue),
      amount: _toDouble(amountValue),
      deductionType: deductionType,
    );
  }

  /// Convert HrRequestItem from API to RecentActivity
  factory RecentActivity.fromHrRequestItem(dynamic item) {
    // Same logic as fromHomeRequestItem since the structure is identical
    return RecentActivity.fromHomeRequestItem(item);
  }

  /// Convert SuperAdminRequest from dashboard API to RecentActivity
  factory RecentActivity.fromSuperAdminRequest(SuperAdminRequest r) {
    RequestType type;
    String title;
    switch (r.type.toLowerCase()) {
      case 'leave':
        type = RequestType.leave;
        title = 'إجازة';
        break;
      case 'permission':
        type = RequestType.permission;
        title = 'إذن خروج';
        break;
      case 'overtime':
        type = RequestType.overtime;
        title = 'عمل إضافي';
        break;
      case 'assignment':
        type = RequestType.assignment;
        title = 'مأمورية';
        break;
      default:
        type = RequestType.other;
        title = r.type;
    }

    RequestStatus status;
    switch (r.status.toLowerCase()) {
      case 'approved':
      case 'accepted':
        status = RequestStatus.approved;
        break;
      case 'rejected':
        status = RequestStatus.rejected;
        break;
      default:
        status = RequestStatus.pending;
    }

    String? description;
    if (r.type.toLowerCase() == 'leave' && r.startDate != null && r.endDate != null) {
      description = 'من ${r.startDate} إلى ${r.endDate}';
    } else if (r.type.toLowerCase() == 'permission' && r.startTime != null && r.endTime != null) {
      description = 'من ${r.startTime} إلى ${r.endTime}';
    } else if (r.type.toLowerCase() == 'assignment' && r.where != null) {
      description = r.where;
    }

    final date = _resolveRequestDate(r);
    final startDate = r.startDate != null ? DateTime.tryParse(r.startDate!) : null;
    final endDate = r.endDate != null ? DateTime.tryParse(r.endDate!) : null;

    return RecentActivity(
      id: r.id.toString(),
      type: type,
      status: status,
      title: title,
      date: date,
      description: description ?? r.reason,
      reason: r.reason,
      userId: r.userId,
      userName: r.employeeNameAr ?? r.employeeNameEn,
      startDate: startDate,
      endDate: endDate,
      startTime: r.startTime,
      endTime: r.endTime,
      location: r.where,
    );
  }

  /// Convert NotificationModel to RecentActivity
  factory RecentActivity.fromNotification(NotificationModel notification) {
    RequestType requestType;
    switch (notification.type) {
      case NotificationType.leave:
        requestType = RequestType.leave;
        break;
      case NotificationType.permission:
        requestType = RequestType.permission;
        break;
      case NotificationType.overtime:
        requestType = RequestType.overtime;
        break;
      default:
        requestType = RequestType.other;
    }

    RequestStatus requestStatus = RequestStatus.pending;
    final text = notification.title.toLowerCase();
    if (text.contains('موافقة') || text.contains('accepted') || text.contains('approved')) {
      requestStatus = RequestStatus.approved;
    } else if (text.contains('رفض') || text.contains('rejected')) {
      requestStatus = RequestStatus.rejected;
    }

    String summary = notification.title;
    if (notification.description != null && notification.description!.isNotEmpty) {
      summary += '\n\n${notification.description}';
    }

    // Try to extract username if it matches "طلب جديد: إجازة من صفيه ابراهيم..."
    String? userName;
    final match = RegExp(r'من\s+([^\.]+)\.').firstMatch(notification.title);
    if (match != null) {
      userName = match.group(1)?.trim();
    }

    return RecentActivity(
      id: notification.actionId ?? notification.id,
      type: requestType,
      status: requestStatus,
      title: notification.typeText,
      date: notification.date,
      description: summary,
      userName: userName,
    );
  }

  static DateTime _resolveRequestDate(dynamic item) {
    final type = item.type.toString().toLowerCase();

    final primaryDate = switch (type) {
      'permission' => item.date,
      'leave' => item.startDate ?? item.date,
      'assignment' => item.startDate ?? item.date,
      _ => item.date ?? item.startDate,
    };

    if (primaryDate is String && primaryDate.trim().isNotEmpty) {
      final parsedPrimary = DateTime.tryParse(primaryDate);
      if (parsedPrimary != null) {
        return parsedPrimary;
      }
    }

    final createdAt = item.createdAt?.toString();
    if (createdAt != null && createdAt.trim().isNotEmpty) {
      final parsedCreatedAt = DateTime.tryParse(createdAt);
      if (parsedCreatedAt != null) {
        return parsedCreatedAt;
      }
    }

    return DateTime.now();
  }

  static DateTime? _tryParseDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static String? _readOptionalString(dynamic item, List<String> keys) {
    for (final key in keys) {
      final value = _readDynamicField(item, key)?.toString();
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  static dynamic _readDynamicField(dynamic item, String key) {
    if (item is Map) {
      return item[key];
    }

    final dynamic source = item;
    try {
      switch (key) {
        case 'employeeNameAr':
          return source.employeeNameAr;
        case 'employeeNameEn':
          return source.employeeNameEn;
        case 'leaveType':
          return source.leaveType;
        case 'rejectionReason':
          return source.rejectionReason;
        case 'deductionType':
          return source.deductionType;
        case 'totalHours':
          return source.totalHours;
        case 'amount':
          return source.amount;
        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }
}

