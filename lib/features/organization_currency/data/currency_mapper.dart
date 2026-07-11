import 'package:algo_erp_front/core/data/mapper.dart';
import 'package:algo_erp_front/features/organization_currency/data/currency_dto.dart';
import 'package:algo_erp_front/features/organization_currency/domain/currency.dart';

class CurrencyMapper implements Mapper<CurrencyDto, Currency> {
  const CurrencyMapper();

  @override
  Currency toEntity(CurrencyDto dto) => Currency(
        id: dto.id,
        isoCode: dto.isoCode,
        name: dto.currencyName,
        symbol: dto.symbol,
        decimalPlaces: dto.decimalPlaces,
        isBaseCurrency: dto.isBaseCurrency,
        isActive: dto.isActive,
      );

  @override
  CurrencyDto toDto(Currency entity) => CurrencyDto(
        id: entity.id,
        isoCode: entity.isoCode,
        currencyName: entity.name,
        symbol: entity.symbol,
        decimalPlaces: entity.decimalPlaces,
        isBaseCurrency: entity.isBaseCurrency,
        isActive: entity.isActive,
      );
}
