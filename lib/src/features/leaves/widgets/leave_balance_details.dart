import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/leave_balance_model.dart';

/// Single unified "رصيد الإجازات" block: quick numbers in the header + a
/// compact per-type breakdown below (one row per type).
class LeaveBalanceDetails extends StatelessWidget {
  final LeaveBalanceModel balance;
  final int remainingLeaves;
  final int pendingRequests;

  const LeaveBalanceDetails({
    super.key,
    required this.balance,
    required this.remainingLeaves,
    required this.pendingRequests,
  });

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
      ),
      child: Column(
        children: [
          _buildHeader(context),
          _buildSeparator(),
          _buildBalanceRow(
            context,
            icon: Icons.beach_access_outlined,
            title: 'السنوية',
            color: AppColors.primary,
            units: [
              _UnitChip(label: 'مجموع', value: '${balance.annualLeaveBalance}', color: AppColors.textSecondary),
              _UnitChip(label: 'مستخدم', value: '${balance.annualLeaveUsed}', color: AppColors.warning),
              _UnitChip(label: 'متبقي', value: '${balance.annualLeaveRemaining}', color: AppColors.success),
            ],
          ),
          _buildSeparator(),
          _buildBalanceRow(
            context,
            icon: Icons.event_available_outlined,
            title: 'العرضية',
            color: AppColors.info,
            units: [
              _UnitChip(label: 'مستخدم', value: '${balance.casualLeaveUsed}', color: AppColors.warning),
            ],
          ),
          _buildSeparator(),
          _buildBalanceRow(
            context,
            icon: Icons.medical_services_outlined,
            title: 'المرضية',
            color: AppColors.error,
            units: [
              _UnitChip(label: 'مجموع', value: '${balance.sickLeaveBalance}', color: AppColors.textSecondary),
              _UnitChip(label: 'مستخدم', value: '${balance.sickLeaveUsed}', color: AppColors.warning),
              _UnitChip(label: 'متبقي', value: '${balance.sickLeaveBalance - balance.sickLeaveUsed}', color: AppColors.success),
            ],
          ),
          if (hasOther) ...[
            _buildSeparator(),
            _buildBalanceRow(
              context,
              icon: Icons.more_horiz,
              title: 'أخرى',
              color: AppColors.textSecondary,
              units: [
                if (balance.maternity > 0)
                  _UnitChip(label: 'وضع', value: '${balance.maternity}', color: AppColors.textPrimary),
                if (balance.paternity > 0)
                  _UnitChip(label: 'أبوة', value: '${balance.paternity}', color: AppColors.textPrimary),
                if (balance.hajj > 0)
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'رصيد الإجازات',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'المتبقي من الإجازة السنوية: $remainingLeaves يوم',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.pending_actions_outlined,
                  color: AppColors.warning,
                  size: 14,
                ),
                const SizedBox(width: 5),
                Text(
                  '$pendingRequests معلقة',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
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
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 17),
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
            if (unit != units.first) const SizedBox(width: 12),
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