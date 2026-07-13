import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/accounts_account_group/bloc/account_group_form_event.dart';
import 'package:algo_erp_front/features/accounts_account_group/bloc/account_group_form_state.dart';
import 'package:algo_erp_front/features/accounts_account_group/domain/account_group.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AccountGroupFormBloc
    extends Bloc<AccountGroupFormEvent, AccountGroupFormState> {
  AccountGroupFormBloc({required Repository<AccountGroup, int> repository})
    : _repository = repository,
      super(const AccountGroupFormState()) {
    on<AccountGroupFormInitialized>(_onInitialized);
    on<AccountGroupFormNameChanged>(_onNameChanged);
    on<AccountGroupFormCodeChanged>(_onCodeChanged);
    on<AccountGroupFormParentGroupIdChanged>(_onParentGroupIdChanged);
    on<AccountGroupFormSubmitted>(_onSubmitted);
  }

  final Repository<AccountGroup, int> _repository;

  Future<void> _onInitialized(
    AccountGroupFormInitialized event,
    Emitter<AccountGroupFormState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AccountGroupFormStatus.loading,
        entityId: event.entityId,
        isEdit: event.entityId != null,
      ),
    );

    final groupsResult = await _repository.list(const PageQuery());
    final groups = groupsResult.fold((_) => <AccountGroup>[], (p) => p.items);

    if (event.entityId == null) {
      emit(
        state.copyWith(
          status: AccountGroupFormStatus.ready,
          isEdit: false,
          availableGroups: groups,
        ),
      );
      return;
    }

    final result = await _repository.getById(event.entityId!);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AccountGroupFormStatus.failure,
          failure: () => failure,
        ),
      ),
      (group) => emit(
        state.copyWith(
          status: AccountGroupFormStatus.ready,
          name: group.name,
          code: group.code ?? '',
          parentGroupId: () => group.parentGroupId,
          availableGroups: groups.where((g) => g.id != event.entityId).toList(),
        ),
      ),
    );
  }

  void _onNameChanged(
    AccountGroupFormNameChanged event,
    Emitter<AccountGroupFormState> emit,
  ) {
    emit(state.copyWith(name: event.name));
  }

  void _onCodeChanged(
    AccountGroupFormCodeChanged event,
    Emitter<AccountGroupFormState> emit,
  ) {
    emit(state.copyWith(code: event.code));
  }

  void _onParentGroupIdChanged(
    AccountGroupFormParentGroupIdChanged event,
    Emitter<AccountGroupFormState> emit,
  ) {
    emit(state.copyWith(parentGroupId: () => event.parentGroupId));
  }

  Future<void> _onSubmitted(
    AccountGroupFormSubmitted event,
    Emitter<AccountGroupFormState> emit,
  ) async {
    if (state.name.trim().isEmpty) {
      emit(state.copyWith(errorMessage: () => 'Name is required'));
      return;
    }

    emit(
      state.copyWith(
        status: AccountGroupFormStatus.submitting,
        errorMessage: () => null,
      ),
    );

    final group = AccountGroup(
      id: state.entityId ?? 0,
      name: state.name.trim(),
      code: state.code.trim().isEmpty ? null : state.code.trim(),
      parentGroupId: state.parentGroupId,
    );

    if (state.isEdit) {
      final result = await _repository.update(state.entityId!, group);
      result.fold(
        (failure) => emit(
          state.copyWith(
            status: AccountGroupFormStatus.ready,
            errorMessage: () => _messageOf(failure),
          ),
        ),
        (_) => emit(state.copyWith(status: AccountGroupFormStatus.success)),
      );
      return;
    }

    final result = await _repository.create(group);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AccountGroupFormStatus.ready,
          errorMessage: () => _messageOf(failure),
        ),
      ),
      (_) => emit(state.copyWith(status: AccountGroupFormStatus.success)),
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
