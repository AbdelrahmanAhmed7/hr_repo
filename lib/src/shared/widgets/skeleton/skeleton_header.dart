import 'package:flutter/material.dart';
import 'package:mediconsult_internal/src/core/theme/app_colors.dart';
import 'skeleton_base.dart';

class SkeletonHeader extends StatelessWidget {
  final bool showAvatar;
  final bool showBadge;

  const SkeletonHeader({
    super.key,
    this.showAvatar = true,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (showAvatar) ...[
              SkeletonBase(
                width: 56,
                height: 56,
                borderRadius: BorderRadius.circular(28),
                baseColor: Colors.white.withValues(alpha: 0.2),
                highlightColor: Colors.white.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBase(
                    width: 100,
                    height: 13,
                    borderRadius: BorderRadius.circular(4),
                    baseColor: Colors.white.withValues(alpha: 0.3),
                    highlightColor: Colors.white.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 6),
                  SkeletonBase(
                    width: 150,
                    height: 20,
                    borderRadius: BorderRadius.circular(4),
                    baseColor: Colors.white.withValues(alpha: 0.3),
                    highlightColor: Colors.white.withValues(alpha: 0.5),
                  ),
                  if (showBadge) ...[
                    const SizedBox(height: 6),
                    SkeletonBase(
                      width: 80,
                      height: 24,
                      borderRadius: BorderRadius.circular(6),
                      baseColor: Colors.white.withValues(alpha: 0.2),
                      highlightColor: Colors.white.withValues(alpha: 0.4),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}





