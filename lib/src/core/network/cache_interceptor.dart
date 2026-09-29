import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/services/auth_storage_service.dart';
import '../time/server_clock.dart';

class CacheInterceptor extends Interceptor {
  static const maxCacheAge = Duration(hours: 12);
  static const attendancePrefix = '/api/Attendance/my';

  final Future<String?> Function() _userIdProvider;
  final ServerClock _clock;

  CacheInterceptor({
    Future<String?> Function()? userIdProvider,
    ServerClock? clock,
  })  : _userIdProvider = userIdProvider ?? AuthStorageService.loadUserId,
        _clock = clock ?? ServerClock.instance;

  static String _keyFor(String uri) => 'GET:$uri';

  static Future<void> evictPath(String pathSubstring) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys()) {
        if (key.startsWith('GET:') && key.contains(pathSubstring)) {
          await prefs.remove(key);
        }
      }
    } catch (_) {}
  }

  static Future<void> clearNetworkCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys()) {
        if (key.startsWith('GET:')) {
          await prefs.remove(key);
        }
      }
    } catch (_) {}
  }

  bool _isAttendancePath(String path) => path.contains(attendancePrefix);

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    _syncClock(response);
    if (response.requestOptions.method == 'GET' &&
        response.statusCode == 200 &&
        !_isAttendancePath(response.requestOptions.path)) {
      try {
        final serverNow = _clock.tryNowServerUtc();
        if (serverNow == null) return handler.next(response);
        final prefs = await SharedPreferences.getInstance();
        final userId = await _safeUserId();
        final envelope = {
          'v': 1,
          'cachedAt': serverNow.toIso8601String(),
          'userId': userId,
          'data': response.data,
        };
        await prefs.setString(
          _keyFor(response.requestOptions.uri.toString()),
          jsonEncode(envelope),
        );
      } catch (_) {}
    }
    handler.next(response);
  }

  void _syncClock(Response response) {
    try {
      if (response.extra['fromCache'] == true) return;
      final dateHeader = response.headers.value(HttpHeaders.dateHeader);
      if (dateHeader == null || dateHeader.isEmpty) return;
      _clock.sync(HttpDate.parse(dateHeader));
    } catch (_) {}
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.requestOptions.method == 'GET' &&
        !_isAttendancePath(err.requestOptions.path) &&
        (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            err.type == DioExceptionType.connectionError ||
            err.type == DioExceptionType.unknown)) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(_keyFor(err.requestOptions.uri.toString()));
        final currentUser = await _safeUserId();
        final data = _servableData(raw, currentUser);
        if (data != null) {
          return handler.resolve(
            Response(
              requestOptions: err.requestOptions,
              data: data,
              statusCode: 200,
              statusMessage: 'Cached Data',
              extra: {'fromCache': true},
            ),
          );
        }
      } catch (_) {}
    }

    handler.next(err);
  }

  Future<String?> _safeUserId() async {
    try {
      return await _userIdProvider();
    } catch (_) {
      return null;
    }
  }

  dynamic _servableData(String? raw, String? currentUser) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      if (decoded['v'] != 1) return null;
      final storedUser = decoded['userId']?.toString();
      if (storedUser == null ||
          storedUser.isEmpty ||
          currentUser == null ||
          currentUser.isEmpty ||
          storedUser != currentUser) {
        return null;
      }
      final cachedAt = DateTime.tryParse(decoded['cachedAt']?.toString() ?? '');
      if (cachedAt == null) return null;
      final serverNow = _clock.tryNowServerUtc();
      if (serverNow == null) return null;
      if (serverNow.difference(cachedAt) > maxCacheAge) return null;
      final cachedDay = ServerClock.cairoWall(cachedAt);
      final nowDay = ServerClock.cairoWall(serverNow);
      if (cachedDay.year != nowDay.year ||
          cachedDay.month != nowDay.month ||
          cachedDay.day != nowDay.day) {
        return null;
      }
      return decoded['data'];
    } catch (_) {
      return null;
    }
  }
}
