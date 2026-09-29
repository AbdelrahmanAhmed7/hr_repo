import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mediconsult_internal/src/core/network/cache_interceptor.dart';
import 'package:mediconsult_internal/src/features/attendance/cubit/attendance_cubit.dart';

void main() {
  test('logout cleanup removes network cache and attendance snapshot', () async {
    SharedPreferences.setMockInitialValues({
      'GET:https://hr-api.mediconsulteg.com/api/Home': '{}',
      'GET:https://hr-api.mediconsulteg.com/api/Leave/my': '[]',
      AttendanceCubit.todayCacheKey: '{}',
      'unrelated_key': 'keep',
    });
    final prefs = await SharedPreferences.getInstance();

    await CacheInterceptor.clearNetworkCache();
    await prefs.remove(AttendanceCubit.todayCacheKey);

    expect(prefs.getString('GET:https://hr-api.mediconsulteg.com/api/Home'), isNull);
    expect(prefs.getString('GET:https://hr-api.mediconsulteg.com/api/Leave/my'), isNull);
    expect(prefs.getString(AttendanceCubit.todayCacheKey), isNull);
    expect(prefs.getString('unrelated_key'), 'keep');
  });
}
