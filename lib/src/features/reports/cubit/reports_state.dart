import 'package:equatable/equatable.dart';

import '../../attendance/data/models/punch_pair_model.dart';
import '../../attendance/data/models/punch_summary_model.dart';
import '../services/reports_service.dart';

enum PunchDataStatus { initial, loading, loaded, error, loadingMore }

class ReportDownloadState {
  final bool isLoading;
  final bool isSuccess;
  final String? error;

  const ReportDownloadState({
    this.isLoading = false,
    this.isSuccess = false,
    this.error,
  });

  const ReportDownloadState.idle()
      : isLoading = false,
        isSuccess = false,
        error = null;
  const ReportDownloadState.loading()
      : isLoading = true,
        isSuccess = false,
        error = null;
  const ReportDownloadState.success()
      : isLoading = false,
        isSuccess = true,
        error = null;
  ReportDownloadState.failure(String msg)
      : isLoading = false,
        isSuccess = false,
        error = msg;
}

class ReportsState extends Equatable {
  final int selectedMonth;
  final int selectedYear;
  final int? tenantId;

  // Tenants
  final List<TenantModel> tenants;

  // Per-report download status
  final ReportDownloadState monthlyReportStatus;
  final ReportDownloadState detailsByTenantStatus;
  final ReportDownloadState shiftReportStatus;
  final ReportDownloadState payrollExportStatus;
  final ReportDownloadState bankSalaryReportStatus;

  // Punch-pairs (entry/exit)
  final PunchDataStatus punchPairsStatus;
  final List<PunchPairModel> punchPairs;
  final int punchPairsPage;
  final int punchPairsTotalPages;
  final int punchPairsTotalCount;
  final String? punchPairsError;

  // Punch-summary (work hours)
  final PunchDataStatus punchSummaryStatus;
  final List<PunchSummaryModel> punchSummary;
  final int punchSummaryPage;
  final int punchSummaryTotalPages;
  final int punchSummaryTotalCount;
  final String? punchSummaryError;

  // Employee filter (optional)
  final String? filterEmployeeId;
  final String? filterEmployeeName;

  // Date range filter
  final String? filterFromDate;
  final String? filterToDate;

  const ReportsState({
    this.selectedMonth = 0,
    this.selectedYear = 0,
    this.tenantId,
    this.tenants = const [],
    this.monthlyReportStatus = const ReportDownloadState(),
    this.detailsByTenantStatus = const ReportDownloadState(),
    this.shiftReportStatus = const ReportDownloadState(),
    this.payrollExportStatus = const ReportDownloadState(),
    this.bankSalaryReportStatus = const ReportDownloadState(),
    this.punchPairsStatus = PunchDataStatus.initial,
    this.punchPairs = const [],
    this.punchPairsPage = 1,
    this.punchPairsTotalPages = 1,
    this.punchPairsTotalCount = 0,
    this.punchPairsError,
    this.punchSummaryStatus = PunchDataStatus.initial,
    this.punchSummary = const [],
    this.punchSummaryPage = 1,
    this.punchSummaryTotalPages = 1,
    this.punchSummaryTotalCount = 0,
    this.punchSummaryError,
    this.filterEmployeeId,
    this.filterEmployeeName,
    this.filterFromDate,
    this.filterToDate,
  });

  ReportsState copyWith({
    int? selectedMonth,
    int? selectedYear,
    int? Function()? tenantId,
    List<TenantModel>? tenants,
    ReportDownloadState? monthlyReportStatus,
    ReportDownloadState? detailsByTenantStatus,
    ReportDownloadState? shiftReportStatus,
    ReportDownloadState? payrollExportStatus,
    ReportDownloadState? bankSalaryReportStatus,
    PunchDataStatus? punchPairsStatus,
    List<PunchPairModel>? punchPairs,
    int? punchPairsPage,
    int? punchPairsTotalPages,
    int? punchPairsTotalCount,
    String? Function()? punchPairsError,
    PunchDataStatus? punchSummaryStatus,
    List<PunchSummaryModel>? punchSummary,
    int? punchSummaryPage,
    int? punchSummaryTotalPages,
    int? punchSummaryTotalCount,
    String? Function()? punchSummaryError,
    String? Function()? filterEmployeeId,
    String? Function()? filterEmployeeName,
    String? Function()? filterFromDate,
    String? Function()? filterToDate,
  }) {
    return ReportsState(
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedYear: selectedYear ?? this.selectedYear,
      tenantId: tenantId != null ? tenantId() : this.tenantId,
      tenants: tenants ?? this.tenants,
      monthlyReportStatus: monthlyReportStatus ?? this.monthlyReportStatus,
      detailsByTenantStatus:
          detailsByTenantStatus ?? this.detailsByTenantStatus,
      shiftReportStatus: shiftReportStatus ?? this.shiftReportStatus,
      payrollExportStatus: payrollExportStatus ?? this.payrollExportStatus,
      bankSalaryReportStatus:
          bankSalaryReportStatus ?? this.bankSalaryReportStatus,
      punchPairsStatus: punchPairsStatus ?? this.punchPairsStatus,
      punchPairs: punchPairs ?? this.punchPairs,
      punchPairsPage: punchPairsPage ?? this.punchPairsPage,
      punchPairsTotalPages:
          punchPairsTotalPages ?? this.punchPairsTotalPages,
      punchPairsTotalCount:
          punchPairsTotalCount ?? this.punchPairsTotalCount,
      punchPairsError:
          punchPairsError != null ? punchPairsError() : this.punchPairsError,
      punchSummaryStatus: punchSummaryStatus ?? this.punchSummaryStatus,
      punchSummary: punchSummary ?? this.punchSummary,
      punchSummaryPage: punchSummaryPage ?? this.punchSummaryPage,
      punchSummaryTotalPages:
          punchSummaryTotalPages ?? this.punchSummaryTotalPages,
      punchSummaryTotalCount:
          punchSummaryTotalCount ?? this.punchSummaryTotalCount,
      punchSummaryError: punchSummaryError != null
          ? punchSummaryError()
          : this.punchSummaryError,
      filterEmployeeId:
          filterEmployeeId != null ? filterEmployeeId() : this.filterEmployeeId,
      filterEmployeeName: filterEmployeeName != null
          ? filterEmployeeName()
          : this.filterEmployeeName,
      filterFromDate:
          filterFromDate != null ? filterFromDate() : this.filterFromDate,
      filterToDate:
          filterToDate != null ? filterToDate() : this.filterToDate,
    );
  }

  @override
  List<Object?> get props => [
        selectedMonth,
        selectedYear,
        tenantId,
        tenants,
        monthlyReportStatus,
        detailsByTenantStatus,
        shiftReportStatus,
        payrollExportStatus,
        bankSalaryReportStatus,
        punchPairsStatus,
        punchPairs,
        punchPairsPage,
        punchPairsTotalPages,
        punchPairsTotalCount,
        punchPairsError,
        punchSummaryStatus,
        punchSummary,
        punchSummaryPage,
        punchSummaryTotalPages,
        punchSummaryTotalCount,
        punchSummaryError,
        filterEmployeeId,
        filterEmployeeName,
        filterFromDate,
        filterToDate,
      ];
}
