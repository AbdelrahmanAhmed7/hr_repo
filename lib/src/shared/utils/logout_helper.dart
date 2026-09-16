import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/storage_keys.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/device_fingerprint.dart';
import '../components/custom_toast.dart';
import '../../features/auth/cubit/auth_cubit.dart';
import '../../features/auth/services/auth_storage_service.dart';

/// Shared logout flow: confirm dialog → clear fingerprint + auth state +
/// cached profile → navigate to login. Used by every logout entry point
/// (profile settings, super admin header, ...).
class LogoutHelper {
  const LogoutHelper._();

  static Future<void> confirmAndLogout(BuildContext context) async {
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

    if (confirmed != true || !context.mounted) return;

    // Capture cubit before async gaps (avoids BuildContext across gaps).
    final authCubit = context.read<AuthCubit>();

    try {
      final authState = await AuthStorageService.loadAuthState();
      final userId = authState.userId ?? '';

      if (userId.isNotEmpty) {
        await DeviceFingerprintService().clearFingerprint(userId: userId);
      }

      await authCubit.logout();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(StorageKeys.userProfile);
    } catch (_) {
      if (!context.mounted) return;
      CustomToast.showError('حدث خطأ أثناء تسجيل الخروج');
      return;
    }

    if (!context.mounted) return;
    context.go('/login');
  }
}
