import 'package:algo_erp_front/core/bloc/form_mixin.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/accounts_ledger/bloc/ledger_form_event.dart';
import 'package:algo_erp_front/features/accounts_ledger/bloc/ledger_form_state.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LedgerFormBloc extends Bloc<LedgerFormEvent, LedgerFormState>
    with FormMixin {
  LedgerFormBloc({required Repository<Ledger, int> repository})
    : _repository = repository,
      super(const LedgerFormState()) {
    on<LedgerFormInitialized>(_onInitialized);
    on<LedgerFormEntityUpdated>(_onEntityUpdated);
    on<LedgerFormSubmitted>(_onSubmitted);
    on<LedgerFormDeleted>(_onDeleted);
  }

  final Repository<Ledger, int> _repository;

  Future<void> _onInitialized(
    LedgerFormInitialized event,
    Emitter<LedgerFormState> emit,
  ) async {
    if (event.entityId == null) {
      emit(state.copyWith(status: LedgerFormStatus.ready, isEdit: false));
      return;
    }

    emit(
      state.copyWith(
        status: LedgerFormStatus.loading,
        entityId: event.entityId,
        isEdit: true,
      ),
    );

    final result = await _repository.getById(event.entityId!);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: LedgerFormStatus.failure,
          failure: () => failure,
        ),
      ),
      (entity) =>
          emit(state.copyWith(status: LedgerFormStatus.ready, entity: entity)),
    );
  }

  void _onEntityUpdated(
    LedgerFormEntityUpdated event,
    Emitter<LedgerFormState> emit,
  ) {
    emit(state.copyWith(entity: event.entity));
  }

  Future<void> _onSubmitted(
    LedgerFormSubmitted event,
    Emitter<LedgerFormState> emit,
  ) async {
    if (state.currentEntity.name.trim().isEmpty) {
      emit(state.copyWith(errorMessage: () => 'Name is required'));
      return;
    }

    emit(
      state.copyWith(
        status: LedgerFormStatus.submitting,
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
          status: LedgerFormStatus.ready,
          fieldErrors: fieldErrorsFrom(failure),
          errorMessage: () =>
              failure is ValidationFailure ? null : _messageOf(failure),
        ),
      ),
      (_) => emit(state.copyWith(status: LedgerFormStatus.success)),
    );
  }

  Future<void> _onDeleted(
    LedgerFormDeleted event,
    Emitter<LedgerFormState> emit,
  ) async {
    if (state.entityId == null) return;
    emit(state.copyWith(status: LedgerFormStatus.submitting));

    final result = await _repository.delete(state.entityId!);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: LedgerFormStatus.ready,
          errorMessage: () => _messageOf(failure),
        ),
      ),
      (_) => emit(state.copyWith(status: LedgerFormStatus.deleted)),
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
