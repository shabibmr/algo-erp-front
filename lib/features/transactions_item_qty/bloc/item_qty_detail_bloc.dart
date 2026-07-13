import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/vouchers/item_qty/item_qty_repository.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:algo_erp_front/features/inventory_godown/domain/godown.dart';
import 'package:algo_erp_front/features/inventory_item/domain/inventory_item.dart';
import 'package:algo_erp_front/features/transactions_item_qty/bloc/item_qty_detail_event.dart';
import 'package:algo_erp_front/features/transactions_item_qty/bloc/item_qty_detail_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ItemQtyDetailBloc extends Bloc<ItemQtyDetailEvent, ItemQtyDetailState> {
  ItemQtyDetailBloc({
    required ItemQtyRepository repository,
    required Repository<InventoryItem, int> itemRepository,
    required Repository<Ledger, int> ledgerRepository,
    required Repository<Godown, int> godownRepository,
  }) : _repository = repository,
       _itemRepo = itemRepository,
       _ledgerRepo = ledgerRepository,
       _godownRepo = godownRepository,
       super(const ItemQtyDetailState()) {
    on<ItemQtyDetailFetchRequested>(_onFetchRequested);
    on<ItemQtyDetailRefreshed>(_onRefreshed);
    on<ItemQtyDetailCancelled>(_onCancelled);
  }

  final ItemQtyRepository _repository;
  final Repository<InventoryItem, int> _itemRepo;
  final Repository<Ledger, int> _ledgerRepo;
  final Repository<Godown, int> _godownRepo;

  Future<void> _onFetchRequested(
    ItemQtyDetailFetchRequested event,
    Emitter<ItemQtyDetailState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ItemQtyDetailStatus.loading,
        actionMessage: () => null,
      ),
    );

    final result = await _repository.getById(
      event.id,
      resolveItemLabel: (itemId) async {
        final r = await _itemRepo.getById(itemId);
        return r.fold(
          (_) => null,
          (item) =>
              item.code.isEmpty ? item.name : '${item.code} — ${item.name}',
        );
      },
      resolvePartyLabel: (ledgerId) async {
        final r = await _ledgerRepo.getById(ledgerId);
        return r.fold((_) => null, (l) {
          final code = l.code;
          return (code == null || code.isEmpty) ? l.name : '$code — ${l.name}';
        });
      },
      resolveGodownLabel: (godownId) async {
        final r = await _godownRepo.getById(godownId);
        return r.fold((_) => null, (g) => g.name);
      },
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ItemQtyDetailStatus.failure,
          failure: () => failure,
        ),
      ),
      (detail) => emit(
        state.copyWith(status: ItemQtyDetailStatus.success, detail: detail),
      ),
    );
  }

  Future<void> _onRefreshed(
    ItemQtyDetailRefreshed event,
    Emitter<ItemQtyDetailState> emit,
  ) async {
    if (state.detail != null) {
      add(ItemQtyDetailFetchRequested(state.detail!.id));
    }
  }

  Future<void> _onCancelled(
    ItemQtyDetailCancelled event,
    Emitter<ItemQtyDetailState> emit,
  ) async {
    if (state.detail == null) return;
    emit(state.copyWith(isBusy: true, actionMessage: () => null));

    final result = await _repository.cancel(state.detail!.id);
    result.fold(
      (failure) => emit(
        state.copyWith(isBusy: false, actionMessage: () => _messageOf(failure)),
      ),
      (_) {
        emit(state.copyWith(isBusy: false, actionMessage: () => 'Cancelled'));
        add(ItemQtyDetailFetchRequested(state.detail!.id));
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
