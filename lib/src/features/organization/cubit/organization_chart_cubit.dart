import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:graphview/GraphView.dart';
import '../../../core/services/organization_service.dart';
import '../models/organization_models.dart';
import '../models/view_mode.dart';
import '../services/preferences_service.dart';
import 'organization_chart_state.dart';

/// Cubit for managing organization chart state and operations
/// 
/// Handles:
/// - Loading organization data from API
/// - Managing view modes (tree, list, grid, department)
/// - Filtering (by department, level, search)
/// - Graph operations (expand/collapse nodes, zoom/pan)
/// - User preferences (cached locally)
class OrganizationChartCubit extends Cubit<OrganizationChartState> {
  OrganizationChartCubit() : super(const OrganizationChartState());

  @override
  Future<void> close() {
    // GraphViewController doesn't need explicit disposal
    return super.close();
  }

  /// Load organization data from API
  Future<void> loadOrganization(String? token) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final data = await OrganizationService.getOrganizationChart(
        token: token ?? '',
      );

      // Convert to flat list with managerId
      var employees = OrganizationData.convertToOrgChartList(data);

      // Pre-calculate subordinates count
      employees = _calculateSubordinatesCounts(employees);

      // Initialize with only root nodes expanded
      final expandedNodeIds = data.roots.map((root) => root.id).toSet();
      
      // Build Graph from employees (only roots expanded initially)
      final graph = _buildGraphFromEmployees(employees, expandedNodeIds);
      
      // Create GraphViewController for zoom/pan
      final graphViewController = GraphViewController();

      // Load saved preferences
      final savedViewMode = await OrganizationChartPreferencesService.getViewMode();
      final savedOrientation = await OrganizationChartPreferencesService.getOrientation();
      final savedCompactMode = await OrganizationChartPreferencesService.getCompactMode();

      emit(state.copyWith(
        organizationData: data,
        employees: employees,
        graph: graph,
        graphViewController: graphViewController,
        expandedNodeIds: expandedNodeIds,
        viewMode: savedViewMode ?? state.viewMode,
        isHorizontal: savedOrientation ?? state.isHorizontal,
        isCompactMode: savedCompactMode ?? state.isCompactMode,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  /// Build Graph from Employee list
  Graph _buildGraphFromEmployees(List<Employee> employees, Set<String> expandedNodeIds) {
    final graph = Graph();
    final nodeMap = <String, Node>{};
    
    // Create employee map for O(1) lookup instead of O(n) firstWhere
    final employeeMap = <String, Employee>{};
    for (final emp in employees) {
      employeeMap[emp.id] = emp;
    }
    
    // Helper function to check if a node should be visible
    // A node is visible if:
    // 1. It's a root node (no manager), OR
    // 2. All its ancestors are expanded
    bool isNodeVisible(String employeeId) {
      final employee = employeeMap[employeeId];
      if (employee == null) return false;
      
      // Root nodes (CEO) are always visible
      if (employee.managerId == null) {
        return true;
      }
      
      // Check if all ancestors are expanded
      String? currentManagerId = employee.managerId;
      while (currentManagerId != null) {
        if (!expandedNodeIds.contains(currentManagerId)) {
          return false;
        }
        final manager = employeeMap[currentManagerId];
        if (manager == null) return false;
        currentManagerId = manager.managerId;
      }
      
      return true;
    }

    // Only create nodes for visible employees
    for (final employee in employees) {
      if (isNodeVisible(employee.id)) {
        final node = Node.Id(employee.id);
        nodeMap[employee.id] = node;
        graph.addNode(node);
      }
    }

    // Connect nodes based on managerId relationships
    // Only add edges if parent node is expanded and both nodes are visible
    for (final employee in employees) {
      if (employee.managerId != null && 
          nodeMap.containsKey(employee.managerId) &&
          nodeMap.containsKey(employee.id)) {
        // Only add edge if the parent node is expanded
        if (expandedNodeIds.contains(employee.managerId)) {
          final childNode = nodeMap[employee.id]!;
          final parentNode = nodeMap[employee.managerId]!;
          graph.addEdge(parentNode, childNode);
        }
      }
    }

    return graph;
  }

  /// Select an employee
  void selectEmployee(String employeeId) {
    if (state.employees == null) return;

    final employee = state.employees!.firstWhere(
      (emp) => emp.id == employeeId,
      orElse: () => throw StateError('Employee not found'),
    );

    emit(state.copyWith(selectedEmployee: employee));
  }

  /// Clear selection
  void clearSelection() {
    emit(state.copyWith(selectedEmployee: null));
  }

  /// Search employees by name
  /// 
  /// Filters employees by matching the search query against their username.
  /// Uses highlighting to show matching employees in the chart.
  void searchEmployees(String query) {
    emit(state.copyWith(searchQuery: query.isEmpty ? null : query));
    _updateGraphItems();
  }

  /// Filter employees by department
  /// 
  /// When a department is selected, shows only:
  /// - The department manager
  /// - All employees in that department
  void filterByDepartment(int? departmentId) {
    emit(state.copyWith(filteredDepartmentId: departmentId));
    _updateGraphItems();
  }

  /// Filter employees by level (CEO, Manager, Employee)
  /// 
  /// Shows only employees matching the selected level.
  void filterByLevel(EmployeeLevel? level) {
    emit(state.copyWith(filteredLevel: level));
    _updateGraphItems();
  }

  /// Clear all active filters (department and level)
  void clearFilter() {
    emit(state.copyWith(
      filteredDepartmentId: null,
      filteredLevel: null,
    ));
    _updateGraphItems();
  }

  /// Update graph based on current filters
  void _updateGraphItems() {
    if (state.organizationData == null) return;

    final allEmployees = OrganizationData.convertToOrgChartList(state.organizationData!);
    var filtered = allEmployees;

    // Apply level filter
    if (state.filteredLevel != null) {
      filtered = filtered.where((emp) => emp.level == state.filteredLevel).toList();
    }

    // Apply search filter (Highlighting)
    if (state.searchQuery != null && state.searchQuery!.isNotEmpty) {
      final query = state.searchQuery!.toLowerCase();
      filtered = filtered.map((emp) {
        final matches = emp.username.toLowerCase().contains(query);
        return emp.copyWith(isHighlighted: matches);
      }).toList();
    } else {
      // Reset highlighting
      filtered = filtered.map((emp) {
        return emp.copyWith(isHighlighted: false);
      }).toList();
    }

    // Recalculate subordinates counts for filtered employees
    filtered = _calculateSubordinatesCounts(filtered);

    // Build new graph with filtered employees and current expanded nodes
    final newGraph = _buildGraphFromEmployees(filtered, state.expandedNodeIds);

    emit(state.copyWith(
      graph: newGraph,
      employees: filtered,
    ));
  }

  /// Calculate subordinates count for each employee recursively
  /// 
  /// Uses memoization to cache counts and improve performance.
  /// Returns employees with updated subordinatesCount field.
  List<Employee> _calculateSubordinatesCounts(List<Employee> allEmployees) {
    // Create a map for quick lookup of direct subordinates
    final subordinatesMap = <String, List<String>>{};
    for (final emp in allEmployees) {
      if (emp.managerId != null) {
        if (!subordinatesMap.containsKey(emp.managerId!)) {
          subordinatesMap[emp.managerId!] = [];
        }
        subordinatesMap[emp.managerId!]!.add(emp.id);
      }
    }

    // Memoization cache for counts
    final countCache = <String, int>{};

    // Helper to get count recursively with memoization
    int getCount(String empId) {
      // Check cache first
      if (countCache.containsKey(empId)) {
        return countCache[empId]!;
      }

      int count = 0;
      final directSubs = subordinatesMap[empId];
      if (directSubs != null) {
        count += directSubs.length;
        for (final subId in directSubs) {
          count += getCount(subId);
        }
      }
      
      // Cache the result
      countCache[empId] = count;
      return count;
    }

    // Return mapped employees with updated counts
    return allEmployees.map((emp) {
      return emp.copyWith(
        subordinatesCount: getCount(emp.id),
      );
    }).toList();
  }

  /// Toggle node expansion (expand/collapse a specific node)
  void toggleNodeExpansion(String nodeId) {
    final newExpandedNodeIds = Set<String>.from(state.expandedNodeIds);
    if (newExpandedNodeIds.contains(nodeId)) {
      newExpandedNodeIds.remove(nodeId);
    } else {
      newExpandedNodeIds.add(nodeId);
    }
    
    // Rebuild graph with new expansion state
    if (state.employees != null) {
      final newGraph = _buildGraphFromEmployees(state.employees!, newExpandedNodeIds);
      emit(state.copyWith(
        expandedNodeIds: newExpandedNodeIds,
        graph: newGraph,
      ));
    } else {
      emit(state.copyWith(expandedNodeIds: newExpandedNodeIds));
    }
  }

  /// Expand all nodes
  void expandAll() {
    if (state.employees == null) return;
    
    final allNodeIds = state.employees!.map((e) => e.id).toSet();
    
    // Also reset filters
    if (state.organizationData != null) {
      final allEmployees = OrganizationData.convertToOrgChartList(state.organizationData!);
      final newGraph = _buildGraphFromEmployees(allEmployees, allNodeIds);
      
      emit(state.copyWith(
        graph: newGraph,
        employees: allEmployees,
        expandedNodeIds: allNodeIds,
        filteredDepartmentId: null,
        filteredLevel: null,
        searchQuery: null,
      ));
    } else {
      emit(state.copyWith(expandedNodeIds: allNodeIds));
    }
  }

  /// Collapse all nodes (keep only root nodes)
  void collapseAll() {
    if (state.employees == null) return;
    
    // Find root nodes (nodes with no manager)
    final rootNodeIds = state.employees!
        .where((emp) => emp.managerId == null)
        .map((e) => e.id)
        .toSet();
    
    emit(state.copyWith(expandedNodeIds: rootNodeIds));
  }

  /// Toggle orientation (horizontal/vertical)
  void toggleOrientation() {
    final newOrientation = !state.isHorizontal;
    emit(state.copyWith(isHorizontal: newOrientation));
    OrganizationChartPreferencesService.saveOrientation(newOrientation);
  }

  /// Toggle compact mode
  void toggleCompactMode() {
    final newCompactMode = !state.isCompactMode;
    emit(state.copyWith(isCompactMode: newCompactMode));
    OrganizationChartPreferencesService.saveCompactMode(newCompactMode);
  }

  /// Change view mode
  void changeViewMode(OrganizationViewMode viewMode) {
    emit(state.copyWith(viewMode: viewMode));
    OrganizationChartPreferencesService.saveViewMode(viewMode);
  }

  /// Reset zoom/pan to fit all nodes
  void resetZoom() {
    if (state.graphViewController != null) {
      final newController = GraphViewController();
      emit(state.copyWith(graphViewController: newController));
    }
  }
}
