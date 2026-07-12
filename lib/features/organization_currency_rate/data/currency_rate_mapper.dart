import 'package:algo_erp_front/core/data/mapper.dart';
import 'package:algo_erp_front/features/organization_currency_rate/data/currency_rate_dto.dart';
import 'package:algo_erp_front/features/organization_currency_rate/domain/currency_rate.dart';

class CurrencyRateMapper implements Mapper<CurrencyRateDto, CurrencyRate> {
  const CurrencyRateMapper();

  @override
  CurrencyRate toEntity(CurrencyRateDto dto) => CurrencyRate(
    id: dto.id,
    currencyId: dto.currencyId,
    rateDate: dto.rateDate,
    buyRate: dto.buyRate,
    sellRate: dto.sellRate,
    midRate: dto.midRate,
    financialYearId: dto.financialYearId,
  );

  @override
  CurrencyRateDto toDto(CurrencyRate entity) => CurrencyRateDto(
    id: entity.id,
    currencyId: entity.currencyId,
    rateDate: entity.rateDate,
    buyRate: entity.buyRate,
    sellRate: entity.sellRate,
    midRate: entity.midRate,
    financialYearId: entity.financialYearId,
  );
}
