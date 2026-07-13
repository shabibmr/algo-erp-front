import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/accounts_ledger/bloc/ledger_list_event.dart';
import 'package:algo_erp_front/features/accounts_ledger/bloc/ledger_list_state.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LedgerListBloc extends Bloc<LedgerListEvent, LedgerListState> {
  LedgerListBloc({required Repository<Ledger, int> repository})
    : _repository = repository,
      super(const LedgerListState()) {
    on<LedgerListFetchRequested>(_onFetchRequested);
    on<LedgerListRefreshed>(_onRefreshed);
    on<LedgerListSearchChanged>(_onSearchChanged);
    on<LedgerItemDeleted>(_onItemDeleted);
  }

  final Repository<Ledger, int> _repository;

  Future<void> _onFetchRequested(
    LedgerListFetchRequested event,
    Emitter<LedgerListState> emit,
  ) async {
    emit(
      state.copyWith(
        status: LedgerListStatus.loading,
        actionMessage: () => null,
      ),
    );
    await _loadData(emit);
  }

  Future<void> _onRefreshed(
    LedgerListRefreshed event,
    Emitter<LedgerListState> emit,
  ) async {
    await _loadData(emit);
  }

  Future<void> _onSearchChanged(
    LedgerListSearchChanged event,
    Emitter<LedgerListState> emit,
  ) async {
    emit(
      state.copyWith(search: event.search, status: LedgerListStatus.loading),
    );
    await _loadData(emit);
  }

  Future<void> _onItemDeleted(
    LedgerItemDeleted event,
    Emitter<LedgerListState> emit,
  ) async {
    final result = await _repository.delete(event.id);
    result.fold(
      (failure) =>
          emit(state.copyWith(actionMessage: () => _messageOf(failure))),
      (_) {
        emit(
          state.copyWith(actionMessage: () => 'Ledger deleted successfully'),
        );
        add(const LedgerListFetchRequested());
      },
    );
  }

  Future<void> _loadData(Emitter<LedgerListState> emit) async {
    final result = await _repository.list(state.query);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: LedgerListStatus.failure,
          failure: () => failure,
        ),
      ),
      (page) => emit(
        state.copyWith(status: LedgerListStatus.success, items: page.items),
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
