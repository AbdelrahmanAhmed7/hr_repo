class AdminInfo {
  final String name;
  final String department;
  final String position;
  final String? profileImageUrl;
  final int notificationCount;

  AdminInfo({
    required this.name,
    this.department = '',
    this.position = 'مدير قسم',
    this.profileImageUrl,
    this.notificationCount = 0,
  });

  AdminInfo copyWith({
    String? name,
    String? department,
    String? position,
    String? profileImageUrl,
    int? notificationCount,
  }) {
    return AdminInfo(
      name: name ?? this.name,
      department: department ?? this.department,
      position: position ?? this.position,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      notificationCount: notificationCount ?? this.notificationCount,
    );
  }


}

