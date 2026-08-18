import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mediconsult_internal/src/features/admin/super_admin_attendance_screen.dart';
import 'package:mediconsult_internal/src/features/employee_of_month/presentation/cubit/employee_of_month_cubit.dart';
import 'package:mediconsult_internal/src/features/employee_of_month/presentation/screens/super_admin_employee_of_month_screen.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme/app_colors.dart';
import 'cubit/super_admin_dashboard_cubit.dart';
import 'super_admin_home_screen.dart';
import 'pending_requests_screen.dart';
import 'system_settings_screen.dart';
import 'punch_pairs_screen.dart';

class SuperAdminScreen extends StatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  State<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen> {
  int _currentIndex = 0;
  DateTime? _lastBackPress;

  final List<Widget> _screens = [
    const SuperAdminHomeScreen(),
    const SuperAdminAttendanceScreen(),
    const PunchPairsScreen(),
    const PendingRequestsScreen(),
    BlocProvider(
      create: (_) => getIt<SuperAdminEmployeeOfMonthCubit>(),
      child: const SuperAdminEmployeeOfMonthScreen(),
    ),
    const SystemSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SuperAdminDashboardCubit>()..loadDashboard(),
      child: _SuperAdminScreenBody(
        currentIndex: _currentIndex,
        screens: _screens,
        lastBackPress: _lastBackPress,
        onIndexChanged: (i) => setState(() => _currentIndex = i),
        onBackPress: (dt) => _lastBackPress = dt,
      ),
    );
  }
}

class _SuperAdminScreenBody extends StatelessWidget {
  final int currentIndex;
  final List<Widget> screens;
  final DateTime? lastBackPress;
  final ValueChanged<int> onIndexChanged;
  final ValueChanged<DateTime?> onBackPress;

  const _SuperAdminScreenBody({
    required this.currentIndex,
    required this.screens,
    required this.lastBackPress,
    required this.onIndexChanged,
    required this.onBackPress,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final now = DateTime.now();
        if (lastBackPress == null ||
            now.difference(lastBackPress!) > const Duration(seconds: 2)) {
          onBackPress(now);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('اضغط مرة أخرى للخروج'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(index: currentIndex, children: screens),
        bottomNavigationBar: SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.backgroundSecondary.withValues(alpha: 0),
                  AppColors.backgroundSecondary,
                ],
              ),
            ),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildNavItem(
                    context,
                    0,
                    Icons.dashboard_outlined,
                    'لوحة التحكم',
                  ),
                  _buildNavItem(context, 1, Icons.how_to_reg_rounded, 'الحضور'),
                  _buildNavItem(context, 2, Icons.swap_horiz_rounded, 'الدخول والخروج'),
                  _buildNavItem(
                    context,
                    3,
                    Icons.pending_actions_outlined,
                    'الطلبات',
                  ),
                  _buildNavItem(
                    context,
                    4,
                    Icons.emoji_events_rounded,
                    'موظف الشهر',
                  ),
                  _buildNavItem(
                    context,
                    5,
                    Icons.settings_outlined,
                    'الإعدادات',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
  ) {
    final isSelected = currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => onIndexChanged(index),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textTertiary,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
