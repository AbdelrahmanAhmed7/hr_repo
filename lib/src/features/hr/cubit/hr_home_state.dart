import '../models/hr_home_response.dart';
import '../models/employee.dart';

class HrHomeState {
  final bool isLoading;
  final String? error;
  final HrHomeResponse? data;
  final List<Employee> featuredEmployees;

  HrHomeState({
    this.isLoading = false,
    this.error,
    this.data,
    this.featuredEmployees = const [],
  });

  HrHomeState copyWith({
    bool? isLoading,
    String? error,
    HrHomeResponse? data,
    List<Employee>? featuredEmployees,
  }) {
    return HrHomeState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      data: data ?? this.data,
      featuredEmployees: featuredEmployees ?? this.featuredEmployees,
    );
  }

  factory HrHomeState.initial() => HrHomeState();
}
