import 'package:equatable/equatable.dart';

/// Employee level in the organization hierarchy
enum EmployeeLevel {
  ceo,
  manager,
  employee;

  static EmployeeLevel fromString(String level) {
    switch (level.toLowerCase()) {
      case 'superadmin':
      case 'ceo':
        return EmployeeLevel.ceo;
      case 'admin':
      case 'manager':
        return EmployeeLevel.manager;
      case 'user':
      case 'employee':
      default:
        return EmployeeLevel.employee;
    }
  }

  String get displayName {
    switch (this) {
      case EmployeeLevel.ceo:
        return 'CEO';
      case EmployeeLevel.manager:
        return 'مدير';
      case EmployeeLevel.employee:
        return 'موظف';
    }
  }
}

/// Department model for backward compatibility
class Department extends Equatable {
  final int id;
  final String name;
  final Employee manager;
  final List<Employee> employees;

  const Department({
    required this.id,
    required this.name,
    required this.manager,
    required this.employees,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    final managerJson = json['manager'] as Map<String, dynamic>?;
    final employeesJson = json['employees'] as List<dynamic>?;
    final placeholderEmployee = Employee(
      id: '',
      username: 'Unknown',
      level: EmployeeLevel.employee,
    );

    return Department(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unknown Department',
      manager: managerJson != null ? Employee.fromJson(managerJson) : placeholderEmployee,
      employees: employeesJson != null
          ? employeesJson
              .whereType<Map<String, dynamic>>()
              .map((e) => Employee.fromJson(e))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'manager': manager.toJson(),
      'employees': employees.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [id, name, manager, employees];
}

/// Employee model for organization chart
class Employee extends Equatable {
  final String id;
  final String username;
  final String? firstNameAr;
  final String? lastNameAr;
  final String? firstNameEn;
  final String? lastNameEn;
  final String? imageUrl;
  final String? jobTitle;
  final String? role;
  final String? employeeCode;
  final bool isActive;
  final bool isPending;
  final EmployeeLevel level;
  final String? managerId;
  final List<Employee> subordinates;
  final int subordinatesCount;
  final bool isHighlighted;

  const Employee({
    required this.id,
    required this.username,
    this.firstNameAr,
    this.lastNameAr,
    this.firstNameEn,
    this.lastNameEn,
    this.imageUrl,
    this.jobTitle,
    this.role,
    this.employeeCode,
    this.isActive = true,
    this.isPending = false,
    this.level = EmployeeLevel.employee,
    this.managerId,
    this.subordinates = const [],
    this.subordinatesCount = 0,
    this.isHighlighted = false,
  });

  static String _composeUsername(Map<String, dynamic> json) {
    // Try Arabic name first
    final arabicParts = [
      json['firstNameAr'] as String?,
      json['middleNameAr'] as String?,
      json['lastNameAr'] as String?,
    ].whereType<String>().map((p) => p.trim()).where((p) => p.isNotEmpty);
    if (arabicParts.isNotEmpty) {
      return arabicParts.join(' ');
    }
    // Try English name
    final englishParts = [
      json['firstNameEn'] as String?,
      json['middleNameEn'] as String?,
      json['lastNameEn'] as String?,
    ].whereType<String>().map((p) => p.trim()).where((p) => p.isNotEmpty);
    if (englishParts.isNotEmpty) {
      return englishParts.join(' ');
    }
    // Fallback
    return 'Unknown';
  }

  factory Employee.fromJson(Map<String, dynamic> json, {String? managerId}) {
    final username = _composeUsername(json);
    final role = json['role'] as String? ?? 'User';

    // Recursively parse subordinates
    final List<dynamic>? subordinatesJson = json['subordinates'] as List?;
    final parsedSubordinates = subordinatesJson != null
        ? subordinatesJson
            .whereType<Map<String, dynamic>>()
            .map((subJson) => Employee.fromJson(subJson, managerId: json['id'] as String?))
            .toList()
        : <Employee>[];

    // Extract and clean image URL
    String? rawImageUrl = json['imageUrl'] as String?;
    String? cleanedImageUrl;
    if (rawImageUrl != null) {
      cleanedImageUrl = rawImageUrl.replaceAll('`', '').trim();
      if (cleanedImageUrl.isEmpty) cleanedImageUrl = null;
    }

    return Employee(
      id: json['id'] as String? ?? '',
      username: username,
      firstNameAr: json['firstNameAr'] as String?,
      lastNameAr: json['lastNameAr'] as String?,
      firstNameEn: json['firstNameEn'] as String?,
      lastNameEn: json['lastNameEn'] as String?,
      imageUrl: cleanedImageUrl,
      jobTitle: json['jobTitle'] as String?,
      role: role,
      employeeCode: json['employeeCode'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      isPending: json['isPending'] as bool? ?? false,
      level: EmployeeLevel.fromString(role),
      managerId: managerId,
      subordinates: parsedSubordinates,
      subordinatesCount: parsedSubordinates.length,
      isHighlighted: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstNameAr': firstNameAr,
      'lastNameAr': lastNameAr,
      'firstNameEn': firstNameEn,
      'lastNameEn': lastNameEn,
      'imageUrl': imageUrl,
      'jobTitle': jobTitle,
      'role': role,
      'employeeCode': employeeCode,
      'isActive': isActive,
      'isPending': isPending,
      'managerId': managerId,
      'subordinates': subordinates.map((e) => e.toJson()).toList(),
    };
  }

  Employee copyWith({
    String? id,
    String? username,
    String? firstNameAr,
    String? lastNameAr,
    String? firstNameEn,
    String? lastNameEn,
    String? imageUrl,
    String? jobTitle,
    String? role,
    String? employeeCode,
    bool? isActive,
    bool? isPending,
    EmployeeLevel? level,
    String? managerId,
    List<Employee>? subordinates,
    int? subordinatesCount,
    bool? isHighlighted,
  }) {
    return Employee(
      id: id ?? this.id,
      username: username ?? this.username,
      firstNameAr: firstNameAr ?? this.firstNameAr,
      lastNameAr: lastNameAr ?? this.lastNameAr,
      firstNameEn: firstNameEn ?? this.firstNameEn,
      lastNameEn: lastNameEn ?? this.lastNameEn,
      imageUrl: imageUrl ?? this.imageUrl,
      jobTitle: jobTitle ?? this.jobTitle,
      role: role ?? this.role,
      employeeCode: employeeCode ?? this.employeeCode,
      isActive: isActive ?? this.isActive,
      isPending: isPending ?? this.isPending,
      level: level ?? this.level,
      managerId: managerId ?? this.managerId,
      subordinates: subordinates ?? this.subordinates,
      subordinatesCount: subordinatesCount ?? this.subordinatesCount,
      isHighlighted: isHighlighted ?? this.isHighlighted,
    );
  }

  String get initials {
    if (username.isEmpty) return '?';
    final parts = username.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0].toUpperCase()}${parts[1][0].toUpperCase()}';
    }
    return username[0].toUpperCase();
  }

  @override
  List<Object?> get props => [
        id,
        username,
        imageUrl,
        level,
        managerId,
        subordinatesCount,
        isHighlighted,
      ];
}

/// Root organization data structure - matches API response
class OrganizationData extends Equatable {
  final List<Employee> roots;

  const OrganizationData({
    required this.roots,
  });

  /// Backward-compatible CEO getter
  Employee get ceo {
    return roots.isNotEmpty
        ? roots.first
        : Employee(id: '', username: 'CEO', level: EmployeeLevel.ceo);
  }

  /// Backward-compatible departments getter (empty for now)
  List<Department> get departments => [];

  factory OrganizationData.fromJson(Map<String, dynamic> json) {
    final rootsJson = json['roots'] as List<dynamic>? ?? [];
    final parsedRoots = rootsJson
        .whereType<Map<String, dynamic>>()
        .map((rootJson) => Employee.fromJson(rootJson))
        .toList();

    return OrganizationData(roots: parsedRoots);
  }

  Map<String, dynamic> toJson() {
    return {
      'roots': roots.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [roots];

  /// Convert OrganizationData to flat list of Employees with managerId
  static List<Employee> convertToOrgChartList(OrganizationData data) {
    final List<Employee> employees = [];

    void addEmployee(Employee emp) {
      employees.add(emp);
      for (final sub in emp.subordinates) {
        addEmployee(sub);
      }
    }

    for (final root in data.roots) {
      addEmployee(root);
    }

    return employees;
  }

  /// Get total employee count (including all levels)
  int get totalEmployees {
    int count = 0;
    void addCount(Employee emp) {
      count++;
      for (final sub in emp.subordinates) {
        addCount(sub);
      }
    }
    for (final root in roots) {
      addCount(root);
    }
    return count;
  }
}

class EmployeeNode extends Equatable {
  final Employee employee;
  final List<EmployeeNode> subordinates;
  final bool isExpanded;
  final int level;

  const EmployeeNode({
    required this.employee,
    required this.subordinates,
    this.isExpanded = true,
    required this.level,
  });

  EmployeeNode copyWith({
    Employee? employee,
    List<EmployeeNode>? subordinates,
    bool? isExpanded,
    int? level,
  }) {
    return EmployeeNode(
      employee: employee ?? this.employee,
      subordinates: subordinates ?? this.subordinates,
      isExpanded: isExpanded ?? this.isExpanded,
      level: level ?? this.level,
    );
  }

  /// Build hierarchy tree from OrganizationData
  static List<EmployeeNode> buildHierarchyFromData(OrganizationData data) {
    return data.roots
        .map((root) => _buildNode(root, level: 0))
        .toList();
  }

  static EmployeeNode _buildNode(Employee emp, {required int level}) {
    final subNodes = emp.subordinates
        .map((sub) => _buildNode(sub, level: level + 1))
        .toList();
    return EmployeeNode(
      employee: emp,
      subordinates: subNodes,
      isExpanded: true,
      level: level,
    );
  }

  /// Build hierarchy tree with a single root for compatibility
  static EmployeeNode buildSingleRootHierarchy(OrganizationData data) {
    if (data.roots.isEmpty) {
      return EmployeeNode(
        employee: Employee(id: '', username: 'CEO', level: EmployeeLevel.ceo),
        subordinates: [],
        isExpanded: true,
        level: 0,
      );
    }
    // Take first root as main root
    final root = data.roots.first;
    final subNodes = root.subordinates
        .map((sub) => _buildNode(sub, level: 1))
        .toList();
    return EmployeeNode(
      employee: root,
      subordinates: subNodes,
      isExpanded: true,
      level: 0,
    );
  }

  /// Get all visible nodes (respecting expanded state)
  List<EmployeeNode> getVisibleNodes() {
    final List<EmployeeNode> visible = [this];
    if (isExpanded) {
      for (final subordinate in subordinates) {
        visible.addAll(subordinate.getVisibleNodes());
      }
    }
    return visible;
  }

  /// Find node by employee ID
  EmployeeNode? findNodeById(String employeeId) {
    if (employee.id == employeeId) return this;
    for (final subordinate in subordinates) {
      final found = subordinate.findNodeById(employeeId);
      if (found != null) return found;
    }
    return null;
  }

  /// Get all subordinates count recursively
  int getTotalSubordinatesCount() {
    int count = subordinates.length;
    for (final subordinate in subordinates) {
      count += subordinate.getTotalSubordinatesCount();
    }
    return count;
  }

  @override
  List<Object?> get props => [employee, subordinates, isExpanded, level];
}

