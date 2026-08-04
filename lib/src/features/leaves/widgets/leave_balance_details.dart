import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/leave_balance_model.dart';

class LeaveBalanceDetails extends StatelessWidget {
  final LeaveBalanceModel balance;

  const LeaveBalanceDetails({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'تفاصيل رصيد الإجازات',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Annual Leave
          _buildBalanceRow(
            context,
            icon: Icons.beach_access_outlined,
            title: 'الإجازة السنوية',
            total: balance.annualLeaveBalance,
            used: balance.annualLeaveUsed,
            remaining: balance.annualLeaveRemaining,
            color: AppColors.primary,
          ),
          const Divider(height: 24),

          // Casual Leave
          _buildBalanceRow(
            context,
            icon: Icons.event_available_outlined,
            title: 'الإجازة العرضية',
            used: balance.casualLeaveUsed,
            color: AppColors.info,
            showOnlyUsed: true,
          ),
          const Divider(height: 24),

          // Sick Leave
          _buildBalanceRow(
            context,
            icon: Icons.medical_services_outlined,
            title: 'الإجازة المرضية',
            total: balance.sickLeaveBalance,
            used: balance.sickLeaveUsed,
            remaining: balance.sickLeaveBalance - balance.sickLeaveUsed,
            color: AppColors.error,
          ),

          if (balance.maternity > 0 ||
              balance.paternity > 0 ||
              balance.hajj > 0 ||
              balance.exam > 0 ||
              balance.paid > 0) ...[
            const Divider(height: 24),
            Text(
              'إجازات أخرى',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            // Maternity Leave
            _buildSimpleBalanceRow(
              context,
              icon: Icons.pregnant_woman_outlined,
              title: 'إجازة وضع',
              days: balance.maternity,
            ),

            // Paternity Leave
            _buildSimpleBalanceRow(
              context,
              icon: Icons.family_restroom_outlined,
              title: 'إجازة أبوة',
              days: balance.paternity,
            ),

            // Hajj Leave
            _buildSimpleBalanceRow(
              context,
              icon: Icons.mosque_outlined,
              title: 'إجازة حج',
              days: balance.hajj,
            ),

            // Exam Leave
            _buildSimpleBalanceRow(
              context,
              icon: Icons.school_outlined,
              title: 'إجازة امتحانات',
              days: balance.exam,
            ),

            // Paid Leave
            if (balance.paid > 0)
              _buildSimpleBalanceRow(
                context,
                icon: Icons.paid_outlined,
                title: 'إجازة مدفوعة',
                days: balance.paid,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildBalanceRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    int? total,
    required int used,
    int? remaining,
    required Color color,
    bool showOnlyUsed = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (showOnlyUsed)
          Row(
            children: [
              const SizedBox(width: 48),
              Text(
                'المستخدم: ',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '$used يوم',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              const SizedBox(width: 48),
              Expanded(
                child: _buildStatChip(
                  label: 'المجموع',
                  value: '$total',
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatChip(
                  label: 'المستخدم',
                  value: '$used',
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatChip(
                  label: 'المتبقي',
                  value: '$remaining',
                  color: AppColors.success,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSimpleBalanceRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int days,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const Spacer(),
          Text(
            '$days يوم',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: color)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
