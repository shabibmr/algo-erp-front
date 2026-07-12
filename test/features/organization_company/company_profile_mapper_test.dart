import 'package:algo_erp_front/features/organization_company/data/company_profile_dto.dart';
import 'package:algo_erp_front/features/organization_company/data/company_profile_mapper.dart';
import 'package:algo_erp_front/features/organization_company/domain/company_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = CompanyProfileMapper();

  test("fromJson reads Prisma PascalCase columns", () {
    final dto = CompanyProfileDto.fromJson(const {
      'id': 1,
      'Company_Name': 'Algo Trading LLC',
      'Branch': 'HQ',
      'TRN': '100',
      'City': 'Dubai',
      'Currency': 'AED',
      'Currency_Decimal': 2,
      'WebSite': 'https://example.com',
      'Email': 'ops@example.com',
    });

    expect(dto.companyName, 'Algo Trading LLC');
    expect(dto.branch, 'HQ');
    expect(dto.website, 'https://example.com');
    expect(
      mapper.toEntity(dto),
      const CompanyProfile(
        id: 1,
        name: 'Algo Trading LLC',
        branch: 'HQ',
        trn: '100',
        city: 'Dubai',
        currency: 'AED',
        currencyDecimal: 2,
        website: 'https://example.com',
        email: 'ops@example.com',
      ),
    );
  });

  test('toJson uses snake_case write keys and omits empty email/website', () {
    const entity = CompanyProfile(
      id: 1,
      name: 'Acme',
      email: '',
      website: '',
      currencyDecimal: 3,
    );

    expect(mapper.toDto(entity).toJson(), {
      'company_name': 'Acme',
      'currency_decimal': 3,
    });
  });
}
