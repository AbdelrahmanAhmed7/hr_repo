import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_exception.dart';
import '../../shared/widgets/searchable_dropdown_field.dart';
import '../hr/models/employee.dart';
import '../hr/models/employee_payslip.dart';
import '../hr/models/salary_calculation.dart';
import '../hr/repository/employees_repository.dart';
import '../../core/services/service_locator.dart';

class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  List<Employee> _employees = const [];
  bool _employeesLoading = true;
  Employee? _selectedEmployee;

  bool _isLoading = false;
  String? _error;
  EmployeePayslip? _result;
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;

  static const _months = [
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
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final repo = getIt<EmployeesRepository>();
      final page = await repo.getEmployees(
        pageNumber: 1,
        pageSize: 1000,
        isActive: true,
        status: 'active',
      );
      if (!mounted) return;
      setState(() {
        _employees = page.items;
        _employeesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _employeesLoading = false);
    }
  }

  Future<void> _load() async {
    if (_selectedEmployee == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await getIt<EmployeesRepository>().getPayslip(
        employeeId: _selectedEmployee!.id,
        month: _month,
        year: _year,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _result = null;
        _isLoading = false;
        _error = AppException.from(e).message;
      });
    }
  }

  String _fmt(double v) {
    final text = v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);
    return '$text ج.م';
  }

  String _fmtNumber(double v) {
    return v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);
  }

  String _fmtFullDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _penaltyLabel(SalaryPenaltyDetail p) {
    final parts = <String>[
      p.isDayPenalty
          ? 'جزاء أيام'
          : p.isAmountPenalty
          ? 'جزاء مبلغ'
          : 'جزاء',
      if ((p.reason ?? p.description)?.trim().isNotEmpty == true)
        (p.reason ?? p.description)!.trim(),
      if (p.penaltyDate?.trim().isNotEmpty == true)
        _fmtFullDate(p.penaltyDate!),
    ];
    return parts.join(' - ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundSecondary,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'كشف رواتب',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEmployeeCard(),
              const SizedBox(height: 16),
              _buildControls(),
              if (_error != null) ...[
                const SizedBox(height: 16),
                _ErrorBox(message: _error!, onRetry: _load),
              ],
              if (_result != null) ...[
                const SizedBox(height: 16),
                _buildPayslipMeta(_result!),
                const SizedBox(height: 16),
                _buildWorkingHours(_result!.salaryDetails),
                const SizedBox(height: 16),
                _buildSummary(_result!.salaryDetails),
                const SizedBox(height: 16),
                _buildAllowances(_result!.salaryDetails),
                const SizedBox(height: 16),
                _buildDeductions(_result!.salaryDetails),
                const SizedBox(height: 16),
                _buildInsurance(_result!.salaryDetails),
                if (_result!.salaryDetails.bonusAmount != 0 ||
                    _result!.salaryDetails.settlementAmount != 0 ||
                    _result!.salaryDetails.settlementAdditions != 0 ||
                    _result!.salaryDetails.settlementDeductions != 0) ...[
                  const SizedBox(height: 16),
                  _buildBonusesSettlements(_result!.salaryDetails),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'اختر الموظف',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          if (_employeesLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_employees.isEmpty)
            const Text(
              'تعذر تحميل الموظفين',
              style: TextStyle(fontSize: 13, color: AppColors.error),
            )
          else
            SearchableDropdownField<String>(
              value: _selectedEmployee?.id,
              hintText: 'اختر الموظف',
              searchHintText: 'ابحث عن موظف',
              isDense: true,
              items: _employees
                  .map(
                    (e) => SearchableDropdownItem<String?>(
                      value: e.id,
                      label: e.fullName,
                    ),
                  )
                  .toList(),
              onChanged: (id) {
                if (id == null) return;
                setState(() {
                  _selectedEmployee = _employees.firstWhere((e) => e.id == id);
                  _result = null;
                  _error = null;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الفترة',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SearchableDropdownField<int>(
                  value: _month,
                  labelText: 'الشهر',
                  searchHintText: 'ابحث عن شهر',
                  items: List<int>.generate(12, (i) => i + 1)
                      .map(
                        (m) => SearchableDropdownItem<int?>(
                          value: m,
                          label: _months[m - 1],
                        ),
                      )
                      .toList(),
                  isDense: true,
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _month = v);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SearchableDropdownField<int>(
                  value: _year,
                  labelText: 'السنة',
                  searchHintText: 'ابحث عن سنة',
                  items: List<int>.generate(5, (i) => DateTime.now().year - i)
                      .map(
                        (y) => SearchableDropdownItem<int?>(
                          value: y,
                          label: y.toString(),
                        ),
                      )
                      .toList(),
                  isDense: true,
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _year = v);
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                child: FilledButton.icon(
                  onPressed: (_isLoading || _selectedEmployee == null)
                      ? null
                      : _load,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.search_rounded, size: 18),
                  label: Text(_isLoading ? 'جاري...' : 'حساب'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayslipMeta(EmployeePayslip p) {
    final issued = p.issuedAt != null
        ? '${p.issuedAt!.day.toString().padLeft(2, '0')}/${p.issuedAt!.month.toString().padLeft(2, '0')}/${p.issuedAt!.year}'
        : '--';
    return _SectionCard(
      icon: Icons.receipt_long_rounded,
      title: 'بيانات القسيمة',
      child: Column(
        children: [
          _Row('الاسم بالعربي', p.displayName, valueFlex: 3, maxLines: 3),
          _Row('الاسم بالإنجليزي', p.fullNameEn, valueFlex: 3, maxLines: 3),
          _Row('القسم', p.departmentName),
          _Row('نظام العمل', p.employmentMode),
          _Row('أيام العمل الفعلية', '${p.actualWorkingDays} يوم'),
          const Divider(height: 20, color: AppColors.border),
          if (p.bankName.isNotEmpty) _Row('البنك', p.bankName),
          if (p.bankAccountNumber.isNotEmpty)
            _Row('رقم الحساب', p.bankAccountNumber),
          _Row('تاريخ الإصدار', issued),
        ],
      ),
    );
  }

  Widget _buildSummary(SalaryCalculation d) {
    return _SectionCard(
      icon: Icons.payments_rounded,
      title: 'ملخص الراتب',
      child: Column(
        children: [
          _SummaryBig(amount: d.netSalary, label: 'صافي الراتب'),
          const SizedBox(height: 16),
          _Row('الراتب الأساسي', _fmt(d.grossSalary)),
          _Row('البدلات', _fmt(d.allowances.total)),
          if (d.bonusAmount != 0) _Row('المكافآت', _fmt(d.bonusAmount)),
          const Divider(height: 20, color: AppColors.border),
          _Row(
            'إجمالي الخصومات',
            _fmt(d.deductions.total),
            color: AppColors.error,
          ),
          if (d.taxAmount != 0) _Row('الضرائب', _fmt(d.taxAmount)),
          const Divider(height: 20, color: AppColors.border),
          _Row('صافي الراتب', _fmt(d.netSalary), strong: true),
        ],
      ),
    );
  }

  Widget _buildAllowances(SalaryCalculation d) {
    final a = d.allowances;
    return _SectionCard(
      icon: Icons.add_circle_outline_rounded,
      title: 'الإضافات (البدلات)',
      child: Column(
        children: [
          _Row('بدل سكن', _fmt(a.housing)),
          _Row('بدل وجبات', _fmt(a.meal)),
          _Row('بدل مواصلات', _fmt(a.transportation)),
          _Row('بدل تأمين', _fmt(a.insurance)),
          _Row('إضافي', _fmt(a.additional)),
          _Row('أخرى', _fmt(a.other)),
          const Divider(height: 20, color: AppColors.border),
          _Row('إجمالي الإضافات', _fmt(a.total), strong: true),
        ],
      ),
    );
  }

  Widget _buildDeductions(SalaryCalculation d) {
    final dd = d.deductions;
    return _SectionCard(
      icon: Icons.remove_circle_outline_rounded,
      title: 'الخصومات',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Row(
            'تأخير (${dd.lateHours.toStringAsFixed(0)} ساعة)',
            _fmt(dd.lateAmount),
          ),
          if (d.lateDates.isNotEmpty) ...[
            const SizedBox(height: 6),
            _DateChips(
              dates: d.lateDates,
              color: AppColors.error,
              label: 'تأخير',
            ),
          ],
          const SizedBox(height: 8),
          _Row(
            'غياب (${dd.absenceDays.toStringAsFixed(0)} يوم)',
            _fmt(dd.absenceAmount),
          ),
          if (d.absenceDates.isNotEmpty) ...[
            const SizedBox(height: 6),
            _DateChips(
              dates: d.absenceDates,
              color: AppColors.error,
              label: 'غياب',
            ),
          ],
          const SizedBox(height: 8),
          _Row('جزاءات', _fmt(dd.penaltiesAmount)),
          if (dd.penaltyDetails.isNotEmpty) ...[
            const SizedBox(height: 6),
            for (final p in dd.penaltyDetails)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _DetailChip(
                  label: _penaltyLabel(p),
                  value: p.isDayPenalty
                      ? '${_fmtNumber(p.days)} يوم'
                      : _fmt(p.amount),
                  color: AppColors.error,
                ),
              ),
          ],
          const SizedBox(height: 4),
          _Row('سلف', _fmt(dd.advancesAmount)),
          _Row('تأمين صحي', _fmt(dd.healthInsuranceAmount)),
          if (dd.settlementDeductions != 0)
            _Row('تسويات خصم', _fmt(dd.settlementDeductions)),
          const Divider(height: 20, color: AppColors.border),
          _Row('إجمالي الخصومات', _fmt(dd.total), strong: true),
        ],
      ),
    );
  }

  Widget _buildInsurance(SalaryCalculation d) {
    final ins = d.insurance;
    return _SectionCard(
      icon: Icons.shield_outlined,
      title: 'التأمينات',
      child: Column(
        children: [
          _Row('راتب التأمين', _fmt(d.insuranceSalary)),
          _Row('تأمين اجتماعي', _fmt(ins.social)),
          _Row('تأمين صحي', _fmt(ins.health)),
          _Row('حصة الشركة', _fmt(ins.companyShare)),
          const Divider(height: 20, color: AppColors.border),
          _Row('إجمالي المخصوم', _fmt(ins.totalDeducted), strong: true),
        ],
      ),
    );
  }

  Widget _buildWorkingHours(SalaryCalculation d) {
    return _SectionCard(
      icon: Icons.schedule_rounded,
      title: 'الحضور وساعات العمل',
      child: Column(
        children: [
          _Row('ساعات العمل', '${_fmtNumber(d.hoursWorked)} ساعة'),
          _Row('الساعات الإضافية', '${_fmtNumber(d.overtimeHours)} ساعة'),
          _Row('أجر الساعات الإضافية', _fmt(d.overtimePay)),
          if (d.overtimeDetails.isNotEmpty) ...[
            const Divider(height: 24, color: AppColors.border),
            _OvertimeDetailsBlock(
              details: d.overtimeDetails,
              formatDate: _fmtFullDate,
              formatHours: _fmtNumber,
              formatPay: _fmt,
            ),
          ] else if (d.overtimeDates.isNotEmpty) ...[
            const SizedBox(height: 6),
            _DateChips(
              dates: d.overtimeDates,
              color: AppColors.success,
              label: 'إضافي',
            ),
          ],
          if (d.shiftRate != 0) ...[
            const Divider(height: 20, color: AppColors.border),
            _Row('أجر يوم الشيفت', _fmt(d.shiftRate)),
          ],
          if (d.shiftMonthlyRequiredWorkingDays != 0 ||
              d.shiftMonthlyRequiredHours != 0) ...[
            const Divider(height: 20, color: AppColors.border),
            const _SubHeader('بيانات الشيفت الشهرية'),
            if (d.shiftMonthlyRequiredWorkingDays != 0)
              _Row(
                'أيام العمل المطلوبة',
                '${d.shiftMonthlyRequiredWorkingDays} يوم',
              ),
            if (d.shiftMonthlyRequiredHours != 0)
              _Row(
                'الساعات المطلوبة',
                '${d.shiftMonthlyRequiredHours.toStringAsFixed(1)} ساعة',
              ),
            if (d.shiftMonthlyActualHours != 0)
              _Row(
                'الساعات الفعلية',
                '${d.shiftMonthlyActualHours.toStringAsFixed(1)} ساعة',
              ),
            if (d.shiftMonthlyMissingHours != 0)
              _Row(
                'الساعات الناقصة',
                '${d.shiftMonthlyMissingHours.toStringAsFixed(1)} ساعة',
                color: AppColors.error,
              ),
            if (d.shiftMonthlyDeductionDays != 0)
              _Row(
                ' أيام خصم',
                '${d.shiftMonthlyDeductionDays} يوم',
                color: AppColors.error,
              ),
            if (d.shiftMonthlyAbsentDays != 0)
              _Row(
                'أيام غياب',
                '${d.shiftMonthlyAbsentDays} يوم',
                color: AppColors.error,
              ),
            if (d.shiftMonthlyHourDeficitDays != 0)
              _Row(
                'أيام عجز الساعات',
                '${d.shiftMonthlyHourDeficitDays} يوم',
                color: AppColors.error,
              ),
          ],
          if (d.employeeStatusNote?.isNotEmpty == true) ...[
            const Divider(height: 20, color: AppColors.border),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                d.employeeStatusNote!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBonusesSettlements(SalaryCalculation d) {
    return _SectionCard(
      icon: Icons.redeem_rounded,
      title: 'المكافآت والتسويات',
      child: Column(
        children: [
          if (d.bonusAmount != 0)
            _Row('مكافأة', _fmt(d.bonusAmount), color: AppColors.success),
          if (d.settlementAmount != 0)
            _Row('التسوية', _fmt(d.settlementAmount)),
          if (d.settlementAdditions != 0)
            _Row(
              'تسويات إضافية',
              _fmt(d.settlementAdditions),
              color: AppColors.success,
            ),
          if (d.settlementDeductions != 0)
            _Row(
              'تسويات خصم',
              _fmt(d.settlementDeductions),
              color: AppColors.error,
            ),
          if (d.settlementDetails.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final s in d.settlementDetails)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _DetailChip(
                  label: s.description ?? 'تسوية',
                  value: _fmt(s.amount),
                  color: s.amount >= 0 ? AppColors.success : AppColors.error,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ── Section card ───────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            color: AppColors.primary.withValues(alpha: 0.06),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
}

class _SummaryBig extends StatelessWidget {
  final double amount;
  final String label;

  const _SummaryBig({required this.amount, required this.label});

  @override
  Widget build(BuildContext context) {
    final text = amount.toStringAsFixed(
      amount.truncateToDouble() == amount ? 0 : 2,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            '$text ج.م',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;
  final Color? color;
  final int valueFlex;
  final int maxLines;

  const _Row(
    this.label,
    this.value, {
    this.strong = false,
    this.color,
    this.valueFlex = 2,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor =
        color ?? (strong ? AppColors.primary : AppColors.textSecondary);
    final valueColor =
        color ?? (strong ? AppColors.primary : AppColors.textPrimary);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
                color: labelColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: valueFlex,
            child: Text(
              value,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              textAlign: TextAlign.start,
              style: TextStyle(
                fontSize: 13,
                fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubHeader extends StatelessWidget {
  final String text;
  const _SubHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _DateChips extends StatelessWidget {
  final List<String> dates;
  final Color color;
  final String label;

  const _DateChips({
    required this.dates,
    required this.color,
    required this.label,
  });

  String _fmtDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: dates.map((date) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Text(
            _fmtDate(date),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _OvertimeDetailsBlock extends StatefulWidget {
  final List<SalaryOvertimeDetail> details;
  final String Function(String) formatDate;
  final String Function(double) formatHours;
  final String Function(double) formatPay;

  const _OvertimeDetailsBlock({
    required this.details,
    required this.formatDate,
    required this.formatHours,
    required this.formatPay,
  });

  @override
  State<_OvertimeDetailsBlock> createState() => _OvertimeDetailsBlockState();
}

class _OvertimeDetailsBlockState extends State<_OvertimeDetailsBlock> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final details = widget.details.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return Material(
      color: AppColors.success.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.success.withValues(alpha: 0.16)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: _expanded,
            onExpansionChanged: (value) => setState(() => _expanded = value),
            tilePadding: const EdgeInsets.symmetric(horizontal: 10),
            childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
            iconColor: AppColors.success,
            collapsedIconColor: AppColors.success,
            title: Text(
              'تفاصيل أيام العمل الإضافي',
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${details.length} يوم',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                ),
              ],
            ),
            children: [
              for (final detail in details)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _OvertimeDetailTile(
                    date: widget.formatDate(detail.date),
                    hours: widget.formatHours(detail.hours),
                    pay: widget.formatPay(detail.pay),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OvertimeDetailTile extends StatelessWidget {
  final String date;
  final String hours;
  final String pay;

  const _OvertimeDetailTile({
    required this.date,
    required this.hours,
    required this.pay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: _InlineMetric(label: 'التاريخ', value: date),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: _InlineMetric(label: 'الساعات', value: '$hours ساعة'),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: _InlineMetric(
              label: 'الأجر',
              value: pay,
              valueColor: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InlineMetric({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: '$label\n',
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          height: 1.2,
        ),
        children: [
          TextSpan(
            text: value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: valueColor ?? AppColors.textPrimary,
              height: 1.25,
            ),
          ),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _DetailChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DetailChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 12))),
          TextButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
        ],
      ),
    );
  }
}
