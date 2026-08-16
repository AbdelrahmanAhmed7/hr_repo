import 'package:equatable/equatable.dart';
import '../../data/models/nominee_model.dart';
import '../../data/models/winner_model.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum EmployeeOfMonthStatus { initial, loading, success, error }

enum VoteStatus { idle, loading, success, error }

enum CalculateStatus { idle, loading, success, error }

// ─── Employee Cubit State ─────────────────────────────────────────────────────

class EmployeeOfMonthState extends Equatable {
  final EmployeeOfMonthStatus status;
  final VoteStatus voteStatus;
  final List<NomineeModel> nominees;
  final List<WinnerModel> winners;
  final bool hasVoted;
  final String? votedForUserId;
  final String? votedForName;
  final String? errorMessage;
  final int currentMonth;
  final int currentYear;

  const EmployeeOfMonthState({
    this.status = EmployeeOfMonthStatus.initial,
    this.voteStatus = VoteStatus.idle,
    this.nominees = const [],
    this.winners = const [],
    this.hasVoted = false,
    this.votedForUserId,
    this.votedForName,
    this.errorMessage,
    required this.currentMonth,
    required this.currentYear,
  });

  factory EmployeeOfMonthState.initial() {
    final now = DateTime.now();
    return EmployeeOfMonthState(currentMonth: now.month, currentYear: now.year);
  }

  EmployeeOfMonthState copyWith({
    EmployeeOfMonthStatus? status,
    VoteStatus? voteStatus,
    List<NomineeModel>? nominees,
    List<WinnerModel>? winners,
    bool? hasVoted,
    String? votedForUserId,
    String? votedForName,
    String? errorMessage,
    int? currentMonth,
    int? currentYear,
    bool clearError = false,
    bool clearVotedFor = false,
  }) {
    return EmployeeOfMonthState(
      status: status ?? this.status,
      voteStatus: voteStatus ?? this.voteStatus,
      nominees: nominees ?? this.nominees,
      winners: winners ?? this.winners,
      hasVoted: hasVoted ?? this.hasVoted,
      votedForUserId: clearVotedFor
          ? null
          : (votedForUserId ?? this.votedForUserId),
      votedForName: clearVotedFor ? null : (votedForName ?? this.votedForName),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      currentMonth: currentMonth ?? this.currentMonth,
      currentYear: currentYear ?? this.currentYear,
    );
  }

  @override
  List<Object?> get props => [
    status,
    voteStatus,
    nominees,
    winners,
    hasVoted,
    votedForUserId,
    votedForName,
    errorMessage,
    currentMonth,
    currentYear,
  ];
}

// ─── Super Admin Cubit State ──────────────────────────────────────────────────

class SuperAdminEmployeeOfMonthState extends Equatable {
  final EmployeeOfMonthStatus status;
  final CalculateStatus calculateStatus;
  final List<WinnerModel> winners;
  final String? errorMessage;
  final int selectedMonth;
  final int selectedYear;

  const SuperAdminEmployeeOfMonthState({
    this.status = EmployeeOfMonthStatus.initial,
    this.calculateStatus = CalculateStatus.idle,
    this.winners = const [],
    this.errorMessage,
    required this.selectedMonth,
    required this.selectedYear,
  });

  factory SuperAdminEmployeeOfMonthState.initial() {
    final now = DateTime.now();
    return SuperAdminEmployeeOfMonthState(
      selectedMonth: now.month,
      selectedYear: now.year,
    );
  }

  SuperAdminEmployeeOfMonthState copyWith({
    EmployeeOfMonthStatus? status,
    CalculateStatus? calculateStatus,
    List<WinnerModel>? winners,
    String? errorMessage,
    int? selectedMonth,
    int? selectedYear,
    bool clearError = false,
  }) {
    return SuperAdminEmployeeOfMonthState(
      status: status ?? this.status,
      calculateStatus: calculateStatus ?? this.calculateStatus,
      winners: winners ?? this.winners,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedYear: selectedYear ?? this.selectedYear,
    );
  }

  @override
  List<Object?> get props => [
    status,
    calculateStatus,
    winners,
    errorMessage,
    selectedMonth,
    selectedYear,
  ];
}
