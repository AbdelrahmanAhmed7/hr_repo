import '../../domain/repositories/employee_of_month_repository.dart';
import '../datasources/employee_of_month_service.dart';
import '../models/my_vote_model.dart';
import '../models/nominee_model.dart';
import '../models/winner_model.dart';

class EmployeeOfMonthRepositoryImpl implements EmployeeOfMonthRepository {
  final EmployeeOfMonthService _service;

  EmployeeOfMonthRepositoryImpl(this._service);

  @override
  Future<List<NomineeModel>> getNominees() => _service.getNominees();

  @override
  Future<MyVoteModel> getMyVote({required int month, required int year}) =>
      _service.getMyVote(month, year);

  @override
  Future<void> vote({
    required String nomineeUserId,
    required int month,
    required int year,
  }) => _service.vote({
    'nomineeUserId': nomineeUserId,
    'month': month,
    'year': year,
  });

  @override
  Future<List<WinnerModel>> getWinners({
    required int month,
    required int year,
  }) => _service.getWinners(month, year);

  @override
  Future<void> calculateWinners({required int month, required int year}) =>
      _service.calculateWinners(month, year);
}
