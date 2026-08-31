class PenaltyType {
  final int value;
  final String name;
  final String displayName;

  const PenaltyType({
    required this.value,
    required this.name,
    required this.displayName,
  });

  factory PenaltyType.fromJson(Map<String, dynamic> json) {
    return PenaltyType(
      value: (json['value'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
    );
  }
}
