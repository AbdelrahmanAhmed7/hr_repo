import 'package:flutter/material.dart';
import 'package:mediconsult_internal/src/core/theme/app_colors.dart';
import 'skeleton_base.dart';

class SkeletonListItem extends StatelessWidget {
  final bool showAvatar;
  final double? height;

  const SkeletonListItem({
    super.key,
    this.showAvatar = true,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          if (showAvatar) ...[
            SkeletonBase(
              width: 48,
              height: 48,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SkeletonBase(
                  width: double.infinity,
                  height: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                SkeletonBase(
                  width: 150,
                  height: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
                if (height == null) ...[
                  const SizedBox(height: 6),
                  SkeletonBase(
                    width: 100,
                    height: 12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}





