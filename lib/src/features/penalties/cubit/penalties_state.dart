import 'package:equatable/equatable.dart';

import '../../home/models/employee_penalty.dart';
import '../models/penalty_type.dart';

enum PenaltiesStatus {
  initial,
  loading,
  loaded,
  failure,
  saving,
}

class PenaltiesState extends Equatable {
  final PenaltiesStatus status;
  final String? error;

  // Selected employee
  final String? selectedEmployeeId;
  final String? selectedEmployeeName;

  // Types
  final List<PenaltyType> types;
  final bool typesLoaded;

  // Penalties
  final List<EmployeePenalty> penalties;

  // Save status for the add/edit dialog
  final bool isSaving;
  final String? saveError;

  const PenaltiesState({
    this.status = PenaltiesStatus.initial,
    this.error,
    this.selectedEmployeeId,
    this.selectedEmployeeName,
    this.types = const [],
    this.typesLoaded = false,
    this.penalties = const [],
    this.isSaving = false,
    this.saveError,
  });

  PenaltiesState copyWith({
    PenaltiesStatus? status,
    String? Function()? error,
    String? Function()? selectedEmployeeId,
    String? Function()? selectedEmployeeName,
    List<PenaltyType>? types,
    bool? typesLoaded,
    List<EmployeePenalty>? penalties,
    bool? isSaving,
    String? Function()? saveError,
  }) {
    return PenaltiesState(
      status: status ?? this.status,
      error: error != null ? error() : this.error,
      selectedEmployeeId: selectedEmployeeId != null
          ? selectedEmployeeId()
          : this.selectedEmployeeId,
      selectedEmployeeName: selectedEmployeeName != null
          ? selectedEmployeeName()
          : this.selectedEmployeeName,
      types: types ?? this.types,
      typesLoaded: typesLoaded ?? this.typesLoaded,
      penalties: penalties ?? this.penalties,
      isSaving: isSaving ?? this.isSaving,
      saveError: saveError != null ? saveError() : this.saveError,
    );
  }

  @override
  List<Object?> get props => [
        status,
        error,
        selectedEmployeeId,
        selectedEmployeeName,
        types,
        typesLoaded,
        penalties,
        isSaving,
        saveError,
      ];
}
