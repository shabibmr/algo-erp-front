import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/inventory_item/bloc/inventory_item_list_event.dart';
import 'package:algo_erp_front/features/inventory_item/bloc/inventory_item_list_state.dart';
import 'package:algo_erp_front/features/inventory_item/domain/inventory_item.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InventoryItemListBloc
    extends Bloc<InventoryItemListEvent, InventoryItemListState> {
  InventoryItemListBloc({required Repository<InventoryItem, int> repository})
    : _repository = repository,
      super(const InventoryItemListState()) {
    on<InventoryItemListFetchRequested>(_onFetchRequested);
    on<InventoryItemListRefreshed>(_onRefreshed);
    on<InventoryItemListSearchChanged>(_onSearchChanged);
    on<InventoryItemItemDeleted>(_onItemDeleted);
  }

  final Repository<InventoryItem, int> _repository;

  Future<void> _onFetchRequested(
    InventoryItemListFetchRequested event,
    Emitter<InventoryItemListState> emit,
  ) async {
    emit(
      state.copyWith(
        status: InventoryItemListStatus.loading,
        actionMessage: () => null,
      ),
    );
    await _loadData(emit);
  }

  Future<void> _onRefreshed(
    InventoryItemListRefreshed event,
    Emitter<InventoryItemListState> emit,
  ) async {
    await _loadData(emit);
  }

  Future<void> _onSearchChanged(
    InventoryItemListSearchChanged event,
    Emitter<InventoryItemListState> emit,
  ) async {
    emit(
      state.copyWith(
        search: event.search,
        status: InventoryItemListStatus.loading,
      ),
    );
    await _loadData(emit);
  }

  Future<void> _onItemDeleted(
    InventoryItemItemDeleted event,
    Emitter<InventoryItemListState> emit,
  ) async {
    final result = await _repository.delete(event.id);
    result.fold(
      (failure) =>
          emit(state.copyWith(actionMessage: () => _messageOf(failure))),
      (_) {
        emit(state.copyWith(actionMessage: () => 'Item deleted successfully'));
        add(const InventoryItemListFetchRequested());
      },
    );
  }

  Future<void> _loadData(Emitter<InventoryItemListState> emit) async {
    final result = await _repository.list(state.query);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: InventoryItemListStatus.failure,
          failure: () => failure,
        ),
      ),
      (page) => emit(
        state.copyWith(
          status: InventoryItemListStatus.success,
          items: page.items,
        ),
      ),
    );
  }

  String _messageOf(Failure f) => switch (f) {
    NetworkFailure(:final message) => message,
    ValidationFailure(:final message) => message,
    ForbiddenFailure(:final message) => message,
    ServerFailure(:final message) => message,
    _ => f.toString(),
  };
}
