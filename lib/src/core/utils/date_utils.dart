class AppDateUtils {
  /// Weekly off days in the app: Friday & Saturday.
  static bool isWeeklyOff(DateTime date) {
    return date.weekday == DateTime.friday || date.weekday == DateTime.saturday;
  }
}

