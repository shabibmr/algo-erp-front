import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/vouchers/effective_price.dart';
import 'package:algo_erp_front/core/vouchers/item_qty/item_qty_kind.dart';
import 'package:algo_erp_front/core/vouchers/item_qty/item_qty_models.dart';
import 'package:algo_erp_front/core/vouchers/item_qty/item_qty_repository.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:algo_erp_front/features/inventory_godown/domain/godown.dart';
import 'package:algo_erp_front/features/inventory_item/domain/inventory_item.dart';
import 'package:algo_erp_front/features/inventory_pricelist/domain/price_list.dart';
import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class ItemQtyFormState extends Equatable {
  const ItemQtyFormState({
    required this.draft,
    this.party,
    this.godown,
    this.source,
    this.posting = false,
    this.error,
    this.posted,
  });

  final ItemQtyDraft draft;
  final Ledger? party;
  final Godown? godown;
  final ItemQtySourceLite? source;
  final bool posting;
  final String? error;
  final ItemQtyPostResult? posted;

  ItemQtyFormState copyWith({
    ItemQtyDraft? draft,
    Ledger? Function()? party,
    Godown? Function()? godown,
    ItemQtySourceLite? Function()? source,
    bool? posting,
    String? Function()? error,
    ItemQtyPostResult? Function()? posted,
  }) {
    return ItemQtyFormState(
      draft: draft ?? this.draft,
      party: party != null ? party() : this.party,
      godown: godown != null ? godown() : this.godown,
      source: source != null ? source() : this.source,
      posting: posting ?? this.posting,
      error: error != null ? error() : this.error,
      posted: posted != null ? posted() : this.posted,
    );
  }

  @override
  List<Object?> get props => [
    draft,
    party,
    godown,
    source,
    posting,
    error,
    posted,
  ];
}

class ItemQtyFormCubit extends Cubit<ItemQtyFormState> {
  ItemQtyFormCubit({
    required this.kind,
    required ItemQtyRepository repository,
    required Repository<Godown, int> godownRepository,
  }) : _repository = repository,
       _godownRepository = godownRepository,
       super(
         ItemQtyFormState(
           draft: ItemQtyDraft(
             voucherPrefix: kind.blueprint.defaultPrefix ?? '',
             financialYear: DateTime.now().year.toString(),
           ),
         ),
       );

  final ItemQtyVoucherKind kind;
  final ItemQtyRepository _repository;
  final Repository<Godown, int> _godownRepository;

  ItemQtyRepository get repository => _repository;

  void updateDraft(ItemQtyDraft draft) {
    emit(state.copyWith(draft: draft, error: () => null, posted: () => null));
  }

  void setParty(Ledger? l) {
    emit(
      state.copyWith(
        party: () => l,
        draft: state.draft.copyWith(
          partyLedgerId: l?.id,
          partyLabel: l?.name,
          billingName: l?.name,
        ),
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

  void setLines(List<ItemQtyLine> lines) {
    updateDraft(state.draft.copyWith(lines: lines));
  }

  void updateLine(int index, ItemQtyLine line) {
    final lines = List<ItemQtyLine>.of(state.draft.lines);
    lines[index] = line;
    setLines(lines);
  }

  Future<void> setPriceList(PriceList? pl) async {
    final draft = state.draft.copyWith(
      priceListId: pl?.id,
      priceListLabel: pl?.name,
    );
    final lines = List<ItemQtyLine>.of(draft.lines);
    if (pl != null && kind.supportsPriceList) {
      final dio = getIt<DioClient>();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final code = line.itemCode;
        if (code == null || code.isEmpty) continue;
        final result = await fetchEffectivePrice(
          dio,
          itemCode: code,
          priceListId: pl.id,
          date: draft.voucherDate,
        );
        if (isClosed) return;
        result.fold((_) {}, (price) {
          lines[i] = line.copyWith(price: price, priceLevel: pl.name);
        });
      }
    }
    emit(
      state.copyWith(
        draft: draft.copyWith(lines: lines),
        error: () => null,
      ),
    );
  }

  Future<Decimal> resolveLinePrice(InventoryItem item) async {
    final fallback = item.price;
    if (!kind.supportsPriceList) return fallback;
    final priceListId = state.draft.priceListId;
    final code = item.code.trim();
    if (priceListId == null || code.isEmpty) return fallback;
    final result = await fetchEffectivePrice(
      getIt<DioClient>(),
      itemCode: code,
      priceListId: priceListId,
      date: state.draft.voucherDate,
    );
    return result.fold((_) => fallback, (p) => p);
  }

  String? priceLevelStamp() => state.draft.priceListLabel;

  Future<void> clearSource() async {
    emit(
      state.copyWith(
        source: () => null,
        draft: state.draft.copyWith(
          sourceVoucherId: null,
          sourceVoucherLabel: null,
        ),
      ),
    );
  }

  Future<void> applySource(ItemQtySourceLite? s) async {
    if (s == null) {
      await clearSource();
      return;
    }
    final full = await _repository.getSourceVoucher(s.id);
    if (isClosed) return;
    full.fold((f) => emit(state.copyWith(error: () => _messageOf(f))), (src) {
      Ledger? party;
      Godown? godown;
      if (src.partyLedgerId != null) {
        party = Ledger(
          id: src.partyLedgerId!,
          name: src.billingName ?? 'Ledger #${src.partyLedgerId}',
          openingBalance: Decimal.zero,
        );
      }
      if (src.godownId != null) {
        godown = Godown(id: src.godownId!, name: 'Godown #${src.godownId}');
      }
      emit(
        state.copyWith(
          source: () => src,
          party: () => party ?? state.party,
          godown: () => godown ?? state.godown,
          draft: state.draft.copyWith(
            sourceVoucherId: src.id,
            sourceVoucherLabel: src.displayNo,
            partyLedgerId: src.partyLedgerId,
            billingName: src.billingName,
            godownId: src.godownId ?? state.draft.godownId,
            lines: src.lines,
          ),
          error: () => null,
        ),
      );
      if (src.godownId != null) {
        _godownRepository.getById(src.godownId!).then((r) {
          if (isClosed) return;
          r.fold((_) {}, (g) {
            emit(
              state.copyWith(
                godown: () => g,
                draft: state.draft.copyWith(godownLabel: g.name),
              ),
            );
          });
        });
      }
    });
  }

  Future<void> submit({required bool Function() formIsValid}) async {
    if (!formIsValid()) return;
    final draft = state.draft;
    if (draft.partyLedgerId == null) {
      emit(state.copyWith(error: () => '${kind.partyLabel} is required'));
      return;
    }
    if (kind.requiresGodown && draft.godownId == null) {
      emit(state.copyWith(error: () => 'Godown is required'));
      return;
    }
    final complete = draft.lines.where((l) => l.isComplete).toList();
    if (complete.isEmpty) {
      emit(
        state.copyWith(
          error: () => 'Add at least one complete line (item, qty, price)',
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
