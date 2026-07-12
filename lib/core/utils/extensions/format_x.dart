import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

/// Money/quantity formatting for **display only**. The underlying value stays a
/// [Decimal] everywhere in the domain (never `double`); `toDouble()` is used
/// solely to drive `intl`'s grouping/locale formatting of the shown string —
/// it is never fed back into a calculation.
extension DecimalFormatX on Decimal {
  /// e.g. `AED 1,234.50`. Default UAE currency + 2 dp.
  String toMoney({String symbol = 'AED ', int decimalDigits = 2}) {
    return NumberFormat.currency(
      symbol: symbol,
      decimalDigits: decimalDigits,
    ).format(toDouble());
  }

  /// Grouped number without a currency symbol, e.g. `1,234.5`.
  String toQuantity({int maxDecimals = 3}) {
    return NumberFormat.decimalPatternDigits(
      decimalDigits: maxDecimals,
    ).format(toDouble());
  }

  /// The exact, loss-free string — use this for anything sent back to the API.
  String get exact => toString();
}

extension DateTimeFormatX on DateTime {
  /// Locale-independent day format, e.g. `07/11/2026`.
  String toDayString([String pattern = 'dd/MM/yyyy']) =>
      DateFormat(pattern).format(this);

  /// Day + time, e.g. `07/11/2026 14:05`.
  String toDateTimeString([String pattern = 'dd/MM/yyyy HH:mm']) =>
      DateFormat(pattern).format(this);
}
