import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/department_model.dart';
import '../../data/repositories/meetings_repository.dart';
import 'meetings_state.dart';

class MeetingsCubit extends Cubit<MeetingsState> {
  final MeetingsRepository _repository;

  MeetingsCubit(this._repository) : super(MeetingsState.initial());

  Future<void> loadMeetings({bool refresh = false}) async {
    if (isClosed) return;

    if (refresh) {
      emit(state.copyWith(
        loadStatus: MeetingsLoadStatus.loading,
        clearError: true,
      ));
    }

    final page = refresh ? 1 : state.currentPage;

    try {
      final response = await _repository.getMeetings(
        pageNumber: page,
        pageSize: 20,
      );
      if (isClosed) return;

      emit(state.copyWith(
        loadStatus: MeetingsLoadStatus.success,
        meetings: refresh
            ? response.items
            : [...state.meetings, ...response.items],
        currentPage: response.pageNumber + 1,
        totalPages: response.totalPages,
        clearError: true,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        loadStatus: MeetingsLoadStatus.failure,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> loadMoreMeetings() async {
    if (isClosed) return;
    if (state.isLoadingMore) return;
    if (state.currentPage > state.totalPages) return;

    emit(state.copyWith(isLoadingMore: true));
    await loadMeetings();
    if (isClosed) return;
    emit(state.copyWith(isLoadingMore: false));
  }

  Future<void> loadDepartments() async {
    if (isClosed) return;
    emit(state.copyWith(departmentsStatus: DepartmentsStatus.loading));

    try {
      final response = await _repository.getDepartments(
        pageNumber: 1,
        pageSize: 100,
      );
      if (isClosed) return;

      final departments = <DepartmentModel>[];
      final seen = <int>{};
      for (final department in response.items) {
        if (seen.add(department.id)) departments.add(department);
      }

      emit(state.copyWith(
        departmentsStatus: DepartmentsStatus.success,
        departments: departments,
      ));
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(departmentsStatus: DepartmentsStatus.failure));
    }
  }

  Future<bool> createMeeting({
    required String title,
    required String message,
    required DateTime meetingDate,
    required TimeOfDay meetingTime,
    required List<int> departmentIds,
  }) async {
    if (isClosed) return false;

    emit(state.copyWith(
      actionStatus: MeetingsActionStatus.submitting,
      clearActionError: true,
    ));

    try {
      await _repository.createMeeting(
        title: title,
        message: message,
        meetingDate: _formatDate(meetingDate),
        meetingTime: _formatTime(meetingTime),
        departmentIds: departmentIds,
      );
      if (isClosed) return false;

      emit(state.copyWith(actionStatus: MeetingsActionStatus.success));
      await loadMeetings(refresh: true);
      if (isClosed) return false;

      emit(state.copyWith(
        actionStatus: MeetingsActionStatus.idle,
        clearActionError: true,
      ));
      return true;
    } catch (e) {
      if (isClosed) return false;
      emit(state.copyWith(
        actionStatus: MeetingsActionStatus.failure,
        actionErrorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
      return false;
    }
  }

  Future<bool> updateMeeting({
    required int id,
    required String title,
    required String message,
    required DateTime meetingDate,
    required TimeOfDay meetingTime,
  }) async {
    if (isClosed) return false;

    emit(state.copyWith(
      actionStatus: MeetingsActionStatus.submitting,
      clearActionError: true,
    ));

    try {
      await _repository.updateMeeting(
        id: id,
        title: title,
        message: message,
        meetingDate: _formatDate(meetingDate),
        meetingTime: _formatTime(meetingTime),
      );
      if (isClosed) return false;

      emit(state.copyWith(actionStatus: MeetingsActionStatus.success));
      await loadMeetings(refresh: true);
      if (isClosed) return false;

      emit(state.copyWith(
        actionStatus: MeetingsActionStatus.idle,
        clearActionError: true,
      ));
      return true;
    } catch (e) {
      if (isClosed) return false;
      emit(state.copyWith(
        actionStatus: MeetingsActionStatus.failure,
        actionErrorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
      return false;
    }
  }

  Future<bool> deleteMeeting(int id) async {
    if (isClosed) return false;

    emit(state.copyWith(
      actionStatus: MeetingsActionStatus.submitting,
      clearActionError: true,
    ));

    try {
      await _repository.deleteMeeting(id);
      if (isClosed) return false;

      emit(state.copyWith(actionStatus: MeetingsActionStatus.success));
      await loadMeetings(refresh: true);
      if (isClosed) return false;

      emit(state.copyWith(
        actionStatus: MeetingsActionStatus.idle,
        clearActionError: true,
      ));
      return true;
    } catch (e) {
      if (isClosed) return false;
      emit(state.copyWith(
        actionStatus: MeetingsActionStatus.failure,
        actionErrorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
      return false;
    }
  }

  void resetActionStatus() {
    if (isClosed) return;
    emit(state.copyWith(
      actionStatus: MeetingsActionStatus.idle,
      clearActionError: true,
    ));
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}