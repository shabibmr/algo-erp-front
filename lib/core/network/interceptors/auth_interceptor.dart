import 'dart:async';

import 'package:algo_erp_front/core/auth/token_storage.dart';
import 'package:dio/dio.dart';

/// Attaches the bearer token to every request; on a 401, attempts exactly
/// one `/auth/refresh` (concurrent 401s share that single refresh call via
/// [_refreshCompleter]) and replays the original request with the new
/// token. If refresh fails, tokens are cleared and the original 401
/// propagates so the app can route to /login.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStorage, this._refreshDio);

  final TokenStorage _tokenStorage;

  /// A bare Dio instance (no interceptors) used only for the refresh call
  /// itself and for replaying the original request — avoids recursing back
  /// into this interceptor.
  final Dio _refreshDio;

  Completer<String?>? _refreshCompleter;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final isRefreshCall = err.requestOptions.path.contains('/auth/refresh');
    if (!isUnauthorized || isRefreshCall) {
      handler.next(err);
      return;
    }

    try {
      final newAccessToken = await _refreshOnce();
      if (newAccessToken == null) {
        await _tokenStorage.clear();
        handler.next(err);
        return;
      }

      final retryOptions = err.requestOptions
        ..headers['Authorization'] = 'Bearer $newAccessToken';
      final response = await _refreshDio.fetch<dynamic>(retryOptions);
      handler.resolve(response);
    } on Object catch (_) {
      await _tokenStorage.clear();
      handler.next(err);
    }
  }

  Future<String?> _refreshOnce() {
    final inFlight = _refreshCompleter;
    if (inFlight != null) return inFlight.future;

    final completer = Completer<String?>();
    _refreshCompleter = completer;
    unawaited(
      _doRefresh()
          .then(completer.complete)
          .catchError(completer.completeError)
          .whenComplete(() => _refreshCompleter = null),
    );
    return completer.future;
  }

  Future<String?> _doRefresh() async {
    final refreshToken = await _tokenStorage.refreshToken;
    if (refreshToken == null) return null;

    final response = await _refreshDio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    final data = response.data?['data'] as Map<String, dynamic>?;
    final newAccessToken = data?['accessToken'] as String?;
    final newRefreshToken = data?['refreshToken'] as String?;
    if (newAccessToken == null) return null;

    await _tokenStorage.saveTokens(
      accessToken: newAccessToken,
      refreshToken: newRefreshToken ?? refreshToken,
    );
    return newAccessToken;
  }
}
