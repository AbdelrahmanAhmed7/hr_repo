import '../models/payslip.dart';
import '../services/payslip_service.dart';

class PayslipRepository {
  final PayslipService _service;

  PayslipRepository(this._service);

  Future<Payslip> getMyPayslip({
    required int month,
    required int year,
  }) {
    return _service.getMyPayslip(month: month, year: year);
  }

  Future<List<int>> downloadPayslipPdf({
    required int month,
    required int year,
  }) {
    return _service.downloadPayslipPdf(month: month, year: year);
  }
}
