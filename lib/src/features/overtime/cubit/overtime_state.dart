import 'package:equatable/equatable.dart';

import '../api/models/overtime_status_item.dart';
import '../models/overtime_request.dart';

enum OvertimeLoadStatus { initial, loading, success, failure }
enum OvertimeSubmissionStatus { initial, submitting, success, failure }

class OvertimeState extends Equatable {
  final OvertimeLoadStatus loadStatus;
  final OvertimeSubmissionStatus submissionStatus;
  final List<OvertimeRequest> requests;
  final List<OvertimeStatusItem> statuses;
  final String? errorMessage;
  final String? submissionErrorMessage;
  final String selectedFilter;

  const OvertimeState({
    this.loadStatus = OvertimeLoadStatus.initial,
    this.submissionStatus = OvertimeSubmissionStatus.initial,
    this.requests = const [],
    this.statuses = const [],
    this.errorMessage,
    this.submissionErrorMessage,
    this.selectedFilter = 'all',
  });

  List<OvertimeRequest> get filteredRequests {
    if (selectedFilter == 'all') return requests;

    final normalized = selectedFilter.toLowerCase();
    return requests.where((request) {
      switch (request.status) {
        case OvertimeRequestStatus.pending:
          return normalized == 'pending';
        case OvertimeRequestStatus.approved:
          return normalized == 'approved';
        case OvertimeRequestStatus.rejected:
          return normalized == 'rejected';
      }
    }).toList();
  }

  OvertimeState copyWith({
    OvertimeLoadStatus? loadStatus,
    OvertimeSubmissionStatus? submissionStatus,
    List<OvertimeRequest>? requests,
    List<OvertimeStatusItem>? statuses,
    String? errorMessage,
    String? submissionErrorMessage,
    String? selectedFilter,
  }) {
    return OvertimeState(
      loadStatus: loadStatus ?? this.loadStatus,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      requests: requests ?? this.requests,
      statuses: statuses ?? this.statuses,
      errorMessage: errorMessage,
      submissionErrorMessage: submissionErrorMessage,
      selectedFilter: selectedFilter ?? this.selectedFilter,
    );
  }

  @override
  List<Object?> get props => [
        loadStatus,
        submissionStatus,
        requests,
        statuses,
        errorMessage,
        submissionErrorMessage,
        selectedFilter,
      ];
}
