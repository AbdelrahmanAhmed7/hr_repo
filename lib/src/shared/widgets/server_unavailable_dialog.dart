import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

Future<void> showServerUnavailableDialog(
  BuildContext context, {
  required VoidCallback onRetry,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.cloud_off_rounded,
          color: AppColors.error,
          size: 30,
        ),
      ),
      title: const Text('السيرفر غير متاح', textAlign: TextAlign.center),
      content: const Text(
        'يبدو أن السيرفر واقع أو لا يستجيب حاليا. حاول مرة أخرى بعد قليل.',
        textAlign: TextAlign.center,
        style: TextStyle(height: 1.5),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('إغلاق'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            onRetry();
          },
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('إعادة المحاولة'),
        ),
      ],
    ),
  );
}
