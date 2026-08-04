import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class SystemSettingsScreen extends StatelessWidget {
  const SystemSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        title: const Text('إعدادات النظام'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'صفحة إعدادات النظام (Super Admin فقط)',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
