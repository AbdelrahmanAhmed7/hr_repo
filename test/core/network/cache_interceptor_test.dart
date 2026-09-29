import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mediconsult_internal/src/core/network/cache_interceptor.dart';
import 'package:mediconsult_internal/src/core/time/server_clock.dart';

class _FakeAdapter implements HttpClientAdapter {
  Future<ResponseBody> Function(RequestOptions)? handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      handler!(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonOk(Map<String, dynamic> payload, DateTime dateHeaderUtc) {
  return ResponseBody.fromString(
    jsonEncode(payload),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
      HttpHeaders.dateHeader: [HttpDate.format(dateHeaderUtc)],
    },
  );
}

DioException _timeout(RequestOptions options) => DioException(
      requestOptions: options,
      type: DioExceptionType.connectionTimeout,
    );

void main() {
  const baseUrl = 'https://x.test';
  final fixedInstant = DateTime.utc(2026, 9, 28, 10, 0);

  late _FakeAdapter adapter;
  late ServerClock clock;
  late Dio dio;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    adapter = _FakeAdapter();
    clock = ServerClock();
    dio = Dio(BaseOptions(baseUrl: baseUrl));
    dio.interceptors.add(
      CacheInterceptor(userIdProvider: () async => 'u1', clock: clock),
    );
    dio.httpClientAdapter = adapter;
  });

  test('fresh same-day same-user cache is served on failure, marked', () async {
    adapter.handler = (options) async =>
        _jsonOk({'today': 'fresh'}, fixedInstant);
    final first = await dio.get('/api/X');
    expect(first.data, {'today': 'fresh'});

    adapter.handler = (options) async => throw _timeout(options);
    final second = await dio.get('/api/X');
    expect(second.data, {'today': 'fresh'});
    expect(second.extra['fromCache'], true);
    expect(second.statusMessage, 'Cached Data');
  });

  test("yesterday's cache is NOT served", () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'GET:$baseUrl/api/X',
      jsonEncode({
        'v': 1,
        'cachedAt': DateTime.utc(2026, 9, 27, 10, 0).toIso8601String(),
        'userId': 'u1',
        'data': {'today': 'stale'},
      }),
    );
    clock.sync(fixedInstant);
    adapter.handler = (options) async => throw _timeout(options);

    await expectLater(() => dio.get('/api/X'), throwsA(isA<DioException>()));
  });

  test("another user's cache is NOT served", () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'GET:$baseUrl/api/X',
      jsonEncode({
        'v': 1,
        'cachedAt': fixedInstant.toIso8601String(),
        'userId': 'u2',
        'data': {'today': 'other-user'},
      }),
    );
    clock.sync(fixedInstant);
    adapter.handler = (options) async => throw _timeout(options);

    await expectLater(() => dio.get('/api/X'), throwsA(isA<DioException>()));
  });

  test('legacy envelope-less entries are never served', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'GET:$baseUrl/api/X',
      jsonEncode({'today': 'legacy'}),
    );
    clock.sync(fixedInstant);
    adapter.handler = (options) async => throw _timeout(options);

    await expectLater(() => dio.get('/api/X'), throwsA(isA<DioException>()));
  });

  test('attendance endpoints are never served nor stored', () async {
    const path = '/api/Attendance/my/2026-09-28';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'GET:$baseUrl$path',
      jsonEncode({
        'v': 1,
        'cachedAt': fixedInstant.toIso8601String(),
        'userId': 'u1',
        'data': {'stale': true},
      }),
    );
    clock.sync(fixedInstant);
    adapter.handler = (options) async => throw _timeout(options);

    await expectLater(() => dio.get(path), throwsA(isA<DioException>()));

    adapter.handler = (options) async =>
        _jsonOk({'fresh': true}, fixedInstant);
    await dio.get(path);
    final stored = jsonDecode(prefs.getString('GET:$baseUrl$path')!);
    expect(stored['data'], {'stale': true});
    expect(stored['v'], 1);
  });

  test('served responses do not re-sync the clock', () async {
    adapter.handler = (options) async =>
        _jsonOk({'today': 'fresh'}, fixedInstant);
    await dio.get('/api/X');
    final afterStore = clock.tryNowServerUtc();
    expect(afterStore, isNotNull);

    adapter.handler = (options) async => throw _timeout(options);
    await dio.get('/api/X');
    final afterServe = clock.tryNowServerUtc();
    expect(afterServe, isNotNull);
    expect(
      afterServe!.difference(afterStore!).inSeconds.abs() < 5,
      isTrue,
    );
  });

  test('clearNetworkCache removes GET entries only', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('GET:$baseUrl/api/X', '{}');
    await prefs.setString('unrelated_key', 'keep');
    await CacheInterceptor.clearNetworkCache();
    expect(prefs.getString('GET:$baseUrl/api/X'), isNull);
    expect(prefs.getString('unrelated_key'), 'keep');
  });
}
