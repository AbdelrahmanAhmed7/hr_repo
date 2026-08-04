class LeaveStatistics {
  final int totalLeaves;
  final int usedLeaves;
  final int remainingLeaves;
  final int pendingRequests;
  final int approvedRequests;
  final int rejectedRequests;

  LeaveStatistics({
    required this.totalLeaves,
    required this.usedLeaves,
    required this.remainingLeaves,
    required this.pendingRequests,
    required this.approvedRequests,
    required this.rejectedRequests,
  });

  double get usagePercentage {
    if (totalLeaves == 0) return 0;
    return (usedLeaves / totalLeaves) * 100;
  }


}

