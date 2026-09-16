import 'package:equatable/equatable.dart';

import '../models/task.dart';
import '../models/task_filters.dart';
import '../models/task_lookups.dart';

enum TasksStatus { initial, loading, success, failure }

enum TasksActionStatus { initial, submitting, success, failure }

class TasksState extends Equatable {
  final TasksStatus status;
  final TasksStatus myTasksStatus;
  final TasksStatus lookupsStatus;
  final TasksActionStatus actionStatus;
  final List<TaskModel> tasks;
  final List<TaskModel> myTasks;
  final TaskLookups lookups;
  final List<AssignableEmployee> assignableEmployees;
  final bool assignableLoading;
  final TaskFilters filters;
  final TaskFilters myTasksFilters;
  final int currentPage;
  final int myTasksCurrentPage;
  final bool hasMoreTasks;
  final bool hasMoreMyTasks;
  final bool loadingMoreTasks;
  final bool loadingMoreMyTasks;
  final int totalTasks;
  final int totalMyTasks;
  final String? errorMessage;
  final String? myTasksErrorMessage;
  final String? actionErrorMessage;

  const TasksState({
    this.status = TasksStatus.initial,
    this.myTasksStatus = TasksStatus.initial,
    this.lookupsStatus = TasksStatus.initial,
    this.actionStatus = TasksActionStatus.initial,
    this.tasks = const [],
    this.myTasks = const [],
    this.lookups = const TaskLookups(),
    this.assignableEmployees = const [],
    this.assignableLoading = false,
    this.filters = const TaskFilters(),
    this.myTasksFilters = const TaskFilters(),
    this.currentPage = 0,
    this.myTasksCurrentPage = 0,
    this.hasMoreTasks = false,
    this.hasMoreMyTasks = false,
    this.loadingMoreTasks = false,
    this.loadingMoreMyTasks = false,
    this.totalTasks = 0,
    this.totalMyTasks = 0,
    this.errorMessage,
    this.myTasksErrorMessage,
    this.actionErrorMessage,
  });

  TasksState copyWith({
    TasksStatus? status,
    TasksStatus? myTasksStatus,
    TasksStatus? lookupsStatus,
    TasksActionStatus? actionStatus,
    List<TaskModel>? tasks,
    List<TaskModel>? myTasks,
    TaskLookups? lookups,
    List<AssignableEmployee>? assignableEmployees,
    bool? assignableLoading,
    TaskFilters? filters,
    bool clearFilters = false,
    TaskFilters? myTasksFilters,
    bool clearMyFilters = false,
    int? currentPage,
    int? myTasksCurrentPage,
    bool? hasMoreTasks,
    bool? hasMoreMyTasks,
    bool? loadingMoreTasks,
    bool? loadingMoreMyTasks,
    int? totalTasks,
    int? totalMyTasks,
    String? errorMessage,
    String? myTasksErrorMessage,
    String? actionErrorMessage,
  }) {
    return TasksState(
      status: status ?? this.status,
      myTasksStatus: myTasksStatus ?? this.myTasksStatus,
      lookupsStatus: lookupsStatus ?? this.lookupsStatus,
      actionStatus: actionStatus ?? this.actionStatus,
      tasks: tasks ?? this.tasks,
      myTasks: myTasks ?? this.myTasks,
      lookups: lookups ?? this.lookups,
      assignableEmployees: assignableEmployees ?? this.assignableEmployees,
      assignableLoading: assignableLoading ?? this.assignableLoading,
      filters: clearFilters ? const TaskFilters() : filters ?? this.filters,
      myTasksFilters: clearMyFilters
          ? const TaskFilters()
          : myTasksFilters ?? this.myTasksFilters,
      currentPage: currentPage ?? this.currentPage,
      myTasksCurrentPage: myTasksCurrentPage ?? this.myTasksCurrentPage,
      hasMoreTasks: hasMoreTasks ?? this.hasMoreTasks,
      hasMoreMyTasks: hasMoreMyTasks ?? this.hasMoreMyTasks,
      loadingMoreTasks: loadingMoreTasks ?? this.loadingMoreTasks,
      loadingMoreMyTasks: loadingMoreMyTasks ?? this.loadingMoreMyTasks,
      totalTasks: totalTasks ?? this.totalTasks,
      totalMyTasks: totalMyTasks ?? this.totalMyTasks,
      errorMessage: errorMessage,
      myTasksErrorMessage: myTasksErrorMessage,
      actionErrorMessage: actionErrorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        myTasksStatus,
        lookupsStatus,
        actionStatus,
        tasks,
        myTasks,
        lookups,
        assignableEmployees,
        assignableLoading,
        filters,
        myTasksFilters,
        currentPage,
        myTasksCurrentPage,
        hasMoreTasks,
        hasMoreMyTasks,
        loadingMoreTasks,
        loadingMoreMyTasks,
        totalTasks,
        totalMyTasks,
        errorMessage,
        myTasksErrorMessage,
        actionErrorMessage,
      ];
}