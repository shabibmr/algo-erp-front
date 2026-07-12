import 'package:equatable/equatable.dart';

const _unset = Object();

/// The Currency master entity — soft-deleted (`CurrencyRepository` sets
/// `softDeleteField: 'is_active'`).
///
/// [isoCode] is exactly 3 characters (`currencySchema`'s `z.string().length(3)`).
class Currency extends Equatable {
  const Currency({
    required this.id,
    required this.isoCode,
    required this.name,
    this.symbol,
    this.decimalPlaces = 2,
    this.isBaseCurrency = false,
    this.isActive = true,
  });

  final int id;
  final String isoCode;
  final String name;
  final String? symbol;
  final int decimalPlaces;
  final bool isBaseCurrency;
  final bool isActive;

  Currency copyWith({
    int? id,
    String? isoCode,
    String? name,
    Object? symbol = _unset,
    int? decimalPlaces,
    bool? isBaseCurrency,
    bool? isActive,
  }) => Currency(
    id: id ?? this.id,
    isoCode: isoCode ?? this.isoCode,
    name: name ?? this.name,
    symbol: identical(symbol, _unset) ? this.symbol : symbol as String?,
    decimalPlaces: decimalPlaces ?? this.decimalPlaces,
    isBaseCurrency: isBaseCurrency ?? this.isBaseCurrency,
    isActive: isActive ?? this.isActive,
  );

  @override
  List<Object?> get props => [
    id,
    isoCode,
    name,
    symbol,
    decimalPlaces,
    isBaseCurrency,
    isActive,
  ];
}
