import 'package:equatable/equatable.dart';
import '../models/mission.dart';

class AssignmentState extends Equatable {
  final List<Mission> assignments;
  final bool isLoading;
  final String? error;

  const AssignmentState({
    this.assignments = const [],
    this.isLoading = false,
    this.error,
  });

  AssignmentState copyWith({
    List<Mission>? assignments,
    bool? isLoading,
    String? error,
  }) {
    return AssignmentState(
      assignments: assignments ?? this.assignments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [assignments, isLoading, error];
}
