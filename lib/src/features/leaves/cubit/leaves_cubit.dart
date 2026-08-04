import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/service_locator.dart';
import '../../profile/repository/profile_repository.dart';
import '../models/leave_submission_model.dart';
import '../repository/leaves_repository.dart';
import 'leaves_state.dart';

class LeavesCubit extends Cubit<LeavesState> {
  final LeavesRepository _repository;

  LeavesCubit(this._repository) : super(const LeavesState());

  /// Load leaves + balance for the leaves screen using ONE API call:
  /// GET /api/Leave/my/with-balance
  Future<void> loadLeavesOverview({
    bool forceRefresh = false,
    bool silent = false,
  }) async {
    if (isClosed) return;
    final hasData =
        state.leaveBalance != null || state.leaveRequests.isNotEmpty;
    final shouldShowLoading = !silent && !hasData;
    if (shouldShowLoading) {
      emit(state.copyWith(status: LeavesStatus.loading));
    }
    try {
      final res = await _repository.getMyLeavesWithBalance(
        forceRefresh: forceRefresh,
      );
      final leaves = res.leaves;
      final balance = res.balance;

      if (isClosed) return;
      emit(
        state.copyWith(
          status: LeavesStatus.success,
          leaveRequests: leaves,
          leaveBalance: balance,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      emit(
        state.copyWith(
          status: LeavesStatus.failure,
          errorMessage: errorMessage,
        ),
      );
    }
  }

  /// Load leave types only (used by create leave flow).
  Future<void> loadLeaveTypes({bool forceRefresh = false}) async {
    if (isClosed) return;
    emit(
      state.copyWith(
        leaveTypesStatus: LeavesStatus.loading,
        leaveTypesErrorMessage: null,
      ),
    );
    try {
      var types = await _repository.getLeaveTypes(forceRefresh: forceRefresh);

      // Filter out Maternity leave for male users
      try {
        final profileRepo = getIt<ProfileRepository>();
        final profile = await profileRepo.getProfile();
        if (profile.isMale) {
          types = types
              .where(
                (t) =>
                    t.name.toLowerCase() != 'maternity' &&
                    t.nameAr != 'إجازة وضع',
              )
              .toList();
        }
      } catch (_) {}

      if (isClosed) return;
      emit(
        state.copyWith(
          leaveTypes: types,
          leaveTypesStatus: LeavesStatus.success,
          leaveTypesErrorMessage: null,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          leaveTypesStatus: LeavesStatus.failure,
          leaveTypesErrorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  /// Backward compatible: loads overview + types when needed.
  Future<void> loadLeavesData() async {
    await loadLeavesOverview();
    if (state.leaveTypes.isEmpty) {
      await loadLeaveTypes(forceRefresh: true);
    }
  }

  // Specific method to refresh only history
  Future<void> refreshLeavesHistory() async {
    try {
      final leaves = await _repository.getMyLeaves();
      if (isClosed) return;
      emit(state.copyWith(leaveRequests: leaves));
    } catch (e) {
      // Log error but maybe don't change global status if types are loaded
      if (kDebugMode) {
        print('Error refreshing leaves: $e');
      }
    }
  }

  Future<void> submitLeave(LeaveSubmissionModel submission, {required int leaveTypeId}) async {
    if (isClosed) return;

    // Safety guard: if annual balance is insufficient, do not send request.
    try {
      final type = submission.leaveType.toLowerCase().trim();
      if (type == 'annual' && state.leaveBalance != null) {
        final start = DateTime.tryParse(submission.startDate);
        final end = DateTime.tryParse(submission.endDate);
        if (start != null && end != null) {
          final requestedDays = end.difference(start).inDays + 1;
          if (requestedDays > state.leaveBalance!.annualLeaveRemaining) {
            emit(
              state.copyWith(
                submissionStatus: SubmissionStatus.failure,
                submissionErrorMessage:
                    'رصيد الإجازات غير كافٍ (${state.leaveBalance!.annualLeaveRemaining} يوم متاح).',
              ),
            );
            return;
          }
        }
      }
    } catch (_) {}

    emit(state.copyWith(submissionStatus: SubmissionStatus.submitting));
    try {
      // Convert attachment path to File if exists
      File? medicalReport;
      if (submission.medicalReportUrl != null &&
          submission.medicalReportUrl!.isNotEmpty) {
        final f = File(submission.medicalReportUrl!);
        final exists = await f.exists();
        if (!exists) {
          throw Exception('المرفق غير موجود. يرجى اختيار الملف مرة أخرى');
        }
        medicalReport = f;
      }

      await _repository
          .submitLeave(
            submission,
            leaveTypeId: leaveTypeId,
            medicalReport: medicalReport,
          )
          .timeout(const Duration(seconds: 25));

      // Refresh list after successful submission but reset status first
      final leaves = await _repository
          .getMyLeaves(forceRefresh: true)
          .timeout(const Duration(seconds: 25));

      if (isClosed) return;
      emit(
        state.copyWith(
          submissionStatus: SubmissionStatus.success,
          leaveRequests: leaves,
        ),
      );

      // Reset submission status after short delay to allow UI to react
      await Future.delayed(const Duration(milliseconds: 100));
      if (isClosed) return;
      emit(state.copyWith(submissionStatus: SubmissionStatus.initial));
    } on TimeoutException {
      if (isClosed) return;
      emit(
        state.copyWith(
          submissionStatus: SubmissionStatus.failure,
          submissionErrorMessage:
              'انتهت مهلة الاتصال. يرجى التحقق من الإنترنت والمحاولة مرة أخرى',
        ),
      );
    } catch (e) {
      if (isClosed) return;
      final errorMessage = e.toString().replaceFirst('Exception: ', '');

      emit(
        state.copyWith(
          submissionStatus: SubmissionStatus.failure,
          submissionErrorMessage: errorMessage,
        ),
      );
    }
  }

  void resetSubmissionStatus() {
    if (isClosed) return;
    emit(
      state.copyWith(
        submissionStatus: SubmissionStatus.initial,
        submissionErrorMessage: null,
      ),
    );
  }
}
