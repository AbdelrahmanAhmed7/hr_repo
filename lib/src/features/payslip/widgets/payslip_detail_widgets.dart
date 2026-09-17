import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_formatters.dart';
import '../../hr/models/salary_calculation.dart';

// ───────────────────────── Formatting helpers ─────────────────────────

String payslipFmtNumber(double v) {
  return v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);
}

// ───────────────────────── Section Card (Admin/HR style) ─────────────────────────

class PayslipSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const PayslipSectionCard({
    super.key,
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

// ───────────────────────── Row (Admin/HR style) ─────────────────────────

class PayslipRow extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;
  final Color? color;

  const PayslipRow(
    this.label,
    this.value, {
    super.key,
    this.strong = false,
    this.color,
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
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              textAlign: TextAlign.end,
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

// ───────────────────────── Summary Big Card ─────────────────────────

class PayslipSummaryBig extends StatelessWidget {
  final double amount;
  final String label;

  const PayslipSummaryBig({
    super.key,
    required this.amount,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final text = AppFormatters.currency(amount);
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
            text,
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

// ───────────────────────── Allowances Section ─────────────────────────

class PayslipAllowancesSection extends StatelessWidget {
  final SalaryAllowances allowances;
  final double bonusAmount;
  final double overtimePay;
  final double settlementAdditions;
  final double settlementAmount;
  final bool showOvertime;
  final bool showBonuses;

  const PayslipAllowancesSection({
    super.key,
    required this.allowances,
    this.bonusAmount = 0,
    this.overtimePay = 0,
    this.settlementAdditions = 0,
    this.settlementAmount = 0,
    this.showOvertime = false,
    this.showBonuses = false,
  });

  @override
  Widget build(BuildContext context) {
    return PayslipSectionCard(
      icon: Icons.add_circle_outline_rounded,
      title: 'الإضافات (البدلات)',
      child: Column(
        children: [
          PayslipRow('بدل سكن', AppFormatters.currency(allowances.housing)),
          PayslipRow('بدل وجبات', AppFormatters.currency(allowances.meal)),
          PayslipRow('بدل مواصلات', AppFormatters.currency(allowances.transportation)),
          PayslipRow('بدل تأمين', AppFormatters.currency(allowances.insurance)),
          PayslipRow('إضافي', AppFormatters.currency(allowances.additional)),
          PayslipRow('أخرى', AppFormatters.currency(allowances.other)),
          if (showBonuses && bonusAmount != 0) ...[
            PayslipRow('مكافآت', AppFormatters.currency(bonusAmount)),
          ],
          if (showOvertime && overtimePay != 0) ...[
            PayslipRow('أجر إضافي', AppFormatters.currency(overtimePay)),
          ],
          if (settlementAdditions != 0) ...[
            PayslipRow(
              'تسويات إضافة',
              AppFormatters.currency(settlementAdditions),
            ),
          ],
          if (settlementAmount != 0) ...[
            PayslipRow('قيمة التسوية', AppFormatters.currency(settlementAmount)),
          ],
          const Divider(height: 20, color: AppColors.border),
          PayslipRow(
            'إجمالي المستحقات',
            AppFormatters.currency(allowances.total),
            strong: true,
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Deductions Section ─────────────────────────

class PayslipDeductionsSection extends StatelessWidget {
  final SalaryDeductions deductions;
  final bool showHoursInLate;
  final bool showDaysInAbsence;

  const PayslipDeductionsSection({
    super.key,
    required this.deductions,
    this.showHoursInLate = false,
    this.showDaysInAbsence = false,
  });

  @override
  Widget build(BuildContext context) {
    final lateLabel = showHoursInLate
        ? 'تأخير (${deductions.lateHours.toStringAsFixed(0)} ساعة)'
        : 'خصم التأخير';
    final absenceLabel = showDaysInAbsence
        ? 'غياب (${deductions.absenceDays.toStringAsFixed(0)} يوم)'
        : 'خصم الغياب';

    return PayslipSectionCard(
      icon: Icons.remove_circle_outline_rounded,
      title: 'الخصومات',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PayslipRow(lateLabel, AppFormatters.currency(deductions.lateAmount)),
          PayslipRow(absenceLabel, AppFormatters.currency(deductions.absenceAmount)),
          PayslipRow('جزاءات', AppFormatters.currency(deductions.penaltiesAmount)),
          PayslipRow('سلف', AppFormatters.currency(deductions.advancesAmount)),
          PayslipRow(
            'تأمين صحي',
            AppFormatters.currency(deductions.healthInsuranceAmount),
          ),
          if (deductions.settlementDeductions != 0)
            PayslipRow(
              'تسويات خصم',
              AppFormatters.currency(deductions.settlementDeductions),
            ),
          const Divider(height: 20, color: AppColors.border),
          PayslipRow(
            'إجمالي الخصومات',
            AppFormatters.currency(deductions.total),
            strong: true,
          ),
          if (deductions.penaltyDetails.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...deductions.penaltyDetails.map((p) {
              final label = p.isDayPenalty
                  ? 'جزاء أيام'
                  : p.isAmountPenalty
                  ? 'جزاء مبلغ'
                  : 'جزاء';
              final value = p.isDayPenalty
                  ? '${payslipFmtNumber(p.days)} يوم'
                  : AppFormatters.currency(p.amount);
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 6, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$label: $value',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

// ───────────────────────── Insurance Section ─────────────────────────

class PayslipInsuranceSection extends StatelessWidget {
  final SalaryInsurance insurance;
  final double? insuranceSalary;

  const PayslipInsuranceSection({
    super.key,
    required this.insurance,
    this.insuranceSalary,
  });

  @override
  Widget build(BuildContext context) {
    return PayslipSectionCard(
      icon: Icons.shield_outlined,
      title: 'التأمينات',
      child: Column(
        children: [
          if (insuranceSalary != null)
            PayslipRow('راتب التأمين', AppFormatters.currency(insuranceSalary!)),
          PayslipRow('تأمين اجتماعي', AppFormatters.currency(insurance.social)),
          PayslipRow('تأمين صحي', AppFormatters.currency(insurance.health)),
          PayslipRow('حصة الشركة', AppFormatters.currency(insurance.companyShare)),
          const Divider(height: 20, color: AppColors.border),
          PayslipRow(
            'إجمالي المخصوم',
            AppFormatters.currency(insurance.totalDeducted),
            strong: true,
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Summary Section ─────────────────────────

class PayslipSummarySection extends StatelessWidget {
  final double grossSalary;
  final double totalEarnings;
  final double deductionsTotal;
  final double netSalary;
  final double taxAmount;
  final double? bonusAmount;

  const PayslipSummarySection({
    super.key,
    required this.grossSalary,
    required this.totalEarnings,
    required this.deductionsTotal,
    required this.netSalary,
    this.taxAmount = 0,
    this.bonusAmount,
  });

  @override
  Widget build(BuildContext context) {
    return PayslipSectionCard(
      icon: Icons.payments_rounded,
      title: 'ملخص الراتب',
      child: Column(
        children: [
          PayslipSummaryBig(amount: netSalary, label: 'صافي الراتب'),
          const SizedBox(height: 16),
          PayslipRow('الراتب الأساسي', AppFormatters.currency(grossSalary)),
          PayslipRow('إجمالي المستحقات', AppFormatters.currency(totalEarnings)),
          if (bonusAmount != null && bonusAmount != 0)
            PayslipRow('المكافآت', AppFormatters.currency(bonusAmount!)),
          const Divider(height: 20, color: AppColors.border),
          PayslipRow('إجمالي الخصومات', AppFormatters.currency(deductionsTotal)),
          if (taxAmount != 0)
            PayslipRow('الضرائب', AppFormatters.currency(taxAmount)),
          const Divider(height: 20, color: AppColors.border),
          PayslipRow('صافي الراتب', AppFormatters.currency(netSalary), strong: true),
        ],
      ),
    );
  }
}
