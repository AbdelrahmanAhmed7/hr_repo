import 'package:flutter_bloc/flutter_bloc.dart';

import '../../attendance/models/monthly_report_file.dart';
import '../services/reports_service.dart';
import 'reports_state.dart';

class ReportsCubit extends Cubit<ReportsState> {
  final ReportsService _reportsService;

  static const int _pageSize = 20;

  ReportsCubit(this._reportsService) : super(const ReportsState()) {
    final now = DateTime.now();
    emit(state.copyWith(
      selectedMonth: now.month,
      selectedYear: now.year,
    ));
    loadTenants();
  }

  Future<void> loadTenants() async {
    try {
      final tenants = await _reportsService.getTenants();
      if (!isClosed) {
        emit(state.copyWith(tenants: tenants));
      }
    } catch (_) {}
  }

  void setMonth(int month) => emit(state.copyWith(selectedMonth: month));

  void setYear(int year) => emit(state.copyWith(selectedYear: year));

  void setTenantId(int? id) => emit(state.copyWith(tenantId: () => id));

  void setFilterEmployee(String? id, String? name) {
    emit(state.copyWith(
      filterEmployeeId: () => id,
      filterEmployeeName: () => name,
    ));
  }

  void setFilterDateRange(String? from, String? to) {
    emit(state.copyWith(
      filterFromDate: () => from,
      filterToDate: () => to,
    ));
  }

  void clearFilters() {
    emit(state.copyWith(
      filterEmployeeId: () => null,
      filterEmployeeName: () => null,
      filterFromDate: () => null,
      filterToDate: () => null,
    ));
  }

  // ── Excel downloads (per-report state) ───────────────────────────────────

  Future<void> downloadReport(ReportType type) async {
    // Set loading for the specific report
    _setReportStatus(type, const ReportDownloadState.loading());

    try {
      MonthlyReportFile report;
      final month = state.selectedMonth;
      final year = state.selectedYear;

      switch (type) {
        case ReportType.monthlyReport:
          report = await _reportsService.downloadMonthlyReport(
            month: month,
            year: year,
          );
        case ReportType.detailsByTenant:
          final tenantId = state.tenantId;
          if (tenantId == null) {
            throw Exception('يجب اختيار الشركة أولاً.');
          }
          report = await _reportsService.downloadDetailsByTenant(
            month: month,
            year: year,
            tenantId: tenantId,
          );
        case ReportType.shiftReport:
          report = await _reportsService.downloadShiftReport(
            month: month,
            year: year,
          );
        case ReportType.payrollExport:
          final tenantId = state.tenantId;
          if (tenantId == null) {
            throw Exception('يجب اختيار الشركة أولاً.');
          }
          report = await _reportsService.downloadPayrollExport(
            month: month,
            year: year,
            tenantId: tenantId,
          );
        case ReportType.bankSalary:
          final tenantId = state.tenantId;
          if (tenantId == null) {
            throw Exception('يجب اختيار الشركة أولاً.');
          }
          report = await _reportsService.downloadBankSalaryReport(
            month: month,
            year: year,
            tenantId: tenantId,
          );
      }

      await _reportsService.saveAndOpen(report);

      if (!isClosed) {
        _setReportStatus(type, const ReportDownloadState.success());
      }
    } catch (e) {
      if (!isClosed) {
        _setReportStatus(type, ReportDownloadState.failure(e.toString()));
      }
    }
  }

  void _setReportStatus(ReportType type, ReportDownloadState s) {
    switch (type) {
      case ReportType.monthlyReport:
        emit(state.copyWith(monthlyReportStatus: s));
      case ReportType.detailsByTenant:
        emit(state.copyWith(detailsByTenantStatus: s));
      case ReportType.shiftReport:
        emit(state.copyWith(shiftReportStatus: s));
      case ReportType.payrollExport:
        emit(state.copyWith(payrollExportStatus: s));
      case ReportType.bankSalary:
        emit(state.copyWith(bankSalaryReportStatus: s));
    }
  }

  // ── Punch pairs (entry/exit details) ─────────────────────────────────────

  Future<void> loadPunchPairs({bool refresh = false}) async {
    if (refresh) {
      emit(state.copyWith(
        punchPairsStatus: PunchDataStatus.loading,
        punchPairsPage: 1,
      ));
    } else if (state.punchPairsStatus == PunchDataStatus.initial) {
      emit(state.copyWith(punchPairsStatus: PunchDataStatus.loading));
    }

    try {
      final result = await _reportsService.getPunchPairs(
        userId: state.filterEmployeeId,
        from: state.filterFromDate,
        to: state.filterToDate,
        page: state.punchPairsPage,
        pageSize: _pageSize,
      );

      if (!isClosed) {
        emit(state.copyWith(
          punchPairsStatus: PunchDataStatus.loaded,
          punchPairs: result.items,
          punchPairsTotalPages: result.totalPages,
          punchPairsTotalCount: result.totalCount,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
          punchPairsStatus: PunchDataStatus.error,
          punchPairsError: () => e.toString(),
        ));
      }
    }
  }

  Future<void> loadMorePunchPairs() async {
    if (state.punchPairsStatus == PunchDataStatus.loadingMore) return;
    if (state.punchPairsPage >= state.punchPairsTotalPages) return;

    emit(state.copyWith(punchPairsStatus: PunchDataStatus.loadingMore));

    try {
      final nextPage = state.punchPairsPage + 1;
      final result = await _reportsService.getPunchPairs(
        userId: state.filterEmployeeId,
        from: state.filterFromDate,
        to: state.filterToDate,
        page: nextPage,
        pageSize: _pageSize,
      );

      if (!isClosed) {
        emit(state.copyWith(
          punchPairsStatus: PunchDataStatus.loaded,
          punchPairs: [...state.punchPairs, ...result.items],
          punchPairsPage: nextPage,
          punchPairsTotalPages: result.totalPages,
          punchPairsTotalCount: result.totalCount,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
          punchPairsStatus: PunchDataStatus.error,
          punchPairsError: () => e.toString(),
        ));
      }
    }
  }

  // ── Punch summary (work hours) ───────────────────────────────────────────

  Future<void> loadPunchSummary({bool refresh = false}) async {
    if (refresh) {
      emit(state.copyWith(
        punchSummaryStatus: PunchDataStatus.loading,
        punchSummaryPage: 1,
      ));
    } else if (state.punchSummaryStatus == PunchDataStatus.initial) {
      emit(state.copyWith(punchSummaryStatus: PunchDataStatus.loading));
    }

    try {
      final result = await _reportsService.getPunchSummary(
        userId: state.filterEmployeeId,
        from: state.filterFromDate,
        to: state.filterToDate,
        page: state.punchSummaryPage,
        pageSize: _pageSize,
      );

      if (!isClosed) {
        emit(state.copyWith(
          punchSummaryStatus: PunchDataStatus.loaded,
          punchSummary: result.items,
          punchSummaryTotalPages: result.totalPages,
          punchSummaryTotalCount: result.totalCount,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
          punchSummaryStatus: PunchDataStatus.error,
          punchSummaryError: () => e.toString(),
        ));
      }
    }
  }

  Future<void> loadMorePunchSummary() async {
    if (state.punchSummaryStatus == PunchDataStatus.loadingMore) return;
    if (state.punchSummaryPage >= state.punchSummaryTotalPages) return;

    emit(state.copyWith(punchSummaryStatus: PunchDataStatus.loadingMore));

    try {
      final nextPage = state.punchSummaryPage + 1;
      final result = await _reportsService.getPunchSummary(
        userId: state.filterEmployeeId,
        from: state.filterFromDate,
        to: state.filterToDate,
        page: nextPage,
        pageSize: _pageSize,
      );

      if (!isClosed) {
        emit(state.copyWith(
          punchSummaryStatus: PunchDataStatus.loaded,
          punchSummary: [...state.punchSummary, ...result.items],
          punchSummaryPage: nextPage,
          punchSummaryTotalPages: result.totalPages,
          punchSummaryTotalCount: result.totalCount,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
          punchSummaryStatus: PunchDataStatus.error,
          punchSummaryError: () => e.toString(),
        ));
      }
    }
  }

}

enum ReportType {
  monthlyReport,
  detailsByTenant,
  shiftReport,
  payrollExport,
  bankSalary,
}
