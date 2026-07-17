import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/vouchers/debit_credit/debit_credit_dto.dart';
import 'package:algo_erp_front/core/vouchers/debit_credit/debit_credit_kind.dart';
import 'package:algo_erp_front/core/vouchers/debit_credit/debit_credit_models.dart';
import 'package:algo_erp_front/core/vouchers/debit_credit/debit_credit_repository.dart';
import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class DebitCreditFormState extends Equatable {
  const DebitCreditFormState({
    required this.draft,
    this.posting = false,
    this.error,
    this.posted,
  });

  final DebitCreditDraft draft;
  final bool posting;
  final String? error;
  final DebitCreditPostResult? posted;

  DebitCreditFormState copyWith({
    DebitCreditDraft? draft,
    bool? posting,
    String? Function()? error,
    DebitCreditPostResult? Function()? posted,
  }) {
    return DebitCreditFormState(
      draft: draft ?? this.draft,
      posting: posting ?? this.posting,
      error: error != null ? error() : this.error,
      posted: posted != null ? posted() : this.posted,
    );
  }

  @override
  List<Object?> get props => [draft, posting, error, posted];
}

class DebitCreditFormCubit extends Cubit<DebitCreditFormState> {
  DebitCreditFormCubit({
    required this.kind,
    required DebitCreditRepository repository,
  }) : _repository = repository,
       super(
         DebitCreditFormState(
           draft: DebitCreditDraft(
             voucherPrefix: kind.blueprint.defaultPrefix ?? '',
             financialYear: DateTime.now().year.toString(),
           ),
         ),
       );

  final DebitCreditVoucherKind kind;
  final DebitCreditRepository _repository;

  bool get isJournal => kind.lineMode == DebitCreditLineMode.dualAmount;

  ({Decimal debit, Decimal credit}) get totals =>
      DebitCreditDto.totals(state.draft, mode: kind.lineMode);

  bool get balanced {
    final t = totals;
    return t.debit > Decimal.zero && t.debit == t.credit;
  }

  void updateDraft(DebitCreditDraft draft) {
    emit(state.copyWith(draft: draft, error: () => null, posted: () => null));
  }

  void setLines(List<DebitCreditLine> lines) {
    updateDraft(state.draft.copyWith(lines: lines));
  }

  void updateLine(int index, DebitCreditLine line) {
    final lines = List<DebitCreditLine>.of(state.draft.lines);
    lines[index] = line;
    setLines(lines);
  }

  Future<void> submit({required bool Function() formIsValid}) async {
    if (!formIsValid()) return;
    final draft = state.draft;
    if (draft.financialYear.trim().isEmpty) {
      emit(state.copyWith(error: () => 'Financial year is required'));
      return;
    }

    final complete = isJournal
        ? draft.lines.where((l) => l.isCompleteForJournal()).toList()
        : draft.lines.where((l) => l.isCompleteForContra()).toList();
    if (complete.length < kind.minLines) {
      emit(
        state.copyWith(
          error: () =>
              'Add at least ${kind.minLines} complete lines (ledger + amount)',
        ),
      );
      return;
    }
    if (!balanced) {
      final t = totals;
      emit(
        state.copyWith(
          error: () => 'Debits (${t.debit}) must equal credits (${t.credit})',
        ),
      );
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

  void clearPosted() {
    if (state.posted == null) return;
    emit(state.copyWith(posted: () => null));
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
