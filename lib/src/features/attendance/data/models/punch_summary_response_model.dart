import 'punch_summary_model.dart';

class PunchSummaryResponseModel {
  final List<PunchSummaryModel> items;
  final int pageNumber;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  const PunchSummaryResponseModel({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  factory PunchSummaryResponseModel.fromJson(Map<String, dynamic> json) {
    return PunchSummaryResponseModel(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => PunchSummaryModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      pageNumber: json['pageNumber'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 10,
      totalCount: json['totalCount'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 1,
    );
  }
}
