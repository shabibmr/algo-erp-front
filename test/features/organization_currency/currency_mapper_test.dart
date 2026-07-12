import 'package:algo_erp_front/features/organization_currency/data/currency_dto.dart';
import 'package:algo_erp_front/features/organization_currency/data/currency_mapper.dart';
import 'package:algo_erp_front/features/organization_currency/domain/currency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = CurrencyMapper();

  test("CurrencyDto.fromJson reads the backend's exact wire casing", () {
    final dto = CurrencyDto.fromJson(const {
      'id': 1,
      'iso_code': 'USD',
      'currency_name': 'US Dollar',
      'symbol': r'$',
      'decimal_places': 2,
      'is_base_currency': true,
      'is_active': false,
    });

    expect(dto.id, 1);
    expect(dto.isoCode, 'USD');
    expect(dto.currencyName, 'US Dollar');
    expect(dto.symbol, r'$');
    expect(dto.decimalPlaces, 2);
    expect(dto.isBaseCurrency, true);
    expect(dto.isActive, false);
  });

  test('CurrencyDto.fromJson applies defaults when optional fields absent', () {
    final dto = CurrencyDto.fromJson(const {
      'id': 1,
      'iso_code': 'INR',
      'currency_name': 'Indian Rupee',
    });

    expect(dto.symbol, isNull);
    expect(dto.decimalPlaces, 2);
    expect(dto.isBaseCurrency, false);
    expect(dto.isActive, true);
  });

  test('CurrencyMapper.toEntity maps dto fields to entity fields', () {
    const dto = CurrencyDto(
      id: 1,
      isoCode: 'USD',
      currencyName: 'US Dollar',
      symbol: r'$',
      isBaseCurrency: true,
      isActive: false,
    );

    expect(
      mapper.toEntity(dto),
      const Currency(
        id: 1,
        isoCode: 'USD',
        name: 'US Dollar',
        symbol: r'$',
        isBaseCurrency: true,
        isActive: false,
      ),
    );
  });

  test('CurrencyMapper.toDto round-trips back to the wire shape '
      '(omitting isActive)', () {
    const currency = Currency(
      id: 1,
      isoCode: 'USD',
      name: 'US Dollar',
      symbol: r'$',
      isBaseCurrency: true,
    );

    expect(mapper.toDto(currency).toJson(), {
      'iso_code': 'USD',
      'currency_name': 'US Dollar',
      'symbol': r'$',
      'decimal_places': 2,
      'is_base_currency': true,
    });
  });

  test('round-trip toEntity(toDto(x)) is identity', () {
    const currency = Currency(
      id: 5,
      isoCode: 'EUR',
      name: 'Euro',
      isActive: false,
    );
    expect(mapper.toEntity(mapper.toDto(currency)), currency);
  });
}
