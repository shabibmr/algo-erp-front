import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/inventory_godown/bloc/godown_list_event.dart';
import 'package:algo_erp_front/features/inventory_godown/bloc/godown_list_state.dart';
import 'package:algo_erp_front/features/inventory_godown/domain/godown.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GodownListBloc extends Bloc<GodownListEvent, GodownListState> {
  GodownListBloc({required Repository<Godown, int> repository})
    : _repository = repository,
      super(const GodownListState()) {
    on<GodownListFetchRequested>(_onFetchRequested);
    on<GodownListRefreshed>(_onRefreshed);
    on<GodownListSearchChanged>(_onSearchChanged);
    on<GodownItemDeleted>(_onItemDeleted);
  }

  final Repository<Godown, int> _repository;

  Future<void> _onFetchRequested(
    GodownListFetchRequested event,
    Emitter<GodownListState> emit,
  ) async {
    emit(
      state.copyWith(
        status: GodownListStatus.loading,
        actionMessage: () => null,
      ),
    );
    await _loadData(emit);
  }

  Future<void> _onRefreshed(
    GodownListRefreshed event,
    Emitter<GodownListState> emit,
  ) async {
    await _loadData(emit);
  }

  Future<void> _onSearchChanged(
    GodownListSearchChanged event,
    Emitter<GodownListState> emit,
  ) async {
    emit(
      state.copyWith(search: event.search, status: GodownListStatus.loading),
    );
    await _loadData(emit);
  }

  Future<void> _onItemDeleted(
    GodownItemDeleted event,
    Emitter<GodownListState> emit,
  ) async {
    final result = await _repository.delete(event.id);
    result.fold(
      (failure) =>
          emit(state.copyWith(actionMessage: () => _messageOf(failure))),
      (_) {
        emit(
          state.copyWith(actionMessage: () => 'Godown deleted successfully'),
        );
        add(const GodownListFetchRequested());
      },
    );
  }

  Future<void> _loadData(Emitter<GodownListState> emit) async {
    final result = await _repository.list(state.query);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: GodownListStatus.failure,
          failure: () => failure,
        ),
      ),
      (page) => emit(
        state.copyWith(status: GodownListStatus.success, items: page.items),
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
