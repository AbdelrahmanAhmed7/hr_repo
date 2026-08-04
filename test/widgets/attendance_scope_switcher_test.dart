import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediconsult_internal/src/features/attendance/widgets/sections/attendance_scope_switcher.dart';

void main() {
  testWidgets('AttendanceScopeSwitcher emits selected scope', (tester) async {
    AttendancePeriodScope? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: AttendanceScopeSwitcher(
            selectedScope: AttendancePeriodScope.month,
            onScopeChanged: (value) => selected = value,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ChoiceChip).first);
    await tester.pumpAndSettle();

    expect(selected, AttendancePeriodScope.day);
  });
}
