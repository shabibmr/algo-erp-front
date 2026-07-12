import 'package:algo_erp_front/core/auth/token_storage.dart';
import 'package:algo_erp_front/core/config/app_config.dart';
import 'package:algo_erp_front/core/network/interceptors/auth_interceptor.dart';
import 'package:algo_erp_front/core/network/interceptors/request_id_interceptor.dart';
import 'package:algo_erp_front/core/network/interceptors/tenant_interceptor.dart';
import 'package:algo_erp_front/core/network/tenant_context.dart';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:injectable/injectable.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

@lazySingleton
class DioClient {
  DioClient(this._tokenStorage, this._tenantContext);

  final TokenStorage _tokenStorage;
  final TenantContext _tenantContext;

  late final Dio dio = _build();

  Dio _build() {
    final baseOptions = BaseOptions(
      baseUrl: AppConfig.instance.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
    );

    final client = Dio(baseOptions);
    // No interceptors: used only for the refresh call itself and for
    // replaying a request after refresh, so it never recurses back into
    // AuthInterceptor.
    final refreshClient = Dio(baseOptions);

    client.interceptors.addAll([
      const RequestIdInterceptor(),
      TenantInterceptor(_tenantContext),
      AuthInterceptor(_tokenStorage, refreshClient),
      RetryInterceptor(
        dio: client,
        retries: 2,
        retryDelays: const [Duration(milliseconds: 500), Duration(seconds: 1)],
      ),
      if (!AppConfig.instance.isProd)
        PrettyDioLogger(requestHeader: true, requestBody: true),
    ]);
    return client;
  }
}
