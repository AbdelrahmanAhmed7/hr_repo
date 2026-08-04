import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/components/screen_header.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../shared/widgets/error_state_widget.dart';
import '../auth/cubit/auth_cubit.dart';
import 'cubit/organization_chart_cubit.dart';
import 'cubit/organization_chart_state.dart';
import 'models/view_mode.dart';
import 'widgets/organization_chart_widget.dart';
import 'widgets/organization_chart_list_view.dart';
import 'widgets/organization_chart_grid_view.dart';
import 'widgets/organization_chart_department_view.dart';
import 'widgets/organization_chart_toolbar.dart';
import 'widgets/organization_chart_drawer.dart';
import 'widgets/organization_chart_loading_state.dart';
import 'services/export_service.dart';
import 'widgets/floating_legend.dart';

class OrganizationChartScreen extends StatefulWidget {
  const OrganizationChartScreen({super.key});

  @override
  State<OrganizationChartScreen> createState() => _OrganizationChartScreenState();
}

class _OrganizationChartScreenState extends State<OrganizationChartScreen> {
  final TextEditingController _searchController = TextEditingController();
  int? _selectedDepartmentId;


  @override
  void initState() {
    super.initState();
    // Enable landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _loadData();
  }

  @override
  void dispose() {
    // Reset orientation preferences
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    final authCubit = context.read<AuthCubit>();
    final orgCubit = context.read<OrganizationChartCubit>();
    orgCubit.loadOrganization(authCubit.state.token);
  }

  void _exportChart(BuildContext context) {
    final state = context.read<OrganizationChartCubit>().state;
    if (state.organizationData != null) {
      ExportService.showExportDialog(
        context: context,
        organizationData: state.organizationData!,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد بيانات للتصدير'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      drawer: OrganizationChartDrawer(
        selectedDepartmentId: _selectedDepartmentId,
        onDepartmentChanged: (value) {
          setState(() {
            _selectedDepartmentId = value;
          });
          context.read<OrganizationChartCubit>().filterByDepartment(value);
        },
        onExport: () => _exportChart(context),
        onReset: () => context.read<OrganizationChartCubit>().expandAll(),
      ),
      body: Stack(
        children: [
          BlocBuilder<OrganizationChartCubit, OrganizationChartState>(
            builder: (context, state) {
              final cubit = context.read<OrganizationChartCubit>();

              // في وضع landscape: عرض فقط الـ chart بدون header وtoolbar
              if (isLandscape) {
                return _buildContent(context, cubit, state);
              }

              // في وضع portrait: عرض التخطيط الكامل
              return Column(
                children: [
                  // Header with menu button
                  ScreenHeader(
                    title: 'الهيكل التنظيمي',
                    subtitle: 'عرض الهيكل التنظيمي للشركة',
                    showBackButton: true,
                    leading: Builder(
                      builder: (context) => Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Scaffold.of(context).openDrawer(),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.menu_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Compact Toolbar (simplified - only search and stats)
                  OrganizationChartToolbar(
                    searchController: _searchController,
                    selectedDepartmentId: _selectedDepartmentId,
                    onDepartmentChanged: (value) {
                      setState(() {
                        _selectedDepartmentId = value;
                      });
                      cubit.filterByDepartment(value);
                      // If filter cleared, also clear search
                      if (value == null) {
                        _searchController.clear();
                        cubit.searchEmployees('');
                      }
                    },
                    onExport: () => _exportChart(context),
                    onReset: () {
                      _searchController.clear();
                      setState(() {
                        _selectedDepartmentId = null;
                      });
                      cubit.expandAll();
                    },
                  ),
                  // Chart - takes remaining space
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // Unfocus search when tapping on chart area
                        FocusScope.of(context).unfocus();
                      },
                      child: _buildContent(context, cubit, state),
                    ),
                  ),
                ],
              );
            },
          ),
          // Floating Legend
          const Positioned(
            left: 20,
            bottom: 20,
            child: FloatingLegend(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    OrganizationChartCubit cubit,
    OrganizationChartState state,
  ) {
    if (state.isLoading) {
      return const OrganizationChartLoadingState();
    }

    if (state.error != null) {
      return ErrorStateWidget(
        error: state.error!,
        buttonLabel: 'إعادة المحاولة',
        onRetry: _loadData,
      );
    }

    if (state.employees == null || state.employees!.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.account_tree_rounded,
        title: 'لا توجد بيانات للعرض',
        message: 'لم يتم العثور على بيانات الهيكل التنظيمي',
        buttonLabel: 'إعادة التحميل',
        onButtonPressed: _loadData,
      );
    }

    // For tree view, graph is required
    if (state.viewMode == OrganizationViewMode.tree &&
        (state.graph == null || state.graph!.nodeCount() == 0)) {
      return EmptyStateWidget(
        icon: Icons.account_tree_rounded,
        title: 'لا توجد بيانات للعرض',
        message: 'لم يتم العثور على بيانات الهيكل التنظيمي',
        buttonLabel: 'إعادة التحميل',
        onButtonPressed: _loadData,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadData();
        await Future.delayed(const Duration(seconds: 1));
      },
      color: AppColors.primary,
      backgroundColor: Colors.white,
      strokeWidth: 3.0,
      displacement: 40.0,
      edgeOffset: 20.0,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.05),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(state.viewMode),
          child: _buildViewModeContent(context, cubit, state),
        ),
      ),
    );
  }

  Widget _buildViewModeContent(
    BuildContext context,
    OrganizationChartCubit cubit,
    OrganizationChartState state,
  ) {
    switch (state.viewMode) {
      case OrganizationViewMode.tree:
        if (state.graph == null || state.graphViewController == null || state.employees == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        return OrganizationChartWidget(
          key: ValueKey(state.graph.hashCode),
          graph: state.graph!,
          graphViewController: state.graphViewController!,
          organizationData: state.organizationData,
          employees: state.employees!,
          expandedNodeIds: state.expandedNodeIds,
          isCompactMode: state.isCompactMode,
          isHorizontal: state.isHorizontal,
          selectedEmployeeId: state.selectedEmployee?.id,
          onNodeTap: (employeeId) {
            cubit.selectEmployee(employeeId);
          },
        );
      case OrganizationViewMode.list:
        return OrganizationChartListView(
          employees: state.employees ?? [],
          organizationData: state.organizationData,
          selectedEmployeeId: state.selectedEmployee?.id,
          onEmployeeTap: (employeeId) {
            cubit.selectEmployee(employeeId);
          },
        );
      case OrganizationViewMode.grid:
        return OrganizationChartGridView(
          employees: state.employees ?? [],
          organizationData: state.organizationData,
          selectedEmployeeId: state.selectedEmployee?.id,
          onEmployeeTap: (employeeId) {
            cubit.selectEmployee(employeeId);
          },
        );
      case OrganizationViewMode.department:
        return OrganizationChartDepartmentView(
          employees: state.employees ?? [],
          organizationData: state.organizationData,
          selectedEmployeeId: state.selectedEmployee?.id,
          onEmployeeTap: (employeeId) {
            cubit.selectEmployee(employeeId);
          },
        );
    }
  }
}
