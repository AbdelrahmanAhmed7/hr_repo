import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Unified back button widget for auth screens
class BackButtonWidget extends StatelessWidget {
  final VoidCallback? onPressed;

  const BackButtonWidget({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      right: 16,
      child: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: onPressed ?? () => Navigator.of(context).pop(),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.9),
          padding: const EdgeInsets.all(12),
        ),
      ),
    );
  }
}



