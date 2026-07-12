import 'package:equatable/equatable.dart';

/// Wire shape of `/organization/currencies`, matching the backend
/// `currencymaster` table.
class CurrencyDto extends Equatable {
  const CurrencyDto({
    required this.id,
    required this.isoCode,
    required this.currencyName,
    this.symbol,
    this.decimalPlaces = 2,
    this.isBaseCurrency = false,
    this.isActive = true,
  });

  factory CurrencyDto.fromJson(Map<String, dynamic> json) => CurrencyDto(
    id: json['id'] as int,
    isoCode: json['iso_code'] as String,
    currencyName: json['currency_name'] as String,
    symbol: json['symbol'] as String?,
    decimalPlaces: json['decimal_places'] as int? ?? 2,
    isBaseCurrency: json['is_base_currency'] as bool? ?? false,
    isActive: json['is_active'] as bool? ?? true,
  );

  final int id;
  final String isoCode;
  final String currencyName;
  final String? symbol;
  final int decimalPlaces;
  final bool isBaseCurrency;
  final bool isActive;

  /// `id`/timestamps are server-generated and never sent on write. `is_active`
  /// is omitted: it is the soft-delete flag, owned by `DELETE`.
  Map<String, dynamic> toJson() => {
    'iso_code': isoCode,
    'currency_name': currencyName,
    'symbol': symbol,
    'decimal_places': decimalPlaces,
    'is_base_currency': isBaseCurrency,
  };

  @override
  List<Object?> get props => [
    id,
    isoCode,
    currencyName,
    symbol,
    decimalPlaces,
    isBaseCurrency,
    isActive,
  ];
}
