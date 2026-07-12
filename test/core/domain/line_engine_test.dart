import 'package:algo_erp_front/core/domain/line_engine/line_engine.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Decimal d(String s) => Decimal.parse(s);

  group('LineEngine.roundMoney', () {
    test('half-up to 2 dp', () {
      expect(LineEngine.roundMoney(d('1.234')), d('1.23'));
      expect(LineEngine.roundMoney(d('1.235')), d('1.24'));
      expect(LineEngine.roundMoney(d('1.225')), d('1.23'));
    });
  });

  group('LineEngine.computeLine', () {
    test('qty × price, no discount/tax', () {
      final c = LineEngine.computeLine(
        LineInput(quantity: d('2'), price: d('10')),
      );
      expect(c.subtotal, d('20'));
      expect(c.discountAmount, Decimal.zero);
      expect(c.taxAmount, Decimal.zero);
      expect(c.lineTotal, d('20'));
    });

    test('matches backend discount then tax-on-net', () {
      // qty=3, price=100 → subtotal 300
      // disc 10% → 30.00
      // net 270, tax 5% → 13.50
      // line total 283.50
      final c = LineEngine.computeLine(
        LineInput(
          quantity: d('3'),
          price: d('100'),
          discountPercent: d('10'),
          taxRate: d('5'),
        ),
      );
      expect(c.subtotal, d('300'));
      expect(c.discountAmount, d('30'));
      expect(c.netAmount, d('270'));
      expect(c.taxAmount, d('13.5'));
      expect(c.lineTotal, d('283.5'));
    });

    test('rounds discount and tax to 2 dp independently', () {
      // subtotal 10.00, disc 33.33% → 3.333 → 3.33
      // net 6.67, tax 5% → 0.3335 → 0.33
      final c = LineEngine.computeLine(
        LineInput(
          quantity: d('1'),
          price: d('10'),
          discountPercent: d('33.33'),
          taxRate: d('5'),
        ),
      );
      expect(c.discountAmount, d('3.33'));
      expect(c.netAmount, d('6.67'));
      expect(c.taxAmount, d('0.33'));
    });
  });

  group('LineEngine.computeDocument', () {
    test('sums lines and rounds gross total', () {
      final totals = LineEngine.computeDocument([
        LineInput(
          quantity: d('2'),
          price: d('50'),
          discountPercent: d('0'),
          taxRate: d('5'),
        ),
        LineInput(
          quantity: d('1'),
          price: d('20'),
          discountPercent: d('10'),
          taxRate: d('0'),
        ),
      ]);
      // line1: sub 100, disc 0, tax 5 → net 100
      // line2: sub 20, disc 2, tax 0 → net 18
      expect(totals.subtotal, d('120'));
      expect(totals.discount, d('2'));
      expect(totals.tax, d('5'));
      expect(totals.total, d('123'));
      expect(totals.lines, hasLength(2));
    });
  });
}
