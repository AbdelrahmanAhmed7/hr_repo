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
  });
}
