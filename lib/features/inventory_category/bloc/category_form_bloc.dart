import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/inventory_category/bloc/category_form_event.dart';
import 'package:algo_erp_front/features/inventory_category/bloc/category_form_state.dart';
import 'package:algo_erp_front/features/inventory_category/domain/category.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoryFormBloc extends Bloc<CategoryFormEvent, CategoryFormState> {
  CategoryFormBloc({required Repository<Category, int> repository})
    : _repository = repository,
      super(const CategoryFormState()) {
    on<CategoryFormInitialized>(_onInitialized);
    on<CategoryFormNameChanged>(_onNameChanged);
    on<CategoryFormCodeChanged>(_onCodeChanged);
    on<CategoryFormDescriptionChanged>(_onDescriptionChanged);
    on<CategoryFormSubmitted>(_onSubmitted);
  }

  final Repository<Category, int> _repository;

  Future<void> _onInitialized(
    CategoryFormInitialized event,
    Emitter<CategoryFormState> emit,
  ) async {
    if (event.entityId == null) {
      emit(state.copyWith(status: CategoryFormStatus.ready, isEdit: false));
      return;
    }

    emit(
      state.copyWith(
        status: CategoryFormStatus.loading,
        entityId: event.entityId,
        isEdit: true,
      ),
    );

    final result = await _repository.getById(event.entityId!);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: CategoryFormStatus.failure,
          failure: () => failure,
        ),
      ),
      (category) => emit(
        state.copyWith(
          status: CategoryFormStatus.ready,
          name: category.name,
          code: category.code ?? '',
          description: category.description ?? '',
        ),
      ),
    );
  }

  void _onNameChanged(
    CategoryFormNameChanged event,
    Emitter<CategoryFormState> emit,
  ) {
    emit(state.copyWith(name: event.name));
  }

  void _onCodeChanged(
    CategoryFormCodeChanged event,
    Emitter<CategoryFormState> emit,
  ) {
    emit(state.copyWith(code: event.code));
  }

  void _onDescriptionChanged(
    CategoryFormDescriptionChanged event,
    Emitter<CategoryFormState> emit,
  ) {
    emit(state.copyWith(description: event.description));
  }

  Future<void> _onSubmitted(
    CategoryFormSubmitted event,
    Emitter<CategoryFormState> emit,
  ) async {
    if (state.name.trim().isEmpty) {
      emit(state.copyWith(errorMessage: () => 'Name is required'));
      return;
    }

    emit(
      state.copyWith(
        status: CategoryFormStatus.submitting,
        errorMessage: () => null,
      ),
    );

    final category = Category(
      id: state.entityId ?? 0,
      name: state.name.trim(),
      code: state.code.trim().isEmpty ? null : state.code.trim(),
      description: state.description.trim().isEmpty
          ? null
          : state.description.trim(),
    );

    if (state.isEdit) {
      final result = await _repository.update(state.entityId!, category);
      result.fold(
        (failure) => emit(
          state.copyWith(
            status: CategoryFormStatus.ready,
            errorMessage: () => _messageOf(failure),
          ),
        ),
        (_) => emit(state.copyWith(status: CategoryFormStatus.success)),
      );
      return;
    }

    final result = await _repository.create(category);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: CategoryFormStatus.ready,
          errorMessage: () => _messageOf(failure),
        ),
      ),
      (_) => emit(state.copyWith(status: CategoryFormStatus.success)),
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
