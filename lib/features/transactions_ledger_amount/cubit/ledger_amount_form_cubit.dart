import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/vouchers/ledger_amount/ledger_amount_kind.dart';
import 'package:algo_erp_front/core/vouchers/ledger_amount/ledger_amount_models.dart';
import 'package:algo_erp_front/core/vouchers/ledger_amount/ledger_amount_repository.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class LedgerAmountFormState extends Equatable {
  const LedgerAmountFormState({
    required this.draft,
    this.cashBank,
    this.posting = false,
    this.error,
    this.posted,
  });

  final LedgerAmountDraft draft;
  final Ledger? cashBank;
  final bool posting;
  final String? error;
  final LedgerAmountPostResult? posted;

  LedgerAmountFormState copyWith({
    LedgerAmountDraft? draft,
    Ledger? Function()? cashBank,
    bool? posting,
    String? Function()? error,
    LedgerAmountPostResult? Function()? posted,
  }) {
    return LedgerAmountFormState(
      draft: draft ?? this.draft,
      cashBank: cashBank != null ? cashBank() : this.cashBank,
      posting: posting ?? this.posting,
      error: error != null ? error() : this.error,
      posted: posted != null ? posted() : this.posted,
    );
  }

  @override
  List<Object?> get props => [draft, cashBank, posting, error, posted];
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

    emit(state.copyWith(posting: true, error: () => null, posted: () => null));
    final result = await _repository.post(draft.copyWith(lines: complete));
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(posting: false, error: () => _messageOf(failure)),
      ),
      (posted) => emit(state.copyWith(posting: false, posted: () => posted)),
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
