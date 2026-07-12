import 'package:algo_erp_front/core/data/mapper.dart';
import 'package:algo_erp_front/features/organization_financial_year/data/financial_year_dto.dart';
import 'package:algo_erp_front/features/organization_financial_year/domain/financial_year.dart';

class FinancialYearMapper implements Mapper<FinancialYearDto, FinancialYear> {
  const FinancialYearMapper();

  @override
  FinancialYear toEntity(FinancialYearDto dto) => FinancialYear(
    id: dto.id,
    fyCode: dto.fyCode,
    displayName: dto.displayName,
    startDate: dto.startDate,
    endDate: dto.endDate,
    companyId: dto.companyId,
    status: dto.status,
    isDefault: dto.isDefault,
  );

  @override
  FinancialYearDto toDto(FinancialYear entity) => FinancialYearDto(
    id: entity.id,
    fyCode: entity.fyCode,
    displayName: entity.displayName,
    startDate: entity.startDate,
    endDate: entity.endDate,
    companyId: entity.companyId,
    status: entity.status,
    isDefault: entity.isDefault,
  );
}
