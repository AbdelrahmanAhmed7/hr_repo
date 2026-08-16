import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/my_vote_model.dart';
import '../models/nominee_model.dart';
import '../models/winner_model.dart';

part 'employee_of_month_service.g.dart';

@RestApi()
abstract class EmployeeOfMonthService {
  factory EmployeeOfMonthService(Dio dio, {String baseUrl}) =
      _EmployeeOfMonthService;

  @GET('/api/employee-of-the-month/nominees')
  Future<List<NomineeModel>> getNominees();

  @GET('/api/employee-of-the-month/my-vote')
  Future<MyVoteModel> getMyVote(
    @Query('month') int month,
    @Query('year') int year,
  );

  @POST('/api/employee-of-the-month/vote')
  Future<void> vote(@Body() Map<String, dynamic> body);

  @GET('/api/employee-of-the-month/winners')
  Future<List<WinnerModel>> getWinners(
    @Query('month') int month,
    @Query('year') int year,
  );

  @POST('/api/employee-of-the-month/calculate-winners')
  Future<void> calculateWinners(
    @Query('month') int month,
    @Query('year') int year,
  );
}
