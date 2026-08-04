import 'package:equatable/equatable.dart';
import 'package:graphview/GraphView.dart';
import '../models/organization_models.dart';
import '../models/view_mode.dart';

class OrganizationChartState extends Equatable {
  final OrganizationData? organizationData;
  final List<Employee>? employees; // Flat list for graphview
  final Graph? graph;
  final GraphViewController? graphViewController;
  final Set<String> expandedNodeIds; // Track expanded nodes
  final bool isCompactMode;
  final bool isHorizontal;
  final Employee? selectedEmployee;
  final bool isLoading;
  final String? error;
  final String? searchQuery;
  final int? filteredDepartmentId;
  final EmployeeLevel? filteredLevel;
  final OrganizationViewMode viewMode;

  const OrganizationChartState({
    this.organizationData,
    this.employees,
    this.graph,
    this.graphViewController,
    this.expandedNodeIds = const {},
    this.isCompactMode = false,
    this.isHorizontal = false,
    this.selectedEmployee,
    this.isLoading = false,
    this.error,
    this.searchQuery,
    this.filteredDepartmentId,
    this.filteredLevel,
    this.viewMode = OrganizationViewMode.tree,
  });

  OrganizationChartState copyWith({
    OrganizationData? organizationData,
    List<Employee>? employees,
    Graph? graph,
    GraphViewController? graphViewController,
    Set<String>? expandedNodeIds,
    bool? isCompactMode,
    bool? isHorizontal,
    Employee? selectedEmployee,
    bool? isLoading,
    String? error,
    String? searchQuery,
    int? filteredDepartmentId,
    EmployeeLevel? filteredLevel,
    OrganizationViewMode? viewMode,
  }) {
    return OrganizationChartState(
      organizationData: organizationData ?? this.organizationData,
      employees: employees ?? this.employees,
      graph: graph ?? this.graph,
      graphViewController: graphViewController ?? this.graphViewController,
      expandedNodeIds: expandedNodeIds ?? this.expandedNodeIds,
      isCompactMode: isCompactMode ?? this.isCompactMode,
      isHorizontal: isHorizontal ?? this.isHorizontal,
      selectedEmployee: selectedEmployee ?? this.selectedEmployee,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      filteredDepartmentId: filteredDepartmentId ?? this.filteredDepartmentId,
      filteredLevel: filteredLevel ?? this.filteredLevel,
      viewMode: viewMode ?? this.viewMode,
    );
  }

  @override
  List<Object?> get props => [
        organizationData,
        employees,
        graph,
        graphViewController,
        expandedNodeIds,
        isCompactMode,
        isHorizontal,
        selectedEmployee,
        isLoading,
        error,
        searchQuery,
        filteredDepartmentId,
        filteredLevel,
        viewMode,
      ];
}

