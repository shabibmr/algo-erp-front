import 'package:algo_erp_front/core/vouchers/debit_credit/debit_credit_kind.dart';
import 'package:algo_erp_front/core/vouchers/debit_credit/debit_credit_models.dart';
import 'package:decimal/decimal.dart';

/// Wire helpers for Journal / Contra vouchers.
abstract final class DebitCreditDto {
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

  static DebitCreditListItem listItemFromJson(
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

    return DebitCreditListItem(
      id: json['id'] as int,
      voucherPrefix: json['voucher_prefix'] as String? ?? '',
      voucherNo: json['voucher_no'] as String? ?? '',
      voucherDate: date,
      status: mainMap?['VoucherStatus'] as String?,
      total: _decimal(mainMap?['Total'] ?? mainMap?['Gross_Total']),
      narration: mainMap?['Narration'] as String?,
    );
  }

  static DebitCreditDetail detailFromJson(Map<String, dynamic> json) {
    final headers = json['voucher_headers'];
    Map<String, dynamic>? h;
    if (headers is Map<String, dynamic>) h = headers;

    DateTime? date;
    final dateRaw = h?['voucher_date'] ?? json['Date_Created'];
    if (dateRaw is String && dateRaw.isNotEmpty) {
      date = DateTime.tryParse(dateRaw);
    }

    final lines = <DebitCreditDetailLine>[];
    final rawDetails = json['details'];
    if (rawDetails is List) {
      for (final row in rawDetails) {
        if (row is! Map<String, dynamic>) continue;
        // Journal uses DR_Amount/CR_Amount; Contra uses Dr_Amount/Cr_Amount.
        final debit = _decimal(
          row['DR_Amount'] ?? row['Dr_Amount'] ?? row['debit_amount'],
        );
        final credit = _decimal(
          row['CR_Amount'] ?? row['Cr_Amount'] ?? row['credit_amount'],
        );
        lines.add(
          DebitCreditDetailLine(
            id: row['id'] as int? ?? 0,
            ledgerId:
                row['voucher_ledger_id'] as int? ?? row['ledger_id'] as int?,
            debit: debit,
            credit: credit,
            narration: row['Narration'] as String?,
          ),
        );
      }
    }

    return DebitCreditDetail(
      id: json['id'] as int,
      status: json['VoucherStatus'] as String? ?? 'Posted',
      voucherPrefix: h?['voucher_prefix'] as String? ?? '',
      voucherNo:
          (h?['voucher_no'] as String?) ??
          (json['Voucher_No_Display'] as String? ?? ''),
      voucherDate: date,
      total: _decimal(json['Total'] ?? json['Gross_Total']),
      narration: json['Narration'] as String?,
      lines: lines,
    );
  }

  static Map<String, dynamic> draftToPostJson(
    DebitCreditDraft draft, {
    required DebitCreditVoucherKind kind,
  }) {
    final complete = kind.lineMode == DebitCreditLineMode.dualAmount
        ? draft.lines.where((l) => l.isCompleteForJournal())
        : draft.lines.where((l) => l.isCompleteForContra());

    return {
      'voucher_prefix': draft.voucherPrefix,
      'voucher_date': _dateOnly(draft.voucherDate),
      'financial_year': draft.financialYear,
      if (draft.narration != null && draft.narration!.isNotEmpty)
        'narration': draft.narration,
      'lines': [
        for (final line in complete)
          if (kind.lineMode == DebitCreditLineMode.dualAmount)
            {
              'ledger_id': line.ledgerId,
              'debit_amount': double.tryParse(line.debit.toString()) ?? 0,
              'credit_amount': double.tryParse(line.credit.toString()) ?? 0,
              if (line.narration != null && line.narration!.isNotEmpty)
                'narration': line.narration,
            }
          else
            {
              'ledger_id': line.ledgerId,
              'amount': double.tryParse(line.amount.toString()) ?? 0,
              'type': line.side == DebitCreditSide.debit ? 'DR' : 'CR',
              if (line.narration != null && line.narration!.isNotEmpty)
                'narration': line.narration,
            },
      ],
    };
  }

  static DebitCreditPostResult postResultFromJson(Map<String, dynamic> json) {
    final id = json['id'] as int? ?? json['headerId'] as int?;
    if (id == null) {
      throw const FormatException('Expected journal/contra post id');
    }
    return DebitCreditPostResult(
      id: id,
      voucherNo: json['voucherNo'] as String? ?? '',
      total: _decimal(json['total']) ?? Decimal.zero,
    );
  }

  static DebitCreditLifecycleResult lifecycleFromJson(
    Map<String, dynamic> json,
  ) {
    return DebitCreditLifecycleResult(
      id: json['id'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      message: json['message'] as String?,
    );
  }

  /// Sum debit / credit for complete lines (client balance check).
  static ({Decimal debit, Decimal credit}) totals(
    DebitCreditDraft draft, {
    required DebitCreditLineMode mode,
  }) {
    var dr = Decimal.zero;
    var cr = Decimal.zero;
    for (final line in draft.lines) {
      if (mode == DebitCreditLineMode.dualAmount) {
        if (!line.isCompleteForJournal()) continue;
        dr += line.debit;
        cr += line.credit;
      } else {
        if (!line.isCompleteForContra()) continue;
        if (line.side == DebitCreditSide.debit) {
          dr += line.amount;
        } else {
          cr += line.amount;
        }
      }
    }
    return (debit: dr, credit: cr);
  }
}
