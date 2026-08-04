import 'package:flutter/material.dart';
import 'skeleton_base.dart';

class SkeletonActivityItem extends StatelessWidget {
  const SkeletonActivityItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Icon placeholder
        SkeletonBase(
          width: 44,
          height: 44,
          borderRadius: BorderRadius.circular(12),
        ),
        const SizedBox(width: 12),
        // Text content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBase(
                width: double.infinity,
                height: 16,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 6),
              SkeletonBase(
                width: 150,
                height: 14,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
        // Time placeholder
        SkeletonBase(
          width: 60,
          height: 12,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}





