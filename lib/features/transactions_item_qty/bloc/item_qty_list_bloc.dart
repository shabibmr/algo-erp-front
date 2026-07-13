import 'package:algo_erp_front/core/vouchers/item_qty/item_qty_kind.dart';
import 'package:algo_erp_front/core/vouchers/item_qty/item_qty_repository.dart';
import 'package:algo_erp_front/features/transactions_item_qty/bloc/item_qty_list_event.dart';
import 'package:algo_erp_front/features/transactions_item_qty/bloc/item_qty_list_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ItemQtyListBloc extends Bloc<ItemQtyListEvent, ItemQtyListState> {
  ItemQtyListBloc({
    required ItemQtyRepository repository,
    required ItemQtyVoucherKind kind,
  }) : _repository = repository,
       super(ItemQtyListState(kind: kind)) {
    on<ItemQtyListFetchRequested>(_onFetchRequested);
    on<ItemQtyListRefreshed>(_onRefreshed);
    on<ItemQtyListFilterToggled>(_onFilterToggled);
    on<ItemQtyListStartDateChanged>(_onStartDateChanged);
    on<ItemQtyListEndDateChanged>(_onEndDateChanged);
    on<ItemQtyListStatusChanged>(_onStatusChanged);
    on<ItemQtyListPrefixChanged>(_onPrefixChanged);
    on<ItemQtyListPartyChanged>(_onPartyChanged);
    on<ItemQtyListSearchChanged>(_onSearchChanged);
    on<ItemQtyListFiltersCleared>(_onFiltersCleared);
  }

  final ItemQtyRepository _repository;

  Future<void> _onFetchRequested(
    ItemQtyListFetchRequested event,
    Emitter<ItemQtyListState> emit,
  ) async {
    emit(state.copyWith(status: ItemQtyListStatus.loading));
    await _loadData(emit);
  }

  Future<void> _onRefreshed(
    ItemQtyListRefreshed event,
    Emitter<ItemQtyListState> emit,
  ) async {
    await _loadData(emit);
  }

  void _onFilterToggled(
    ItemQtyListFilterToggled event,
    Emitter<ItemQtyListState> emit,
  ) {
    emit(state.copyWith(filtersExpanded: !state.filtersExpanded));
  }

  Future<void> _onStartDateChanged(
    ItemQtyListStartDateChanged event,
    Emitter<ItemQtyListState> emit,
  ) async {
    emit(
      state.copyWith(
        startDate: () => event.startDate,
        status: ItemQtyListStatus.loading,
      ),
    );
    await _loadData(emit);
  }

  Future<void> _onEndDateChanged(
    ItemQtyListEndDateChanged event,
    Emitter<ItemQtyListState> emit,
  ) async {
    emit(
      state.copyWith(
        endDate: () => event.endDate,
        status: ItemQtyListStatus.loading,
      ),
    );
    await _loadData(emit);
  }

  Future<void> _onStatusChanged(
    ItemQtyListStatusChanged event,
    Emitter<ItemQtyListState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedStatus: () => event.status,
        status: ItemQtyListStatus.loading,
      ),
    );
    await _loadData(emit);
  }

  Future<void> _onPrefixChanged(
    ItemQtyListPrefixChanged event,
    Emitter<ItemQtyListState> emit,
  ) async {
    emit(
      state.copyWith(prefix: event.prefix, status: ItemQtyListStatus.loading),
    );
    await _loadData(emit);
  }

  Future<void> _onPartyChanged(
    ItemQtyListPartyChanged event,
    Emitter<ItemQtyListState> emit,
  ) async {
    emit(
      state.copyWith(
        party: () => event.party,
        status: ItemQtyListStatus.loading,
      ),
    );
    await _loadData(emit);
  }

  Future<void> _onSearchChanged(
    ItemQtyListSearchChanged event,
    Emitter<ItemQtyListState> emit,
  ) async {
    emit(
      state.copyWith(search: event.search, status: ItemQtyListStatus.loading),
    );
    await _loadData(emit);
  }

  Future<void> _onFiltersCleared(
    ItemQtyListFiltersCleared event,
    Emitter<ItemQtyListState> emit,
  ) async {
    emit(
      state.copyWith(
        startDate: () => null,
        endDate: () => null,
        selectedStatus: () => null,
        prefix: '',
        party: () => null,
        search: '',
        status: ItemQtyListStatus.loading,
      ),
    );
    await _loadData(emit);
  }

  Future<void> _loadData(Emitter<ItemQtyListState> emit) async {
    final result = await _repository.list(state.query);
    result.fold(
      (failure) => emit(
        state.copyWith(status: ItemQtyListStatus.failure, failure: failure),
      ),
      (page) => emit(
        state.copyWith(status: ItemQtyListStatus.success, items: page.items),
      ),
    );
  }
}
