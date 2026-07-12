import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

const _unset = Object();

/// Ledger + amount line for Payment / Receipt.
class LedgerAmountLine extends Equatable {
  LedgerAmountLine({
    this.ledgerId,
    this.ledgerLabel,
    Decimal? amount,
    this.narration,
  }) : amount = amount ?? Decimal.zero;

  final int? ledgerId;
  final String? ledgerLabel;
  final Decimal amount;
  final String? narration;

  bool get isComplete => ledgerId != null && amount > Decimal.zero;

  LedgerAmountLine copyWith({
    Object? ledgerId = _unset,
    Object? ledgerLabel = _unset,
    Decimal? amount,
    Object? narration = _unset,
  }) => LedgerAmountLine(
    ledgerId: identical(ledgerId, _unset) ? this.ledgerId : ledgerId as int?,
    ledgerLabel: identical(ledgerLabel, _unset)
        ? this.ledgerLabel
        : ledgerLabel as String?,
    amount: amount ?? this.amount,
    narration: identical(narration, _unset)
        ? this.narration
        : narration as String?,
  );

  @override
  List<Object?> get props => [ledgerId, ledgerLabel, amount, narration];
}

class LedgerAmountDraft extends Equatable {
  LedgerAmountDraft({
    this.voucherPrefix = '',
    DateTime? voucherDate,
    this.financialYear = '',
    this.cashBankLedgerId,
    this.cashBankLabel,
    this.narration,
    List<LedgerAmountLine>? lines,
  }) : voucherDate = voucherDate ?? DateTime.now(),
       lines = lines ?? [LedgerAmountLine()];

  final String voucherPrefix;
  final DateTime voucherDate;
  final String financialYear;
  final int? cashBankLedgerId;
  final String? cashBankLabel;
  final String? narration;
  final List<LedgerAmountLine> lines;

  LedgerAmountDraft copyWith({
    String? voucherPrefix,
    DateTime? voucherDate,
    String? financialYear,
    Object? cashBankLedgerId = _unset,
    Object? cashBankLabel = _unset,
    Object? narration = _unset,
    List<LedgerAmountLine>? lines,
  }) => LedgerAmountDraft(
    voucherPrefix: voucherPrefix ?? this.voucherPrefix,
    voucherDate: voucherDate ?? this.voucherDate,
    financialYear: financialYear ?? this.financialYear,
    cashBankLedgerId: identical(cashBankLedgerId, _unset)
        ? this.cashBankLedgerId
        : cashBankLedgerId as int?,
    cashBankLabel: identical(cashBankLabel, _unset)
        ? this.cashBankLabel
        : cashBankLabel as String?,
    narration: identical(narration, _unset)
        ? this.narration
        : narration as String?,
    lines: lines ?? this.lines,
  );

  @override
  List<Object?> get props => [
    voucherPrefix,
    voucherDate,
    financialYear,
    cashBankLedgerId,
    narration,
    lines,
  ];
}

class LedgerAmountListItem extends Equatable {
  const LedgerAmountListItem({
    required this.id,
    required this.voucherPrefix,
    required this.voucherNo,
    required this.voucherDate,
    this.status,
    this.total,
    this.narration,
  });

  final int id;
  final String voucherPrefix;
  final String voucherNo;
  final DateTime? voucherDate;
  final String? status;
  final Decimal? total;
  final String? narration;

  String get displayNo =>
      voucherNo.isEmpty ? '$voucherPrefix/?' : '$voucherPrefix$voucherNo';

  @override
  List<Object?> get props => [
    id,
    voucherPrefix,
    voucherNo,
    voucherDate,
    status,
    total,
    narration,
  ];
}

class LedgerAmountPostResult extends Equatable {
  const LedgerAmountPostResult({
    required this.id,
    required this.voucherNo,
    required this.total,
  });

  final int id;
  final String voucherNo;
  final Decimal total;

  @override
  List<Object?> get props => [id, voucherNo, total];
}

class LedgerAmountDetailLine extends Equatable {
  const LedgerAmountDetailLine({
    required this.id,
    this.ledgerId,
    this.ledgerLabel,
    this.amount,
    this.narration,
  });

  final int id;
  final int? ledgerId;
  final String? ledgerLabel;
  final Decimal? amount;
  final String? narration;

  LedgerAmountDetailLine copyWith({Object? ledgerLabel = _unset}) =>
      LedgerAmountDetailLine(
        id: id,
        ledgerId: ledgerId,
        ledgerLabel: identical(ledgerLabel, _unset)
            ? this.ledgerLabel
            : ledgerLabel as String?,
        amount: amount,
        narration: narration,
      );

  @override
  List<Object?> get props => [id, ledgerId, ledgerLabel, amount, narration];
}

class LedgerAmountDetail extends Equatable {
  const LedgerAmountDetail({
    required this.id,
    required this.status,
    required this.lines,
    this.voucherPrefix = '',
    this.voucherNo = '',
    this.voucherDate,
    this.cashBankLedgerId,
    this.cashBankLabel,
    this.total,
    this.narration,
  });

  final int id;
  final String status;
  final String voucherPrefix;
  final String voucherNo;
  final DateTime? voucherDate;
  final int? cashBankLedgerId;
  final String? cashBankLabel;
  final Decimal? total;
  final String? narration;
  final List<LedgerAmountDetailLine> lines;

  String get displayNo {
    if (voucherNo.isEmpty) return '#$id';
    final p = voucherPrefix;
    if (p.isEmpty) return voucherNo;
    if (voucherNo.startsWith(p)) return voucherNo;
    return '$p$voucherNo';
  }

  bool get canCancel =>
      status == 'Posted' || status == 'Approved' || status == 'Draft';

  LedgerAmountDetail copyWith({
    String? status,
    Object? cashBankLabel = _unset,
    List<LedgerAmountDetailLine>? lines,
  }) => LedgerAmountDetail(
    id: id,
    status: status ?? this.status,
    voucherPrefix: voucherPrefix,
    voucherNo: voucherNo,
    voucherDate: voucherDate,
    cashBankLedgerId: cashBankLedgerId,
    cashBankLabel: identical(cashBankLabel, _unset)
        ? this.cashBankLabel
        : cashBankLabel as String?,
    total: total,
    narration: narration,
    lines: lines ?? this.lines,
  );

  @override
  List<Object?> get props => [
    id,
    status,
    voucherPrefix,
    voucherNo,
    voucherDate,
    cashBankLedgerId,
    cashBankLabel,
    total,
    narration,
    lines,
  ];
}

class LedgerAmountLifecycleResult extends Equatable {
  const LedgerAmountLifecycleResult({
    required this.id,
    required this.status,
    this.message,
  });

  final int id;
  final String status;
  final String? message;

  @override
  List<Object?> get props => [id, status, message];
}
