import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class ServerClock {
  static const cairoZone = 'Africa/Cairo';
  static const maxSyncAge = Duration(minutes: 10);
  static bool _tzReady = false;

  DateTime? _lastSyncUtc;
  final Stopwatch _stopwatch = Stopwatch();
  final Duration Function()? _elapsedForTesting;

  ServerClock({Duration Function()? elapsedForTesting})
      : _elapsedForTesting = elapsedForTesting;

  static final ServerClock instance = ServerClock();

  static void _ensureTimeZones() {
    if (_tzReady) return;
    tzdata.initializeTimeZones();
    _tzReady = true;
  }

  void sync(DateTime serverInstant) {
    _lastSyncUtc = serverInstant.toUtc();
    _stopwatch
      ..reset()
      ..start();
  }

  Duration get _elapsed => _elapsedForTesting?.call() ?? _stopwatch.elapsed;

  bool get isSynced {
    final last = _lastSyncUtc;
    if (last == null) return false;
    return _elapsed <= maxSyncAge;
  }

  DateTime? tryNowServerUtc() {
    if (!isSynced) return null;
    return _lastSyncUtc!.add(_elapsed);
  }

  DateTime? tryCairoNow() {
    final utc = tryNowServerUtc();
    if (utc == null) return null;
    return cairoWall(utc);
  }

  static DateTime cairoWall(DateTime utcInstant) {
    _ensureTimeZones();
    final zoned = tz.TZDateTime.from(
      utcInstant.toUtc(),
      tz.getLocation(cairoZone),
    );
    return DateTime(
      zoned.year,
      zoned.month,
      zoned.day,
      zoned.hour,
      zoned.minute,
      zoned.second,
      zoned.millisecond,
    );
  }
}
