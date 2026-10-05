import 'package:flutter_test/flutter_test.dart';
import 'package:mediconsult_internal/src/core/utils/date_utils.dart';
import 'package:mediconsult_internal/src/features/notifications/models/notification.dart';
import 'package:intl/intl.dart';

void main() {
  group('AppDateUtils.parseFlexible', () {
    test('ISO-8601 date near the start of a month', () {
      final d = AppDateUtils.parseFlexible('2026-03-01T08:30:00');

      expect(d, isNotNull);
      expect(d!.year, 2026);
      expect(d.month, 3);
      expect(d.day, 1);
      expect(d.hour, 8);
      expect(AppDateUtils.formatDate(d), '01/03/2026');
    });

    test('timezone-aware ISO string is converted to local time', () {
      final d = AppDateUtils.parseFlexible('2026-03-01T00:30:00+02:00');

      expect(d, isNotNull);
      expect(d!.toUtc(), DateTime.utc(2026, 2, 28, 22, 30));
      expect(
        AppDateUtils.formatDate(d),
        DateFormat('dd/MM/yyyy').format(d.toLocal()),
      );
    });

    test('the reported "1/3/01" value resolves to a real calendar date', () {
      // `DateTime.parse('1/3/01')` throws, so the old code fell back to
      // `DateTime.now()` and showed a fabricated date. This value is actually
      // 01/03/2001 in the house dd/MM/yyyy convention.
      final d = AppDateUtils.parseFlexible('1/3/01');

      expect(d, isNotNull);
      expect(d!.year, 2001);
      expect(d.month, 3);
      expect(d.day, 1);
      expect(AppDateUtils.formatDate(d), '01/03/2001');
    });

    test('epoch milliseconds string is parsed as an epoch, not a date string', () {
      // 2001-03-01T00:00:00Z.
      final d = AppDateUtils.parseFlexible('983404800000');

      expect(d, isNotNull);
      expect(d!.toUtc(), DateTime.utc(2001, 3, 1));
      expect(AppDateUtils.formatDate(d), '01/03/2001');
    });

    test('dd/MM/yyyy is preferred over MM/dd/yyyy', () {
      final d = AppDateUtils.parseFlexible('01/03/2026');

      expect(d, isNotNull);
      expect(d!.year, 2026);
      expect(d.month, 3); // 1 March, not 3 January.
      expect(d.day, 1);
      expect(AppDateUtils.formatDate(d), '01/03/2026');
    });

    test('12-hour clock with AM/PM parses (backend default string)', () {
      final am = AppDateUtils.parseFlexible('31/01/2026 08:30:00 AM');
      expect(am, isNotNull);
      expect(am!.day, 31);
      expect(am.month, 1);
      expect(am.hour, 8);

      final pm = AppDateUtils.parseFlexible('31/01/2026 08:30:00 PM');
      expect(pm, isNotNull);
      expect(pm!.hour, 20);

      final us = AppDateUtils.parseFlexible('01/31/2026 08:30:00 AM');
      expect(us, isNotNull);
      expect(us!.day, 31);
      expect(us.month, 1);
    });

    test('dash/dot separators and yyyy/MM/dd ordering parse', () {
      for (final s in ['31-01-2026', '31.01.2026', '2026/01/31']) {
        final d = AppDateUtils.parseFlexible(s);
        expect(d, isNotNull, reason: s);
        expect(d!.year, 2026, reason: s);
        expect(d.month, 1, reason: s);
        expect(d.day, 31, reason: s);
      }
      final withTime = AppDateUtils.parseFlexible('31-01-2026 08:30:00');
      expect(withTime, isNotNull);
      expect(withTime!.hour, 8);
    });

    test('legacy .NET /Date()/ payload parses as epoch', () {
      final d = AppDateUtils.parseFlexible('/Date(1769817600000)/');

      expect(d, isNotNull);
      expect(d!.toUtc(), DateTime.utc(2026, 1, 31));
    });

    test('Arabic-Indic digits parse like Latin digits', () {
      final d = AppDateUtils.parseFlexible('٣١/٠١/٢٠٢٦');

      expect(d, isNotNull);
      expect(d!.year, 2026);
      expect(d.month, 1);
      expect(d.day, 31);
      expect(AppDateUtils.formatDate(d), '31/01/2026');
    });

    test('fractional seconds do not break slash formats', () {
      final d = AppDateUtils.parseFlexible('31/01/2026 08:30:00.000');

      expect(d, isNotNull);
      expect(d!.day, 31);
      expect(d.hour, 8);
      expect(d.minute, 30);
    });
  });

  group('NotificationModel.fromApi', () {
    test('dd/MM/yyyy createdAt is kept as the real date', () {
      final model = NotificationModel.fromApi({
        'id': '7',
        'type': 'leave',
        'message': 'طلبات بانتظار الموافقة',
        'isRead': false,
        'createdAt': '01/03/2026 08:30:00',
      });

      expect(model.date.year, 2026);
      expect(model.date.month, 3);
      expect(model.date.day, 1);
    });

    test('ISO-8601 createdAt is parsed normally', () {
      final model = NotificationModel.fromApi({
        'id': '8',
        'type': 'permission',
        'message': 'إشعار',
        'isRead': true,
        'createdAt': '2026-05-20T14:15:00',
      });

      expect(model.date.year, 2026);
      expect(model.date.month, 5);
      expect(model.date.day, 20);
    });

    test('null createdAt still falls back without crashing', () {
      final model = NotificationModel.fromApi({
        'id': '9',
        'type': 'general',
        'message': 'إشعار',
        'isRead': false,
        'createdAt': null,
      });

      expect(model.date, isNotNull);
    });

    test('capitalized CreatedAt key is honoured', () {
      final model = NotificationModel.fromApi({
        'id': '10',
        'type': 'general',
        'message': 'إشعار',
        'isRead': false,
        'CreatedAt': '2026-01-31T08:30:00',
      });

      expect(model.date.year, 2026);
      expect(model.date.month, 1);
      expect(model.date.day, 31);
    });

    test('near-future date from clock skew shows as now, not a stale date',
        () {
      final model = NotificationModel.fromApi({
        'id': '11',
        'type': 'general',
        'message': 'إشعار جديد',
        'isRead': false,
        'createdAt':
            DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
      });

      expect(model.timeAgo, 'الآن');
    });
  });
}