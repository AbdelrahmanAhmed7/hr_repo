import 'package:dio/dio.dart';

import '../../features/organization/models/organization_models.dart';
import '../network/dio_client.dart';
import 'service_locator.dart';

class OrganizationService {
  /// Fetch organization chart data from API
  static Future<OrganizationData> getOrganizationChart({
    required String token,
  }) async {
    try {
      final response = await getIt<DioClient>().dio.get(
        '/api/Auth/organization-chart',
        options: Options(
          headers: token.trim().isEmpty
              ? null
              : {
                  'Authorization': 'Bearer $token',
                },
        ),
      );

      final jsonData = response.data;
      if (jsonData is! Map<String, dynamic>) {
        throw Exception('صيغة بيانات الهيكل التنظيمي غير صحيحة');
      }

      return OrganizationData.fromJson(jsonData);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('انتهت الجلسة أو بيانات الدخول غير صالحة');
      }

      if (e.response?.statusCode == 403) {
        throw Exception('غير مصرح لك بعرض الهيكل التنظيمي');
      }

      if (e.response?.statusCode == 404) {
        throw Exception('بيانات الهيكل التنظيمي غير متوفرة');
      }

      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final title = data['title']?.toString();
        if (title != null && title.trim().isNotEmpty) {
          throw Exception(title);
        }
      }

      throw Exception('تعذر تحميل الهيكل التنظيمي حاليا');
    }
  }
}
