import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/inventory_uom/bloc/uom_form_event.dart';
import 'package:algo_erp_front/features/inventory_uom/bloc/uom_form_state.dart';
import 'package:algo_erp_front/features/inventory_uom/domain/uom.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UomFormBloc extends Bloc<UomFormEvent, UomFormState> {
  UomFormBloc({required Repository<Uom, int> repository})
    : _repository = repository,
      super(const UomFormState()) {
    on<UomFormInitialized>(_onInitialized);
    on<UomFormNameChanged>(_onNameChanged);
    on<UomFormCodeChanged>(_onCodeChanged);
    on<UomFormSymbolChanged>(_onSymbolChanged);
    on<UomFormDecimalPlacesChanged>(_onDecimalPlacesChanged);
    on<UomFormSubmitted>(_onSubmitted);
  }

  final Repository<Uom, int> _repository;

  Future<void> _onInitialized(
    UomFormInitialized event,
    Emitter<UomFormState> emit,
  ) async {
    if (event.entityId == null) {
      emit(state.copyWith(status: UomFormStatus.ready, isEdit: false));
      return;
    }

    emit(
      state.copyWith(
        status: UomFormStatus.loading,
        entityId: event.entityId,
        isEdit: true,
      ),
    );

    final result = await _repository.getById(event.entityId!);
    result.fold(
      (failure) => emit(
        state.copyWith(status: UomFormStatus.failure, failure: () => failure),
      ),
      (uom) => emit(
        state.copyWith(
          status: UomFormStatus.ready,
          name: uom.name,
          code: uom.code ?? '',
          symbol: uom.symbol ?? '',
          decimalPlaces: uom.decimalPlaces,
        ),
      ),
    );
  }

  void _onNameChanged(UomFormNameChanged event, Emitter<UomFormState> emit) {
    emit(state.copyWith(name: event.name));
  }

  void _onCodeChanged(UomFormCodeChanged event, Emitter<UomFormState> emit) {
    emit(state.copyWith(code: event.code));
  }

  void _onSymbolChanged(
    UomFormSymbolChanged event,
    Emitter<UomFormState> emit,
  ) {
    emit(state.copyWith(symbol: event.symbol));
  }

  void _onDecimalPlacesChanged(
    UomFormDecimalPlacesChanged event,
    Emitter<UomFormState> emit,
  ) {
    emit(state.copyWith(decimalPlaces: event.decimalPlaces));
  }

  Future<void> _onSubmitted(
    UomFormSubmitted event,
    Emitter<UomFormState> emit,
  ) async {
    if (state.name.trim().isEmpty) {
      emit(state.copyWith(errorMessage: () => 'Name is required'));
      return;
    }

    emit(
      state.copyWith(
        status: UomFormStatus.submitting,
        errorMessage: () => null,
      ),
    );

    final uom = Uom(
      id: state.entityId ?? 0,
      name: state.name.trim(),
      code: state.code.trim().isEmpty ? null : state.code.trim(),
      symbol: state.symbol.trim().isEmpty ? null : state.symbol.trim(),
      decimalPlaces: state.decimalPlaces,
    );

    if (state.isEdit) {
      final result = await _repository.update(state.entityId!, uom);
      result.fold(
        (failure) => emit(
          state.copyWith(
            status: UomFormStatus.ready,
            errorMessage: () => _messageOf(failure),
          ),
        ),
        (_) => emit(state.copyWith(status: UomFormStatus.success)),
      );
      return;
    }

    final result = await _repository.create(uom);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: UomFormStatus.ready,
          errorMessage: () => _messageOf(failure),
        ),
      ),
      (_) => emit(state.copyWith(status: UomFormStatus.success)),
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
