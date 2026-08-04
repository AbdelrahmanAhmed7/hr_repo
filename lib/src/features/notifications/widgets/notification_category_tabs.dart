import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/notification.dart';

class NotificationCategoryTabs extends StatelessWidget {
  final TabController controller;
  final Function(NotificationType?) onCategorySelected;

  const NotificationCategoryTabs({
    super.key,
    required this.controller,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          TabBar(
            controller: controller,
            isScrollable: true,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            tabs: const [
              Tab(text: 'الكل'),
              Tab(text: 'إجازة'),
              Tab(text: 'إذن'),
              Tab(text: 'حضور'),
              Tab(text: 'عمل إضافي'),
              Tab(text: 'مهمة'),
              Tab(text: 'عام'),
              Tab(text: 'نظام'),
            ],
            onTap: (index) {
              if (index == 0) {
                onCategorySelected(null);
              } else {
                final types = [
                  NotificationType.leave,
                  NotificationType.permission,
                  NotificationType.attendance,
                  NotificationType.overtime,
                  NotificationType.mission,
                  NotificationType.general,
                  NotificationType.system,
                ];
                onCategorySelected(types[index - 1]);
              }
            },
          ),
        ],
      ),
    );
  }
}



