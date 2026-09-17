import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/app_exception.dart';
import '../models/task.dart';
import '../models/task_filters.dart';
import '../repository/tasks_repository.dart';
import 'tasks_state.dart';

/// Tasks list cubit: all tasks (paginated + filterable), my tasks, lookups,
/// assignable employees, create/update and recurrence management.
class TasksCubit extends Cubit<TasksState> {
  final TasksRepository _repository;

  static const int _pageSize = 20;
  int _currentPage = 1;
  int _myTasksPage = 1;

  TasksCubit(this._repository) : super(const TasksState());

  /// Loads the tasks list. [loadMore] fetches the next page and appends it;
  /// otherwise it resets to page 1 (honouring the current [TasksState.filters]).
  Future<void> loadTasks({bool silent = false, bool loadMore = false}) async {
    if (isClosed) return;
    if (loadMore && (state.loadingMoreTasks || !state.hasMoreTasks)) return;

    final pageNumber = loadMore ? _currentPage + 1 : 1;
    if (loadMore) {
      emit(state.copyWith(loadingMoreTasks: true));
    } else if (!silent) {
      emit(
        state.copyWith(status: TasksStatus.loading, loadingMoreTasks: false),
      );
    }

    try {
      final page = await _repository.getTasks(
        pageNumber: pageNumber,
        pageSize: _pageSize,
        filters: state.filters,
      );
      if (isClosed) return;
      _currentPage = pageNumber;
      emit(
        state.copyWith(
          status: TasksStatus.success,
          tasks: loadMore ? [...state.tasks, ...page.items] : page.items,
          currentPage: pageNumber,
          hasMoreTasks: pageNumber < page.totalPages,
          loadingMoreTasks: false,
          totalTasks: page.totalCount,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: loadMore ? state.status : TasksStatus.failure,
          loadingMoreTasks: false,
          errorMessage: loadMore
              ? state.errorMessage
              : AppException.from(e).message,
        ),
      );
    }
  }

  Future<void> loadMyTasks({bool silent = false, bool loadMore = false}) async {
    if (isClosed) return;
    if (loadMore && (state.loadingMoreMyTasks || !state.hasMoreMyTasks)) return;

    final pageNumber = loadMore ? _myTasksPage + 1 : 1;
    if (loadMore) {
      emit(state.copyWith(loadingMoreMyTasks: true));
    } else if (!silent) {
      emit(
        state.copyWith(
          myTasksStatus: TasksStatus.loading,
          loadingMoreMyTasks: false,
        ),
      );
    }

    try {
      final page = await _repository.getMyTasks(
        pageNumber: pageNumber,
        pageSize: _pageSize,
        filters: state.myTasksFilters,
      );
      if (isClosed) return;
      _myTasksPage = pageNumber;
      emit(
        state.copyWith(
          myTasksStatus: TasksStatus.success,
          myTasks: loadMore ? [...state.myTasks, ...page.items] : page.items,
          myTasksCurrentPage: pageNumber,
          hasMoreMyTasks: pageNumber < page.totalPages,
          loadingMoreMyTasks: false,
          totalMyTasks: page.totalCount,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          myTasksStatus: loadMore ? state.myTasksStatus : TasksStatus.failure,
          loadingMoreMyTasks: false,
          myTasksErrorMessage: loadMore
              ? state.myTasksErrorMessage
              : AppException.from(e).message,
        ),
      );
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([loadTasks(silent: true), loadMyTasks(silent: true)]);
  }

  void setStatusFilter(int? status) {
    if (state.filters.status == status) return;
    emit(state.copyWith(filters: state.filters.copyWith(status: status)));
    loadTasks();
  }

  void setMyStatusFilter(int? status) {
    if (state.myTasksFilters.status == status) return;
    emit(
      state.copyWith(
        myTasksFilters: state.myTasksFilters.copyWith(status: status),
      ),
    );
    loadMyTasks();
  }

  void applyFilters(TaskFilters filters) {
    if (state.filters == filters) return;
    emit(state.copyWith(filters: filters));
    loadTasks();
  }

  void applyMyFilters(TaskFilters filters) {
    if (state.myTasksFilters == filters) return;
    emit(state.copyWith(myTasksFilters: filters));
    loadMyTasks();
  }

  Future<void> loadLookups() async {
    if (isClosed) return;
    if (state.lookupsStatus == TasksStatus.success) return;
    emit(state.copyWith(lookupsStatus: TasksStatus.loading));
    try {
      final lookups = await _repository.getLookups();
      if (isClosed) return;
      emit(
        state.copyWith(lookupsStatus: TasksStatus.success, lookups: lookups),
      );
    } catch (e) {
      if (isClosed) return;
      // Lookups are enhancement-only (Arabic fallbacks exist) — don't fail.
      emit(state.copyWith(lookupsStatus: TasksStatus.failure));
    }
  }

  Future<void> loadAssignableEmployees() async {
    if (isClosed) return;
    if (state.assignableEmployees.isNotEmpty || state.assignableLoading) {
      return;
    }
    emit(state.copyWith(assignableLoading: true));
    try {
      final employees = await _repository.getAssignableEmployees();
      if (isClosed) return;
      emit(
        state.copyWith(
          assignableEmployees: employees,
          assignableLoading: false,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          assignableLoading: false,
          actionErrorMessage: AppException.from(e).message,
        ),
      );
    }
  }

  /// Creates a task, returns the created task on success, null on failure.
  Future<TaskModel?> createTask(TaskUpsertRequest request) async {
    if (isClosed) return null;
    emit(
      state.copyWith(
        actionStatus: TasksActionStatus.submitting,
        actionErrorMessage: null,
      ),
    );
    try {
      final task = await _repository.createTask(request);
      if (isClosed) return null;
      emit(state.copyWith(actionStatus: TasksActionStatus.success));
      await refreshAll();
      return task;
    } catch (e) {
      if (isClosed) return null;
      emit(
        state.copyWith(
          actionStatus: TasksActionStatus.failure,
          actionErrorMessage: AppException.from(e).message,
        ),
      );
      return null;
    }
  }

  /// Updates a task, returns true on success.
  Future<bool> updateTask(int id, TaskUpsertRequest request) async {
    if (isClosed) return false;
    emit(
      state.copyWith(
        actionStatus: TasksActionStatus.submitting,
        actionErrorMessage: null,
      ),
    );
    try {
      await _repository.updateTask(id, request);
      if (isClosed) return false;
      emit(state.copyWith(actionStatus: TasksActionStatus.success));
      await refreshAll();
      return true;
    } catch (e) {
      if (isClosed) return false;
      emit(
        state.copyWith(
          actionStatus: TasksActionStatus.failure,
          actionErrorMessage: AppException.from(e).message,
        ),
      );
      return false;
    }
  }

  Future<bool> pauseRecurrence(int id) =>
      _recurrenceAction(() => _repository.pauseRecurrence(id));

  Future<bool> resumeRecurrence(int id) =>
      _recurrenceAction(() => _repository.resumeRecurrence(id));

  Future<bool> stopRecurrence(int id) =>
      _recurrenceAction(() => _repository.stopRecurrence(id));

  Future<bool> _recurrenceAction(Future<void> Function() call) async {
    if (isClosed) return false;
    emit(
      state.copyWith(
        actionStatus: TasksActionStatus.submitting,
        actionErrorMessage: null,
      ),
    );
    try {
      await call();
      if (isClosed) return false;
      emit(state.copyWith(actionStatus: TasksActionStatus.success));
      await refreshAll();
      return true;
    } catch (e) {
      if (isClosed) return false;
      emit(
        state.copyWith(
          actionStatus: TasksActionStatus.failure,
          actionErrorMessage: AppException.from(e).message,
        ),
      );
      return false;
    }
  }

  void resetActionStatus() {
    if (isClosed) return;
    emit(
      state.copyWith(
        actionStatus: TasksActionStatus.initial,
        actionErrorMessage: null,
      ),
    );
  }
}
