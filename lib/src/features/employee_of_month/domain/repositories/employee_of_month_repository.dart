import '../../data/models/my_vote_model.dart';
import '../../data/models/nominee_model.dart';
import '../../data/models/winner_model.dart';

abstract class EmployeeOfMonthRepository {
  Future<List<NomineeModel>> getNominees();

  Future<MyVoteModel> getMyVote({required int month, required int year});

  Future<void> vote({
    required String nomineeUserId,
    required int month,
    required int year,
  });

  Future<List<WinnerModel>> getWinners({required int month, required int year});

  Future<void> calculateWinners({required int month, required int year});
}
