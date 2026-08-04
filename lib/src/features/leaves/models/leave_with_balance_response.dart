import 'leave_balance_model.dart';
import 'leave_request_model.dart';

class LeaveWithBalanceResponse {
  final LeaveBalanceModel balance;
  final List<LeaveRequestModel> leaves;

  const LeaveWithBalanceResponse({
    required this.balance,
    required this.leaves,
  });

  factory LeaveWithBalanceResponse.fromJson(Map<String, dynamic> json) {
    final balanceJson = json['balance'] as Map<String, dynamic>? ?? const {};
    final leavesRaw = json['leaves'] as List<dynamic>? ?? const [];

    return LeaveWithBalanceResponse(
      balance: LeaveBalanceModel.fromJson(balanceJson),
      leaves: leavesRaw
          .map((e) => LeaveRequestModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

