import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_exception.dart';
import '../../core/utils/app_formatters.dart';
import '../payslip/widgets/payslip_detail_widgets.dart';
import 'cubit/employees_cubit.dart';
import 'models/employee.dart';
import 'models/employee_payslip.dart';
import 'models/salary_calculation.dart';

class SalaryCalculationScreen extends StatefulWidget {
  final Employee employee;

  const SalaryCalculationScreen({super.key, required this.employee});

  @override
  State<SalaryCalculationScreen> createState() =>
      _SalaryCalculationScreenState();
}

class _SalaryCalculationScreenState extends State<SalaryCalculationScreen> {
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

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await context.read<EmployeesCubit>().getPayslip(
        employeeId: widget.employee.id,
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

  String _penaltyLabel(SalaryPenaltyDetail p) {
    final parts = <String>[
      p.isDayPenalty
          ? 'جزاء أيام'
          : p.isAmountPenalty
          ? 'جزاء مبلغ'
          : 'جزاء',
      if ((p.reason ?? p.description)?.trim().isNotEmpty == true)
        (p.reason ?? p.description)!.trim(),
      if (p.penaltyDate?.trim().isNotEmpty == true) p.penaltyDate!.trim(),
    ];
    return parts.join(' - ');
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.employee;
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundSecondary,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'حساب الراتب الشهري',
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
              _buildEmployeeHeader(e),
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
                _buildSummary(_result!.salaryDetails),
                const SizedBox(height: 16),
                _buildAllowances(_result!.salaryDetails),
                const SizedBox(height: 16),
                _buildDeductions(_result!.salaryDetails),
                const SizedBox(height: 16),
                _buildInsurance(_result!.salaryDetails),
                const SizedBox(height: 16),
                _buildAttendance(_result!.salaryDetails),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeHeader(Employee e) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child: Text(
              (e.fullName.isNotEmpty ? e.fullName.trim()[0] : '؟')
                  .toUpperCase(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${e.position ?? '--'} • ${e.department ?? '--'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayslipMeta(EmployeePayslip p) {
    final issued = p.issuedAt != null
        ? '${p.issuedAt!.year}-${p.issuedAt!.month.toString().padLeft(2, '0')}-${p.issuedAt!.day.toString().padLeft(2, '0')}'
        : '--';
    return PayslipSectionCard(
      icon: Icons.receipt_long_rounded,
      title: 'بيانات القسيمة',
      child: Column(
        children: [
          PayslipRow('الاسم بالعربي', p.displayName),
          PayslipRow('الاسم بالإنجليزي', p.fullNameEn),
          PayslipRow('القسم', p.departmentName),
          PayslipRow('نظام العمل', p.employmentMode),
          PayslipRow('أيام العمل الفعلية', '${p.actualWorkingDays} يوم'),
          const Divider(height: 20, color: AppColors.border),
          if (p.bankName.isNotEmpty) PayslipRow('البنك', p.bankName),
          if (p.bankAccountNumber.isNotEmpty)
            PayslipRow('رقم الحساب', p.bankAccountNumber),
          PayslipRow('تاريخ الإصدار', issued),
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
                child: _Dropdown<int>(
                  value: _month,
                  items: List<int>.generate(12, (i) => i + 1),
                  itemLabel: (m) => _months[m - 1],
                  onChanged: (v) => setState(() => _month = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Dropdown<int>(
                  value: _year,
                  items: List<int>.generate(5, (i) => DateTime.now().year - i),
                  itemLabel: (y) => y.toString(),
                  onChanged: (v) => setState(() => _year = v),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _load,
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

  Widget _buildSummary(SalaryCalculation d) {
    return PayslipSummarySection(
      grossSalary: d.grossSalary,
      totalEarnings: d.totalEarnings,
      deductionsTotal: d.deductions.total,
      netSalary: d.netSalary,
      taxAmount: d.taxAmount,
    );
  }

  Widget _buildAllowances(SalaryCalculation d) {
    return PayslipAllowancesSection(allowances: d.allowances);
  }

  Widget _buildDeductions(SalaryCalculation d) {
    final dd = d.deductions;
    return PayslipSectionCard(
      icon: Icons.remove_circle_outline_rounded,
      title: 'الخصومات',
      child: Column(
        children: [
          PayslipRow('تأخير', AppFormatters.currency(dd.lateAmount)),
          PayslipRow('غياب', AppFormatters.currency(dd.absenceAmount)),
          PayslipRow('جزاءات', AppFormatters.currency(dd.penaltiesAmount)),
          PayslipRow('سلف', AppFormatters.currency(dd.advancesAmount)),
          PayslipRow('تأمين صحي', AppFormatters.currency(dd.healthInsuranceAmount)),
          PayslipRow('تسويات', AppFormatters.currency(dd.settlementDeductions)),
          const Divider(height: 20, color: AppColors.border),
          PayslipRow('إجمالي الخصومات', AppFormatters.currency(dd.total), strong: true),
          if (dd.penaltyDetails.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final p in dd.penaltyDetails)
              PayslipRow(
                _penaltyLabel(p),
                p.isDayPenalty ? '${payslipFmtNumber(p.days)} يوم' : AppFormatters.currency(p.amount),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildInsurance(SalaryCalculation d) {
    return PayslipInsuranceSection(insurance: d.insurance);
  }

  Widget _buildAttendance(SalaryCalculation d) {
    return PayslipSectionCard(
      icon: Icons.how_to_reg_rounded,
      title: 'الحضور والانصراف',
      child: Column(
        children: [
          PayslipRow('أيام عمل مدفوعة', '${d.paidShiftDays} يوم'),
          PayslipRow('أيام عمل إجمالية', '${d.totalWorkingDays} يوم'),
          PayslipRow('ساعات العمل', '${d.hoursWorked.toStringAsFixed(2)} ساعة'),
          PayslipRow(
            'الساعات الإضافية',
            '${d.overtimeHours.toStringAsFixed(2)} ساعة',
          ),
          PayslipRow('أجر الساعات الإضافية', AppFormatters.currency(d.overtimePay)),
          if (d.bonusAmount != 0) ...[
            const Divider(height: 20, color: AppColors.border),
            PayslipRow('مكافأة', AppFormatters.currency(d.bonusAmount)),
            PayslipRow('تسويات إضافية', AppFormatters.currency(d.settlementAdditions)),
            PayslipRow('تسويات', AppFormatters.currency(d.settlementAmount)),
          ],
          if (d.employeeStatusNote?.isNotEmpty == true) ...[
            const Divider(height: 20, color: AppColors.border),
            Text(
              d.employeeStatusNote!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Local helpers ──────────────────────────────────────────────────────

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(10),
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
          isDense: true,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          iconEnabledColor: AppColors.primary,
          iconSize: 20,
          items: items
              .map(
                (item) =>
                    DropdownMenuItem(value: item, child: Text(itemLabel(item))),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
