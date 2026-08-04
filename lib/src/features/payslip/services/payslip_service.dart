import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../models/payslip.dart';

class PayslipService {
  final DioClient _dioClient;

  PayslipService(this._dioClient);

  Future<Payslip> getMyPayslip({
    required int month,
    required int year,
  }) async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>(
        '/api/Payslip/my',
        queryParameters: {
          'month': month,
          'year': year,
        },
      );

      final data = response.data;
      if (data == null) {
        throw Exception('لم يتم العثور على بيان مرتب لهذه الفترة.');
      }

      return Payslip.fromJson(data);
    } on DioException catch (error) {
      throw Exception(_extractMessage(error));
    }
  }

  Future<List<int>> downloadPayslipPdf({
    required int month,
    required int year,
  }) async {
    try {
      final response = await _dioClient.dio.get<List<int>>(
        '/api/Payslip/my/pdf',
        queryParameters: {
          'month': month,
          'year': year,
        },
        options: Options(
          responseType: ResponseType.bytes,
          headers: const {
            'Accept': '*/*',
          },
        ),
      );

      return response.data ?? const [];
    } on DioException catch (error) {
      throw Exception(_extractMessage(error));
    }
  }

  String _extractMessage(DioException error) {
    final data = error.response?.data;

    if (data is Map<String, dynamic>) {
      final message = data['message']?.toString();
      if (message != null && message.trim().isNotEmpty) {
        return message;
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return data;
    }

    return 'تعذر تحميل بيان المرتب حاليًا.';
  }
}
