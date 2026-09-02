import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/app_exception.dart';
import '../../home/models/employee_info.dart';
import '../models/payslip.dart';
import '../repository/payslip_repository.dart';
import '../utils/payslip_period.dart';
import 'payslip_state.dart';

class PayslipCubit extends Cubit<PayslipState> {
  final PayslipRepository _repository;

  PayslipCubit(this._repository)
    : super(
        PayslipState(
          selectedMonth: PayslipPeriod.defaultMonth(),
          selectedYear: PayslipPeriod.defaultYear(),
        ),
      );

  Future<void> loadPayslip() async {
    // Load hire date if not already loaded
    DateTime? hireDate = state.hireDate;
    if (hireDate == null) {
      final employeeInfo = await EmployeeInfo.loadFromStorage();
      hireDate = employeeInfo?.hireDate;
    }

    // Check for future period
    if (state.isFuturePeriod) {
      emit(
        state.copyWith(
          loadStatus: PayslipLoadStatus.success,
          errorMessage: null,
          clearPayslip: true,
          hireDate: hireDate,
        ),
      );
      return;
    }

    // Check for pre-hire period
    final isPreHire =
        hireDate != null &&
        DateTime(
          state.selectedYear,
          state.selectedMonth + 1,
          0,
        ).isBefore(hireDate);

    if (isPreHire) {
      // Create empty payslip for pre-hire period
      final emptyPayslip = _createPreHirePayslip(hireDate);
      emit(
        state.copyWith(
          loadStatus: PayslipLoadStatus.success,
          payslip: emptyPayslip,
          errorMessage: null,
          hireDate: hireDate,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        loadStatus: PayslipLoadStatus.loading,
        errorMessage: null,
        hireDate: hireDate,
      ),
    );

    try {
      final payslip = await _repository.getMyPayslip(
        month: state.selectedMonth,
        year: state.selectedYear,
      );

      emit(
        state.copyWith(
          loadStatus: PayslipLoadStatus.success,
          payslip: payslip,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          loadStatus: PayslipLoadStatus.failure,
          errorMessage: AppException.from(e).message,
          clearPayslip: true,
        ),
      );
    }
  }

  /// Creates an empty payslip for pre-hire period
  Payslip _createPreHirePayslip(DateTime? hireDate) {
    return Payslip(
      fullNameAr: '',
      fullNameEn: '',
      departmentName: null,
      jobTitle: null,
      employmentMode: null,
      month: state.selectedMonth,
      year: state.selectedYear,
      actualWorkingDays: 0,
      salaryDetails: SalaryDetails(
        grossSalary: 0,
        totalEarnings: 0,
        netSalary: 0,
        allowances: const Allowances(
          housing: 0,
          meal: 0,
          transportation: 0,
          insurance: 0,
          additional: 0,
          other: 0,
          total: 0,
        ),
        deductions: const Deductions(
          lateAmount: 0,
          lateHours: 0,
          absenceAmount: 0,
          absenceDays: 0,
          penaltiesAmount: 0,
          advancesAmount: 0,
          healthInsuranceAmount: 0,
          settlementDeductions: 0,
          penaltyDetails: [],
          total: 0,
        ),
        insurance: const Insurance(
          social: 0,
          health: 0,
          companyShare: 0,
          insuranceSalary: 0,
          totalDeducted: 0,
        ),
        insuranceSalary: 0,
        bonusAmount: 0,
        settlementAmount: 0,
        settlementAdditions: 0,
        settlementDeductions: 0,
        settlementDetails: const [],
        taxAmount: 0,
        shiftRate: 0,
        paidShiftDays: 0,
        totalWorkingDays: 0,
        hoursWorked: 0,
        overtimeHours: 0,
        overtimePay: 0,
        absenceDates: const [],
        lateDates: const [],
        incompleteDates: const [],
        overtimeDates: const [],
        shiftMonthlyRequiredWorkingDays: 0,
        shiftMonthlyRequiredHours: 0,
        shiftMonthlyActualHours: 0,
        shiftMonthlyMissingHours: 0,
        shiftMonthlyDeductionDays: 0,
        shiftMonthlyAbsentDays: 0,
        shiftMonthlyHourDeficitDays: 0,
      ),
      issuedAt: DateTime.now(),
    );
  }

  Future<void> refresh() async {
    await loadPayslip();
  }

  void selectMonth(int month) {
    emit(
      state.copyWith(
        selectedMonth: month,
        loadStatus: PayslipLoadStatus.initial,
        errorMessage: null,
      ),
    );
  }

  void selectYear(int year) {
    emit(
      state.copyWith(
        selectedYear: year,
        loadStatus: PayslipLoadStatus.initial,
        errorMessage: null,
      ),
    );
  }

  Future<List<int>> downloadPdf() async {
    if (state.isFuturePeriod) {
      throw Exception('بيان المرتب لهذا الشهر لم يصدر بعد.');
    }
    if (state.isPreHirePeriod) {
      throw Exception('لم يكن الموظف متواجد في العمل خلال هذه الفترة.');
    }

    emit(
      state.copyWith(
        pdfStatus: PayslipPdfStatus.downloading,
        pdfErrorMessage: null,
      ),
    );

    try {
      final bytes = await _repository.downloadPayslipPdf(
        month: state.selectedMonth,
        year: state.selectedYear,
      );

      emit(
        state.copyWith(
          pdfStatus: PayslipPdfStatus.success,
          pdfErrorMessage: null,
        ),
      );
      return bytes;
    } catch (e) {
      emit(
        state.copyWith(
          pdfStatus: PayslipPdfStatus.failure,
          pdfErrorMessage: AppException.from(e).message,
        ),
      );
      rethrow;
    }
  }
}
