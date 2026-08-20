import '../models/department_response_model.dart';
import '../models/meeting_response_model.dart';

abstract class MeetingsRepository {
  Future<MeetingResponseModel> getMeetings({
    required int pageNumber,
    required int pageSize,
  });

  Future<void> createMeeting({
    required String title,
    required String message,
    required String meetingDate,
    required String meetingTime,
    required List<int> departmentIds,
  });

  Future<void> updateMeeting({
    required int id,
    required String title,
    required String message,
    required String meetingDate,
    required String meetingTime,
  });

  Future<void> deleteMeeting(int id);

  Future<DepartmentResponseModel> getDepartments({
    required int pageNumber,
    required int pageSize,
  });
}