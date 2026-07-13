import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/inventory_group/bloc/inventory_group_list_event.dart';
import 'package:algo_erp_front/features/inventory_group/bloc/inventory_group_list_state.dart';
import 'package:algo_erp_front/features/inventory_group/domain/inventory_group.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InventoryGroupListBloc
    extends Bloc<InventoryGroupListEvent, InventoryGroupListState> {
  InventoryGroupListBloc({required Repository<InventoryGroup, int> repository})
    : _repository = repository,
      super(const InventoryGroupListState()) {
    on<InventoryGroupListFetchRequested>(_onFetchRequested);
    on<InventoryGroupListRefreshed>(_onRefreshed);
    on<InventoryGroupListSearchChanged>(_onSearchChanged);
    on<InventoryGroupItemDeleted>(_onItemDeleted);
  }

  final Repository<InventoryGroup, int> _repository;

  Future<void> _onFetchRequested(
    InventoryGroupListFetchRequested event,
    Emitter<InventoryGroupListState> emit,
  ) async {
    emit(
      state.copyWith(
        status: InventoryGroupListStatus.loading,
        actionMessage: () => null,
      ),
    );
    await _loadData(emit);
  }

  Future<void> _onRefreshed(
    InventoryGroupListRefreshed event,
    Emitter<InventoryGroupListState> emit,
  ) async {
    await _loadData(emit);
  }

  Future<void> _onSearchChanged(
    InventoryGroupListSearchChanged event,
    Emitter<InventoryGroupListState> emit,
  ) async {
    emit(
      state.copyWith(
        search: event.search,
        status: InventoryGroupListStatus.loading,
      ),
    );
    await _loadData(emit);
  }

  Future<void> _onItemDeleted(
    InventoryGroupItemDeleted event,
    Emitter<InventoryGroupListState> emit,
  ) async {
    final result = await _repository.delete(event.id);
    result.fold(
      (failure) =>
          emit(state.copyWith(actionMessage: () => _messageOf(failure))),
      (_) {
        emit(state.copyWith(actionMessage: () => 'Group deleted successfully'));
        add(const InventoryGroupListFetchRequested());
      },
    );
  }

  Future<void> _loadData(Emitter<InventoryGroupListState> emit) async {
    final result = await _repository.list(state.query);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: InventoryGroupListStatus.failure,
          failure: () => failure,
        ),
      ),
      (page) => emit(
        state.copyWith(
          status: InventoryGroupListStatus.success,
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
