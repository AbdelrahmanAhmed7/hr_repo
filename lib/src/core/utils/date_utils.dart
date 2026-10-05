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
  ///     Legacy .NET `/Date(123456789)/` payloads are unwrapped first.
  ///  3. Legacy 2-digit-year values (`d/M/yy`, etc.) such as "1/3/01",
  ///     resolved to 20yy BEFORE the full-year patterns below — intl's `yyyy`
  ///     would otherwise swallow "01" and produce year 1 (year 0001).
  ///  4. `dd/MM/yyyy[ HH:mm[:ss]][ a]`               (house format, first)
  ///  5. `MM/dd/yyyy[ HH:mm[:ss]][ a]`               (fallback for US feeds)
  ///
  /// Separators `/`, `-` and `.` are all accepted, an optional 12-hour
  /// `AM`/`PM` (or Arabic `ص`/`م`) suffix is understood, and Arabic-Indic
  /// digits (`٠١٢٣٤٥٦٧٨٩`) are normalized before parsing.
  ///
  /// Returns `null` when the value is not a recognised date/time so callers
  /// never end up formatting a fabricated `DateTime.now()` as the real date.
  static DateTime? parseFlexible(Object? raw) {
    if (raw == null) return null;

    if (raw is num) {
      return _fromEpoch(raw);
    }

    var s = _normalizeDigits(raw.toString().trim());
    if (s.isEmpty) return null;

    // Legacy .NET JSON date: "/Date(1769817600000)/" (optional timezone).
    final dotNet = RegExp(r'/Date\((\-?\d+)([+-]\d{4})?\)/').firstMatch(s);
    if (dotNet != null) {
      final n = int.tryParse(dotNet.group(1)!);
      if (n != null) {
        final epoch = _fromEpoch(n);
        if (epoch != null) return epoch;
      }
    }

    // Epoch milliseconds/seconds serialized as a plain numeric string.
    if (RegExp(r'^\-?\d{9,}$').hasMatch(s)) {
      final n = int.tryParse(s);
      if (n != null) {
        final epoch = _fromEpoch(n);
        if (epoch != null) return epoch;
      }
    }

    // ISO-8601, `yyyy-MM-dd`, `yyyy-MM-dd HH:mm[:ss]`.
    final iso = DateTime.tryParse(s);
    if (iso != null) return iso;

    // Normalize separators and 12-hour clock so one pattern set covers
    // "31/01/2026", "31-01-2026", "31.01.2026" and "08:30 PM" / "08:30 م".
    // NOTE: fractional seconds are stripped BEFORE separator replacement,
    // otherwise "08:30:00.000" would become "08:30:00/000".
    s = _normalizeForPatterns(s);

    // 2-digit-year legacy payloads ("1/3/01" => 01/03/2001). MUST run before
    // every `yyyy` pattern: intl's `yyyy` happily swallows a 2-digit "01"
    // and turns it into year 1 (year 0001), which is not a real date.
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

    // `yyyy/MM/dd[ HH:mm[:ss]]` (separator variant of ISO ordering).
    // Runs AFTER the 2-digit-year block above so "1/3/01" is never
    // misread as year 1 by the greedy `yyyy` token.
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

    // House format first: dd/MM/yyyy. MM/dd/yyyy is only tried when the first
    // pass fails (e.g. "12/15/2026" -> invalid month in dd/MM ordering).
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

  /// Convert Arabic-Indic / Eastern Arabic-Indic digits to Latin digits so
  /// values like "٣١/٠١/٢٠٢٦" parse exactly like "31/01/2026".
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

  /// Normalize separators (`.`/`-` -> `/`) and 12-hour markers
  /// (`ص`/`م` -> `AM`/`PM`) and drop fractional seconds so a single set of
  /// `dd/MM/yyyy` / `MM/dd/yyyy` patterns covers every backend variant.
  static String _normalizeForPatterns(String s) {
    var out = s;
    // Strip fractional seconds FIRST: "08:30:00.000" -> "08:30:00".
    // (Must run before the dot-to-slash replacement below, otherwise the
    // ".000" would turn into "/000".)
    out = out.replaceAllMapped(
      RegExp(r'(\d{2}:\d{2}:\d{2})\.\d+'),
      (m) => m.group(1)!,
    );
    // Unify day-first separators: "31-01-2026" / "31.01.2026" -> "31/01/2026".
    // Year-first orderings ("2026.01.31") are normalized too so the
    // `yyyy/MM/dd` patterns below accept them.
    out = out.replaceAll('-', '/').replaceAll('.', '/');
    out = out.replaceAll('ص', 'AM').replaceAll('م', 'PM');
    return out.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}