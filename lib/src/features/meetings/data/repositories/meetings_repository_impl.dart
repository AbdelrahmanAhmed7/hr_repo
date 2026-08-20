import '../datasources/meetings_service.dart';
import '../models/department_response_model.dart';
import '../models/meeting_response_model.dart';
import 'meetings_repository.dart';

class MeetingsRepositoryImpl implements MeetingsRepository {
  final MeetingsService _service;

  MeetingsRepositoryImpl(this._service);

  @override
  Future<MeetingResponseModel> getMeetings({
    required int pageNumber,
    required int pageSize,
  }) => _service.getMeetings(pageNumber, pageSize);

  @override
  Future<void> createMeeting({
    required String title,
    required String message,
    required String meetingDate,
    required String meetingTime,
    required List<int> departmentIds,
  }) => _service.createMeeting({
    'title': title,
    'message': message,
    'meetingDate': meetingDate,
    'meetingTime': meetingTime,
    'departmentIds': departmentIds,
  });

  @override
  Future<void> updateMeeting({
    required int id,
    required String title,
    required String message,
    required String meetingDate,
    required String meetingTime,
  }) => _service.updateMeeting(id, {
    'title': title,
    'message': message,
    'meetingDate': meetingDate,
    'meetingTime': meetingTime,
  });

  @override
  Future<void> deleteMeeting(int id) => _service.deleteMeeting(id);

  @override
  Future<DepartmentResponseModel> getDepartments({
    required int pageNumber,
    required int pageSize,
  }) => _service.getDepartments(pageNumber, pageSize);
}