import 'punch_pair_model.dart';

class PunchPairResponseModel {
  final List<PunchPairModel> items;
  final int pageNumber;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  const PunchPairResponseModel({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  factory PunchPairResponseModel.fromJson(Map<String, dynamic> json) {
    return PunchPairResponseModel(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => PunchPairModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      pageNumber: json['pageNumber'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 10,
      totalCount: json['totalCount'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 1,
    );
  }
}
