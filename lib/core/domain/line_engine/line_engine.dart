import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

/// Pure-Dart money math for voucher lines. Mirrors backend
/// `voucherPosting.service.ts` (qty×price, % discount, tax on net).
///
/// Never uses `double` for intermediate values. Rounding is half-up to
/// 2 decimal places by default, matching Prisma `toDecimalPlaces(2)`.
abstract final class LineEngine {
  static final Decimal _hundred = Decimal.fromInt(100);

  /// Half-up money round (default 2 dp).
  static Decimal roundMoney(Decimal value, [int places = 2]) {
    if (places < 0) {
      throw ArgumentError.value(places, 'places', 'must be >= 0');
    }
    var factor = Decimal.one;
    for (var i = 0; i < places; i++) {
      factor *= Decimal.fromInt(10);
    }
    return ((value * factor).round() / factor).toDecimal();
  }

  /// Gross line amount before discount: `qty × price` (unrounded product;
  /// backend stores this as Subtotal before rounding discount/tax).
  static Decimal lineSubtotal({
    required Decimal quantity,
    required Decimal price,
  }) => quantity * price;

  /// Discount amount: round(`subtotal × discountPercent / 100`, 2).
  static Decimal lineDiscount({
    required Decimal subtotal,
    required Decimal discountPercent,
  }) {
    if (discountPercent == Decimal.zero) return Decimal.zero;
    return roundMoney(subtotal * (discountPercent / _hundred).toDecimal());
  }

  /// Tax amount: round(`net × taxRate / 100`, 2) where net = subtotal − discount.
  static Decimal lineTax({
    required Decimal netAmount,
    required Decimal taxRate,
  }) {
    if (taxRate == Decimal.zero) return Decimal.zero;
    return roundMoney(netAmount * (taxRate / _hundred).toDecimal());
  }

  /// Full per-line breakdown.
  static LineComputation computeLine(LineInput input) {
    final subtotal = lineSubtotal(quantity: input.quantity, price: input.price);
    final discount = lineDiscount(
      subtotal: subtotal,
      discountPercent: input.discountPercent,
    );
    final net = subtotal - discount;
    final tax = lineTax(netAmount: net, taxRate: input.taxRate);
    final total = net + tax;
    return LineComputation(
      subtotal: subtotal,
      discountAmount: discount,
      netAmount: net,
      taxAmount: tax,
      lineTotal: total,
    );
  }

  /// Document totals from many lines (matches SI posting sums).
  static DocumentTotals computeDocument(Iterable<LineInput> lines) {
    var subtotalSum = Decimal.zero;
    var discountSum = Decimal.zero;
    var taxSum = Decimal.zero;
    final computed = <LineComputation>[];

    for (final line in lines) {
      final c = computeLine(line);
      computed.add(c);
      subtotalSum += c.subtotal;
      discountSum += c.discountAmount;
      taxSum += c.taxAmount;
    }

    // Backend: grossTotal = round(subtotal - discount + tax, 2)
    final gross = roundMoney(subtotalSum - discountSum + taxSum);
    return DocumentTotals(
      lines: computed,
      subtotal: subtotalSum,
      discount: discountSum,
      tax: taxSum,
      total: gross,
    );
  }
}

/// Input quantities for one item-qty line (Sales Invoice shape).
class LineInput extends Equatable {
  LineInput({
    required this.quantity,
    required this.price,
    Decimal? discountPercent,
    Decimal? taxRate,
  }) : discountPercent = discountPercent ?? Decimal.zero,
       taxRate = taxRate ?? Decimal.zero;

  final Decimal quantity;
  final Decimal price;
  final Decimal discountPercent;
  final Decimal taxRate;

  @override
  List<Object?> get props => [quantity, price, discountPercent, taxRate];
}

/// Computed amounts for one line.
class LineComputation extends Equatable {
  const LineComputation({
    required this.subtotal,
    required this.discountAmount,
    required this.netAmount,
    required this.taxAmount,
    required this.lineTotal,
  });

  final Decimal subtotal;
  final Decimal discountAmount;
  final Decimal netAmount;
  final Decimal taxAmount;
  final Decimal lineTotal;

  @override
  List<Object?> get props => [
    subtotal,
    discountAmount,
    netAmount,
    taxAmount,
    lineTotal,
  ];
}

/// Aggregated document totals.
class DocumentTotals extends Equatable {
  const DocumentTotals({
    required this.lines,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
  });

  final List<LineComputation> lines;
  final Decimal subtotal;
  final Decimal discount;
  final Decimal tax;
  final Decimal total;

  @override
  List<Object?> get props => [lines, subtotal, discount, tax, total];
}
