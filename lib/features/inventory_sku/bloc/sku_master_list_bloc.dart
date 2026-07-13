import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/inventory_sku/bloc/sku_master_list_event.dart';
import 'package:algo_erp_front/features/inventory_sku/bloc/sku_master_list_state.dart';
import 'package:algo_erp_front/features/inventory_sku/domain/sku_master.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SkuMasterListBloc extends Bloc<SkuMasterListEvent, SkuMasterListState> {
  SkuMasterListBloc({required Repository<SkuMaster, int> repository})
    : _repository = repository,
      super(const SkuMasterListState()) {
    on<SkuMasterListFetchRequested>(_onFetchRequested);
    on<SkuMasterListRefreshed>(_onRefreshed);
    on<SkuMasterListSearchChanged>(_onSearchChanged);
    on<SkuMasterItemDeleted>(_onItemDeleted);
  }

  final Repository<SkuMaster, int> _repository;

  Future<void> _onFetchRequested(
    SkuMasterListFetchRequested event,
    Emitter<SkuMasterListState> emit,
  ) async {
    emit(
      state.copyWith(
        status: SkuMasterListStatus.loading,
        actionMessage: () => null,
      ),
    );
    await _loadData(emit);
  }

  Future<void> _onRefreshed(
    SkuMasterListRefreshed event,
    Emitter<SkuMasterListState> emit,
  ) async {
    await _loadData(emit);
  }

  Future<void> _onSearchChanged(
    SkuMasterListSearchChanged event,
    Emitter<SkuMasterListState> emit,
  ) async {
    emit(
      state.copyWith(search: event.search, status: SkuMasterListStatus.loading),
    );
    await _loadData(emit);
  }

  Future<void> _onItemDeleted(
    SkuMasterItemDeleted event,
    Emitter<SkuMasterListState> emit,
  ) async {
    final result = await _repository.delete(event.id);
    result.fold(
      (failure) =>
          emit(state.copyWith(actionMessage: () => _messageOf(failure))),
      (_) {
        emit(state.copyWith(actionMessage: () => 'SKU deleted successfully'));
        add(const SkuMasterListFetchRequested());
      },
    );
  }

  Future<void> _loadData(Emitter<SkuMasterListState> emit) async {
    final result = await _repository.list(state.query);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: SkuMasterListStatus.failure,
          failure: () => failure,
        ),
      ),
      (page) => emit(
        state.copyWith(status: SkuMasterListStatus.success, items: page.items),
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
