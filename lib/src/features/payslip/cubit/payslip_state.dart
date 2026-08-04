import 'package:equatable/equatable.dart';

import '../models/payslip.dart';
import '../utils/payslip_period.dart';

enum PayslipLoadStatus { initial, loading, success, failure }

enum PayslipPdfStatus { initial, downloading, success, failure }

class PayslipState extends Equatable {
  final PayslipLoadStatus loadStatus;
  final PayslipPdfStatus pdfStatus;
  final Payslip? payslip;
  final String? errorMessage;
  final String? pdfErrorMessage;
  final int selectedMonth;
  final int selectedYear;
  final DateTime? hireDate;

  const PayslipState({
    required this.selectedMonth,
    required this.selectedYear,
    this.loadStatus = PayslipLoadStatus.initial,
    this.pdfStatus = PayslipPdfStatus.initial,
    this.payslip,
    this.errorMessage,
    this.pdfErrorMessage,
    this.hireDate,
  });

  bool get isFuturePeriod {
    return PayslipPeriod.isFuturePeriod(
      month: selectedMonth,
      year: selectedYear,
    );
  }

  bool get isPreHirePeriod {
    if (hireDate == null) return false;
    final selectedMonthEnd = DateTime(selectedYear, selectedMonth + 1, 0);
    return selectedMonthEnd.isBefore(hireDate!);
  }

  PayslipState copyWith({
    PayslipLoadStatus? loadStatus,
    PayslipPdfStatus? pdfStatus,
    Payslip? payslip,
    String? errorMessage,
    String? pdfErrorMessage,
    int? selectedMonth,
    int? selectedYear,
    DateTime? hireDate,
    bool clearPayslip = false,
    bool clearHireDate = false,
  }) {
    return PayslipState(
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedYear: selectedYear ?? this.selectedYear,
      loadStatus: loadStatus ?? this.loadStatus,
      pdfStatus: pdfStatus ?? this.pdfStatus,
      payslip: clearPayslip ? null : (payslip ?? this.payslip),
      errorMessage: errorMessage,
      pdfErrorMessage: pdfErrorMessage,
      hireDate: clearHireDate ? null : (hireDate ?? this.hireDate),
    );
  }

  @override
  List<Object?> get props => [
    loadStatus,
    pdfStatus,
    payslip,
    errorMessage,
    pdfErrorMessage,
    selectedMonth,
    selectedYear,
    hireDate,
  ];
}
