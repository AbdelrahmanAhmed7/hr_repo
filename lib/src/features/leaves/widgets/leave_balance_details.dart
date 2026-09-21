import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/leave_balance_model.dart';

class LeaveBalanceDetails extends StatelessWidget {
  final LeaveBalanceModel balance;

  const LeaveBalanceDetails({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    final hasOther = balance.maternity > 0 ||
        balance.paternity > 0 ||
        balance.hajj > 0 ||
        balance.exam > 0 ||
        balance.paid > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildBalanceRow(
            context,
            icon: Icons.beach_access_outlined,
            title: 'الإجازة السنوية',
            color: AppColors.primary,
            units: [
              _UnitChip(label: 'الإجمالي', value: '${balance.annualLeaveBalance}', color: AppColors.textSecondary),
              _UnitChip(label: 'المستخدم', value: '${balance.annualLeaveUsed}', color: AppColors.warning),
              _UnitChip(label: 'المتبقي', value: '${balance.annualLeaveRemaining}', color: AppColors.success),
            ],
          ),
          _buildSeparator(),
          _buildBalanceRow(
            context,
            icon: Icons.event_available_outlined,
            title: 'الإجازة العرضية',
            color: AppColors.info,
            units: [
              _UnitChip(label: 'المستخدم', value: '${balance.casualLeaveUsed}', color: AppColors.warning),
            ],
          ),
          _buildSeparator(),
          _buildBalanceRow(
            context,
            icon: Icons.medical_services_outlined,
            title: 'الإجازة المرضية',
            color: AppColors.error,
            units: [
              _UnitChip(label: 'الإجمالي', value: '${balance.sickLeaveBalance}', color: AppColors.textSecondary),
              _UnitChip(label: 'المستخدم', value: '${balance.sickLeaveUsed}', color: AppColors.warning),
              _UnitChip(label: 'المتبقي', value: '${balance.sickLeaveBalance - balance.sickLeaveUsed}', color: AppColors.success),
            ],
          ),
          if (hasOther) ...[
            _buildSeparator(),
            _buildBalanceRow(
              context,
              icon: Icons.more_horiz,
              title: 'إجازات أخرى',
              color: AppColors.textSecondary,
              units: [
                _UnitChip(label: 'وضع', value: '${balance.maternity}', color: AppColors.textPrimary),
                _UnitChip(label: 'أبوة', value: '${balance.paternity}', color: AppColors.textPrimary),
                _UnitChip(label: 'حج', value: '${balance.hajj}', color: AppColors.textPrimary),
                if (balance.exam > 0)
                  _UnitChip(label: 'امتحانات', value: '${balance.exam}', color: AppColors.textPrimary),
                if (balance.paid > 0)
                  _UnitChip(label: 'مدفوعة', value: '${balance.paid}', color: AppColors.textPrimary),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSeparator() {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: AppColors.border,
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _buildBalanceRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required List<_UnitChip> units,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          for (final unit in units) ...[
            if (unit != units.first) const SizedBox(width: 10),
            _buildUnitChip(context, unit),
          ],
        ],
      ),
    );
  }

  Widget _buildUnitChip(BuildContext context, _UnitChip unit) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          unit.value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: unit.color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          unit.label,
          style: TextStyle(
            fontSize: 9.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _UnitChip {
  final String label;
  final String value;
  final Color color;

  const _UnitChip({required this.label, required this.value, required this.color});
}