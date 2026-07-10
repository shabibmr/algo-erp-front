import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

/// Attaches a fresh `X-Request-Id` to every outgoing request so it can be
/// correlated with backend logs. The server only echoes this back — it does
/// not (yet) use it for idempotency (see CR-004).
class RequestIdInterceptor extends Interceptor {
  const RequestIdInterceptor();

  static const _uuid = Uuid();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['X-Request-Id'] = _uuid.v4();
    handler.next(options);
  }
}
