import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediconsult_internal/src/features/home/models/recent_activity.dart';
import 'package:mediconsult_internal/src/features/requests/widgets/unified_request_card.dart';

RecentActivity _activity(DateTime date) {
  return RecentActivity(
    id: '1',
    type: RequestType.permission,
    status: RequestStatus.approved,
    title: 'إذن خروج',
    date: date,
    reason: 'سبب',
    startTime: '09:00',
    endTime: '10:00',
  );
}

Future<void> _pumpCard(WidgetTester tester, DateTime date) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: UnifiedRequestCard(request: _activity(date)),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the time next to the relative date', (tester) async {
    final now = DateTime.now();
    await _pumpCard(tester, DateTime(now.year, now.month, now.day, 8, 17));

    expect(find.textContaining('08:17'), findsOneWidget);
  });

  testWidgets('hides midnight time for date-only sources', (tester) async {
    final now = DateTime.now();
    await _pumpCard(tester, DateTime(now.year, now.month, now.day));

    expect(find.textContaining('00:00'), findsNothing);
  });
}
