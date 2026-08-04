import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/components/custom_button.dart';

class LeaveRequestNavigationButtons extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final String? nextButtonText;

  const LeaveRequestNavigationButtons({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
    this.onPrevious,
    this.onNext,
    this.nextButtonText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.border.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (currentStep > 0 && onPrevious != null)
            Expanded(
              child: SecondaryButton(
                text: 'السابق',
                onPressed: onPrevious,
              ),
            ),
          if (currentStep > 0 && onPrevious != null) const SizedBox(width: 12),
          Expanded(
            child: PrimaryButton(
              text: nextButtonText ?? (currentStep == totalSteps - 1 ? 'إرسال' : 'التالي'),
              onPressed: onNext,
            ),
          ),
        ],
      ),
    );
  }
}
