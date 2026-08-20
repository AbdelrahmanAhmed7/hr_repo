import 'package:mediconsult_internal/src/features/home/models/recent_activity.dart';

import 'management_request.dart';
import 'management_requests_data_source.dart';

/// Aggregates the management `/all` request endpoints into a single
/// consistently-typed list of [RecentActivity] with employee names.
class ManagementRequestsRepository {
  final ManagementRequestsDataSource _dataSource;

  ManagementRequestsRepository(this._dataSource);

  Future<List<RecentActivity>> getAllRequests({int? month}) async {
    final results = await Future.wait([
      _safely(_dataSource.fetchLeaves),
      _safely(_dataSource.fetchPermissions),
      _safely(_dataSource.fetchAssignments),
    ]);

    final all = <RecentActivity>[
      for (final requests in results)
        for (final request in requests) request.toRecentActivity(),
    ];

    final filtered = month == null
        ? all
        : all.where((item) => item.date.month == month).toList();

    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  /// A single endpoint failing shouldn't take the whole screen down.
  static Future<List<ManagementRequest>> _safely(
    Future<List<ManagementRequest>> Function() fetch,
  ) async {
    try {
      return await fetch();
    } catch (_) {
      return const <ManagementRequest>[];
    }
  }
}