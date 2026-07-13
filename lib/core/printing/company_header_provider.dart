import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/network/tenant_context.dart';
import 'package:algo_erp_front/core/printing/voucher_pdf.dart';
import 'package:algo_erp_front/features/organization_company/data/company_profile_repository.dart';

/// Fetches the current tenant's company profile for the printed letterhead.
/// Returns null (letterhead omitted) if no company is selected or the fetch
/// fails — printing should never block on this.
Future<PdfCompanyHeader?> fetchCurrentCompanyHeader(
  DioClient client,
  TenantContext tenant,
) async {
  final companyId = tenant.companyId;
  if (companyId == null) return null;

  final result = await CompanyProfileRepository(client).getById(companyId);
  return result.fold((_) => null, (company) {
    final address = [
      company.building,
      company.street,
      company.addressLine,
      company.city,
      company.country,
    ].where((part) => part != null && part.isNotEmpty).join(', ');
    return PdfCompanyHeader(
      name: company.name ?? 'Company',
      trn: company.trn,
      address: address.isEmpty ? null : address,
    );
  });
}
