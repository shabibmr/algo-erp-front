import 'package:algo_erp_front/core/vouchers/stock/stock_voucher_dto.dart';
import 'package:algo_erp_front/core/vouchers/stock/stock_voucher_kind.dart';
import 'package:algo_erp_front/core/vouchers/stock/stock_voucher_models.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('listItemFromJson reads godown_tranfer_main typo nest', () {
    final item = StockVoucherDto.listItemFromJson({
      'id': 1,
      'voucher_prefix': 'GT',
      'voucher_no': '1',
      'voucher_date': '2025-09-01',
      'godown_tranfer_main': {
        'VoucherStatus': 'Posted',
        'Total': 100,
        'Billing_Name': 'A -> B',
      },
    }, mainNestKey: 'godown_tranfer_main');
    expect(item.billingName, 'A -> B');
    expect(item.total, Decimal.parse('100'));
  });

  test('draftToPostJson godown transfer shape', () {
    final draft = StockVoucherDraft(
      voucherPrefix: 'GT',
      voucherDate: DateTime(2025, 9, 1),
      financialYear: '2025',
      fromGodownId: 1,
      toGodownId: 2,
      lines: [
        StockVoucherLine(
          itemId: 9,
          quantity: Decimal.parse('3'),
          price: Decimal.parse('10'),
          adjValue: Decimal.parse('1'),
        ),
      ],
    );
    final json = StockVoucherDto.draftToPostJson(
      draft,
      kind: StockVoucherKinds.godownTransfer,
    );
    expect(json['from_godown_id'], 1);
    expect(json['to_godown_id'], 2);
    expect(json['lines'][0]['quantity'], 3);
    expect(json['lines'][0]['adj_value'], 1);
  });

  test('draftToPostJson material in cr/dr shape', () {
    final draft = StockVoucherDraft(
      voucherPrefix: 'MI',
      voucherDate: DateTime(2025, 9, 1),
      financialYear: '2025',
      godownId: 3,
      lines: [
        StockVoucherLine(
          itemId: 5,
          crQty: Decimal.parse('2'),
          price: Decimal.parse('4'),
        ),
      ],
    );
    final json = StockVoucherDto.draftToPostJson(
      draft,
      kind: StockVoucherKinds.materialIn,
    );
    expect(json['godown_id'], 3);
    expect(json['lines'][0]['crQty'], 2);
    expect(json['lines'][0]['Price'], 4);
  });

  test('draftToPostJson stock request inventory_item_id', () {
    final draft = StockVoucherDraft(
      voucherPrefix: 'SR',
      voucherDate: DateTime(2025, 9, 1),
      financialYear: '2025',
      fromGodownId: 1,
      toGodownId: 2,
      requirementVoucherNo: '0007',
      lines: [StockVoucherLine(itemId: 11, requestQty: Decimal.parse('8'))],
    );
    final json = StockVoucherDto.draftToPostJson(
      draft,
      kind: StockVoucherKinds.stockRequest,
    );
    expect(json['requirement_voucher_no'], '0007');
    expect(json['lines'][0]['inventory_item_id'], 11);
    expect(json['lines'][0]['request_qty'], 8);
  });

  test('draftToPostJson requirement has no godown', () {
    final draft = StockVoucherDraft(
      voucherPrefix: 'RQ',
      voucherDate: DateTime(2025, 9, 1),
      financialYear: '2025',
      lines: [
        StockVoucherLine(itemId: 1, quantity: Decimal.one, price: Decimal.zero),
      ],
    );
    final json = StockVoucherDto.draftToPostJson(
      draft,
      kind: StockVoucherKinds.requirement,
    );
    expect(json.containsKey('from_godown_id'), isFalse);
    expect(json['lines'][0]['item_id'], 1);
  });

  test('postResultFromJson allows missing total', () {
    final r = StockVoucherDto.postResultFromJson({
      'headerId': 44,
      'voucherNo': 'SR001',
    }, idKey: 'headerId');
    expect(r.id, 44);
    expect(r.total, isNull);
  });
}
