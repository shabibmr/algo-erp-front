import 'package:algo_erp_front/core/vouchers/debit_credit/debit_credit_dto.dart';
import 'package:algo_erp_front/core/vouchers/debit_credit/debit_credit_kind.dart';
import 'package:algo_erp_front/core/vouchers/debit_credit/debit_credit_models.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('listItemFromJson reads journal main nest', () {
    final item = DebitCreditDto.listItemFromJson({
      'id': 1,
      'voucher_prefix': 'JV',
      'voucher_no': '0001',
      'voucher_date': '2025-08-01',
      'journal_voucher_main': {
        'VoucherStatus': 'Posted',
        'Total': 500,
        'Narration': 'Adjust',
      },
    }, mainNestKey: 'journal_voucher_main');
    expect(item.id, 1);
    expect(item.total, Decimal.parse('500'));
    expect(item.status, 'Posted');
  });

  test('draftToPostJson journal uses debit_amount and credit_amount', () {
    final draft = DebitCreditDraft(
      voucherPrefix: 'JV',
      voucherDate: DateTime(2025, 8, 1),
      financialYear: '2025',
      lines: [
        DebitCreditLine(ledgerId: 1, debit: Decimal.parse('100')),
        DebitCreditLine(ledgerId: 2, credit: Decimal.parse('100')),
        DebitCreditLine(), // incomplete
      ],
    );
    final json = DebitCreditDto.draftToPostJson(
      draft,
      kind: DebitCreditKinds.journal,
    );
    expect(json['lines'], hasLength(2));
    expect(json['lines'][0]['debit_amount'], 100);
    expect(json['lines'][0]['credit_amount'], 0);
    expect(json['lines'][1]['credit_amount'], 100);
  });

  test('draftToPostJson contra uses amount and type', () {
    final draft = DebitCreditDraft(
      voucherPrefix: 'CV',
      voucherDate: DateTime(2025, 8, 1),
      financialYear: '2025',
      lines: [
        DebitCreditLine(
          ledgerId: 10,
          amount: Decimal.parse('50'),
          side: DebitCreditSide.debit,
        ),
        DebitCreditLine(
          ledgerId: 11,
          amount: Decimal.parse('50'),
          side: DebitCreditSide.credit,
        ),
      ],
    );
    final json = DebitCreditDto.draftToPostJson(
      draft,
      kind: DebitCreditKinds.contra,
    );
    expect(json['lines'][0]['type'], 'DR');
    expect(json['lines'][0]['amount'], 50);
    expect(json['lines'][1]['type'], 'CR');
  });

  test('totals balances journal and contra', () {
    final journal = DebitCreditDraft(
      lines: [
        DebitCreditLine(ledgerId: 1, debit: Decimal.parse('40')),
        DebitCreditLine(ledgerId: 2, credit: Decimal.parse('40')),
      ],
    );
    final jt = DebitCreditDto.totals(
      journal,
      mode: DebitCreditLineMode.dualAmount,
    );
    expect(jt.debit, Decimal.parse('40'));
    expect(jt.credit, Decimal.parse('40'));

    final contra = DebitCreditDraft(
      lines: [
        DebitCreditLine(
          ledgerId: 1,
          amount: Decimal.parse('25'),
          side: DebitCreditSide.debit,
        ),
        DebitCreditLine(
          ledgerId: 2,
          amount: Decimal.parse('25'),
          side: DebitCreditSide.credit,
        ),
      ],
    );
    final ct = DebitCreditDto.totals(
      contra,
      mode: DebitCreditLineMode.amountWithSide,
    );
    expect(ct.debit, ct.credit);
  });

  test('detailFromJson accepts DR_Amount and Dr_Amount', () {
    final journal = DebitCreditDto.detailFromJson({
      'id': 9,
      'VoucherStatus': 'Posted',
      'Total': 10,
      'voucher_headers': {
        'voucher_prefix': 'JV',
        'voucher_no': '9',
        'voucher_date': '2025-08-01',
      },
      'details': [
        {'id': 1, 'voucher_ledger_id': 3, 'DR_Amount': 10, 'CR_Amount': 0},
        {'id': 2, 'voucher_ledger_id': 4, 'DR_Amount': 0, 'CR_Amount': 10},
      ],
    });
    expect(journal.lines.first.debit, Decimal.parse('10'));

    final contra = DebitCreditDto.detailFromJson({
      'id': 8,
      'VoucherStatus': 'Posted',
      'details': [
        {'id': 1, 'voucher_ledger_id': 3, 'Dr_Amount': 5, 'Cr_Amount': 0},
      ],
      'voucher_headers': {'voucher_prefix': 'CV', 'voucher_no': '8'},
    });
    expect(contra.lines.first.debit, Decimal.parse('5'));
  });
}
