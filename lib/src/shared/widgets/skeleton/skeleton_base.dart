import 'package:flutter/material.dart';
import 'package:mediconsult_internal/src/core/theme/app_colors.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonBase extends StatelessWidget {
  final double width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const SkeletonBase({
    super.key,
    required this.width,
    this.height,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? AppColors.border.withValues(alpha: 0.3),
      highlightColor: highlightColor ?? AppColors.border.withValues(alpha: 0.1),
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: width,
        height: height ?? 20,
        decoration: BoxDecoration(
          color: AppColors.border.withValues(alpha: 0.3),
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}





