import 'package:flutter_test/flutter_test.dart';
import 'package:mediconsult_internal/src/features/missions/widgets/sections/mission_submit_bar.dart';
import 'package:mediconsult_internal/src/shared/components/custom_button.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('MissionSubmitBar disables submit while loading', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: MissionSubmitBar(
            isSubmitting: true,
            onSubmit: null,
          ),
        ),
      ),
    );

    final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
    expect(button.isLoading, isTrue);
    expect(button.onPressed, isNull);
  });
}
