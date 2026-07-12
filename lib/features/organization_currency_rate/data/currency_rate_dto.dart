import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

/// Wire shape of `/organization/rates` / `currencyrates`.
class CurrencyRateDto extends Equatable {
  const CurrencyRateDto({
    required this.id,
    required this.currencyId,
    required this.rateDate,
    required this.buyRate,
    required this.sellRate,
    this.midRate,
    this.financialYearId,
  });

  factory CurrencyRateDto.fromJson(Map<String, dynamic> json) =>
      CurrencyRateDto(
        id: json['id'] as int,
        currencyId: json['currency_id'] as int,
        rateDate: _dateOnly(json['rate_date']) ?? '',
        buyRate: Decimal.parse(json['buy_rate'].toString()),
        sellRate: Decimal.parse(json['sell_rate'].toString()),
        midRate: json['mid_rate'] == null
            ? null
            : Decimal.parse(json['mid_rate'].toString()),
        financialYearId: json['financial_year_id'] as int?,
      );

  final int id;
  final int currencyId;
  final String rateDate;
  final Decimal buyRate;
  final Decimal sellRate;
  final Decimal? midRate;
  final int? financialYearId;

  Map<String, dynamic> toJson() => {
    'currency_id': currencyId,
    'rate_date': rateDate,
    'buy_rate': buyRate.toDouble(),
    'sell_rate': sellRate.toDouble(),
    if (midRate != null) 'mid_rate': midRate!.toDouble(),
    if (financialYearId != null) 'financial_year_id': financialYearId,
  };

  static String? _dateOnly(Object? raw) {
    if (raw == null) return null;
    final s = raw.toString();
    if (s.length >= 10) return s.substring(0, 10);
    return s.isEmpty ? null : s;
  }

  @override
  List<Object?> get props => [
    id,
    currencyId,
    rateDate,
    buyRate,
    sellRate,
    midRate,
    financialYearId,
  ];
}
