import 'package:intl/intl.dart';

class AppDateUtils {
  static bool isWeeklyOff(DateTime date) {
    return date.weekday == DateTime.friday || date.weekday == DateTime.saturday;
  }

  static final DateFormat _displayFormat = DateFormat('dd/MM/yyyy');

  static String formatDate(DateTime? date) {
    if (date == null) return '--';
    return _displayFormat.format(date.toLocal());
  }

  /// Sanity gate for parsed backend dates. Dart's [DateTime.tryParse] is
  /// lenient with bare digit strings (`"20010103"` → 3 Jan 2001,
  /// `"12345678"` → year 1238, `"00000000"` → year -1), so a numeric junk
  /// value in a date field would otherwise surface as an ancient date —
  /// e.g. a tray timestamp of 1/3/01 that also sinks the row to the bottom
  /// of the notification shade (Android orders by `when`).
  /// Only years in [minYear]..[maxYear] are trusted; anything else is
  /// treated as unparseable by the caller (which then falls back to a
  /// sensible default instead of displaying year 2001).
  static bool isSaneDateTime(
    DateTime? date, {
    int minYear = 2020,
    int maxYear = 2100,
  }) {
    if (date == null) return false;
    return date.year >= minYear && date.year <= maxYear;
  }

  static String formatTime12h(DateTime? date) {
    if (date == null) return '--';
    final local = date.toLocal();
    final period = local.hour < 12 ? 'AM' : 'PM';
    var h = local.hour % 12;
    if (h == 0) h = 12;
    final hh = h.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm $period';
  }

  static String formatDateTime12h(DateTime? date) {
    if (date == null) return '--';
    final local = date.toLocal();
    if (local.hour == 0 && local.minute == 0) return formatDate(local);
    return '${formatDate(local)} • ${formatTime12h(local)}';
  }

  static String formatTimeString12h(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '--';
    final parts = raw.trim().split(':');
    if (parts.length < 2) return raw.trim();
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return raw.trim();
    if (h < 0 || h > 23 || m < 0 || m > 59) return raw.trim();

    return formatTime12h(DateTime(2026, 1, 1, h, m));
  }

  static String formatTimeRange12h(String? start, String? end) {
    final s = formatTimeString12h(start);
    final e = formatTimeString12h(end);
    if (s == '--' || e == '--') return '--';
    return '$s - $e';
  }

  static DateTime? parseFlexible(Object? raw) {
    if (raw == null) return null;

    if (raw is num) {
      return _fromEpoch(raw);
    }

    var s = _normalizeDigits(raw.toString().trim());
    if (s.isEmpty) return null;

    final dotNet = RegExp(r'/Date\((\-?\d+)([+-]\d{4})?\)/').firstMatch(s);
    if (dotNet != null) {
      final n = int.tryParse(dotNet.group(1)!);
      if (n != null) {
        final epoch = _fromEpoch(n);
        if (epoch != null) return epoch;
      }
    }

    if (RegExp(r'^\-?\d{9,}$').hasMatch(s)) {
      final n = int.tryParse(s);
      if (n != null) {
        final epoch = _fromEpoch(n);
        if (epoch != null) return epoch;
      }
    }

    final iso = DateTime.tryParse(s);
    if (iso != null) return iso;

    s = _normalizeForPatterns(s);

    for (final fmt in const [
      'd/M/yy',
      'd/M/yy HH:mm',
      'd/M/yy HH:mm:ss',
      'd/M/yy h:mm a',
      'd/M/yy hh:mm a',
      'd/M/yy h:mm:ss a',
      'dd/MM/yy',
      'dd/MM/yy HH:mm',
      'dd/MM/yy HH:mm:ss',
      'dd/MM/yy h:mm a',
      'dd/MM/yy hh:mm a',
      'M/d/yy',
      'M/d/yy h:mm a',
      'M/d/yy hh:mm a',
      'MM/dd/yy',
      'MM/dd/yy h:mm a',
      'MM/dd/yy hh:mm a',
    ]) {
      final parsed = _tryPattern(fmt, s);
      if (parsed != null) return parsed;
    }

    for (final fmt in const [
      'yyyy/MM/dd',
      'yyyy/MM/dd HH:mm',
      'yyyy/MM/dd HH:mm:ss',
      'yyyy/MM/dd h:mm a',
      'yyyy/MM/dd hh:mm a',
    ]) {
      final parsed = _tryPattern(fmt, s);
      if (parsed != null) return parsed;
    }

    for (final fmt in const [
      'dd/MM/yyyy',
      'dd/MM/yyyy HH:mm',
      'dd/MM/yyyy HH:mm:ss',
      'dd/MM/yyyy h:mm a',
      'dd/MM/yyyy hh:mm a',
      'dd/MM/yyyy h:mm:ss a',
      'dd/MM/yyyy hh:mm:ss a',
    ]) {
      final parsed = _tryPattern(fmt, s);
      if (parsed != null) return parsed;
    }
    for (final fmt in const [
      'MM/dd/yyyy',
      'MM/dd/yyyy HH:mm',
      'MM/dd/yyyy HH:mm:ss',
      'MM/dd/yyyy h:mm a',
      'MM/dd/yyyy hh:mm a',
      'MM/dd/yyyy h:mm:ss a',
      'MM/dd/yyyy hh:mm:ss a',
    ]) {
      final parsed = _tryPattern(fmt, s);
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

  static DateTime? _tryPattern(String format, String input) {
    try {
      return DateFormat(format).tryParseStrict(input);
    } catch (_) {
      return null;
    }
  }

  static String _normalizeDigits(String s) {
    if (!RegExp(r'[٠-٩۰-۹]').hasMatch(s)) return s;
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    const eastern = '۰۱۲۳۴۵۶۷۸۹';
    final buffer = StringBuffer();
    for (final rune in s.runes) {
      final ch = String.fromCharCode(rune);
      final a = arabic.indexOf(ch);
      if (a != -1) {
        buffer.write(a);
        continue;
      }
      final e = eastern.indexOf(ch);
      if (e != -1) {
        buffer.write(e);
        continue;
      }
      buffer.write(ch);
    }
    return buffer.toString();
  }

  static String _normalizeForPatterns(String s) {
    var out = s;
    out = out.replaceAllMapped(
      RegExp(r'(\d{2}:\d{2}:\d{2})\.\d+'),
      (m) => m.group(1)!,
    );
    out = out.replaceAll('-', '/').replaceAll('.', '/');
    out = out.replaceAll('ص', 'AM').replaceAll('م', 'PM');
    return out.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
