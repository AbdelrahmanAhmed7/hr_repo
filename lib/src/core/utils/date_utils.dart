import 'package:intl/intl.dart';

class AppDateUtils {
  /// Weekly off days in the app: Friday & Saturday.
  static bool isWeeklyOff(DateTime date) {
    return date.weekday == DateTime.friday || date.weekday == DateTime.saturday;
  }

  /// Single display format used for every date rendered from an API value.
  /// This is the house format (see payslip/absence dates) and keeps the
  /// day/month order consistent across every screen.
  static final DateFormat _displayFormat = DateFormat('dd/MM/yyyy');

  static String formatDate(DateTime? date) {
    if (date == null) return '--';
    return _displayFormat.format(date.toLocal());
  }

  /// Parse a date/time value coming from the API (notifications, requests,
  /// home feed) in the documented, expected shapes, in priority order:
  ///
  ///  1. ISO-8601 / `yyyy-MM-dd[ HH:mm[:ss]]`        -> DateTime.parse
  ///  2. Epoch milliseconds (> 1e11), seconds (> 1e9), as a number or
  ///     numeric string (an epoch NEVER parses as a date string, so it must be
  ///     detected explicitly instead of silently turning into a bogus date).
  ///  3. Legacy 2-digit-year values (`d/M/yy`, etc.) such as "1/3/01",
  ///     resolved to 20yy BEFORE the full-year patterns below — intl's `yyyy`
  ///     would otherwise swallow "01" and produce year 1 (year 0001).
  ///  4. `dd/MM/yyyy[ HH:mm[:ss]]`                   (house format, first)
  ///  5. `MM/dd/yyyy[ HH:mm[:ss]]`                   (fallback for US feeds)
  ///
  /// Returns `null` when the value is not a recognised date/time so callers
  /// never end up formatting a fabricated `DateTime.now()` as the real date.
  static DateTime? parseFlexible(Object? raw) {
    if (raw == null) return null;

    if (raw is num) {
      return _fromEpoch(raw);
    }

    final s = raw.toString().trim();
    if (s.isEmpty) return null;

    // Epoch milliseconds/seconds serialized as a plain numeric string.
    if (RegExp(r'^\d{9,}$').hasMatch(s)) {
      final n = int.tryParse(s);
      if (n != null) {
        final epoch = _fromEpoch(n);
        if (epoch != null) return epoch;
      }
    }

    // ISO-8601, `yyyy-MM-dd`, `yyyy-MM-dd HH:mm[:ss]`.
    final iso = DateTime.tryParse(s);
    if (iso != null) return iso;

    // 2-digit-year legacy payloads ("1/3/01" => 01/03/2001). MUST run before
    // the `yyyy` patterns: intl's `yyyy` happily swallows a 2-digit "01" and
    // turns it into year 1 (year 0001), which is not a real calendar date.
    for (final fmt in const [
      'd/M/yy',
      'dd/MM/yy',
      'M/d/yy',
      'MM/dd/yy',
    ]) {
      final parsed = DateFormat(fmt).tryParseStrict(s);
      if (parsed != null) return parsed;
    }

    // House format first: dd/MM/yyyy. MM/dd/yyyy is only tried when the first
    // pass fails (e.g. "12/15/2026" -> invalid month in dd/MM ordering).
    for (final fmt in const [
      'dd/MM/yyyy',
      'dd/MM/yyyy HH:mm',
      'dd/MM/yyyy HH:mm:ss',
    ]) {
      final parsed = DateFormat(fmt).tryParseStrict(s);
      if (parsed != null) return parsed;
    }
    for (final fmt in const [
      'MM/dd/yyyy',
      'MM/dd/yyyy HH:mm',
      'MM/dd/yyyy HH:mm:ss',
    ]) {
      final parsed = DateFormat(fmt).tryParseStrict(s);
      if (parsed != null) return parsed;
    }

    return null;
  }

  static DateTime? _fromEpoch(num value) {
    if (value.abs() >= 100000000000) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true);
    }
    if (value.abs() >= 1000000000) {
      return DateTime.fromMillisecondsSinceEpoch(
        value.toInt() * 1000,
        isUtc: true,
      );
    }
    return null;
  }
}