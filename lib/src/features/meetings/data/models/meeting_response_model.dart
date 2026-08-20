import 'package:json_annotation/json_annotation.dart';

import 'meeting_model.dart';

part 'meeting_response_model.g.dart';

@JsonSerializable()
class MeetingResponseModel {
  final List<MeetingModel> items;
  final int pageNumber;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  const MeetingResponseModel({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  factory MeetingResponseModel.fromJson(Map<String, dynamic> json) =>
      _$MeetingResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$MeetingResponseModelToJson(this);
}