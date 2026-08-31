import 'package:equatable/equatable.dart';

import '../models/employee_bonus.dart';

enum BonusesStatus {
  initial,
  loading,
  loaded,
  failure,
  saving,
}

class BonusesState extends Equatable {
  final BonusesStatus status;
  final String? error;

  // Selected employee
  final String? selectedEmployeeId;
  final String? selectedEmployeeName;

  // Bonuses
  final List<EmployeeBonus> bonuses;

  // Save status for the add/edit dialog
  final bool isSaving;
  final String? saveError;

  const BonusesState({
    this.status = BonusesStatus.initial,
    this.error,
    this.selectedEmployeeId,
    this.selectedEmployeeName,
    this.bonuses = const [],
    this.isSaving = false,
    this.saveError,
  });

  BonusesState copyWith({
    BonusesStatus? status,
    String? Function()? error,
    String? Function()? selectedEmployeeId,
    String? Function()? selectedEmployeeName,
    List<EmployeeBonus>? bonuses,
    bool? isSaving,
    String? Function()? saveError,
  }) {
    return BonusesState(
      status: status ?? this.status,
      error: error != null ? error() : this.error,
      selectedEmployeeId: selectedEmployeeId != null
          ? selectedEmployeeId()
          : this.selectedEmployeeId,
      selectedEmployeeName: selectedEmployeeName != null
          ? selectedEmployeeName()
          : this.selectedEmployeeName,
      bonuses: bonuses ?? this.bonuses,
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
        bonuses,
        isSaving,
        saveError,
      ];
}
