import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/components/custom_toast.dart';
import '../../../core/utils/app_exception.dart';
import '../cubit/reports_cubit.dart';
import '../cubit/reports_state.dart';

class ReportsHubScreen extends StatelessWidget {
  const ReportsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReportsCubit, ReportsState>(
      listenWhen: (prev, curr) {
        // Listen to any individual report transitioning to error
        return (curr.monthlyReportStatus.error != null &&
                prev.monthlyReportStatus.error == null) ||
            (curr.detailsByTenantStatus.error != null &&
                prev.detailsByTenantStatus.error == null) ||
            (curr.shiftReportStatus.error != null &&
                prev.shiftReportStatus.error == null) ||
            (curr.payrollExportStatus.error != null &&
                prev.payrollExportStatus.error == null) ||
            (curr.bankSalaryReportStatus.error != null &&
                prev.bankSalaryReportStatus.error == null);
      },
      listener: (context, state) {
        final errors = [
          state.monthlyReportStatus.error,
          state.detailsByTenantStatus.error,
          state.shiftReportStatus.error,
          state.payrollExportStatus.error,
          state.bankSalaryReportStatus.error,
        ].whereType<String>();
        if (errors.isNotEmpty) {
          CustomToast.showError(
            AppException.from(Exception(errors.first)).message,
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundSecondary,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const _PageHeader(),
                const SizedBox(height: 20),
                const _MonthYearPicker(),
                const SizedBox(height: 20),
                // ── Report cards (vertical list) ──────────────────────────
                const _ReportCard(
                  title: 'تقرير الحضور والانصراف',
                  subtitle: 'تصدير الحضور الشهري إلى Excel',
                  icon: Icons.table_chart_rounded,
                  reportType: ReportType.monthlyReport,
                ),
                const SizedBox(height: 12),
                const _ReportCardWithTenant(
                  title: 'شيت المرتبات',
                  subtitle: 'تفاصيل المرتبات الشهرية',
                  icon: Icons.business_center_rounded,
                  reportType: ReportType.detailsByTenant,
                ),
                const SizedBox(height: 12),
                const _ReportCard(
                  title: 'تقرير الشيفتات',
                  subtitle: 'بيانات الشيفتات الشهرية',
                  icon: Icons.schedule_rounded,
                  reportType: ReportType.shiftReport,
                ),
                const SizedBox(height: 12),
                const _ReportCardWithTenant(
                  title: 'تقرير الرواتب',
                  subtitle: 'ملف الرواتب الشهري (Excel)',
                  icon: Icons.payments_rounded,
                  reportType: ReportType.payrollExport,
                ),
                const SizedBox(height: 12),
                const _ReportCardWithTenant(
                  title: 'تقرير الرواتب البنكية',
                  subtitle: 'ملف مرتبات البنك الشهري (Excel)',
                  icon: Icons.account_balance_rounded,
                  reportType: ReportType.bankSalary,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Page header ────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.assessment_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'التقارير',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'تحميل التقارير وعرض بيانات الحضور',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Month / Year picker ────────────────────────────────────────────────────

class _MonthYearPicker extends StatelessWidget {
  const _MonthYearPicker();

  static const _monthNames = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportsCubit, ReportsState>(
      buildWhen: (prev, curr) =>
          prev.selectedMonth != curr.selectedMonth ||
          prev.selectedYear != curr.selectedYear,
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              const Text(
                'الفترة:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Dropdown<int>(
                  value: state.selectedMonth,
                  items: List<int>.generate(12, (i) => i + 1),
                  itemLabel: (m) => _monthNames[m - 1],
                  onChanged: (v) => context.read<ReportsCubit>().setMonth(v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Dropdown<int>(
                  value: state.selectedYear,
                  items:
                      List<int>.generate(5, (i) => DateTime.now().year - i),
                  itemLabel: (y) => y.toString(),
                  onChanged: (v) => context.read<ReportsCubit>().setYear(v),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Simple report card (no tenant) ─────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final ReportType reportType;

  const _ReportCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.reportType,
  });

  ReportDownloadState _getStatus(ReportsState state) {
    switch (reportType) {
      case ReportType.monthlyReport:
        return state.monthlyReportStatus;
      case ReportType.shiftReport:
        return state.shiftReportStatus;
      case ReportType.detailsByTenant:
        return state.detailsByTenantStatus;
      case ReportType.payrollExport:
        return state.payrollExportStatus;
      case ReportType.bankSalary:
        return state.bankSalaryReportStatus;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportsCubit, ReportsState>(
      buildWhen: (prev, curr) =>
          _getStatus(prev) != _getStatus(curr),
      builder: (context, state) {
        final dl = _getStatus(state);
        return _DownloadCardInner(
          title: title,
          subtitle: subtitle,
          icon: icon,
          iconColor: AppColors.primary,
          downloadState: dl,
          onDownload: () =>
              context.read<ReportsCubit>().downloadReport(reportType),
        );
      },
    );
  }
}

// ── Report card with tenant dropdown ───────────────────────────────────────

class _ReportCardWithTenant extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final ReportType reportType;

  const _ReportCardWithTenant({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.reportType,
  });

  ReportDownloadState _getStatus(ReportsState state) {
    switch (reportType) {
      case ReportType.detailsByTenant:
        return state.detailsByTenantStatus;
      case ReportType.payrollExport:
        return state.payrollExportStatus;
      case ReportType.bankSalary:
        return state.bankSalaryReportStatus;
      case ReportType.monthlyReport:
        return state.monthlyReportStatus;
      case ReportType.shiftReport:
        return state.shiftReportStatus;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportsCubit, ReportsState>(
      buildWhen: (prev, curr) =>
          _getStatus(prev) != _getStatus(curr) ||
          prev.tenantId != curr.tenantId ||
          prev.tenants != curr.tenants,
      builder: (context, state) {
        final dl = _getStatus(state);
        return _DownloadCardInner(
          title: title,
          subtitle: subtitle,
          icon: icon,
          iconColor: AppColors.primary,
          downloadState: dl,
          showTenantDropdown: true,
          tenants: state.tenants,
          selectedTenantId: state.tenantId,
          onTenantChanged: (id) =>
              context.read<ReportsCubit>().setTenantId(id),
          onDownload: () =>
              context.read<ReportsCubit>().downloadReport(reportType),
        );
      },
    );
  }
}

// ── Inner card widget ──────────────────────────────────────────────────────

class _DownloadCardInner extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final ReportDownloadState downloadState;
  final bool showTenantDropdown;
  final List<dynamic>? tenants;
  final int? selectedTenantId;
  final ValueChanged<int?>? onTenantChanged;
  final VoidCallback onDownload;

  const _DownloadCardInner({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.downloadState,
    this.showTenantDropdown = false,
    this.tenants,
    this.selectedTenantId,
    this.onTenantChanged,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = downloadState.isLoading;
    final error = downloadState.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: error != null
            ? Border.all(
                color: AppColors.error.withValues(alpha: 0.4),
                width: 1.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header row ──────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      iconColor.withValues(alpha: 0.15),
                      iconColor.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Tenant dropdown (only for cards that need it) ───────────
          if (showTenantDropdown && tenants != null) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: selectedTenantId,
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  hint: Text(
                    tenants!.isEmpty ? 'جاري التحميل...' : 'اختر الشركة',
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  iconEnabledColor: AppColors.primary,
                  iconSize: 20,
                  items: (tenants as List)
                      .map((t) => DropdownMenuItem<int>(
                            value: t.id as int,
                            child: Text(t.name as String),
                          ))
                      .toList(),
                  onChanged: onTenantChanged,
                ),
              ),
            ),
          ],

          // ── Error text ──────────────────────────────────────────────
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // ── Download button ─────────────────────────────────────────
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: FilledButton.icon(
              onPressed: isLoading ? null : onDownload,
              style: FilledButton.styleFrom(
                backgroundColor: iconColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: iconColor.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : downloadState.isSuccess
                      ? const Icon(Icons.check_rounded, size: 18)
                      : const Icon(Icons.download_rounded, size: 18),
              label: Text(
                isLoading
                    ? 'جاري التحميل...'
                    : downloadState.isSuccess
                        ? 'تم التحميل'
                        : 'تحميل',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ── Generic dropdown ───────────────────────────────────────────────────────

class _Dropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T> onChanged;

  const _Dropdown({
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: Colors.white,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          iconEnabledColor: AppColors.primary,
          iconSize: 22,
          items: items
              .map((item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(itemLabel(item)),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
