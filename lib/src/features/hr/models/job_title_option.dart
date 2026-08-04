class JobTitleOption {
  final int id;
  final String name;
  final String? nameAr;

  const JobTitleOption({
    required this.id,
    required this.name,
    this.nameAr,
  });

  factory JobTitleOption.fromJson(Map<String, dynamic> json) {
    return JobTitleOption(
      id: json['id'] as int,
      name: json['name'] as String,
      nameAr: json['nameAr'] as String?,
    );
  }

  String get displayName => nameAr?.trim().isNotEmpty == true ? nameAr! : name;
}
