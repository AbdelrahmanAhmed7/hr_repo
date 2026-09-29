import 'package:flutter_test/flutter_test.dart';
import 'package:mediconsult_internal/src/core/time/server_clock.dart';

void main() {
  test('unsynced clock reports unknown', () {
    final clock = ServerClock();
    expect(clock.isSynced, isFalse);
    expect(clock.tryNowServerUtc(), isNull);
    expect(clock.tryCairoNow(), isNull);
  });

  test('sync anchors Cairo wall time (Sept, UTC+3)', () {
    final clock = ServerClock();
    clock.sync(DateTime.utc(2026, 9, 28, 10, 0));
    expect(clock.isSynced, isTrue);
    final cairo = clock.tryCairoNow()!;
    expect([cairo.year, cairo.month, cairo.day], [2026, 9, 28]);
    expect([cairo.hour, cairo.minute], [13, 0]);
  });

  test('stale sync reports unknown', () {
    final fresh = ServerClock(elapsedForTesting: () => Duration(minutes: 9));
    fresh.sync(DateTime.utc(2026, 9, 28, 10, 0));
    expect(fresh.isSynced, isTrue);
    expect(fresh.tryCairoNow(), isNotNull);

    final stale = ServerClock(elapsedForTesting: () => Duration(minutes: 11));
    stale.sync(DateTime.utc(2026, 9, 28, 10, 0));
    expect(stale.isSynced, isFalse);
    expect(stale.tryNowServerUtc(), isNull);
    expect(stale.tryCairoNow(), isNull);
  });

  test('Cairo DST spring forward (2026-04-24)', () {
    expect(
      ServerClock.cairoWall(DateTime.utc(2026, 4, 23, 21, 59)),
      DateTime(2026, 4, 23, 23, 59),
    );
    expect(
      ServerClock.cairoWall(DateTime.utc(2026, 4, 23, 22, 0)),
      DateTime(2026, 4, 24, 1, 0),
    );
  });

  test('Cairo DST fall back (2026-10-29)', () {
    expect(
      ServerClock.cairoWall(DateTime.utc(2026, 10, 29, 20, 59)),
      DateTime(2026, 10, 29, 23, 59),
    );
    expect(
      ServerClock.cairoWall(DateTime.utc(2026, 10, 29, 21, 0)),
      DateTime(2026, 10, 29, 23, 0),
    );
  });
}
