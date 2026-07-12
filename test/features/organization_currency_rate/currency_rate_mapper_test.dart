import 'package:algo_erp_front/features/organization_currency_rate/data/currency_rate_dto.dart';
import 'package:algo_erp_front/features/organization_currency_rate/data/currency_rate_mapper.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = CurrencyRateMapper();

  test('CurrencyRateDto.fromJson parses decimal rates and date', () {
    final dto = CurrencyRateDto.fromJson(const {
      'id': 1,
      'currency_id': 2,
      'rate_date': '2026-03-01T00:00:00.000Z',
      'buy_rate': '3.670000',
      'sell_rate': '3.680000',
      'mid_rate': '3.675000',
    });

    expect(dto.currencyId, 2);
    expect(dto.rateDate, '2026-03-01');
    expect(dto.buyRate, Decimal.parse('3.670000'));
    expect(dto.sellRate, Decimal.parse('3.680000'));
    expect(dto.midRate, Decimal.parse('3.675000'));
  });

  test('toJson sends numeric rates for Zod number schema', () {
    final dto = CurrencyRateDto(
      id: 0,
      currencyId: 2,
      rateDate: '2026-03-01',
      buyRate: Decimal.parse('3.67'),
      sellRate: Decimal.parse('3.68'),
    );

    expect(mapper.toDto(mapper.toEntity(dto)).toJson(), {
      'currency_id': 2,
      'rate_date': '2026-03-01',
      'buy_rate': 3.67,
      'sell_rate': 3.68,
    });
  });
}
