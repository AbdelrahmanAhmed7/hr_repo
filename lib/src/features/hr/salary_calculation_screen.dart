import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_exception.dart';
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
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await context
          .read<EmployeesCubit>()
          .getPayslip(
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

  String _fmt(double v) {
    final text =
        v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);
    return '$text ج.م';
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary),
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
              (e.fullName.isNotEmpty ? e.fullName.trim()[0] : '؟').toUpperCase(),
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
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
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
    return _SectionCard(
      icon: Icons.receipt_long_rounded,
      title: 'بيانات القسيمة',
      child: Column(
        children: [
          _Row('الاسم بالعربي', p.displayName),
          _Row('الاسم بالإنجليزي', p.fullNameEn),
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
                  items: List<int>.generate(
                      5, (i) => DateTime.now().year - i),
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
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
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
    return _SectionCard(
      icon: Icons.payments_rounded,
      title: 'ملخص الراتب',
      child: Column(
        children: [
          _SummaryBig(amount: d.netSalary, label: 'صافي الراتب'),
          const SizedBox(height: 16),
          _Row('الراتب الأساسي', _fmt(d.grossSalary)),
          _Row('إجمالي الإضافات', _fmt(d.totalEarnings)),
          const Divider(height: 20, color: AppColors.border),
          _Row('إجمالي الخصومات', _fmt(d.deductions.total)),
          _Row('الضرائب', _fmt(d.taxAmount)),
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
        children: [
          _Row('تأخير', _fmt(dd.lateAmount)),
          _Row('غياب', _fmt(dd.absenceAmount)),
          _Row('جزاءات', _fmt(dd.penaltiesAmount)),
          _Row('سلف', _fmt(dd.advancesAmount)),
          _Row('تأمين صحي', _fmt(dd.healthInsuranceAmount)),
          _Row('تسويات', _fmt(dd.settlementDeductions)),
          const Divider(height: 20, color: AppColors.border),
          _Row('إجمالي الخصومات', _fmt(dd.total), strong: true),
          if (dd.penaltyDetails.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final p in dd.penaltyDetails)
              _Row(
                p.description ?? 'جزاء',
                _fmt(p.amount),
              ),
          ],
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
          _Row('تأمين اجتماعي', _fmt(ins.social)),
          _Row('تأمين صحي', _fmt(ins.health)),
          _Row('حصة الشركة', _fmt(ins.companyShare)),
          const Divider(height: 20, color: AppColors.border),
          _Row('إجمالي المخصوم', _fmt(ins.totalDeducted), strong: true),
        ],
      ),
    );
  }

  Widget _buildAttendance(SalaryCalculation d) {
    return _SectionCard(
      icon: Icons.how_to_reg_rounded,
      title: 'الحضور والانصراف',
      child: Column(
        children: [
          _Row('أيام عمل مدفوعة', '${d.paidShiftDays} يوم'),
          _Row('أيام عمل إجمالية', '${d.totalWorkingDays} يوم'),
          _Row('ساعات العمل', '${d.hoursWorked.toStringAsFixed(2)} ساعة'),
          _Row('الساعات الإضافية',
              '${d.overtimeHours.toStringAsFixed(2)} ساعة'),
          _Row('أجر الساعات الإضافية', _fmt(d.overtimePay)),
          if (d.bonusAmount != 0) ...[
            const Divider(height: 20, color: AppColors.border),
            _Row('مكافأة', _fmt(d.bonusAmount)),
            _Row('تسويات إضافية', _fmt(d.settlementAdditions)),
            _Row('تسويات', _fmt(d.settlementAmount)),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
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
    final text =
        amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);
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
          const Text(
            'صافي الراتب',
            style: TextStyle(fontSize: 13, color: Colors.white70),
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

  const _Row(this.label, this.value, {this.strong = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
              color: strong ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
              color: strong ? AppColors.primary : AppColors.textPrimary,
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
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12),
            ),
          ),
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
              .map((item) => DropdownMenuItem(
                  value: item, child: Text(itemLabel(item))))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
