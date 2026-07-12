import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

const _unset = Object();

/// Daily FX rate — append-only (create + list/view; no update/delete API).
class CurrencyRate extends Equatable {
  const CurrencyRate({
    required this.id,
    required this.currencyId,
    required this.rateDate,
    required this.buyRate,
    required this.sellRate,
    this.midRate,
    this.financialYearId,
  });

  final int id;
  final int currencyId;

  /// `YYYY-MM-DD` (schema regex).
  final String rateDate;
  final Decimal buyRate;
  final Decimal sellRate;
  final Decimal? midRate;
  final int? financialYearId;

  CurrencyRate copyWith({
    int? id,
    int? currencyId,
    String? rateDate,
    Decimal? buyRate,
    Decimal? sellRate,
    Object? midRate = _unset,
    Object? financialYearId = _unset,
  }) => CurrencyRate(
    id: id ?? this.id,
    currencyId: currencyId ?? this.currencyId,
    rateDate: rateDate ?? this.rateDate,
    buyRate: buyRate ?? this.buyRate,
    sellRate: sellRate ?? this.sellRate,
    midRate: identical(midRate, _unset) ? this.midRate : midRate as Decimal?,
    financialYearId: identical(financialYearId, _unset)
        ? this.financialYearId
        : financialYearId as int?,
  );

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
