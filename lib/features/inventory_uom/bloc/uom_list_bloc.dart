import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/inventory_uom/bloc/uom_list_event.dart';
import 'package:algo_erp_front/features/inventory_uom/bloc/uom_list_state.dart';
import 'package:algo_erp_front/features/inventory_uom/domain/uom.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UomListBloc extends Bloc<UomListEvent, UomListState> {
  UomListBloc({required Repository<Uom, int> repository})
    : _repository = repository,
      super(const UomListState()) {
    on<UomListFetchRequested>(_onFetchRequested);
    on<UomListRefreshed>(_onRefreshed);
    on<UomListSearchChanged>(_onSearchChanged);
    on<UomItemDeleted>(_onItemDeleted);
  }

  final Repository<Uom, int> _repository;

  Future<void> _onFetchRequested(
    UomListFetchRequested event,
    Emitter<UomListState> emit,
  ) async {
    emit(
      state.copyWith(status: UomListStatus.loading, actionMessage: () => null),
    );
    await _loadData(emit);
  }

  Future<void> _onRefreshed(
    UomListRefreshed event,
    Emitter<UomListState> emit,
  ) async {
    await _loadData(emit);
  }

  Future<void> _onSearchChanged(
    UomListSearchChanged event,
    Emitter<UomListState> emit,
  ) async {
    emit(state.copyWith(search: event.search, status: UomListStatus.loading));
    await _loadData(emit);
  }

  Future<void> _onItemDeleted(
    UomItemDeleted event,
    Emitter<UomListState> emit,
  ) async {
    final result = await _repository.delete(event.id);
    result.fold(
      (failure) =>
          emit(state.copyWith(actionMessage: () => _messageOf(failure))),
      (_) {
        emit(state.copyWith(actionMessage: () => 'UOM deleted successfully'));
        add(const UomListFetchRequested());
      },
    );
  }

  Future<void> _loadData(Emitter<UomListState> emit) async {
    final result = await _repository.list(state.query);
    result.fold(
      (failure) => emit(
        state.copyWith(status: UomListStatus.failure, failure: () => failure),
      ),
      (page) => emit(
        state.copyWith(status: UomListStatus.success, items: page.items),
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
