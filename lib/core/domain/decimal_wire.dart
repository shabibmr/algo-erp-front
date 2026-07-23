import 'package:decimal/decimal.dart';

/// Converts domain [Decimal] values to JSON numbers for the REST API.
///
/// Prefer this over `double.tryParse(d.toString())` — one allocation path,
/// shared by all voucher DTOs.
double decimalToWire(Decimal value) => value.toDouble();

double? decimalToWireOrNull(Decimal? value) => value?.toDouble();
