import 'package:algo_erp_front/core/bloc/form_mixin.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/organization_user/bloc/user_credentials_form_event.dart';
import 'package:algo_erp_front/features/organization_user/bloc/user_credentials_form_state.dart';
import 'package:algo_erp_front/features/organization_user/domain/user_credentials.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserCredentialsFormBloc
    extends Bloc<UserCredentialsFormEvent, UserCredentialsFormState>
    with FormMixin {
  UserCredentialsFormBloc({
    required Repository<UserCredentials, int> repository,
  }) : _repository = repository,
       super(const UserCredentialsFormState()) {
    on<UserCredentialsFormInitialized>(_onInitialized);
    on<UserCredentialsFormEntityUpdated>(_onEntityUpdated);
    on<UserCredentialsFormSubmitted>(_onSubmitted);
    on<UserCredentialsFormDeleted>(_onDeleted);
  }

  final Repository<UserCredentials, int> _repository;

  Future<void> _onInitialized(
    UserCredentialsFormInitialized event,
    Emitter<UserCredentialsFormState> emit,
  ) async {
    if (event.entityId == null) {
      emit(
        state.copyWith(status: UserCredentialsFormStatus.ready, isEdit: false),
      );
      return;
    }

    emit(
      state.copyWith(
        status: UserCredentialsFormStatus.loading,
        entityId: event.entityId,
        isEdit: true,
      ),
    );

    final result = await _repository.getById(event.entityId!);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: UserCredentialsFormStatus.failure,
          failure: () => failure,
        ),
      ),
      (entity) => emit(
        state.copyWith(status: UserCredentialsFormStatus.ready, entity: entity),
      ),
    );
  }

  void _onEntityUpdated(
    UserCredentialsFormEntityUpdated event,
    Emitter<UserCredentialsFormState> emit,
  ) {
    emit(state.copyWith(entity: event.entity));
  }

  Future<void> _onSubmitted(
    UserCredentialsFormSubmitted event,
    Emitter<UserCredentialsFormState> emit,
  ) async {
    if (state.currentEntity.username.trim().isEmpty) {
      emit(state.copyWith(errorMessage: () => 'Username is required'));
      return;
    }

    emit(
      state.copyWith(
        status: UserCredentialsFormStatus.submitting,
        errorMessage: () => null,
        fieldErrors: const {},
      ),
    );

    final result = state.isEdit
        ? await _repository.update(state.entityId!, state.currentEntity)
        : await _repository.create(state.currentEntity);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: UserCredentialsFormStatus.ready,
          fieldErrors: fieldErrorsFrom(failure),
          errorMessage: () =>
              failure is ValidationFailure ? null : _messageOf(failure),
        ),
      ),
      (_) => emit(state.copyWith(status: UserCredentialsFormStatus.success)),
    );
  }

  Future<void> _onDeleted(
    UserCredentialsFormDeleted event,
    Emitter<UserCredentialsFormState> emit,
  ) async {
    if (state.entityId == null) return;
    emit(state.copyWith(status: UserCredentialsFormStatus.submitting));

    final result = await _repository.delete(state.entityId!);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: UserCredentialsFormStatus.ready,
          errorMessage: () => _messageOf(failure),
        ),
      ),
      (_) => emit(state.copyWith(status: UserCredentialsFormStatus.deleted)),
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
