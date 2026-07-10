import 'package:algo_erp_front/core/network/tenant_context.dart';
import 'package:dio/dio.dart';

/// Injects `X-Company-Id`/`X-Branch-Id` when the client has a selected
/// tenant. Fallback only — the backend prefers JWT claims when present
/// (see docs/api-contract.md, tenancy resolution).
class TenantInterceptor extends Interceptor {
  TenantInterceptor(this._tenantContext);

  final TenantContext _tenantContext;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final companyId = _tenantContext.companyId;
    final branchId = _tenantContext.branchId;
    if (companyId != null) {
      options.headers['X-Company-Id'] = companyId.toString();
    }
    if (branchId != null) {
      options.headers['X-Branch-Id'] = branchId.toString();
    }
    handler.next(options);
  }
}
