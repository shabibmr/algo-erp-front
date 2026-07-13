import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/organization_user/bloc/user_credentials_list_event.dart';
import 'package:algo_erp_front/features/organization_user/bloc/user_credentials_list_state.dart';
import 'package:algo_erp_front/features/organization_user/domain/user_credentials.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserCredentialsListBloc
    extends Bloc<UserCredentialsListEvent, UserCredentialsListState> {
  UserCredentialsListBloc({
    required Repository<UserCredentials, int> repository,
  }) : _repository = repository,
       super(const UserCredentialsListState()) {
    on<UserCredentialsListFetchRequested>(_onFetchRequested);
    on<UserCredentialsListRefreshed>(_onRefreshed);
    on<UserCredentialsListSearchChanged>(_onSearchChanged);
    on<UserCredentialsItemDeleted>(_onItemDeleted);
  }

  final Repository<UserCredentials, int> _repository;

  Future<void> _onFetchRequested(
    UserCredentialsListFetchRequested event,
    Emitter<UserCredentialsListState> emit,
  ) async {
    emit(
      state.copyWith(
        status: UserCredentialsListStatus.loading,
        actionMessage: () => null,
      ),
    );
    await _loadData(emit);
  }

  Future<void> _onRefreshed(
    UserCredentialsListRefreshed event,
    Emitter<UserCredentialsListState> emit,
  ) async {
    await _loadData(emit);
  }

  Future<void> _onSearchChanged(
    UserCredentialsListSearchChanged event,
    Emitter<UserCredentialsListState> emit,
  ) async {
    emit(
      state.copyWith(
        search: event.search,
        status: UserCredentialsListStatus.loading,
      ),
    );
    await _loadData(emit);
  }

  Future<void> _onItemDeleted(
    UserCredentialsItemDeleted event,
    Emitter<UserCredentialsListState> emit,
  ) async {
    final result = await _repository.delete(event.id);
    result.fold(
      (failure) =>
          emit(state.copyWith(actionMessage: () => _messageOf(failure))),
      (_) {
        emit(
          state.copyWith(actionMessage: () => 'User deactivated successfully'),
        );
        add(const UserCredentialsListFetchRequested());
      },
    );
  }

  Future<void> _loadData(Emitter<UserCredentialsListState> emit) async {
    final result = await _repository.list(state.query);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: UserCredentialsListStatus.failure,
          failure: () => failure,
        ),
      ),
      (page) => emit(
        state.copyWith(
          status: UserCredentialsListStatus.success,
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
