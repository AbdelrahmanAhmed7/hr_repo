import '../api/home_api.dart';
import '../models/home_api_response.dart';

class HomeApiService {
  final HomeApi _api;

  HomeApiService(this._api);

  Future<HomeApiResponse> getHomeData() async {
    return await _api.getHomeData();
  }

  Future<List<HomeRequestItem>> getAllRequests({int? month}) async {
    return await _api.getAllRequests(month: month);
  }

  Future<List<HomeRequestItem>> getPendingRequests({int? month}) async {
    return await _api.getPendingRequests(month: month);
  }

  Future<List<HomeRequestItem>> getAcceptedRequests({int? month}) async {
    return await _api.getAcceptedRequests(month: month);
  }

  Future<List<HomeRequestItem>> getRejectedRequests({int? month}) async {
    return await _api.getRejectedRequests(month: month);
  }

  // Personal requests (current user only)
  Future<List<HomeRequestItem>> getMyLeaves() async {
    return await _api.getMyLeaves();
  }

  Future<List<HomeRequestItem>> getMyPermissions() async {
    return await _api.getMyPermissions();
  }

  Future<List<HomeRequestItem>> getMyAssignments() async {
    return await _api.getMyAssignments();
  }

  Future<List<HomeRequestItem>> getMyOvertime() async {
    return await _api.getMyOvertime();
  }
}
