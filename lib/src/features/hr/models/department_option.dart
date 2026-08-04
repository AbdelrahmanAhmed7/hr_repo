class DepartmentOption {
  final int id;
  final String name;

  const DepartmentOption({required this.id, required this.name});

  factory DepartmentOption.fromJson(Map<String, dynamic> json) {
    return DepartmentOption(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}
