import 'package:flutter/material.dart';
import 'package:mediconsult_internal/src/core/theme/app_colors.dart';
import 'skeleton_base.dart';

class SkeletonCard extends StatelessWidget {
  final double? height;
  final EdgeInsets? padding;

  const SkeletonCard({
    super.key,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(18),
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.border.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon placeholder
          SkeletonBase(
            width: 44,
            height: 44,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(height: 16),
          // Title placeholder
          SkeletonBase(
            width: 100,
            height: 14,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          // Value placeholder
          SkeletonBase(
            width: 60,
            height: 28,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}





