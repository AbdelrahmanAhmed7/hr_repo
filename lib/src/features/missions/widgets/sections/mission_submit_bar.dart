import 'package:flutter/material.dart';

import '../../../../shared/components/custom_button.dart';

class MissionSubmitBar extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback? onSubmit;

  const MissionSubmitBar({
    super.key,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      text: 'تسجيل المأمورية',
      isLoading: isSubmitting,
      onPressed: isSubmitting ? null : onSubmit,
    );
  }
}

