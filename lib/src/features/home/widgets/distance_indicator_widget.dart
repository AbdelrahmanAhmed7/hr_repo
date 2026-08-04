import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class DistanceIndicatorWidget extends StatelessWidget {
  final double distanceFromOffice;

  const DistanceIndicatorWidget({
    super.key,
    required this.distanceFromOffice,
  });

  @override
  Widget build(BuildContext context) {
    final String distanceText;
    if (distanceFromOffice > 1000) {
      final km = distanceFromOffice / 1000;
      distanceText = '${km.toStringAsFixed(1)} كم';
    } else {
      distanceText = '${distanceFromOffice.toStringAsFixed(0)} متر';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_on_outlined,
            size: 18,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            'أنت على بعد $distanceText من المكتب',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
          ),
        ],
      ),
    );
  }
}