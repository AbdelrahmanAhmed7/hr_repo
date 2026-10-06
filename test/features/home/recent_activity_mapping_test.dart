import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediconsult_internal/src/features/home/models/recent_activity.dart';
import 'package:mediconsult_internal/src/features/permissions/models/permission_request.dart';

void main() {
  test('fromPermissionRequest uses created moment with time, keeps day', () {
    final permission = PermissionRequest(
      id: '1737',
      date: DateTime(2026, 10, 4),
      startTime: const TimeOfDay(hour: 9, minute: 0),
      endTime: const TimeOfDay(hour: 10, minute: 0),
      reason: 'شخصي',
      status: PermissionStatus.pending,
      submittedDate: DateTime(2026, 10, 4, 8, 17, 42),
      rejectionReason: null,
    );

    final activity = RecentActivity.fromPermissionRequest(permission);

    expect(activity.date, DateTime(2026, 10, 4, 8, 17, 42));
    expect(activity.date.hour, 8);
    expect(activity.startDate, DateTime(2026, 10, 4));
    expect(activity.title, 'تأخير صباحي');
  });
}
