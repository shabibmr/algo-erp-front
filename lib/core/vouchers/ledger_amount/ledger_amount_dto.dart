import 'package:algo_erp_front/core/vouchers/ledger_amount/ledger_amount_models.dart';
import 'package:decimal/decimal.dart';

/// Wire helpers for Payment / Receipt vouchers.
abstract final class LedgerAmountDto {
  static Decimal? _decimal(dynamic v) {
    if (v == null) return null;
    return Decimal.tryParse(v.toString());
  }

  static String _dateOnly(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static LedgerAmountListItem listItemFromJson(
    Map<String, dynamic> json, {
    required String mainNestKey,
  }) {
    final main = json[mainNestKey];
    Map<String, dynamic>? mainMap;
    if (main is Map<String, dynamic>) mainMap = main;

    final dateRaw = json['voucher_date'];
    DateTime? date;
    if (dateRaw is String && dateRaw.isNotEmpty) {
      date = DateTime.tryParse(dateRaw);
    }

    return LedgerAmountListItem(
      id: json['id'] as int,
      voucherPrefix: json['voucher_prefix'] as String? ?? '',
      voucherNo: json['voucher_no'] as String? ?? '',
      voucherDate: date,
      status: mainMap?['VoucherStatus'] as String?,
      total: _decimal(mainMap?['Total'] ?? mainMap?['Gross_Total']),
      narration: mainMap?['Narration'] as String?,
    );
  }

  static LedgerAmountDetail detailFromJson(Map<String, dynamic> json) {
    final headers = json['voucher_headers'];
    Map<String, dynamic>? h;
    if (headers is Map<String, dynamic>) h = headers;

    DateTime? date;
    final dateRaw = h?['voucher_date'] ?? json['Date_Created'];
    if (dateRaw is String && dateRaw.isNotEmpty) {
      date = DateTime.tryParse(dateRaw);
    }

    final lines = <LedgerAmountDetailLine>[];
    final rawDetails = json['details'];
    if (rawDetails is List) {
      for (final row in rawDetails) {
        if (row is! Map<String, dynamic>) continue;
        lines.add(
          LedgerAmountDetailLine(
            id: row['id'] as int? ?? 0,
            ledgerId:
                row['voucher_ledger_id'] as int? ?? row['ledger_id'] as int?,
            amount: _decimal(
              row['Amount'] ?? row['Dr_Amount'] ?? row['Cr_Amount'],
            ),
            narration: row['Narration'] as String?,
          ),
        );
      }
    }

    return LedgerAmountDetail(
      id: json['id'] as int,
      status: json['VoucherStatus'] as String? ?? 'Posted',
      voucherPrefix: h?['voucher_prefix'] as String? ?? '',
      voucherNo:
          (h?['voucher_no'] as String?) ??
          (json['Voucher_No_Display'] as String? ?? ''),
      voucherDate: date,
      cashBankLedgerId: json['voucher_ledger_id'] as int?,
      total: _decimal(json['Total'] ?? json['Gross_Total']),
      narration: json['Narration'] as String?,
      lines: lines,
    );
  }

  static Map<String, dynamic> draftToPostJson(LedgerAmountDraft draft) {
    return {
      'voucher_prefix': draft.voucherPrefix,
      'voucher_date': _dateOnly(draft.voucherDate),
      'financial_year': draft.financialYear,
      'cash_bank_ledger_id': draft.cashBankLedgerId,
      if (draft.narration != null && draft.narration!.isNotEmpty)
        'narration': draft.narration,
      'lines': [
        for (final line in draft.lines.where((l) => l.isComplete))
          {
            'ledger_id': line.ledgerId,
            'amount': double.tryParse(line.amount.toString()) ?? 0,
            if (line.narration != null && line.narration!.isNotEmpty)
              'narration': line.narration,
          },
      ],
    };
  }

  static LedgerAmountPostResult postResultFromJson(Map<String, dynamic> json) {
    final id = json['id'] as int? ?? json['headerId'] as int?;
    if (id == null) {
      throw const FormatException('Expected payment/receipt post id');
    }
    return LedgerAmountPostResult(
      id: id,
      voucherNo: json['voucherNo'] as String? ?? '',
      total: _decimal(json['total']) ?? Decimal.zero,
    );
  }

  static LedgerAmountLifecycleResult lifecycleFromJson(
    Map<String, dynamic> json,
  ) {
    return LedgerAmountLifecycleResult(
      id: json['id'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      message: json['message'] as String?,
    );
  }
}
