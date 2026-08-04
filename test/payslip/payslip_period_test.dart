import 'package:flutter_test/flutter_test.dart';
import 'package:mediconsult_internal/src/features/payslip/utils/payslip_period.dart';

void main() {
  group('PayslipPeriod', () {
    test('keeps previous month active through the 5th payday', () {
      final period = PayslipPeriod.activePeriod(DateTime(2026, 8, 5));

      expect(period.year, 2026);
      expect(period.month, 7);
    });

    test('switches to current month after the 5th payday', () {
      final period = PayslipPeriod.activePeriod(DateTime(2026, 8, 6));

      expect(period.year, 2026);
      expect(period.month, 8);
    });

    test('handles January by selecting previous December before payday', () {
      final period = PayslipPeriod.activePeriod(DateTime(2026, 1, 3));

      expect(period.year, 2025);
      expect(period.month, 12);
    });

    test('marks months after the active period as future', () {
      final isFuture = PayslipPeriod.isFuturePeriod(
        month: 8,
        year: 2026,
        comparedTo: DateTime(2026, 8, 5),
      );

      expect(isFuture, isTrue);
    });
  });
}
