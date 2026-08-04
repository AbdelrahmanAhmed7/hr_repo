import '../api/hr_home_api.dart';
import '../models/hr_home_response.dart';

class HrHomeService {
  final HrHomeApi _api;

  HrHomeService(this._api);

  Future<HrHomeResponse> getHrHomeData() async {
    return await _api.getHrHomeData();
  }
}
