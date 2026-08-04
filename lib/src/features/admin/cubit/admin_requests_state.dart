import 'package:equatable/equatable.dart';
import 'package:mediconsult_internal/src/features/home/models/recent_activity.dart';

class AdminRequestsState extends Equatable {
  final List<RecentActivity> allRequests;
  final bool isLoading;
  final String? error;

  const AdminRequestsState({
    this.allRequests = const [],
    this.isLoading = false,
    this.error,
  });

  List<RecentActivity> get pendingRequests {
    return allRequests.where((req) => req.status == RequestStatus.pending).toList();
  }

  List<RecentActivity> get approvedRequests {
    return allRequests.where((req) => req.status == RequestStatus.approved).toList();
  }

  List<RecentActivity> get rejectedRequests {
    return allRequests.where((req) => req.status == RequestStatus.rejected).toList();
  }

  AdminRequestsState copyWith({
    List<RecentActivity>? allRequests,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AdminRequestsState(
      allRequests: allRequests ?? this.allRequests,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [allRequests, isLoading, error];
}

