import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediconsult_internal/src/features/missions/create_mission_controller.dart';

void main() {
  group('CreateMissionController', () {
    late CreateMissionController controller;

    setUp(() {
      controller = CreateMissionController()..initialize();
    });

    tearDown(() {
      controller.dispose();
    });

    test('initialize sets current dates', () {
      expect(controller.selectedDate, isNotNull);
      expect(controller.endDate, isNotNull);
    });

    test('selectTimeSlot sets slot and default times', () {
      controller.selectTimeSlot('morning');

      expect(controller.selectedTimeSlot, 'morning');
      expect(controller.startTime, const TimeOfDay(hour: 9, minute: 0));
      expect(controller.endTime, const TimeOfDay(hour: 13, minute: 0));
    });

    test('toggleMultiDay true forces full day slot', () {
      controller.toggleMultiDay(true);

      expect(controller.isMultiDay, isTrue);
      expect(controller.selectedTimeSlot, 'full_day');
      expect(controller.startTime, const TimeOfDay(hour: 0, minute: 0));
      expect(controller.endTime, const TimeOfDay(hour: 23, minute: 59));
    });

    test('calculateDuration returns empty when invalid', () {
      controller.startTime = const TimeOfDay(hour: 10, minute: 0);
      controller.endTime = const TimeOfDay(hour: 9, minute: 0);

      expect(controller.calculateDuration(), isEmpty);
    });

    test('calculateDuration returns formatted value for valid duration', () {
      controller.selectedDate = DateTime(2026, 3, 1);
      controller.endDate = DateTime(2026, 3, 1);
      controller.startTime = const TimeOfDay(hour: 9, minute: 0);
      controller.endTime = const TimeOfDay(hour: 11, minute: 30);

      final duration = controller.calculateDuration();

      expect(duration, isNotEmpty);
    });
  });
}
