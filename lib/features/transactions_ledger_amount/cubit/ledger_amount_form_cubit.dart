import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/vouchers/ledger_amount/ledger_amount_kind.dart';
import 'package:algo_erp_front/core/vouchers/ledger_amount/ledger_amount_models.dart';
import 'package:algo_erp_front/core/vouchers/ledger_amount/ledger_amount_repository.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class LedgerAmountFormState extends Equatable {
  const LedgerAmountFormState({
    required this.draft,
    this.cashBank,
    this.posting = false,
    this.error,
    this.posted,
    this.outstandingByLedger = const {},
    this.allocationsByLedger = const {},
    this.loadingOutstandingFor,
  });

  final LedgerAmountDraft draft;
  final Ledger? cashBank;
  final bool posting;
  final String? error;
  final LedgerAmountPostResult? posted;

  /// Outstanding bills keyed by party ledger id.
  final Map<int, List<OutstandingBill>> outstandingByLedger;

  /// Chosen settlements keyed by party ledger id.
  final Map<int, List<BillAllocation>> allocationsByLedger;

  final int? loadingOutstandingFor;

  LedgerAmountFormState copyWith({
    LedgerAmountDraft? draft,
    Ledger? Function()? cashBank,
    bool? posting,
    String? Function()? error,
    LedgerAmountPostResult? Function()? posted,
    Map<int, List<OutstandingBill>>? outstandingByLedger,
    Map<int, List<BillAllocation>>? allocationsByLedger,
    int? Function()? loadingOutstandingFor,
  }) {
    return LedgerAmountFormState(
      draft: draft ?? this.draft,
      cashBank: cashBank != null ? cashBank() : this.cashBank,
      posting: posting ?? this.posting,
      error: error != null ? error() : this.error,
      posted: posted != null ? posted() : this.posted,
      outstandingByLedger: outstandingByLedger ?? this.outstandingByLedger,
      allocationsByLedger: allocationsByLedger ?? this.allocationsByLedger,
      loadingOutstandingFor: loadingOutstandingFor != null
          ? loadingOutstandingFor()
          : this.loadingOutstandingFor,
    );
  }

  @override
  List<Object?> get props => [
    draft,
    cashBank,
    posting,
    error,
    posted,
    outstandingByLedger,
    allocationsByLedger,
    loadingOutstandingFor,
  ];
}

class LedgerAmountFormCubit extends Cubit<LedgerAmountFormState> {
  LedgerAmountFormCubit({
    required this.kind,
    required LedgerAmountRepository repository,
  }) : _repository = repository,
       super(
         LedgerAmountFormState(
           draft: LedgerAmountDraft(
             voucherPrefix: kind.blueprint.defaultPrefix ?? '',
             financialYear: DateTime.now().year.toString(),
           ),
         ),
       );

  final LedgerAmountVoucherKind kind;
  final LedgerAmountRepository _repository;

  void updateDraft(LedgerAmountDraft draft) {
    emit(state.copyWith(draft: draft, error: () => null, posted: () => null));
  }

  void setCashBank(Ledger? ledger, String Function(Ledger) labelOf) {
    emit(
      state.copyWith(
        cashBank: () => ledger,
        draft: state.draft.copyWith(
          cashBankLedgerId: ledger?.id,
          cashBankLabel: ledger == null ? null : labelOf(ledger),
        ),
        error: () => null,
      ),
    );
  }

  void setLines(List<LedgerAmountLine> lines) {
    updateDraft(state.draft.copyWith(lines: lines));
  }

  void updateLine(int index, LedgerAmountLine line) {
    final lines = List<LedgerAmountLine>.of(state.draft.lines);
    lines[index] = line;
    setLines(lines);
    final ledgerId = line.ledgerId;
    if (ledgerId != null) {
      loadOutstanding(ledgerId);
    }
  }

  Future<void> loadOutstanding(int ledgerId, {bool force = false}) async {
    if (!force &&
        (state.outstandingByLedger.containsKey(ledgerId) ||
            state.loadingOutstandingFor == ledgerId)) {
      return;
    }
    emit(state.copyWith(loadingOutstandingFor: () => ledgerId));
    final result = await _repository.listOutstanding(ledgerId);
    if (isClosed) return;
    result.fold(
      (_) => emit(state.copyWith(loadingOutstandingFor: () => null)),
      (bills) {
        final next = Map<int, List<OutstandingBill>>.of(
          state.outstandingByLedger,
        )..[ledgerId] = bills;
        emit(
          state.copyWith(
            outstandingByLedger: next,
            loadingOutstandingFor: () => null,
          ),
        );
      },
    );
  }

  void setAllocation({
    required int ledgerId,
    required OutstandingBill bill,
    required Decimal amount,
  }) {
    final current = List<BillAllocation>.of(
      state.allocationsByLedger[ledgerId] ?? const [],
    )..removeWhere((a) => a.bill.refNo == bill.refNo);
    if (amount > Decimal.zero) {
      current.add(BillAllocation(bill: bill, amount: amount));
    }
    final next = Map<int, List<BillAllocation>>.of(state.allocationsByLedger)
      ..[ledgerId] = current;
    emit(state.copyWith(allocationsByLedger: next, error: () => null));
  }

  Future<void> submit({required bool Function() formIsValid}) async {
    if (!formIsValid()) return;
    final draft = state.draft;
    if (draft.cashBankLedgerId == null) {
      emit(state.copyWith(error: () => 'Cash/Bank ledger is required'));
      return;
    }
    final complete = draft.lines.where((l) => l.isComplete).toList();
    if (complete.isEmpty) {
      emit(
        state.copyWith(
          error: () => 'Add at least one complete line (ledger, amount)',
        ),
      );
      return;
    }
    if (draft.financialYear.trim().isEmpty) {
      emit(state.copyWith(error: () => 'Financial year is required'));
      return;
    }

    // Allocations per ledger must not exceed the line amount for that ledger.
    for (final line in complete) {
      final ledgerId = line.ledgerId!;
      final allocs = state.allocationsByLedger[ledgerId] ?? const [];
      final allocated = allocs.fold<Decimal>(
        Decimal.zero,
        (sum, a) => sum + a.amount,
      );
      if (allocated > line.amount) {
        emit(
          state.copyWith(
            error: () =>
                'Allocations for ${line.ledgerLabel ?? ledgerId} '
                '($allocated) exceed line amount (${line.amount})',
          ),
        );
        return;
      }
    }

    emit(state.copyWith(posting: true, error: () => null, posted: () => null));
    final result = await _repository.post(draft.copyWith(lines: complete));
    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(state.copyWith(posting: false, error: () => _messageOf(failure)));
      },
      (posted) async {
        final isPayment = kind.lifecycleType == 'PaymentVoucher';
        final voucherType = isPayment ? 'Payment' : 'Receipt';
        // Best-effort settlement rows after successful post.
        for (final entry in state.allocationsByLedger.entries) {
          for (final alloc in entry.value) {
            if (alloc.amount <= Decimal.zero) continue;
            await _repository.createBillwiseSettlement(
              ledgerId: entry.key,
              bill: alloc.bill,
              amount: alloc.amount,
              voucherPrefix: draft.voucherPrefix,
              voucherNo: posted.voucherNo,
              voucherType: voucherType,
              isPayment: isPayment,
            );
          }
        }
        if (isClosed) return;
        emit(state.copyWith(posting: false, posted: () => posted));
      },
    );
  }

  String _messageOf(Failure f) => switch (f) {
    NetworkFailure(:final message) => message,
    TimeoutFailure(:final message) => message,
    UnauthorizedFailure(:final message) => message,
    ForbiddenFailure(:final message) => message,
    ValidationFailure(:final message) => message,
    NotFoundFailure(:final message) => message,
    ConflictFailure(:final message) => message,
    ServerFailure(:final message) => message,
    CacheFailure(:final message) => message,
    UnknownFailure(:final message) => message,
  };
}
