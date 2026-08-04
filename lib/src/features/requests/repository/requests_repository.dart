import '../../home/models/home_api_response.dart';
import '../../home/repository/home_repository.dart';

class RequestsRepository {
  final HomeRepository _homeRepository;

  RequestsRepository(this._homeRepository);

  /// Get all user requests (all employees - for management)
  Future<List<HomeRequestItem>> getAllRequests({int? month}) async {
    return await _homeRepository.getAllRequests(month: month);
  }

  Future<List<HomeRequestItem>> getPendingRequests({int? month}) async {
    return await _homeRepository.getPendingRequests(month: month);
  }

  Future<List<HomeRequestItem>> getAcceptedRequests({int? month}) async {
    return await _homeRepository.getAcceptedRequests(month: month);
  }

  Future<List<HomeRequestItem>> getRejectedRequests({int? month}) async {
    return await _homeRepository.getRejectedRequests(month: month);
  }

  /// Get MY personal requests (current user only)
  Future<List<HomeRequestItem>> getMyAllRequests() async {
    try {
      final results = await Future.wait([
        getMyLeaves(),
        getMyPermissions(),
        getMyAssignments(),
        getMyOvertime(),
      ]);

      // Add type to each item based on which endpoint it came from
      final leaves = results[0].map((item) => _withType(item, 'leave')).toList();
      final permissions = results[1].map((item) => _withType(item, 'permission')).toList();
      final assignments = results[2].map((item) => _withType(item, 'assignment')).toList();
      final overtime = results[3].map((item) => _withType(item, 'overtime')).toList();

      final all = [
        ...leaves,
        ...permissions,
        ...assignments,
        ...overtime,
      ];

      // Sort by createdAt (descending)
      all.sort((a, b) {
        final aDate = DateTime.tryParse(a.createdAt) ?? DateTime(1970);
        final bDate = DateTime.tryParse(b.createdAt) ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });

      return all;
    } catch (e) {
      // Return empty list on error
      return [];
    }
  }

  /// Get my leaves
  Future<List<HomeRequestItem>> getMyLeaves() async {
    return await _homeRepository.getMyLeaves();
  }

  /// Get my permissions
  Future<List<HomeRequestItem>> getMyPermissions() async {
    return await _homeRepository.getMyPermissions();
  }

  /// Get my assignments
  Future<List<HomeRequestItem>> getMyAssignments() async {
    return await _homeRepository.getMyAssignments();
  }

  /// Get my overtime
  Future<List<HomeRequestItem>> getMyOvertime() async {
    return await _homeRepository.getMyOvertime();
  }

  /// Create a copy of the item with the correct type set
  HomeRequestItem _withType(HomeRequestItem item, String type) {
    return HomeRequestItem(
      id: item.id,
      type: type,
      createdAt: item.createdAt,
      status: item.status,
      userId: item.userId,
      date: item.date,
      startDate: item.startDate,
      endDate: item.endDate,
      startTime: item.startTime,
      endTime: item.endTime,
      where: item.where,
      reason: item.reason,
    );
  }
}
