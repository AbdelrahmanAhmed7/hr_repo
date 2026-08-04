import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:graphview/GraphView.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import '../../../core/theme/app_colors.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../hr/cubit/employees_cubit.dart';
import '../../hr/employee_attendance_report_screen.dart';
import '../../hr/models/employee.dart' as hr;
import '../models/organization_models.dart';
import '../cubit/organization_chart_cubit.dart';
import 'org_node_widget.dart';
import 'employee_details_dialog.dart';
import 'employee_actions_menu.dart';

class OrganizationChartWidget extends StatefulWidget {
  final Graph graph;
  final GraphViewController graphViewController;
  final OrganizationData? organizationData;
  final List<Employee> employees;
  final Set<String> expandedNodeIds;
  final String? selectedEmployeeId;
  final Function(String)? onNodeTap;
  final bool isCompactMode;
  final bool isHorizontal;

  const OrganizationChartWidget({
    super.key,
    required this.graph,
    required this.graphViewController,
    this.organizationData,
    required this.employees,
    this.expandedNodeIds = const {},
    this.selectedEmployeeId,
    this.onNodeTap,
    this.isCompactMode = false,
    this.isHorizontal = false,
  });

  @override
  State<OrganizationChartWidget> createState() =>
      _OrganizationChartWidgetState();
}

class _OrganizationChartWidgetState extends State<OrganizationChartWidget>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  // FIX: Track if initial centering has been done
  bool _initialCenteringDone = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // FIX: Schedule initial centering once from initState, not build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerOnRoot();
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // FIX: Moved centering logic out of build()
  void _centerOnRoot() {
    if (_initialCenteringDone) return;
    if (!mounted) return;
    if (!_transformationController.value.isIdentity()) return;
    if (widget.graph.nodeCount() == 0) return;

    final screenSize = MediaQuery.of(context).size;

    final config = BuchheimWalkerConfiguration()
      ..siblingSeparation = widget.isCompactMode ? 30 : 60
      ..levelSeparation = widget.isCompactMode ? 40 : 80
      ..subtreeSeparation = widget.isCompactMode ? 30 : 60
      ..orientation = widget.isHorizontal
          ? BuchheimWalkerConfiguration.ORIENTATION_LEFT_RIGHT
          : BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM;

    final algorithm = BuchheimWalkerAlgorithm(config, TreeEdgeRenderer(config));
    algorithm.run(widget.graph, 0.0, 0.0);

    String? rootId;
    final ceo = widget.employees.cast<Employee?>().firstWhere(
      (e) => e?.level == EmployeeLevel.ceo,
      orElse: () => null,
    );
    rootId = ceo?.id;

    if (rootId == null && widget.graph.nodes.isNotEmpty) {
      rootId = widget.graph.nodes.first.key?.value as String?;
    }

    if (rootId != null) {
      final rootNode = widget.graph.nodes.firstWhere(
        (n) => n.key?.value == rootId,
        orElse: () => widget.graph.nodes.first,
      );

      const scale = 0.8;
      final targetX = (screenSize.width / 2) - (rootNode.x * scale);
      final targetY = widget.isHorizontal
          ? (screenSize.height / 2) - (rootNode.y * scale)
          : 80.0;

      // FIX: use translateByVector3 and scaleByDouble
      _transformationController.value = Matrix4.identity()
        ..translateByVector3(Vector3(targetX, targetY, 0))
        ..scaleByDouble(scale, scale, scale, 1.0);

      _initialCenteringDone = true;
    }
  }

  void _animateZoom(double targetScale) {
    final currentMatrix = _transformationController.value;
    final currentScale = currentMatrix.getMaxScaleOnAxis();

    targetScale = targetScale.clamp(0.3, 2.5);
    if ((currentScale - targetScale).abs() < 0.01) return;

    final currentTranslation = currentMatrix.getTranslation();

    // FIX: use translateByVector3 and scaleByDouble
    final targetMatrix = Matrix4.identity()
      ..translateByVector3(
        Vector3(
          currentTranslation.x * (targetScale / currentScale),
          currentTranslation.y * (targetScale / currentScale),
          0,
        ),
      )
      ..scaleByDouble(targetScale, targetScale, targetScale, 1.0);

    // FIX: Remove old listener before adding new one to avoid memory leak
    _animation?.removeListener(_onAnimationTick);

    _animation = Matrix4Tween(begin: currentMatrix, end: targetMatrix).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animation!.addListener(_onAnimationTick);

    _animationController.forward(from: 0).then((_) {
      if (mounted) {
        _transformationController.value = targetMatrix;
      }
    });
  }

  // FIX: Named method so it can be removed from listener
  void _onAnimationTick() {
    if (mounted) {
      _transformationController.value = _animation!.value;
    }
  }

  void _resetZoom() => _animateZoom(1.0);

  void _zoomIn() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    _animateZoom(currentScale * 1.3);
  }

  void _zoomOut() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    _animateZoom(currentScale / 1.3);
  }

  void _fitToScreen() {
    _transformationController.value = Matrix4.identity();
    _initialCenteringDone = false;
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerOnRoot());
  }

  @override
  Widget build(BuildContext context) {
    if (widget.graph.nodeCount() == 0) {
      return const Center(
        child: Text(
          'لا توجد بيانات للعرض',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
      );
    }

    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    final employeeMap = <String, Employee>{};
    for (final emp in widget.employees) {
      employeeMap[emp.id] = emp;
    }

    final subordinatesMap = <String, List<String>>{};
    for (final emp in widget.employees) {
      if (emp.managerId != null) {
        subordinatesMap.putIfAbsent(emp.managerId!, () => []).add(emp.id);
      }
    }

    final config = BuchheimWalkerConfiguration()
      ..siblingSeparation = widget.isCompactMode ? 30 : 60
      ..levelSeparation = widget.isCompactMode ? 40 : 80
      ..subtreeSeparation = widget.isCompactMode ? 30 : 60
      ..orientation = widget.isHorizontal
          ? BuchheimWalkerConfiguration.ORIENTATION_LEFT_RIGHT
          : BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM;

    // FIX: Read cubits once here before building, not inside builder callback
    final employeesCubit = context.read<EmployeesCubit>();
    final organizationCubit = context.read<OrganizationChartCubit>();

    return Stack(
      children: [
        Container(
          margin: EdgeInsets.all(isLandscape ? 4 : 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isLandscape ? 0 : 16),
            boxShadow: isLandscape
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                      spreadRadius: 2,
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isLandscape ? 0 : 16),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: InteractiveViewer(
                transformationController: _transformationController,
                boundaryMargin: const EdgeInsets.all(200),
                minScale: 0.3,
                maxScale: 2.5,
                panEnabled: true,
                scaleEnabled: true,
                constrained: false,
                clipBehavior: Clip.none,
                child: RepaintBoundary(
                  child: GraphView(
                    key: ValueKey(
                      '${widget.graph.hashCode}_${widget.expandedNodeIds.hashCode}',
                    ),
                    graph: widget.graph,
                    algorithm: BuchheimWalkerAlgorithm(
                      config,
                      TreeEdgeRenderer(config),
                    ),
                    paint: Paint()
                      ..color = Colors.black.withValues(alpha: 0.3)
                      ..strokeWidth = 2.5
                      ..strokeCap = StrokeCap.round
                      ..style = PaintingStyle.stroke,
                    builder: (Node node) {
                      final employeeId = node.key?.value as String?;
                      if (employeeId == null ||
                          !employeeMap.containsKey(employeeId)) {
                        return const SizedBox.shrink();
                      }

                      final employee = employeeMap[employeeId]!;
                      final hasChildren =
                          subordinatesMap.containsKey(employeeId) &&
                          subordinatesMap[employeeId]!.isNotEmpty;
                      final isExpanded = widget.expandedNodeIds.contains(
                        employeeId,
                      );

                      // FIX: Use pre-captured cubit reference instead of context.read inside builder
                      String? position;
                      try {
                        final hrEmployee = employeesCubit.state.employees
                            .firstWhere(
                              (e) => e.id == employeeId,
                              orElse: () => throw StateError('not found'),
                            );
                        position = hrEmployee.position;
                      } catch (_) {
                        position = null;
                      }

                      return OrgNodeWidget(
                        details: _NodeDetails(employee),
                        isSelected: widget.selectedEmployeeId == employeeId,
                        hasSubordinates: hasChildren,
                        subordinatesCount: employee.subordinatesCount > 0
                            ? employee.subordinatesCount
                            : null,
                        position: position,
                        isExpanded: isExpanded,
                        onExpandToggle: hasChildren
                            ? () => organizationCubit.toggleNodeExpansion(
                                employeeId,
                              )
                            : null,
                        onTap: () {
                          widget.onNodeTap?.call(employeeId);
                          _showEmployeeDetails(
                            context,
                            employee,
                            employee.subordinatesCount,
                          );
                        },
                        onLongPress: () => _showEmployeeActionsMenu(
                          context,
                          employee,
                          employee.subordinatesCount,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: isLandscape ? 24 : 20,
          bottom: isLandscape ? 24 : 20,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildControlButton(
                  icon: Icons.add,
                  onPressed: _zoomIn,
                  tooltip: 'تكبير',
                  isFirst: true,
                ),
                const Divider(height: 1, thickness: 1),
                _buildControlButton(
                  icon: Icons.remove,
                  onPressed: _zoomOut,
                  tooltip: 'تصغير',
                ),
                const Divider(height: 1, thickness: 1),
                _buildControlButton(
                  icon: Icons.fit_screen,
                  onPressed: _fitToScreen,
                  tooltip: 'ملء الشاشة',
                ),
                const Divider(height: 1, thickness: 1),
                _buildControlButton(
                  icon: Icons.center_focus_strong,
                  onPressed: _resetZoom,
                  tooltip: 'إعادة تعيين',
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, thickness: 2),
                const SizedBox(height: 8),
                _buildControlButton(
                  icon: widget.isHorizontal
                      ? Icons.view_headline
                      : Icons.view_column,
                  onPressed: () => context
                      .read<OrganizationChartCubit>()
                      .toggleOrientation(),
                  tooltip: 'تغيير الاتجاه',
                ),
                const Divider(height: 1, thickness: 1),
                _buildControlButton(
                  icon: widget.isCompactMode
                      ? Icons.fullscreen_exit
                      : Icons.fullscreen,
                  onPressed: () => context
                      .read<OrganizationChartCubit>()
                      .toggleCompactMode(),
                  tooltip: widget.isCompactMode ? 'عرض عادي' : 'عرض مضغوط',
                  isLast: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.vertical(
            top: isFirst ? const Radius.circular(16) : Radius.zero,
            bottom: isLast ? const Radius.circular(16) : Radius.zero,
          ),
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
        ),
      ),
    );
  }

  void _showEmployeeDetails(
    BuildContext context,
    Employee employee,
    int subordinatesCount,
  ) {
    FocusScope.of(context).unfocus();

    Department? department;
    if (widget.organizationData != null) {
      for (final dept in widget.organizationData!.departments) {
        if (dept.manager.id == employee.id ||
            dept.employees.any((e) => e.id == employee.id)) {
          department = dept;
          break;
        }
      }
    }

    try {
      final employeesCubit = context.read<EmployeesCubit>();
      final authCubit = context.read<AuthCubit>();
      showDialog(
        context: context,
        builder: (dialogContext) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: employeesCubit),
            BlocProvider.value(value: authCubit),
          ],
          child: EmployeeDetailsDialog(
            employee: employee,
            department: department,
            subordinatesCount: subordinatesCount > 0 ? subordinatesCount : null,
          ),
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => EmployeeDetailsDialog(
          employee: employee,
          department: department,
          subordinatesCount: subordinatesCount > 0 ? subordinatesCount : null,
        ),
      );
    }
  }

  void _showEmployeeActionsMenu(
    BuildContext context,
    Employee employee,
    int subordinatesCount,
  ) {
    FocusScope.of(context).unfocus();

    Department? department;
    if (widget.organizationData != null) {
      for (final dept in widget.organizationData!.departments) {
        if (dept.manager.id == employee.id ||
            dept.employees.any((e) => e.id == employee.id)) {
          department = dept;
          break;
        }
      }
    }

    bool isHR = false;
    hr.Employee? hrEmployee;
    try {
      final authCubit = context.read<AuthCubit>();
      isHR = authCubit.state.isHR;

      if (isHR) {
        final employeesCubit = context.read<EmployeesCubit>();
        try {
          hrEmployee = employeesCubit.state.employees.firstWhere(
            (e) => e.id == employee.id,
          );
        } catch (_) {}
      }
    } catch (_) {}

    // FIX: Capture cubits before async gap (showModalBottomSheet)
    final authCubit = context.read<AuthCubit>();
    final employeesCubit = context.read<EmployeesCubit>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: authCubit),
          BlocProvider.value(value: employeesCubit),
        ],
        child: SafeArea(
          top: false,
          child: EmployeeActionsMenu(
            employee: employee,
            department: department,
            subordinatesCount: subordinatesCount > 0 ? subordinatesCount : null,
            onViewAttendance: isHR && hrEmployee != null
                ? () {
                    Navigator.of(sheetContext).pop();
                    SchedulerBinding.instance.addPostFrameCallback((_) {
                      if (context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EmployeeAttendanceReportScreen(
                              employee: hrEmployee!,
                            ),
                          ),
                        );
                      }
                    });
                  }
                : null,
            onClose: () => Navigator.of(sheetContext).pop(),
          ),
        ),
      ),
    );
  }
}

class _NodeDetails {
  final Employee item;
  _NodeDetails(this.item);
}
