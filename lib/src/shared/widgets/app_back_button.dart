import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppBackButton extends StatelessWidget {
  final Color? iconColor;
  final Color? backgroundColor;
  final VoidCallback? onPressed;

  const AppBackButton({
    super.key,
    this.iconColor,
    this.backgroundColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'رجوع',
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      icon: Icon(
        Icons.arrow_back_ios_new_rounded,
        color: iconColor ?? AppColors.textPrimary,
        size: 20,
      ),
      style: IconButton.styleFrom(
        backgroundColor: backgroundColor,
        minimumSize: const Size(44, 44),
      ),
    );
  }
}
