import 'package:algo_erp_front/core/vouchers/item_qty/item_qty_dto.dart';
import 'package:algo_erp_front/core/vouchers/item_qty/item_qty_kind.dart';
import 'package:algo_erp_front/core/vouchers/item_qty/item_qty_models.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('listItemFromJson reads nested main key', () {
    final item = ItemQtyDto.listItemFromJson({
      'id': 9,
      'voucher_prefix': 'QT',
      'voucher_no': '00012',
      'voucher_date': '2025-06-01',
      'quotation_main': {
        'VoucherStatus': 'Draft',
        'Total': 123.5,
        'Billing_Name': 'Acme',
      },
    }, mainNestKey: 'quotation_main');
    expect(item.id, 9);
    expect(item.voucherPrefix, 'QT');
    expect(item.voucherNo, '00012');
    expect(item.status, 'Draft');
    expect(item.total, Decimal.parse('123.5'));
    expect(item.billingName, 'Acme');
  });

  test('draftToPostJson uses customer field for quotation', () {
    final draft = ItemQtyDraft(
      voucherPrefix: 'QT',
      voucherDate: DateTime(2025, 4, 1),
      financialYear: '2025',
      partyLedgerId: 3,
      lines: [
        ItemQtyLine(
          itemId: 10,
          quantity: Decimal.parse('2'),
          price: Decimal.parse('50'),
          discountPercent: Decimal.parse('10'),
          taxRate: Decimal.parse('5'),
        ),
        ItemQtyLine(),
      ],
    );
    final json = ItemQtyDto.draftToPostJson(
      draft,
      kind: ItemQtyKinds.quotation,
    );
    expect(json['voucher_date'], '2025-04-01');
    expect(json['customer_ledger_id'], 3);
    expect(json.containsKey('godown_id'), isFalse);
    expect(json['lines'], hasLength(1));
    expect(json['lines'][0]['item_id'], 10);
  });

  test('draftToPostJson uses supplier + godown for purchase order', () {
    final draft = ItemQtyDraft(
      voucherPrefix: 'PO',
      voucherDate: DateTime(2025, 4, 1),
      financialYear: '2025',
      partyLedgerId: 8,
      godownId: 2,
      lines: [
        ItemQtyLine(
          itemId: 1,
          quantity: Decimal.one,
          price: Decimal.parse('10'),
        ),
      ],
    );
    final json = ItemQtyDto.draftToPostJson(
      draft,
      kind: ItemQtyKinds.purchaseOrder,
    );
    expect(json['supplier_ledger_id'], 8);
    expect(json['godown_id'], 2);
    expect(json.containsKey('customer_ledger_id'), isFalse);
  });

  test('draftToPostJson includes source for delivery note', () {
    final draft = ItemQtyDraft(
      voucherPrefix: 'DN',
      voucherDate: DateTime(2025, 4, 1),
      financialYear: '2025',
      partyLedgerId: 3,
      godownId: 1,
      sourceVoucherId: 99,
      lines: [
        ItemQtyLine(
          itemId: 1,
          quantity: Decimal.one,
          price: Decimal.parse('10'),
          sourceLineId: 5,
        ),
      ],
    );
    final json = ItemQtyDto.draftToPostJson(
      draft,
      kind: ItemQtyKinds.deliveryNote,
    );
    expect(json['source_voucher_id'], 99);
    expect(json['lines'][0]['source_line_id'], 5);
  });

  test('postResultFromJson accepts headerId or id', () {
    final a = ItemQtyDto.postResultFromJson({
      'headerId': 11,
      'voucherNo': 'QT001',
      'total': 50,
    }, idKey: 'headerId');
    expect(a.id, 11);
    expect(a.voucherNo, 'QT001');

    final b = ItemQtyDto.postResultFromJson({
      'id': 22,
      'voucherNo': 'PI001',
      'total': 99,
    }, idKey: 'id');
    expect(b.id, 22);
  });

  test('draftToPostJson uses ledger_id for credit note', () {
    final draft = ItemQtyDraft(
      voucherPrefix: 'CN',
      voucherDate: DateTime(2025, 4, 1),
      financialYear: '2025',
      partyLedgerId: 4,
      godownId: 1,
      lines: [
        ItemQtyLine(
          itemId: 2,
          quantity: Decimal.one,
          price: Decimal.parse('20'),
        ),
      ],
    );
    final json = ItemQtyDto.draftToPostJson(
      draft,
      kind: ItemQtyKinds.creditNote,
    );
    expect(json['ledger_id'], 4);
    expect(json['godown_id'], 1);
    expect(json.containsKey('customer_ledger_id'), isFalse);
  });

  test('detailFromJson reads main + headers + details', () {
    final detail = ItemQtyDto.detailFromJson({
      'id': 42,
      'VoucherStatus': 'Draft',
      'Billing_Name': 'Acme LLC',
      'voucher_ledger_id': 7,
      'godown_id': 2,
      'Total': 100,
      'Gross_Total': 105,
      'Discount_in_Amount': 0,
      'Vat_Amount': 5,
      'Voucher_No_Display': 'SO/00042',
      'voucher_headers': {
        'voucher_prefix': 'SO',
        'voucher_no': '00042',
        'voucher_date': '2025-06-15',
      },
      'details': [
        {
          'id': 1,
          'item_id': 9,
          'Quantity': 2,
          'Price': 50,
          'Discount_Percent': 0,
          'Tax_Rate': 5,
        },
      ],
    });
    expect(detail.id, 42);
    expect(detail.displayNo, 'SO00042');
    expect(detail.partyLedgerId, 7);
    expect(detail.lines, hasLength(1));
    expect(detail.lines.first.itemId, 9);
  });

  test('salesInvoice kind posts status salesperson and source type', () {
    final draft = ItemQtyDraft(
      voucherPrefix: 'SI',
      voucherDate: DateTime(2025, 4, 1),
      financialYear: '2025-26',
      partyLedgerId: 3,
      godownId: 1,
      salespersonEmployeeId: 8,
      voucherProjectId: 4,
      sourceVoucherId: 99,
      sourceVoucherType: 'SalesOrder',
      saveStatus: 'Draft',
      lines: [
        ItemQtyLine(
          itemId: 10,
          quantity: Decimal.one,
          price: Decimal.parse('10'),
          uid: 1,
        ),
      ],
    );
    final json = ItemQtyDto.draftToPostJson(
      draft,
      kind: ItemQtyKinds.salesInvoice,
    );
    expect(json['customer_ledger_id'], 3);
    expect(json['status'], 'Draft');
    expect(json['salesperson_employee_id'], 8);
    expect(json['voucher_project_id'], 4);
    expect(json['source_voucher_type'], 'SalesOrder');
  });

  test('draftToEditJson uses LineEngine totals', () {
    final draft = ItemQtyDraft(
      partyLedgerId: 3,
      godownId: 1,
      lines: [
        ItemQtyLine(
          itemId: 10,
          quantity: Decimal.parse('2'),
          price: Decimal.parse('50'),
          discountPercent: Decimal.parse('10'),
          taxRate: Decimal.parse('5'),
        ),
      ],
    );
    final json = ItemQtyDto.draftToEditJson(draft);
    expect(json['header']['voucher_ledger_id'], 3);
    expect(json['lines'][0]['Discount_Amount'], 10);
    expect(json['lines'][0]['Tax_Amount'], 4.5);
  });

  test('ItemQtyLine uid is stable across copyWith', () {
    final line = ItemQtyLine(itemId: 1, uid: 42);
    expect(line.copyWith(itemLabel: 'x').uid, 42);
  });
}
