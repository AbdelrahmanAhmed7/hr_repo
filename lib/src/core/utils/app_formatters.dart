import 'package:intl/intl.dart';

/// Centralised formatters shared across the app.
///
/// Keeps display formatting consistent on every screen; add new formatters
/// here instead of creating per-feature helpers.
class AppFormatters {
  /// House currency format: `<amount> ج.م`.
  ///
  /// Arabic RTL app, so the symbol is the trailing Arabic abbreviation
  /// `ج.م` (see the payslip, bonuses, penalties and requests screens).
  /// Western digits with thousands separators; up to 2 decimal places with
  /// trailing zeros trimmed (`4,500` not `4,500.00`).
  ///
  /// Returns `--` for a null amount (mirrors [AppDateUtils.formatDate]).
  static final NumberFormat _currencyFormat =
      NumberFormat('#,##0.##', 'en_US');

  static String currency(double? amount) {
    if (amount == null) return '--';
    return '${_currencyFormat.format(amount)} ج.م';
  }
}