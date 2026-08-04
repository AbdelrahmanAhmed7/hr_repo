import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum LocationPermissionChoice {
  whileUsingApp,
  allowOnce,
  dontAllow,
}

class LocationPermissionDialog extends StatelessWidget {
  final String? title;
  final String? message;

  const LocationPermissionDialog({
    super.key,
    this.title,
    this.message,
  });

  static Future<LocationPermissionChoice?> show(
    BuildContext context, {
    String? title,
    String? message,
  }) async {
    return await showDialog<LocationPermissionChoice>(
      context: context,
      barrierDismissible: false,
      builder: (context) => LocationPermissionDialog(
        title: title,
        message: message,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title ?? 'السماح بالوصول للموقع',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontSize: 20,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Message
            Text(
              message ??
                  'نحتاج إلى الوصول لموقعك لتسجيل الحضور والتحقق من موقعك. يرجى اختيار نوع الإذن:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                    fontSize: 14,
                  ),
            ),
            const SizedBox(height: 24),
            // Options
            _buildOption(
              context,
              icon: Icons.location_on_rounded,
              title: 'أثناء استخدام التطبيق',
              subtitle: 'السماح بالوصول للموقع فقط عند استخدام التطبيق',
              choice: LocationPermissionChoice.whileUsingApp,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            _buildOption(
              context,
              icon: Icons.access_time_rounded,
              title: 'السماح مرة واحدة',
              subtitle: 'السماح بالوصول للموقع لمرة واحدة فقط',
              choice: LocationPermissionChoice.allowOnce,
              color: AppColors.warning,
            ),
            const SizedBox(height: 12),
            _buildOption(
              context,
              icon: Icons.block_rounded,
              title: 'عدم السماح',
              subtitle: 'رفض الوصول للموقع',
              choice: LocationPermissionChoice.dontAllow,
              color: AppColors.error,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required LocationPermissionChoice choice,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(choice),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            fontSize: 15,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.3,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: color,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

