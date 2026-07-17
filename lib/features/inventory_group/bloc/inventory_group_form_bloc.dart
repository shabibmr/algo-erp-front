import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/inventory_group/bloc/inventory_group_form_event.dart';
import 'package:algo_erp_front/features/inventory_group/bloc/inventory_group_form_state.dart';
import 'package:algo_erp_front/features/inventory_group/domain/inventory_group.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InventoryGroupFormBloc
    extends Bloc<InventoryGroupFormEvent, InventoryGroupFormState> {
  InventoryGroupFormBloc({required Repository<InventoryGroup, int> repository})
    : _repository = repository,
      super(const InventoryGroupFormState()) {
    on<InventoryGroupFormInitialized>(_onInitialized);
    on<InventoryGroupFormNameChanged>(_onNameChanged);
    on<InventoryGroupFormCodeChanged>(_onCodeChanged);
    on<InventoryGroupFormNameArabicChanged>(_onNameArabicChanged);
    on<InventoryGroupFormGroupTypeChanged>(_onGroupTypeChanged);
    on<InventoryGroupFormParentGroupIdChanged>(_onParentGroupIdChanged);
    on<InventoryGroupFormSubmitted>(_onSubmitted);
  }

  final Repository<InventoryGroup, int> _repository;

  Future<void> _onInitialized(
    InventoryGroupFormInitialized event,
    Emitter<InventoryGroupFormState> emit,
  ) async {
    emit(state.copyWith(status: InventoryGroupFormStatus.loading));

    // Load available parent groups
    final listResult = await _repository.list(const PageQuery(limit: 1000));
    final available = listResult.fold(
      (_) => <InventoryGroup>[],
      (page) => page.items,
    );

    if (event.entityId == null) {
      emit(
        state.copyWith(
          status: InventoryGroupFormStatus.ready,
          isEdit: false,
          availableGroups: available,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        entityId: event.entityId,
        isEdit: true,
        availableGroups: available
            .where((g) => g.id != event.entityId)
            .toList(),
      ),
    );

    final result = await _repository.getById(event.entityId!);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: InventoryGroupFormStatus.failure,
          failure: () => failure,
        ),
      ),
      (group) => emit(
        state.copyWith(
          status: InventoryGroupFormStatus.ready,
          name: group.name,
          code: group.code ?? '',
          nameArabic: group.nameArabic ?? '',
          groupType: group.groupType ?? '',
          parentGroupId: () => group.parentGroupId,
        ),
      ),
    );
  }

  void _onNameChanged(
    InventoryGroupFormNameChanged event,
    Emitter<InventoryGroupFormState> emit,
  ) {
    emit(state.copyWith(name: event.name));
  }

  void _onCodeChanged(
    InventoryGroupFormCodeChanged event,
    Emitter<InventoryGroupFormState> emit,
  ) {
    emit(state.copyWith(code: event.code));
  }

  void _onNameArabicChanged(
    InventoryGroupFormNameArabicChanged event,
    Emitter<InventoryGroupFormState> emit,
  ) {
    emit(state.copyWith(nameArabic: event.nameArabic));
  }

  void _onGroupTypeChanged(
    InventoryGroupFormGroupTypeChanged event,
    Emitter<InventoryGroupFormState> emit,
  ) {
    emit(state.copyWith(groupType: event.groupType));
  }

  void _onParentGroupIdChanged(
    InventoryGroupFormParentGroupIdChanged event,
    Emitter<InventoryGroupFormState> emit,
  ) {
    emit(state.copyWith(parentGroupId: () => event.parentGroupId));
  }

  Future<void> _onSubmitted(
    InventoryGroupFormSubmitted event,
    Emitter<InventoryGroupFormState> emit,
  ) async {
    if (state.name.trim().isEmpty) {
      emit(state.copyWith(errorMessage: () => 'Name is required'));
      return;
    }

    emit(
      state.copyWith(
        status: InventoryGroupFormStatus.submitting,
        errorMessage: () => null,
      ),
    );

    final group = InventoryGroup(
      id: state.entityId ?? 0,
      groupId: state.code.trim().isNotEmpty
          ? state.code.trim()
          : 'GRP-${DateTime.now().millisecondsSinceEpoch}',
      name: state.name.trim(),
      code: state.code.trim().isEmpty ? null : state.code.trim(),
      nameArabic: state.nameArabic.trim().isEmpty
          ? null
          : state.nameArabic.trim(),
      groupType: state.groupType.trim().isEmpty ? null : state.groupType.trim(),
      parentGroupId: state.parentGroupId,
    );

    if (state.isEdit) {
      final result = await _repository.update(state.entityId!, group);
      result.fold(
        (failure) => emit(
          state.copyWith(
            status: InventoryGroupFormStatus.ready,
            errorMessage: () => _messageOf(failure),
          ),
        ),
        (_) => emit(state.copyWith(status: InventoryGroupFormStatus.success)),
      );
      return;
    }

    final result = await _repository.create(group);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: InventoryGroupFormStatus.ready,
          errorMessage: () => _messageOf(failure),
        ),
      ),
      (_) => emit(state.copyWith(status: InventoryGroupFormStatus.success)),
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
