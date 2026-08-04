import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/attendance_record.dart';

part 'attendance_api.g.dart';

@RestApi()
abstract class AttendanceApi {
  factory AttendanceApi(Dio dio, {String baseUrl}) = _AttendanceApi;

  @POST('/api/Attendance/mobile/checkin')
  Future<AttendanceRecord> checkIn(@Body() Map<String, dynamic> body);

  @POST('/api/Attendance/mobile/checkout')
  Future<AttendanceRecord> checkOut(@Body() Map<String, dynamic> body);
  
  @GET('/api/Attendance/my/{date}')
  Future<AttendanceRecord?> getAttendanceByDate(@Path('date') String date);
  
}
