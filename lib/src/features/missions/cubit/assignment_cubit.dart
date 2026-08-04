import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/assignment_repository.dart';
import 'assignment_state.dart';

class AssignmentCubit extends Cubit<AssignmentState> {
  final AssignmentRepository _repository;

  AssignmentCubit(this._repository) : super(const AssignmentState());

  /// Load current user's assignments
  Future<void> loadMyAssignments() async {
    if (isClosed) return;
    emit(state.copyWith(isLoading: true, error: null));
    
    try {
      final missions = await _repository.getMyAssignments();
      if (isClosed) return;
      
      emit(state.copyWith(
        assignments: missions,
        isLoading: false,
      ));
    } catch (e) {
      final errorMessage = e is Exception ? e.toString().replaceFirst('Exception: ', '') : 'حدث خطأ أثناء تحميل المأموريات';
      if (isClosed) return;
      
      emit(state.copyWith(
        isLoading: false,
        error: errorMessage,
      ));
    }
  }

  /// Load all assignments (HR only)
  Future<void> loadAllAssignments() async {
    if (isClosed) return;
    emit(state.copyWith(isLoading: true, error: null));
    
    try {
      final missions = await _repository.getAllAssignments();
      if (isClosed) return;
      
      emit(state.copyWith(
        assignments: missions,
        isLoading: false,
      ));
    } catch (e) {
      final errorMessage = e is Exception ? e.toString().replaceFirst('Exception: ', '') : 'حدث خطأ أثناء تحميل المأموريات';
      if (isClosed) return;
      
      emit(state.copyWith(
        isLoading: false,
        error: errorMessage,
      ));
    }
  }

  /// Create new assignment
  Future<bool> createAssignment({
    required String where,
    required DateTime startDate,
    DateTime? endDate,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required String reason,
  }) async {
    if (isClosed) return false;
    emit(state.copyWith(isLoading: true, error: null));
    
    try {
      // Format time as HH:mm:ss
      final startTimeStr = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00';
      final endTimeStr = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00';
      
      final newMission = await _repository.createAssignment(
        where: where,
        startDate: startDate,
        endDate: endDate ?? startDate,
        startTime: startTimeStr,
        endTime: endTimeStr,
        reason: reason,
      );
      if (isClosed) return false;
      
      // Add to list
      final updatedList = [newMission, ...state.assignments];
      
      emit(state.copyWith(
        assignments: updatedList,
        isLoading: false,
      ));
      
      return true;
    } catch (e) {
      final errorMessage = e is Exception ? e.toString().replaceFirst('Exception: ', '') : 'حدث خطأ أثناء إنشاء المأمورية';
      if (isClosed) return false;
      
      emit(state.copyWith(
        isLoading: false,
        error: errorMessage,
      ));
      
      return false;
    }
  }

  /// Update assignment status (HR only)
  Future<bool> updateAssignmentStatus({
    required int id,
    required int status, // 1 = Pending, 2 = Approved, 3 = Rejected
    String? rejectionReason,
  }) async {
    if (isClosed) return false;
    emit(state.copyWith(isLoading: true, error: null));
    
    try {
      // Find current mission
      final currentMission = state.assignments.firstWhere(
        (m) => m.id == id.toString(),
        orElse: () => throw Exception('المأمورية غير موجودة'),
      );
      
      final updatedMission = await _repository.updateAssignmentStatus(
        id: id,
        status: status,
        rejectionReason: rejectionReason,
        currentMission: currentMission,
      );
      if (isClosed) return false;
      
      // Update local list
      final updatedList = state.assignments.map((mission) {
        return mission.id == id.toString() ? updatedMission : mission;
      }).toList();
      
      emit(state.copyWith(
        assignments: updatedList,
        isLoading: false,
      ));
      
      return true;
    } catch (e) {
      final errorMessage = e is Exception ? e.toString().replaceFirst('Exception: ', '') : 'حدث خطأ أثناء تحديث حالة المأمورية';
      if (isClosed) return false;
      
      emit(state.copyWith(
        isLoading: false,
        error: errorMessage,
      ));
      
      return false;
    }
  }
}
