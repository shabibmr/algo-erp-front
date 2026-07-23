import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

const _unset = Object();

/// Side for Contra lines (maps to DR/CR on the wire).
enum DebitCreditSide { debit, credit }

/// One double-entry line — Journal uses debit+credit; Contra uses amount+side.
class DebitCreditLine extends Equatable {
  DebitCreditLine({
    this.ledgerId,
    this.ledgerLabel,
    Decimal? debit,
    Decimal? credit,
    Decimal? amount,
    this.side = DebitCreditSide.debit,
    this.narration,
  }) : debit = debit ?? Decimal.zero,
       credit = credit ?? Decimal.zero,
       amount = amount ?? Decimal.zero;

  final int? ledgerId;
  final String? ledgerLabel;
  final Decimal debit;
  final Decimal credit;
  final Decimal amount;
  final DebitCreditSide side;
  final String? narration;

  /// Journal: ledger + (debit XOR credit, or either positive).
  bool isCompleteForJournal() {
    if (ledgerId == null) return false;
    final hasDr = debit > Decimal.zero;
    final hasCr = credit > Decimal.zero;
    // Backend allows both non-negative; complete if at least one side > 0.
    return hasDr || hasCr;
  }

  /// Contra: ledger + amount > 0.
  bool isCompleteForContra() => ledgerId != null && amount > Decimal.zero;

  DebitCreditLine copyWith({
    Object? ledgerId = _unset,
    Object? ledgerLabel = _unset,
    Decimal? debit,
    Decimal? credit,
    Decimal? amount,
    DebitCreditSide? side,
    Object? narration = _unset,
  }) => DebitCreditLine(
    ledgerId: identical(ledgerId, _unset) ? this.ledgerId : ledgerId as int?,
    ledgerLabel: identical(ledgerLabel, _unset)
        ? this.ledgerLabel
        : ledgerLabel as String?,
    debit: debit ?? this.debit,
    credit: credit ?? this.credit,
    amount: amount ?? this.amount,
    side: side ?? this.side,
    narration: identical(narration, _unset)
        ? this.narration
        : narration as String?,
  );

  @override
  List<Object?> get props => [
    ledgerId,
    ledgerLabel,
    debit,
    credit,
    amount,
    side,
    narration,
  ];
}

class DebitCreditDraft extends Equatable {
  DebitCreditDraft({
    this.voucherPrefix = '',
    DateTime? voucherDate,
    this.financialYear = '',
    this.narration,
    List<DebitCreditLine>? lines,
  }) : voucherDate = voucherDate ?? DateTime.now(),
       // Start with two empty lines — journal/contra require ≥2.
       lines = lines ?? [DebitCreditLine(), DebitCreditLine()];

  final String voucherPrefix;
  final DateTime voucherDate;
  final String financialYear;
  final String? narration;
  final List<DebitCreditLine> lines;

  DebitCreditDraft copyWith({
    String? voucherPrefix,
    DateTime? voucherDate,
    String? financialYear,
    Object? narration = _unset,
    List<DebitCreditLine>? lines,
  }) => DebitCreditDraft(
    voucherPrefix: voucherPrefix ?? this.voucherPrefix,
    voucherDate: voucherDate ?? this.voucherDate,
    financialYear: financialYear ?? this.financialYear,
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
    narration,
    lines,
  ];
}

class DebitCreditListItem extends Equatable {
  const DebitCreditListItem({
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

class DebitCreditPostResult extends Equatable {
  const DebitCreditPostResult({
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

class DebitCreditDetailLine extends Equatable {
  const DebitCreditDetailLine({
    required this.id,
    this.ledgerId,
    this.ledgerLabel,
    this.debit,
    this.credit,
    this.narration,
  });

  final int id;
  final int? ledgerId;
  final String? ledgerLabel;
  final Decimal? debit;
  final Decimal? credit;
  final String? narration;

  DebitCreditDetailLine copyWith({Object? ledgerLabel = _unset}) =>
      DebitCreditDetailLine(
        id: id,
        ledgerId: ledgerId,
        ledgerLabel: identical(ledgerLabel, _unset)
            ? this.ledgerLabel
            : ledgerLabel as String?,
        debit: debit,
        credit: credit,
        narration: narration,
      );

  @override
  List<Object?> get props => [
    id,
    ledgerId,
    ledgerLabel,
    debit,
    credit,
    narration,
  ];
}

class DebitCreditDetail extends Equatable {
  const DebitCreditDetail({
    required this.id,
    required this.status,
    required this.lines,
    this.voucherPrefix = '',
    this.voucherNo = '',
    this.voucherDate,
    this.total,
    this.narration,
  });

  final int id;
  final String status;
  final String voucherPrefix;
  final String voucherNo;
  final DateTime? voucherDate;
  final Decimal? total;
  final String? narration;
  final List<DebitCreditDetailLine> lines;

  String get displayNo {
    if (voucherNo.isEmpty) return '#$id';
    final p = voucherPrefix;
    if (p.isEmpty) return voucherNo;
    if (voucherNo.startsWith(p)) return voucherNo;
    return '$p$voucherNo';
  }

  bool get canCancel => status == 'Posted' || status == 'Approved';

  bool get canApprove => status == 'Draft' || status == 'Approved';

  bool get canReject => status == 'Draft' || status == 'Approved';

  DebitCreditDetail copyWith({
    String? status,
    List<DebitCreditDetailLine>? lines,
  }) => DebitCreditDetail(
    id: id,
    status: status ?? this.status,
    voucherPrefix: voucherPrefix,
    voucherNo: voucherNo,
    voucherDate: voucherDate,
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
    total,
    narration,
    lines,
  ];
}

class DebitCreditLifecycleResult extends Equatable {
  const DebitCreditLifecycleResult({
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
