import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/skeleton/skeleton_base.dart';

/// Loading state widget for organization chart
/// 
/// Displays a shimmer loading animation while organization data is being fetched.
class OrganizationChartLoadingState extends StatelessWidget {
  const OrganizationChartLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Skeleton for organization chart
            Container(
              width: double.infinity,
              height: 400,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Skeleton nodes with shimmer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SkeletonBase(
                          width: 80,
                          height: 80,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SkeletonBase(
                          width: 60,
                          height: 60,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        SkeletonBase(
                          width: 60,
                          height: 60,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        SkeletonBase(
                          width: 60,
                          height: 60,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'جاري تحميل الهيكل التنظيمي...',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

