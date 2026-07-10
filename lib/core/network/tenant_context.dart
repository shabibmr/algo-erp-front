import 'package:injectable/injectable.dart';

/// Current tenant selection, mutated by auth/session (Step 8) on login and
/// company/branch switch. Read by TenantInterceptor on every request as
/// the `X-Company-Id`/`X-Branch-Id` fallback — the JWT claims still win
/// server-side (see docs/api-contract.md), this only covers requests where
/// the fallback header path applies.
@singleton
class TenantContext {
  int? companyId;
  int? branchId;

  void clear() {
    companyId = null;
    branchId = null;
  }
}
