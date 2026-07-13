import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/inventory_brand/bloc/brand_form_event.dart';
import 'package:algo_erp_front/features/inventory_brand/bloc/brand_form_state.dart';
import 'package:algo_erp_front/features/inventory_brand/domain/brand.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BrandFormBloc extends Bloc<BrandFormEvent, BrandFormState> {
  BrandFormBloc({required Repository<Brand, int> repository})
    : _repository = repository,
      super(const BrandFormState()) {
    on<BrandFormInitialized>(_onInitialized);
    on<BrandFormNameChanged>(_onNameChanged);
    on<BrandFormDescriptionChanged>(_onDescriptionChanged);
    on<BrandFormSubmitted>(_onSubmitted);
  }

  final Repository<Brand, int> _repository;

  Future<void> _onInitialized(
    BrandFormInitialized event,
    Emitter<BrandFormState> emit,
  ) async {
    if (event.entityId == null) {
      emit(state.copyWith(status: BrandFormStatus.ready, isEdit: false));
      return;
    }

    emit(
      state.copyWith(
        status: BrandFormStatus.loading,
        entityId: event.entityId,
        isEdit: true,
      ),
    );

    final result = await _repository.getById(event.entityId!);
    result.fold(
      (failure) => emit(
        state.copyWith(status: BrandFormStatus.failure, failure: () => failure),
      ),
      (brand) => emit(
        state.copyWith(
          status: BrandFormStatus.ready,
          name: brand.name,
          description: brand.description ?? '',
        ),
      ),
    );
  }

  void _onNameChanged(
    BrandFormNameChanged event,
    Emitter<BrandFormState> emit,
  ) {
    emit(state.copyWith(name: event.name));
  }

  void _onDescriptionChanged(
    BrandFormDescriptionChanged event,
    Emitter<BrandFormState> emit,
  ) {
    emit(state.copyWith(description: event.description));
  }

  Future<void> _onSubmitted(
    BrandFormSubmitted event,
    Emitter<BrandFormState> emit,
  ) async {
    if (state.name.trim().isEmpty) {
      emit(state.copyWith(errorMessage: () => 'Name is required'));
      return;
    }

    emit(
      state.copyWith(
        status: BrandFormStatus.submitting,
        errorMessage: () => null,
      ),
    );

    final brand = Brand(
      id: state.entityId ?? 0,
      name: state.name.trim(),
      description: state.description.trim().isEmpty
          ? null
          : state.description.trim(),
    );

    if (state.isEdit) {
      final result = await _repository.update(state.entityId!, brand);
      result.fold(
        (failure) => emit(
          state.copyWith(
            status: BrandFormStatus.ready,
            errorMessage: () => _messageOf(failure),
          ),
        ),
        (_) => emit(state.copyWith(status: BrandFormStatus.success)),
      );
      return;
    }

    final result = await _repository.create(brand);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: BrandFormStatus.ready,
          errorMessage: () => _messageOf(failure),
        ),
      ),
      (_) => emit(state.copyWith(status: BrandFormStatus.success)),
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
