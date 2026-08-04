import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class LeaveRequestProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const LeaveRequestProgressIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        children: List.generate(
          totalSteps,
          (index) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index < totalSteps - 1 ? 8 : 0),
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: currentStep >= index ? AppColors.primary : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
