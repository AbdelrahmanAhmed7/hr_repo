import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mediconsult_internal/src/features/admin/super_admin_attendance_screen.dart';
import 'package:mediconsult_internal/src/features/admin/department_requests/department_requests_screen.dart';
import 'package:mediconsult_internal/src/features/admin/department_requests/cubit/department_requests_cubit.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme/app_colors.dart';
import '../../features/hr/cubit/employees_cubit.dart';
import '../../features/reports/cubit/reports_cubit.dart';
import '../../features/reports/screens/reports_hub_screen.dart';
import 'cubit/super_admin_dashboard_cubit.dart';
import 'super_admin_employees_screen.dart';
import 'super_admin_home_screen.dart';

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
    BlocProvider(
      create: (_) => getIt<EmployeesCubit>(),
      child: const SuperAdminEmployeesScreen(),
    ),
    BlocProvider(
      create: (_) => getIt<DepartmentRequestsCubit>()..load(),
      child: const DepartmentRequestsScreen(),
    ),
    BlocProvider(
      create: (_) => getIt<ReportsCubit>(),
      child: const ReportsHubScreen(),
    ),
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
                    'الرئيسية',
                  ),
                  _buildNavItem(context, 1, Icons.how_to_reg_rounded, 'الحضور'),
                  _buildNavItem(
                    context,
                    2,
                    Icons.people_alt_outlined,
                    'الموظفين',
                  ),
                  _buildNavItem(
                    context,
                    3,
                    Icons.pending_actions_outlined,
                    'الطلبات',
                  ),
                  _buildNavItem(
                    context,
                    4,
                    Icons.assessment_rounded,
                    'التقارير',
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
