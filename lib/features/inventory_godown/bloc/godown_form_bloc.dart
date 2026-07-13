import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/inventory_godown/bloc/godown_form_event.dart';
import 'package:algo_erp_front/features/inventory_godown/bloc/godown_form_state.dart';
import 'package:algo_erp_front/features/inventory_godown/domain/godown.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GodownFormBloc extends Bloc<GodownFormEvent, GodownFormState> {
  GodownFormBloc({required Repository<Godown, int> repository})
    : _repository = repository,
      super(const GodownFormState()) {
    on<GodownFormInitialized>(_onInitialized);
    on<GodownFormNameChanged>(_onNameChanged);
    on<GodownFormCodeChanged>(_onCodeChanged);
    on<GodownFormLocationChanged>(_onLocationChanged);
    on<GodownFormNarrationChanged>(_onNarrationChanged);
    on<GodownFormIsProfitCentreToggled>(_onIsProfitCentreToggled);
    on<GodownFormIsDefaultToggled>(_onIsDefaultToggled);
    on<GodownFormIsProductionToggled>(_onIsProductionToggled);
    on<GodownFormSubmitted>(_onSubmitted);
  }

  final Repository<Godown, int> _repository;

  Future<void> _onInitialized(
    GodownFormInitialized event,
    Emitter<GodownFormState> emit,
  ) async {
    if (event.entityId == null) {
      emit(state.copyWith(status: GodownFormStatus.ready, isEdit: false));
      return;
    }

    emit(
      state.copyWith(
        status: GodownFormStatus.loading,
        entityId: event.entityId,
        isEdit: true,
      ),
    );

    final result = await _repository.getById(event.entityId!);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: GodownFormStatus.failure,
          failure: () => failure,
        ),
      ),
      (godown) => emit(
        state.copyWith(
          status: GodownFormStatus.ready,
          name: godown.name,
          code: godown.code ?? '',
          location: godown.location ?? '',
          narration: godown.narration ?? '',
          isProfitCentre: godown.isProfitCentre,
          isDefault: godown.isDefault,
          isProduction: godown.isProduction,
        ),
      ),
    );
  }

  void _onNameChanged(
    GodownFormNameChanged event,
    Emitter<GodownFormState> emit,
  ) {
    emit(state.copyWith(name: event.name));
  }

  void _onCodeChanged(
    GodownFormCodeChanged event,
    Emitter<GodownFormState> emit,
  ) {
    emit(state.copyWith(code: event.code));
  }

  void _onLocationChanged(
    GodownFormLocationChanged event,
    Emitter<GodownFormState> emit,
  ) {
    emit(state.copyWith(location: event.location));
  }

  void _onNarrationChanged(
    GodownFormNarrationChanged event,
    Emitter<GodownFormState> emit,
  ) {
    emit(state.copyWith(narration: event.narration));
  }

  void _onIsProfitCentreToggled(
    GodownFormIsProfitCentreToggled event,
    Emitter<GodownFormState> emit,
  ) {
    emit(state.copyWith(isProfitCentre: event.value));
  }

  void _onIsDefaultToggled(
    GodownFormIsDefaultToggled event,
    Emitter<GodownFormState> emit,
  ) {
    emit(state.copyWith(isDefault: event.value));
  }

  void _onIsProductionToggled(
    GodownFormIsProductionToggled event,
    Emitter<GodownFormState> emit,
  ) {
    emit(state.copyWith(isProduction: event.value));
  }

  Future<void> _onSubmitted(
    GodownFormSubmitted event,
    Emitter<GodownFormState> emit,
  ) async {
    if (state.name.trim().isEmpty) {
      emit(state.copyWith(errorMessage: () => 'Name is required'));
      return;
    }

    emit(
      state.copyWith(
        status: GodownFormStatus.submitting,
        errorMessage: () => null,
      ),
    );

    final godown = Godown(
      id: state.entityId ?? 0,
      name: state.name.trim(),
      code: state.code.trim().isEmpty ? null : state.code.trim(),
      location: state.location.trim().isEmpty ? null : state.location.trim(),
      narration: state.narration.trim().isEmpty ? null : state.narration.trim(),
      isProfitCentre: state.isProfitCentre,
      isDefault: state.isDefault,
      isProduction: state.isProduction,
    );

    if (state.isEdit) {
      final result = await _repository.update(state.entityId!, godown);
      result.fold(
        (failure) => emit(
          state.copyWith(
            status: GodownFormStatus.ready,
            errorMessage: () => _messageOf(failure),
          ),
        ),
        (_) => emit(state.copyWith(status: GodownFormStatus.success)),
      );
      return;
    }

    final result = await _repository.create(godown);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: GodownFormStatus.ready,
          errorMessage: () => _messageOf(failure),
        ),
      ),
      (_) => emit(state.copyWith(status: GodownFormStatus.success)),
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
