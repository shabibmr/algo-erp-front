import 'package:algo_erp_front/features/organization_financial_year/data/financial_year_dto.dart';
import 'package:algo_erp_front/features/organization_financial_year/data/financial_year_mapper.dart';
import 'package:algo_erp_front/features/organization_financial_year/domain/financial_year.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = FinancialYearMapper();

  test("FinancialYearDto.fromJson reads the backend's exact wire casing", () {
    final dto = FinancialYearDto.fromJson(const {
      'id': 1,
      'fy_code': 'FY2526',
      'display_name': 'FY 2025-26',
      'start_date': '2025-04-01T00:00:00.000Z',
      'end_date': '2026-03-31T00:00:00.000Z',
      'company_id': 1,
      'status': 'Open',
      'is_default': true,
    });

    expect(dto.id, 1);
    expect(dto.fyCode, 'FY2526');
    expect(dto.displayName, 'FY 2025-26');
    expect(dto.startDate, '2025-04-01');
    expect(dto.endDate, '2026-03-31');
    expect(dto.companyId, 1);
    expect(dto.status, 'Open');
    expect(dto.isDefault, true);
  });

  test('FinancialYearDto.fromJson applies defaults when optional fields '
      'absent', () {
    final dto = FinancialYearDto.fromJson(const {
      'id': 1,
      'fy_code': 'FY2526',
      'display_name': 'FY 2025-26',
      'start_date': '2025-04-01',
      'end_date': '2026-03-31',
      'company_id': 1,
    });

    expect(dto.status, 'Open');
    expect(dto.isDefault, false);
  });

  test('FinancialYearMapper.toEntity maps dto fields to entity fields', () {
    const dto = FinancialYearDto(
      id: 1,
      fyCode: 'FY2526',
      displayName: 'FY 2025-26',
      startDate: '2025-04-01',
      endDate: '2026-03-31',
      companyId: 1,
      status: 'Locked',
      isDefault: true,
    );

    expect(
      mapper.toEntity(dto),
      const FinancialYear(
        id: 1,
        fyCode: 'FY2526',
        displayName: 'FY 2025-26',
        startDate: '2025-04-01',
        endDate: '2026-03-31',
        companyId: 1,
        status: 'Locked',
        isDefault: true,
      ),
    );
  });

  test('FinancialYearMapper.toDto round-trips back to the wire shape', () {
    const fy = FinancialYear(
      id: 1,
      fyCode: 'FY2526',
      displayName: 'FY 2025-26',
      startDate: '2025-04-01',
      endDate: '2026-03-31',
      companyId: 1,
    );

    expect(mapper.toDto(fy).toJson(), {
      'fy_code': 'FY2526',
      'display_name': 'FY 2025-26',
      'start_date': '2025-04-01',
      'end_date': '2026-03-31',
      'company_id': 1,
      'status': 'Open',
      'is_default': false,
    });
  });

  test('round-trip toEntity(toDto(x)) is identity', () {
    const fy = FinancialYear(
      id: 5,
      fyCode: 'FY2627',
      displayName: 'FY 2026-27',
      startDate: '2026-04-01',
      endDate: '2027-03-31',
      companyId: 2,
      status: 'Closed',
    );
    expect(mapper.toEntity(mapper.toDto(fy)), fy);
  });
}
