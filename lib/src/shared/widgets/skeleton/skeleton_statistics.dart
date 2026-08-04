import 'package:flutter/material.dart';
import 'package:mediconsult_internal/src/core/theme/app_colors.dart';
import 'skeleton_card.dart';

class SkeletonStatistics extends StatelessWidget {
  final int itemCount;

  const SkeletonStatistics({
    super.key,
    this.itemCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title placeholder
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 120,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.border.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Statistics cards
          ...List.generate(
            (itemCount / 2).ceil(),
            (rowIndex) {
              final itemsInRow = rowIndex * 2 + 2 <= itemCount ? 2 : 1;
              return Padding(
                padding: EdgeInsets.only(bottom: rowIndex < (itemCount / 2).ceil() - 1 ? 12 : 0),
                child: Row(
                  children: List.generate(
                    itemsInRow,
                    (colIndex) {
                      final index = rowIndex * 2 + colIndex;
                      if (index >= itemCount) return const SizedBox.shrink();
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: colIndex == 0 ? 0 : 12,
                            left: colIndex == 1 ? 0 : 12,
                          ),
                          child: const SkeletonCard(),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}





