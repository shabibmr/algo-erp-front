import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/inventory_item_property/bloc/item_property_list_event.dart';
import 'package:algo_erp_front/features/inventory_item_property/bloc/item_property_list_state.dart';
import 'package:algo_erp_front/features/inventory_item_property/domain/item_property.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ItemPropertyListBloc
    extends Bloc<ItemPropertyListEvent, ItemPropertyListState> {
  ItemPropertyListBloc({required Repository<ItemProperty, int> repository})
    : _repository = repository,
      super(const ItemPropertyListState()) {
    on<ItemPropertyListFetchRequested>(_onFetchRequested);
    on<ItemPropertyListRefreshed>(_onRefreshed);
    on<ItemPropertyListSearchChanged>(_onSearchChanged);
    on<ItemPropertyItemDeleted>(_onItemDeleted);
  }

  final Repository<ItemProperty, int> _repository;

  Future<void> _onFetchRequested(
    ItemPropertyListFetchRequested event,
    Emitter<ItemPropertyListState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ItemPropertyListStatus.loading,
        actionMessage: () => null,
      ),
    );
    await _loadData(emit);
  }

  Future<void> _onRefreshed(
    ItemPropertyListRefreshed event,
    Emitter<ItemPropertyListState> emit,
  ) async {
    await _loadData(emit);
  }

  Future<void> _onSearchChanged(
    ItemPropertyListSearchChanged event,
    Emitter<ItemPropertyListState> emit,
  ) async {
    emit(
      state.copyWith(
        search: event.search,
        status: ItemPropertyListStatus.loading,
      ),
    );
    await _loadData(emit);
  }

  Future<void> _onItemDeleted(
    ItemPropertyItemDeleted event,
    Emitter<ItemPropertyListState> emit,
  ) async {
    final result = await _repository.delete(event.id);
    result.fold(
      (failure) =>
          emit(state.copyWith(actionMessage: () => _messageOf(failure))),
      (_) {
        emit(
          state.copyWith(actionMessage: () => 'Property deleted successfully'),
        );
        add(const ItemPropertyListFetchRequested());
      },
    );
  }

  Future<void> _loadData(Emitter<ItemPropertyListState> emit) async {
    final result = await _repository.list(state.query);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ItemPropertyListStatus.failure,
          failure: () => failure,
        ),
      ),
      (page) => emit(
        state.copyWith(
          status: ItemPropertyListStatus.success,
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
