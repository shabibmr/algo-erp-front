import 'package:equatable/equatable.dart';

const _unset = Object();

/// The UOM (unit of measure) master entity — hard-deleted (no `is_active`
/// column on the backend `uomlist` table).
class Uom extends Equatable {
  const Uom({
    required this.id,
    required this.name,
    this.code,
    this.decimalPlaces = 0,
    this.symbol,
    this.isComposite = false,
  });

  final int id;
  final String name;
  final String? code;
  final int decimalPlaces;
  final String? symbol;
  final bool isComposite;

  Uom copyWith({
    int? id,
    String? name,
    Object? code = _unset,
    int? decimalPlaces,
    Object? symbol = _unset,
    bool? isComposite,
  }) => Uom(
    id: id ?? this.id,
    name: name ?? this.name,
    code: identical(code, _unset) ? this.code : code as String?,
    decimalPlaces: decimalPlaces ?? this.decimalPlaces,
    symbol: identical(symbol, _unset) ? this.symbol : symbol as String?,
    isComposite: isComposite ?? this.isComposite,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    code,
    decimalPlaces,
    symbol,
    isComposite,
  ];
}
