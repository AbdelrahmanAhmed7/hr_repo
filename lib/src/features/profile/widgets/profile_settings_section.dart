import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/storage_keys.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/device_fingerprint.dart';
import '../../../shared/components/custom_toast.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/services/auth_storage_service.dart';

class ProfileSettingsSection extends StatelessWidget {
  const ProfileSettingsSection({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final authCubit = context.read<AuthCubit>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final authState = await AuthStorageService.loadAuthState();
        final userId = authState.userId ?? '';

        await authCubit.logout();

        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(StorageKeys.userProfile);

        if (userId.isNotEmpty) {
          await DeviceFingerprint.clearFingerprint(userId);
        }
      } catch (_) {
        if (!context.mounted) return;
        CustomToast.showError('حدث خطأ أثناء تسجيل الخروج');
        return;
      }

      if (!context.mounted) return;

      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.border.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'الإعدادات',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildSettingRow(
                  context,
                  icon: Icons.receipt_long_outlined,
                  label: 'بيان المرتب',
                  onTap: () => context.push('/payslip'),
                ),
                const Divider(height: 32),
                _buildSettingRow(
                  context,
                  icon: Icons.work_history_outlined,
                  label: 'السجل الوظيفي',
                  onTap: () => context.push('/employee-history'),
                ),
                const Divider(height: 32),
                _buildSettingRow(
                  context,
                  icon: Icons.lock_outline,
                  label: 'تغيير كلمة المرور',
                  onTap: () => context.push('/change-password'),
                ),
                const Divider(height: 32),
                _buildSettingRow(
                  context,
                  icon: Icons.help_outline,
                  label: 'المساعدة والدعم',
                  onTap: () => context.push('/help'),
                ),
                const Divider(height: 32),
                _buildSettingRow(
                  context,
                  icon: Icons.info_outline,
                  label: 'عن التطبيق',
                  onTap: () => context.push('/about'),
                ),
                const Divider(height: 32),
                _buildSettingRow(
                  context,
                  icon: Icons.logout_rounded,
                  label: 'تسجيل الخروج',
                  onTap: () => _handleLogout(context),
                  isDestructive: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSettingRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDestructive
                    ? [AppColors.error, AppColors.error.withValues(alpha: 0.8)]
                    : [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: (isDestructive ? AppColors.error : AppColors.primary)
                      .withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 24, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isDestructive ? AppColors.error : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}