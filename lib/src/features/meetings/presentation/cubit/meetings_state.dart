import 'package:equatable/equatable.dart';

import '../../data/models/department_model.dart';
import '../../data/models/meeting_model.dart';

enum MeetingsLoadStatus { initial, loading, success, failure }

enum DepartmentsStatus { initial, loading, success, failure }

enum MeetingsActionStatus { idle, submitting, success, failure }

class MeetingsState extends Equatable {
  final MeetingsLoadStatus loadStatus;
  final DepartmentsStatus departmentsStatus;
  final MeetingsActionStatus actionStatus;
  final List<MeetingModel> meetings;
  final List<DepartmentModel> departments;
  final int currentPage;
  final int totalPages;
  final bool isLoadingMore;
  final String? errorMessage;
  final String? actionErrorMessage;

  const MeetingsState({
    this.loadStatus = MeetingsLoadStatus.initial,
    this.departmentsStatus = DepartmentsStatus.initial,
    this.actionStatus = MeetingsActionStatus.idle,
    this.meetings = const [],
    this.departments = const [],
    this.currentPage = 1,
    this.totalPages = 0,
    this.isLoadingMore = false,
    this.errorMessage,
    this.actionErrorMessage,
  });

  factory MeetingsState.initial() => const MeetingsState();

  MeetingsState copyWith({
    MeetingsLoadStatus? loadStatus,
    DepartmentsStatus? departmentsStatus,
    MeetingsActionStatus? actionStatus,
    List<MeetingModel>? meetings,
    List<DepartmentModel>? departments,
    int? currentPage,
    int? totalPages,
    bool? isLoadingMore,
    String? errorMessage,
    String? actionErrorMessage,
    bool clearError = false,
    bool clearActionError = false,
  }) {
    return MeetingsState(
      loadStatus: loadStatus ?? this.loadStatus,
      departmentsStatus: departmentsStatus ?? this.departmentsStatus,
      actionStatus: actionStatus ?? this.actionStatus,
      meetings: meetings ?? this.meetings,
      departments: departments ?? this.departments,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      actionErrorMessage: clearActionError
          ? null
          : (actionErrorMessage ?? this.actionErrorMessage),
    );
  }

  @override
  List<Object?> get props => [
    loadStatus,
    departmentsStatus,
    actionStatus,
    meetings,
    departments,
    currentPage,
    totalPages,
    isLoadingMore,
    errorMessage,
    actionErrorMessage,
  ];
}