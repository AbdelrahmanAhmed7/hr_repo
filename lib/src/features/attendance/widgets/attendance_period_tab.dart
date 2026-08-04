import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AttendancePeriodTab extends StatelessWidget {
  final EdgeInsets padding;
  final Widget header;
  final Widget summary;
  final Widget table;

  const AttendancePeriodTab({
    super.key,
    required this.padding,
    required this.header,
    required this.summary,
    required this.table,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView(
        padding: padding,
        children: [
          header,
          const SizedBox(height: 12),
          summary,
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  'سجل الأيام',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                'اسحب الجدول أفقيًا',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          table,
        ],
      ),
    );
  }
}
