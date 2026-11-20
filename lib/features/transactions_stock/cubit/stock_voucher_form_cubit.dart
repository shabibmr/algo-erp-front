import 'package:algo_erp_front/core/vouchers/stock/stock_voucher_kind.dart';
import 'package:algo_erp_front/core/vouchers/stock/stock_voucher_models.dart';
import 'package:algo_erp_front/core/vouchers/stock/stock_voucher_repository.dart';
import 'package:algo_erp_front/features/inventory_godown/domain/godown.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class StockVoucherFormState extends Equatable {
  const StockVoucherFormState({
    required this.draft,
    this.fromGodown,
    this.toGodown,
    this.godown,
    this.posting = false,
    this.error,
    this.posted,
  });

  final StockVoucherDraft draft;
  final Godown? fromGodown;
  final Godown? toGodown;
  final Godown? godown;
  final bool posting;
  final String? error;
  final StockVoucherPostResult? posted;

  StockVoucherFormState copyWith({
    StockVoucherDraft? draft,
    Godown? Function()? fromGodown,
    Godown? Function()? toGodown,
    Godown? Function()? godown,
    bool? posting,
    String? Function()? error,
    StockVoucherPostResult? Function()? posted,
  }) {
    return StockVoucherFormState(
      draft: draft ?? this.draft,
      fromGodown: fromGodown != null ? fromGodown() : this.fromGodown,
      toGodown: toGodown != null ? toGodown() : this.toGodown,
      godown: godown != null ? godown() : this.godown,
      posting: posting ?? this.posting,
      error: error != null ? error() : this.error,
      posted: posted != null ? posted() : this.posted,
    );
  }

  @override
  List<Object?> get props => [
    draft,
    fromGodown,
    toGodown,
    godown,
    posting,
    error,
    posted,
  ];
}

class StockVoucherFormCubit extends Cubit<StockVoucherFormState> {
  StockVoucherFormCubit({
    required this.kind,
    required StockVoucherRepository repository,
  }) : _repository = repository,
       super(
         StockVoucherFormState(
           draft: StockVoucherDraft(
             voucherPrefix: kind.blueprint.defaultPrefix ?? '',
             financialYear: DateTime.now().year.toString(),
           ),
         ),
       );

  final StockVoucherKind kind;
  final StockVoucherRepository _repository;

  void updateDraft(StockVoucherDraft draft) {
    emit(state.copyWith(draft: draft, error: () => null, posted: () => null));
  }

  void setFromGodown(Godown? g) {
    emit(
      state.copyWith(
        fromGodown: () => g,
        draft: state.draft.copyWith(
          fromGodownId: g?.id,
          fromGodownLabel: g?.name,
        ),
        error: () => null,
      ),
    );
  }

  void setToGodown(Godown? g) {
    emit(
      state.copyWith(
        toGodown: () => g,
        draft: state.draft.copyWith(toGodownId: g?.id, toGodownLabel: g?.name),
        error: () => null,
      ),
    );
  }

  void setGodown(Godown? g) {
    emit(
      state.copyWith(
        godown: () => g,
        draft: state.draft.copyWith(godownId: g?.id, godownLabel: g?.name),
        error: () => null,
      ),
    );
  }

  void setLines(List<StockVoucherLine> lines) {
    updateDraft(state.draft.copyWith(lines: lines));
  }

  void updateLine(int index, StockVoucherLine line) {
    final lines = List<StockVoucherLine>.of(state.draft.lines);
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
    if (kind.headerMode == StockHeaderMode.fromToGodown) {
      if (draft.fromGodownId == null || draft.toGodownId == null) {
        emit(state.copyWith(error: () => 'From and To godowns are required'));
        return;
      }
      if (draft.fromGodownId == draft.toGodownId) {
        emit(state.copyWith(error: () => 'From and To godowns must differ'));
        return;
      }
    }

    final complete = switch (kind.lineMode) {
      StockLineMode.itemQtyPrice =>
        draft.lines.where((l) => l.isCompleteQtyPrice()).toList(),
      StockLineMode.itemCrDr =>
        draft.lines.where((l) => l.isCompleteCrDr()).toList(),
      StockLineMode.itemRequestQty =>
        draft.lines.where((l) => l.isCompleteRequest()).toList(),
    };
    if (complete.isEmpty) {
      emit(state.copyWith(error: () => 'Add at least one complete line'));
      return;
    }

    emit(state.copyWith(posting: true, error: () => null, posted: () => null));
    final result = await _repository.post(draft.copyWith(lines: complete));
    if (isClosed) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(posting: false, error: () => failure.message)),
      (posted) => emit(state.copyWith(posting: false, posted: () => posted)),
    );
  }
}
