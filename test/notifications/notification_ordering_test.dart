import 'package:flutter_test/flutter_test.dart';
import 'package:mediconsult_internal/src/core/network/dio_client.dart';
import 'package:mediconsult_internal/src/features/notifications/cubit/notifications_cubit.dart';
import 'package:mediconsult_internal/src/features/notifications/models/notification.dart';
import 'package:mediconsult_internal/src/features/notifications/repository/notifications_repository.dart';

/// No mocks: hand fake overrides the two read methods, no HTTP is performed.
class _FakeRepo extends NotificationsRepository {
  _FakeRepo() : super(DioClient());

  @override
  Future<List<NotificationModel>> getNotifications() async =>
      NotificationModel.fromApiList(const [
        {
          'id': 1779,
          'userId': 'u',
          'type': 'Meeting',
          'requestId': 11,
          'message': 'old',
          'isRead': true,
          'createdAt': '2026-03-31T16:36:23.6564246',
        },
        {
          'id': 12062,
          'userId': 'u',
          'type': 'Direct',
          'requestId': 0,
          'message': 'mid',
          'isRead': false,
          'createdAt': '2026-10-06T12:46:00.3385244',
        },
        {
          'id': 12063,
          'userId': 'u',
          'type': 'Direct',
          'requestId': 0,
          'message': 'new',
          'isRead': false,
          'createdAt': '2026-10-06T12:47:02.0344183',
        },
      ]);

  @override
  Future<int> getUnreadCount() async => 2;
}

/// Regression test: newest notifications must always render on top with
/// their real server dates — never with a fabricated date, never buried
/// at the bottom after an API-order/refetch/optimistic-update path.
void main() {
  test('fromApiList keeps real server dates (7-fraction-digit ISO)', () {
    final notifs = NotificationModel.fromApiList(const [
      {
        'id': 12063,
        'userId': 'u',
        'type': 'Direct',
        'requestId': 0,
        'message': 'new',
        'isRead': false,
        'createdAt': '2026-10-06T12:47:02.0344183',
      },
      {
        'id': 1779,
        'userId': 'u',
        'type': 'Meeting',
        'requestId': 11,
        'message': 'old',
        'isRead': true,
        'createdAt': '2026-03-31T16:36:23.6564246',
      },
    ]);
    expect(notifs[0].date, DateTime(2026, 10, 6, 12, 47, 2, 34, 418));
    expect(notifs[1].date, DateTime(2026, 3, 31, 16, 36, 23, 656, 424));
  });

  test('cubit emits newest-first even when API returns oldest-first',
      () async {
    final cubit = NotificationsCubit(_FakeRepo());
    await cubit.loadNotifications();

    expect(
      cubit.state.notifications.map((n) => n.id).toList(),
      ['12063', '12062', '1779'],
    );

    // Optimistic updates must not break the order either.
    cubit.markAsRead('12063');
    expect(
      cubit.state.notifications.map((n) => n.id).toList(),
      ['12063', '12062', '1779'],
    );
    await cubit.close();
  });
}
