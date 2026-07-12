import 'package:algo_erp_front/core/vouchers/ledger_amount/ledger_amount_dto.dart';
import 'package:algo_erp_front/core/vouchers/ledger_amount/ledger_amount_models.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('listItemFromJson reads nested payment main', () {
    final item = LedgerAmountDto.listItemFromJson({
      'id': 3,
      'voucher_prefix': 'PV',
      'voucher_no': '00001',
      'voucher_date': '2025-07-01',
      'payment_voucher_main': {
        'VoucherStatus': 'Posted',
        'Total': 250.5,
        'Narration': 'Supplier pay',
      },
    }, mainNestKey: 'payment_voucher_main');
    expect(item.id, 3);
    expect(item.status, 'Posted');
    expect(item.total, Decimal.parse('250.5'));
    expect(item.narration, 'Supplier pay');
  });

  test('draftToPostJson maps cash bank and ledger lines', () {
    final draft = LedgerAmountDraft(
      voucherPrefix: 'PV',
      voucherDate: DateTime(2025, 7, 1),
      financialYear: '2025',
      cashBankLedgerId: 10,
      narration: 'July pay',
      lines: [
        LedgerAmountLine(
          ledgerId: 20,
          amount: Decimal.parse('100'),
          narration: 'Inv 1',
        ),
        LedgerAmountLine(), // incomplete
      ],
    );
    final json = LedgerAmountDto.draftToPostJson(draft);
    expect(json['voucher_date'], '2025-07-01');
    expect(json['cash_bank_ledger_id'], 10);
    expect(json['narration'], 'July pay');
    expect(json['lines'], hasLength(1));
    expect(json['lines'][0]['ledger_id'], 20);
    expect(json['lines'][0]['amount'], 100);
  });

  test('detailFromJson reads lines with voucher_ledger_id', () {
    final detail = LedgerAmountDto.detailFromJson({
      'id': 5,
      'VoucherStatus': 'Posted',
      'voucher_ledger_id': 10,
      'Total': 50,
      'Narration': 'Pay',
      'voucher_headers': {
        'voucher_prefix': 'PV',
        'voucher_no': '00005',
        'voucher_date': '2025-07-02',
      },
      'details': [
        {'id': 1, 'voucher_ledger_id': 20, 'Amount': 50, 'Narration': 'line'},
      ],
    });
    expect(detail.id, 5);
    expect(detail.cashBankLedgerId, 10);
    expect(detail.lines, hasLength(1));
    expect(detail.lines.first.ledgerId, 20);
    expect(detail.lines.first.amount, Decimal.parse('50'));
  });
}
