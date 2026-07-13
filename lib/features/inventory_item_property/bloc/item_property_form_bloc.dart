import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/inventory_item_property/bloc/item_property_form_event.dart';
import 'package:algo_erp_front/features/inventory_item_property/bloc/item_property_form_state.dart';
import 'package:algo_erp_front/features/inventory_item_property/domain/item_property.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ItemPropertyFormBloc
    extends Bloc<ItemPropertyFormEvent, ItemPropertyFormState> {
  ItemPropertyFormBloc({required Repository<ItemProperty, int> repository})
    : _repository = repository,
      super(const ItemPropertyFormState()) {
    on<ItemPropertyFormInitialized>(_onInitialized);
    on<ItemPropertyFormItemIdChanged>(_onItemIdChanged);
    on<ItemPropertyFormDefaultValueChanged>(_onDefaultValueChanged);
    on<ItemPropertyFormSubmitted>(_onSubmitted);
  }

  final Repository<ItemProperty, int> _repository;

  Future<void> _onInitialized(
    ItemPropertyFormInitialized event,
    Emitter<ItemPropertyFormState> emit,
  ) async {
    if (event.entityId == null) {
      emit(state.copyWith(status: ItemPropertyFormStatus.ready, isEdit: false));
      return;
    }

    emit(
      state.copyWith(
        status: ItemPropertyFormStatus.loading,
        entityId: event.entityId,
        isEdit: true,
      ),
    );

    final result = await _repository.getById(event.entityId!);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ItemPropertyFormStatus.failure,
          failure: () => failure,
        ),
      ),
      (property) => emit(
        state.copyWith(
          status: ItemPropertyFormStatus.ready,
          itemId: property.itemId,
          defaultValue: property.defaultValue ?? '',
        ),
      ),
    );
  }

  void _onItemIdChanged(
    ItemPropertyFormItemIdChanged event,
    Emitter<ItemPropertyFormState> emit,
  ) {
    if (state.isEdit) return; // Read-only in edit mode
    emit(state.copyWith(itemId: event.itemId));
  }

  void _onDefaultValueChanged(
    ItemPropertyFormDefaultValueChanged event,
    Emitter<ItemPropertyFormState> emit,
  ) {
    if (state.isEdit) return; // Read-only in edit mode
    emit(state.copyWith(defaultValue: event.defaultValue));
  }

  Future<void> _onSubmitted(
    ItemPropertyFormSubmitted event,
    Emitter<ItemPropertyFormState> emit,
  ) async {
    if (state.isEdit) {
      emit(
        state.copyWith(
          errorMessage: () => 'Updates are not supported for this entity.',
        ),
      );
      return;
    }

    if (state.itemId.trim().isEmpty) {
      emit(state.copyWith(errorMessage: () => 'Item ID is required'));
      return;
    }

    emit(
      state.copyWith(
        status: ItemPropertyFormStatus.submitting,
        errorMessage: () => null,
      ),
    );

    final property = ItemProperty(
      id: 0,
      propertyId: '0',
      itemId: state.itemId.trim(),
      defaultValue: state.defaultValue.trim().isEmpty
          ? null
          : state.defaultValue.trim(),
    );

    final result = await _repository.create(property);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ItemPropertyFormStatus.ready,
          errorMessage: () => _messageOf(failure),
        ),
      ),
      (_) => emit(state.copyWith(status: ItemPropertyFormStatus.success)),
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
