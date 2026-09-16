import 'package:equatable/equatable.dart';

import '../models/task.dart';
import '../models/task_interactions.dart';

enum TaskDetailsStatus { initial, loading, success, failure }

enum TaskDetailsActionStatus { initial, submitting, success, failure }

class TaskDetailsState extends Equatable {
  final TaskDetailsStatus status;
  final TaskDetailsActionStatus actionStatus;
  final TaskModel? task;
  final List<TaskComment> comments;
  final List<TaskAttachment> attachments;
  final List<TaskHistoryEntry> history;
  final bool commentsLoading;
  final bool attachmentsLoading;
  final bool historyLoading;
  final String? errorMessage;
  final String? actionErrorMessage;

  const TaskDetailsState({
    this.status = TaskDetailsStatus.initial,
    this.actionStatus = TaskDetailsActionStatus.initial,
    this.task,
    this.comments = const [],
    this.attachments = const [],
    this.history = const [],
    this.commentsLoading = false,
    this.attachmentsLoading = false,
    this.historyLoading = false,
    this.errorMessage,
    this.actionErrorMessage,
  });

  TaskDetailsState copyWith({
    TaskDetailsStatus? status,
    TaskDetailsActionStatus? actionStatus,
    TaskModel? task,
    List<TaskComment>? comments,
    List<TaskAttachment>? attachments,
    List<TaskHistoryEntry>? history,
    bool? commentsLoading,
    bool? attachmentsLoading,
    bool? historyLoading,
    String? errorMessage,
    String? actionErrorMessage,
  }) {
    return TaskDetailsState(
      status: status ?? this.status,
      actionStatus: actionStatus ?? this.actionStatus,
      task: task ?? this.task,
      comments: comments ?? this.comments,
      attachments: attachments ?? this.attachments,
      history: history ?? this.history,
      commentsLoading: commentsLoading ?? this.commentsLoading,
      attachmentsLoading: attachmentsLoading ?? this.attachmentsLoading,
      historyLoading: historyLoading ?? this.historyLoading,
      errorMessage: errorMessage,
      actionErrorMessage: actionErrorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        actionStatus,
        task,
        comments,
        attachments,
        history,
        commentsLoading,
        attachmentsLoading,
        historyLoading,
        errorMessage,
        actionErrorMessage,
      ];
}
