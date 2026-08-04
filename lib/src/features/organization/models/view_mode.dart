import 'package:flutter/material.dart';

/// View modes for organization chart
/// 
/// Defines the different ways to display the organization hierarchy:
/// - tree: Hierarchical tree/chart view
/// - list: Flat list view
/// - grid: Grid/card view
/// - department: Grouped by department view
enum OrganizationViewMode {
  tree, // Tree/Chart view
  list, // List view
  grid, // Grid view
  department, // Department-based view
}

extension OrganizationViewModeExtension on OrganizationViewMode {
  String get displayName {
    switch (this) {
      case OrganizationViewMode.tree:
        return 'شجرة';
      case OrganizationViewMode.list:
        return 'قائمة';
      case OrganizationViewMode.grid:
        return 'شبكة';
      case OrganizationViewMode.department:
        return 'أقسام';
    }
  }

  IconData get icon {
    switch (this) {
      case OrganizationViewMode.tree:
        return Icons.account_tree_rounded;
      case OrganizationViewMode.list:
        return Icons.list_rounded;
      case OrganizationViewMode.grid:
        return Icons.grid_view_rounded;
      case OrganizationViewMode.department:
        return Icons.business_rounded;
    }
  }
}

