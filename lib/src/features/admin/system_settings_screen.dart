import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_back_button.dart';

class SystemSettingsScreen extends StatelessWidget {
  const SystemSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        leading: const AppBackButton(),
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
