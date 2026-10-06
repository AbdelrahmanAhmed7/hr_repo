import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediconsult_internal/src/core/services/push_notification_service.dart';

void main() {
  group('background notification delivery', () {
    test('does not display notification payload a second time locally', () {
      const message = RemoteMessage(
        messageId: 'notification-message',
        notification: RemoteNotification(title: 'Title', body: 'Body'),
      );

      expect(shouldShowLocalNotificationInBackground(message), isFalse);
    });

    test('keeps the local display path for data-only messages', () {
      const message = RemoteMessage(
        messageId: 'data-message',
        data: {'title': 'Title', 'body': 'Body'},
      );

      expect(shouldShowLocalNotificationInBackground(message), isTrue);
    });

    test('tray time prefers the server createdAt from data', () {
      final message = RemoteMessage(
        messageId: 'm1',
        data: const {'title': 'T', 'createdAt': '2026-10-06T12:47:02.0344183'},
        sentTime: DateTime(2020, 1, 1),
      );

      expect(
        resolveTrayTimeMillis(message),
        DateTime(2026, 10, 6, 12, 47, 2, 34, 418).millisecondsSinceEpoch,
      );
    });

    test('tray time ignores junk numeric dates like 20010103', () {
      final message = RemoteMessage(
        messageId: 'junk',
        data: const {'title': 'T', 'createdAt': '20010103'},
        sentTime: DateTime(2026, 10, 6, 12, 47, 2),
      );

      // Must fall back to sentTime, never year 2001.
      expect(
        resolveTrayTimeMillis(message),
        DateTime(2026, 10, 6, 12, 47, 2).millisecondsSinceEpoch,
      );
    });

    test('tray time falls back to sentTime then now', () {
      final withSentTime = RemoteMessage(
        messageId: 'm2',
        data: const {'title': 'T'},
        sentTime: DateTime(2026, 10, 6, 12, 47, 2),
      );
      expect(
        resolveTrayTimeMillis(withSentTime),
        DateTime(2026, 10, 6, 12, 47, 2).millisecondsSinceEpoch,
      );

      final before = DateTime.now().millisecondsSinceEpoch;
      const noTime = RemoteMessage(messageId: 'm3', data: {'title': 'T'});
      final resolved = resolveTrayTimeMillis(noTime);
      expect(resolved, greaterThanOrEqualTo(before));
      expect(
        resolved,
        lessThanOrEqualTo(DateTime.now().millisecondsSinceEpoch),
      );
    });

    test('tray time rejects an invalid 2001 sentTime', () {
      final before = DateTime.now().millisecondsSinceEpoch;
      final message = RemoteMessage(
        messageId: 'bad-sent-time',
        data: const {'title': 'T'},
        sentTime: DateTime(2001, 3, 1),
      );

      final resolved = resolveTrayTimeMillis(message);

      expect(resolved, greaterThanOrEqualTo(before));
      expect(
        resolved,
        lessThanOrEqualTo(DateTime.now().millisecondsSinceEpoch),
      );
    });
  });
}
