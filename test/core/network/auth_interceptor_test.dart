import 'dart:convert';

import 'package:algo_erp_front/core/auth/token_storage.dart';
import 'package:algo_erp_front/core/network/interceptors/auth_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTokenStorage implements TokenStorage {
  String? _accessToken = 'old-access';
  String? _refreshToken = 'old-refresh';
  bool cleared = false;

  @override
  Future<String?> get accessToken async => _accessToken;

  @override
  Future<String?> get refreshToken async => _refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  @override
  Future<void> clear() async {
    cleared = true;
    _accessToken = null;
    _refreshToken = null;
  }
}

/// Routes requests to canned responses by path + bearer token, so tests can
/// simulate "old token -> 401 -> refresh -> retry with new token -> 200"
/// without touching a real server.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) => handler(options);
}

ResponseBody _jsonBody(Map<String, dynamic> data, int statusCode) {
  return ResponseBody.fromString(
    jsonEncode(data),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  test(
    '401 triggers exactly one refresh, then the original request is replayed '
    'with the new access token',
    () async {
      var refreshCalls = 0;
      var brandsCallsWithOldToken = 0;
      var brandsCallsWithNewToken = 0;

      final adapter = _FakeAdapter((options) async {
        final auth = options.headers['Authorization'] as String?;
        if (options.path == '/auth/refresh') {
          refreshCalls++;
          return _jsonBody({
            'success': true,
            'data': {
              'accessToken': 'new-access',
              'refreshToken': 'new-refresh',
            },
            'requestId': 'refresh-req',
          }, 200);
        }
        if (options.path == '/brands') {
          if (auth == 'Bearer old-access') {
            brandsCallsWithOldToken++;
            return _jsonBody({
              'success': false,
              'error': {'message': 'Token expired'},
              'requestId': 'unauth-req',
            }, 401);
          }
          if (auth == 'Bearer new-access') {
            brandsCallsWithNewToken++;
            return _jsonBody({
              'success': true,
              'data': {'ok': true},
              'requestId': 'ok-req',
            }, 200);
          }
        }
        throw StateError('Unexpected request: ${options.path} / $auth');
      });

      final tokenStorage = _FakeTokenStorage();
      final baseOptions = BaseOptions(baseUrl: 'https://api.test');

      final refreshDio = Dio(baseOptions)..httpClientAdapter = adapter;
      final mainDio = Dio(baseOptions)..httpClientAdapter = adapter;
      mainDio.interceptors.add(AuthInterceptor(tokenStorage, refreshDio));

      final response = await mainDio.get<dynamic>('/brands');

      expect(response.statusCode, 200);
      expect((response.data as Map<String, dynamic>)['data'], {'ok': true});
      expect(refreshCalls, 1);
      expect(brandsCallsWithOldToken, 1);
      expect(brandsCallsWithNewToken, 1);
      expect(await tokenStorage.accessToken, 'new-access');
      expect(await tokenStorage.refreshToken, 'new-refresh');
      expect(tokenStorage.cleared, isFalse);
    },
  );

  test('concurrent 401s share a single refresh call', () async {
    var refreshCalls = 0;

    final adapter = _FakeAdapter((options) async {
      final auth = options.headers['Authorization'] as String?;
      if (options.path == '/auth/refresh') {
        refreshCalls++;
        // Simulate network latency so both original requests' 401 handlers
        // are in flight before the refresh resolves.
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return _jsonBody({
          'success': true,
          'data': {'accessToken': 'new-access', 'refreshToken': 'new-refresh'},
          'requestId': 'refresh-req',
        }, 200);
      }
      if (auth == 'Bearer old-access') {
        return _jsonBody({
          'success': false,
          'error': {'message': 'Token expired'},
          'requestId': 'unauth-req',
        }, 401);
      }
      return _jsonBody({
        'success': true,
        'data': {'ok': true},
        'requestId': 'ok-req',
      }, 200);
    });

    final tokenStorage = _FakeTokenStorage();
    final baseOptions = BaseOptions(baseUrl: 'https://api.test');
    final refreshDio = Dio(baseOptions)..httpClientAdapter = adapter;
    final mainDio = Dio(baseOptions)..httpClientAdapter = adapter;
    mainDio.interceptors.add(AuthInterceptor(tokenStorage, refreshDio));

    final results = await Future.wait([
      mainDio.get<dynamic>('/brands'),
      mainDio.get<dynamic>('/ledgers'),
    ]);

    expect(results[0].statusCode, 200);
    expect(results[1].statusCode, 200);
    expect(refreshCalls, 1);
  });

  test('failed refresh clears tokens, propagates the original 401', () async {
    final adapter = _FakeAdapter((options) async {
      if (options.path == '/auth/refresh') {
        return _jsonBody({
          'success': false,
          'error': {'message': 'Refresh token invalid'},
          'requestId': 'refresh-fail',
        }, 401);
      }
      return _jsonBody({
        'success': false,
        'error': {'message': 'Token expired'},
        'requestId': 'unauth-req',
      }, 401);
    });

    final tokenStorage = _FakeTokenStorage();
    final baseOptions = BaseOptions(baseUrl: 'https://api.test');
    final refreshDio = Dio(baseOptions)..httpClientAdapter = adapter;
    final mainDio = Dio(baseOptions)..httpClientAdapter = adapter;
    mainDio.interceptors.add(AuthInterceptor(tokenStorage, refreshDio));

    await expectLater(
      mainDio.get<dynamic>('/brands'),
      throwsA(isA<DioException>()),
    );
    expect(tokenStorage.cleared, isTrue);
  });
}
