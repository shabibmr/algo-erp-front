import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/accounts_account_group/bloc/account_group_list_event.dart';
import 'package:algo_erp_front/features/accounts_account_group/bloc/account_group_list_state.dart';
import 'package:algo_erp_front/features/accounts_account_group/domain/account_group.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AccountGroupListBloc
    extends Bloc<AccountGroupListEvent, AccountGroupListState> {
  AccountGroupListBloc({required Repository<AccountGroup, int> repository})
    : _repository = repository,
      super(const AccountGroupListState()) {
    on<AccountGroupListFetchRequested>(_onFetchRequested);
    on<AccountGroupListRefreshed>(_onRefreshed);
    on<AccountGroupListSearchChanged>(_onSearchChanged);
    on<AccountGroupItemDeleted>(_onItemDeleted);
  }

  final Repository<AccountGroup, int> _repository;

  Future<void> _onFetchRequested(
    AccountGroupListFetchRequested event,
    Emitter<AccountGroupListState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AccountGroupListStatus.loading,
        actionMessage: () => null,
      ),
    );
    await _loadData(emit);
  }

  Future<void> _onRefreshed(
    AccountGroupListRefreshed event,
    Emitter<AccountGroupListState> emit,
  ) async {
    await _loadData(emit);
  }

  Future<void> _onSearchChanged(
    AccountGroupListSearchChanged event,
    Emitter<AccountGroupListState> emit,
  ) async {
    emit(
      state.copyWith(
        search: event.search,
        status: AccountGroupListStatus.loading,
      ),
    );
    await _loadData(emit);
  }

  Future<void> _onItemDeleted(
    AccountGroupItemDeleted event,
    Emitter<AccountGroupListState> emit,
  ) async {
    final result = await _repository.delete(event.id);
    result.fold(
      (failure) =>
          emit(state.copyWith(actionMessage: () => _messageOf(failure))),
      (_) {
        emit(
          state.copyWith(
            actionMessage: () => 'Account Group deleted successfully',
          ),
        );
        add(const AccountGroupListFetchRequested());
      },
    );
  }

  Future<void> _loadData(Emitter<AccountGroupListState> emit) async {
    final result = await _repository.list(state.query);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AccountGroupListStatus.failure,
          failure: () => failure,
        ),
      ),
      (page) => emit(
        state.copyWith(
          status: AccountGroupListStatus.success,
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
