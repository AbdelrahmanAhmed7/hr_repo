import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class HolidaysSectionHeader extends StatelessWidget {
  final String title;
  final Color indicatorColor;

  const HolidaysSectionHeader({
    super.key,
    required this.title,
    required this.indicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: indicatorColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }
}


