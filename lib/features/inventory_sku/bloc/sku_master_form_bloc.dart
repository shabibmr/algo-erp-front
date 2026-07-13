import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/inventory_item/domain/inventory_item.dart';
import 'package:algo_erp_front/features/inventory_sku/bloc/sku_master_form_event.dart';
import 'package:algo_erp_front/features/inventory_sku/bloc/sku_master_form_state.dart';
import 'package:algo_erp_front/features/inventory_sku/domain/sku_master.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SkuMasterFormBloc extends Bloc<SkuMasterFormEvent, SkuMasterFormState> {
  SkuMasterFormBloc({
    required Repository<SkuMaster, int> repository,
    required Repository<InventoryItem, int> inventoryItemRepository,
  }) : _repository = repository,
       _inventoryItemRepository = inventoryItemRepository,
       super(const SkuMasterFormState()) {
    on<SkuMasterFormInitialized>(_onInitialized);
    on<SkuMasterFormItemChanged>(_onItemChanged);
    on<SkuMasterFormLegacyItemIdChanged>(_onLegacyItemIdChanged);
    on<SkuMasterFormNameChanged>(_onNameChanged);
    on<SkuMasterFormCodeChanged>(_onCodeChanged);
    on<SkuMasterFormBarcodeChanged>(_onBarcodeChanged);
    on<SkuMasterFormRateChanged>(_onRateChanged);
    on<SkuMasterFormDescriptionChanged>(_onDescriptionChanged);
    on<SkuMasterFormSkuTypeChanged>(_onSkuTypeChanged);
    on<SkuMasterFormValueChanged>(_onValueChanged);
    on<SkuMasterFormPossibleValuesChanged>(_onPossibleValuesChanged);
    on<SkuMasterFormSubmitted>(_onSubmitted);
  }

  final Repository<SkuMaster, int> _repository;
  final Repository<InventoryItem, int> _inventoryItemRepository;

  Future<void> _onInitialized(
    SkuMasterFormInitialized event,
    Emitter<SkuMasterFormState> emit,
  ) async {
    if (event.entityId == null) {
      emit(state.copyWith(status: SkuMasterFormStatus.ready, isEdit: false));
      return;
    }

    emit(
      state.copyWith(
        status: SkuMasterFormStatus.loading,
        entityId: event.entityId,
        isEdit: true,
      ),
    );

    final result = await _repository.getById(event.entityId!);
    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            status: SkuMasterFormStatus.failure,
            failure: () => failure,
          ),
        );
      },
      (sku) async {
        InventoryItem? item;
        if (sku.inventoryItemId != null) {
          final res = await _inventoryItemRepository.getById(
            sku.inventoryItemId!,
          );
          item = res.fold((_) => null, (i) => i);
        }

        emit(
          state.copyWith(
            status: SkuMasterFormStatus.ready,
            inventoryItem: () => item,
            legacyItemId: sku.itemId,
            name: sku.name ?? '',
            code: sku.code ?? '',
            barcode: sku.barcode ?? '',
            rate: () => sku.rate,
            description: sku.description ?? '',
            skuType: () => sku.skuType,
            value: sku.value ?? '',
            possibleValues: sku.possibleValues ?? '',
          ),
        );
      },
    );
  }

  void _onItemChanged(
    SkuMasterFormItemChanged event,
    Emitter<SkuMasterFormState> emit,
  ) {
    final item = event.item;
    String legacy = state.legacyItemId;
    if (item != null) {
      legacy = item.code.isNotEmpty ? item.code : item.id.toString();
    }
    emit(state.copyWith(inventoryItem: () => item, legacyItemId: legacy));
  }

  void _onLegacyItemIdChanged(
    SkuMasterFormLegacyItemIdChanged event,
    Emitter<SkuMasterFormState> emit,
  ) {
    emit(state.copyWith(legacyItemId: event.legacyItemId));
  }

  void _onNameChanged(
    SkuMasterFormNameChanged event,
    Emitter<SkuMasterFormState> emit,
  ) {
    emit(state.copyWith(name: event.name));
  }

  void _onCodeChanged(
    SkuMasterFormCodeChanged event,
    Emitter<SkuMasterFormState> emit,
  ) {
    emit(state.copyWith(code: event.code));
  }

  void _onBarcodeChanged(
    SkuMasterFormBarcodeChanged event,
    Emitter<SkuMasterFormState> emit,
  ) {
    emit(state.copyWith(barcode: event.barcode));
  }

  void _onRateChanged(
    SkuMasterFormRateChanged event,
    Emitter<SkuMasterFormState> emit,
  ) {
    emit(state.copyWith(rate: () => event.rate));
  }

  void _onDescriptionChanged(
    SkuMasterFormDescriptionChanged event,
    Emitter<SkuMasterFormState> emit,
  ) {
    emit(state.copyWith(description: event.description));
  }

  void _onSkuTypeChanged(
    SkuMasterFormSkuTypeChanged event,
    Emitter<SkuMasterFormState> emit,
  ) {
    emit(state.copyWith(skuType: () => event.skuType));
  }

  void _onValueChanged(
    SkuMasterFormValueChanged event,
    Emitter<SkuMasterFormState> emit,
  ) {
    emit(state.copyWith(value: event.value));
  }

  void _onPossibleValuesChanged(
    SkuMasterFormPossibleValuesChanged event,
    Emitter<SkuMasterFormState> emit,
  ) {
    emit(state.copyWith(possibleValues: event.possibleValues));
  }

  Future<void> _onSubmitted(
    SkuMasterFormSubmitted event,
    Emitter<SkuMasterFormState> emit,
  ) async {
    if (state.legacyItemId.trim().isEmpty) {
      emit(state.copyWith(errorMessage: () => 'Legacy item ID is required'));
      return;
    }

    if (state.skuType != null &&
        !SkuMaster.skuTypes.containsKey(state.skuType)) {
      emit(state.copyWith(errorMessage: () => 'SKU Type must be 1, 2, or 3'));
      return;
    }

    emit(
      state.copyWith(
        status: SkuMasterFormStatus.submitting,
        errorMessage: () => null,
      ),
    );

    final sku = SkuMaster(
      id: state.entityId ?? 0,
      inventoryItemId: state.inventoryItem?.id,
      itemId: state.legacyItemId.trim(),
      name: state.name.trim().isEmpty ? null : state.name.trim(),
      code: state.code.trim().isEmpty ? null : state.code.trim(),
      barcode: state.barcode.trim().isEmpty ? null : state.barcode.trim(),
      rate: state.rate,
      description: state.description.trim().isEmpty
          ? null
          : state.description.trim(),
      skuType: state.skuType,
      value: state.value.trim().isEmpty ? null : state.value.trim(),
      possibleValues: state.possibleValues.trim().isEmpty
          ? null
          : state.possibleValues.trim(),
    );

    if (state.isEdit) {
      final result = await _repository.update(state.entityId!, sku);
      result.fold(
        (failure) => emit(
          state.copyWith(
            status: SkuMasterFormStatus.ready,
            errorMessage: () => _messageOf(failure),
          ),
        ),
        (_) => emit(state.copyWith(status: SkuMasterFormStatus.success)),
      );
      return;
    }

    final result = await _repository.create(sku);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: SkuMasterFormStatus.ready,
          errorMessage: () => _messageOf(failure),
        ),
      ),
      (_) => emit(state.copyWith(status: SkuMasterFormStatus.success)),
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
