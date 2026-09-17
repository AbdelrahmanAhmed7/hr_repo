import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/app_exception.dart';
import '../models/task_interactions.dart';
import '../repository/tasks_repository.dart';
import 'task_details_state.dart';

/// Task details cubit: task, comments, attachments and all
/// employee/manager status actions.
class TaskDetailsCubit extends Cubit<TaskDetailsState> {
  final TasksRepository _repository;

  TaskDetailsCubit(this._repository) : super(const TaskDetailsState());

  Future<void> loadTask(int id) async {
    if (isClosed) return;
    emit(state.copyWith(status: TaskDetailsStatus.loading));
    try {
      final task = await _repository.getTask(id);
      if (isClosed) return;
      emit(state.copyWith(status: TaskDetailsStatus.success, task: task));
      // Load interactions in background.
      await Future.wait([
        loadComments(silent: true),
        loadAttachments(silent: true),
      ]);
      // Re-fetch task so action-driven changes (progress/status) reflect.
      if (isClosed) return;
      try {
        final fresh = await _repository.getTask(id);
        if (!isClosed) emit(state.copyWith(task: fresh));
      } catch (_) {}
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: TaskDetailsStatus.failure,
          errorMessage: AppException.from(e).message,
        ),
      );
    }
  }

  Future<void> refresh() async {
    final id = state.task?.id;
    if (id == null) return;
    await loadTask(id);
  }

  Future<void> loadComments({bool silent = false}) async {
    final id = state.task?.id;
    if (id == null || isClosed) return;
    if (!silent) emit(state.copyWith(commentsLoading: true));
    try {
      final comments = await _repository.getComments(id);
      if (isClosed) return;
      emit(state.copyWith(comments: comments, commentsLoading: false));
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(commentsLoading: false));
    }
  }

  Future<void> loadAttachments({bool silent = false}) async {
    final id = state.task?.id;
    if (id == null || isClosed) return;
    if (!silent) emit(state.copyWith(attachmentsLoading: true));
    try {
      final attachments = await _repository.getAttachments(id);
      if (isClosed) return;
      emit(state.copyWith(attachments: attachments, attachmentsLoading: false));
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(attachmentsLoading: false));
    }
  }

  Future<bool> addComment(String comment) async {
    final id = state.task?.id;
    if (id == null || isClosed) return false;
    emit(
      state.copyWith(
        actionStatus: TaskDetailsActionStatus.submitting,
        actionErrorMessage: null,
      ),
    );
    try {
      await _repository.addComment(id, comment);
      if (isClosed) return false;
      emit(state.copyWith(actionStatus: TaskDetailsActionStatus.success));
      await loadComments(silent: true);
      return true;
    } catch (e) {
      if (isClosed) return false;
      emit(
        state.copyWith(
          actionStatus: TaskDetailsActionStatus.failure,
          actionErrorMessage: AppException.from(e).message,
        ),
      );
      return false;
    }
  }

  Future<bool> addAttachment(TaskAttachment attachment) async {
    final id = state.task?.id;
    if (id == null || isClosed) return false;
    emit(
      state.copyWith(
        actionStatus: TaskDetailsActionStatus.submitting,
        actionErrorMessage: null,
      ),
    );
    try {
      await _repository.addAttachment(id, attachment);
      if (isClosed) return false;
      emit(state.copyWith(actionStatus: TaskDetailsActionStatus.success));
      await loadAttachments(silent: true);
      return true;
    } catch (e) {
      if (isClosed) return false;
      emit(
        state.copyWith(
          actionStatus: TaskDetailsActionStatus.failure,
          actionErrorMessage: AppException.from(e).message,
        ),
      );
      return false;
    }
  }

  Future<bool> _statusAction(Future<void> Function(int id) call) async {
    final id = state.task?.id;
    if (id == null || isClosed) return false;
    emit(
      state.copyWith(
        actionStatus: TaskDetailsActionStatus.submitting,
        actionErrorMessage: null,
      ),
    );
    try {
      await call(id);
      if (isClosed) return false;
      emit(state.copyWith(actionStatus: TaskDetailsActionStatus.success));
      await refresh();
      return true;
    } catch (e) {
      if (isClosed) return false;
      emit(
        state.copyWith(
          actionStatus: TaskDetailsActionStatus.failure,
          actionErrorMessage: AppException.from(e).message,
        ),
      );
      return false;
    }
  }

  Future<bool> start() => _statusAction(_repository.startTask);

  Future<bool> submit() => _statusAction(_repository.submitTask);

  Future<bool> approve() => _statusAction(_repository.approveTask);

  Future<bool> updateProgress(int progress) =>
      _statusAction((id) => _repository.updateProgress(id, progress));

  Future<bool> reject(String reason) =>
      _statusAction((id) => _repository.rejectTask(id, reason));

  Future<bool> pauseRecurrence() => _statusAction(_repository.pauseRecurrence);

  Future<bool> resumeRecurrence() =>
      _statusAction(_repository.resumeRecurrence);

  Future<bool> stopRecurrence() => _statusAction(_repository.stopRecurrence);

  void resetActionStatus() {
    if (isClosed) return;
    emit(
      state.copyWith(
        actionStatus: TaskDetailsActionStatus.initial,
        actionErrorMessage: null,
      ),
    );
  }
}
