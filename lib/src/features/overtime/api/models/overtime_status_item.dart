import 'package:json_annotation/json_annotation.dart';

part 'overtime_status_item.g.dart';

@JsonSerializable()
class OvertimeStatusItem {
  final int id;
  final String value;

  OvertimeStatusItem({
    required this.id,
    required this.value,
  });

  factory OvertimeStatusItem.fromJson(Map<String, dynamic> json) =>
      _$OvertimeStatusItemFromJson(json);

  Map<String, dynamic> toJson() => _$OvertimeStatusItemToJson(this);
}
