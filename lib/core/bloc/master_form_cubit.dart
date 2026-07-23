import 'package:algo_erp_front/core/bloc/form_mixin.dart';
import 'package:algo_erp_front/core/bloc/master_form_state.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/manifest/entity_manifest.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Owns draft entity, FK display cache, submit busy flag, and server errors
/// for [MasterFormSurface] (and tabbed shells that reuse the same shape).
class MasterFormCubit<E, ID> extends Cubit<MasterFormState<E>> with FormMixin {
  MasterFormCubit({
    required this.manifest,
    required this.mode,
    required this.idOf,
    this.formFields,
    // Not `const MasterFormState()`: a const instance can't carry the type
    // variable E, so it lands as MasterFormState<Null>, and copyWith's
    // `E? Function()? draft` then rejects a real entity on seed (edit mode).
  }) : super(MasterFormState<E>()) {
    if (mode == FormMode.create) {
      emit(MasterFormState<E>(draft: manifest.emptyEntity!(), seeded: true));
    }
  }

  final EntityManifest<E> manifest;
  final FormMode mode;
  final ID Function(E entity) idOf;

  /// When non-null, used instead of [manifest.formFields] (e.g. employee tabs
  /// merge extra fields not listed on the manifest alone).
  final List<FormFieldSpec<E>>? formFields;

  List<FormFieldSpec<E>> get _fields => formFields ?? manifest.formFields;

  static bool isFkType(FieldType type) =>
      type == FieldType.fk || type == FieldType.selfFk;

  void seedFromEntity(E entity) {
    if (state.seeded) return;
    emit(state.copyWith(draft: () => entity, seeded: true));
    for (final field in _fields) {
      if (!isFkType(field.type)) continue;
      final rawId = field.getValue(entity);
      if (rawId == null) continue;
      final key = field.key;
      field.fkResolveById!(rawId).then((resolved) {
        if (isClosed || resolved == null) return;
        // Drop stale resolves if the draft id for this field changed.
        final currentId = field.getValue(state.draft as E);
        if (currentId != rawId) return;
        final cache = Map<String, Object?>.of(state.fkDisplayCache)
          ..[key] = resolved;
        emit(state.copyWith(fkDisplayCache: cache));
      });
    }
  }

  void setField(FormFieldSpec<E> field, Object? value) {
    final draft = state.draft;
    if (draft == null) return;
    final nextDraft = field.setValue(draft, value);
    final errors = Map<String, String>.of(state.fieldErrors)
      ..remove(field.errorKey);
    final cache = Map<String, Object?>.of(state.fkDisplayCache);
    if (isFkType(field.type)) {
      cache[field.key] = value;
    }
    emit(
      state.copyWith(
        draft: () => nextDraft,
        fieldErrors: errors,
        fkDisplayCache: cache,
        savedEntity: () => null,
      ),
    );
  }

  /// For [FieldType.selfFk], drop the draft row from parent candidates so the
  /// user cannot pick self. Full cycle checks remain server-side.
  Future<List<Object>> fkLoader(FormFieldSpec<E> field, String query) async {
    final items = await field.fkSearch!(query);
    final draft = state.draft;
    if (field.type != FieldType.selfFk || draft == null) return items;
    final selfId = idOf(draft);
    return items
        .where((item) => idOf(item as E) != selfId)
        .toList(growable: false);
  }

  /// Validates via [formIsValid] (widget owns [FormState.validate]), then
  /// create/update. On success sets [MasterFormState.savedEntity].
  Future<void> submit({
    required Repository<E, ID> repository,
    required bool Function() formIsValid,
  }) async {
    if (mode == FormMode.edit && !manifest.supportsUpdate) return;
    if (!formIsValid()) return;
    final draft = state.draft;
    if (draft == null) return;

    emit(
      state.copyWith(
        submitting: true,
        generalError: () => null,
        savedEntity: () => null,
      ),
    );

    final result = mode == FormMode.create
        ? await repository.create(draft)
        : await repository.update(idOf(draft), draft);

    if (isClosed) return;

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            submitting: false,
            fieldErrors: fieldErrorsFrom(failure),
            generalError: () =>
                failure is ValidationFailure ? null : _messageOf(failure),
            serverErrorsVersion: state.serverErrorsVersion + 1,
          ),
        );
      },
      (saved) {
        emit(
          state.copyWith(
            submitting: false,
            draft: () => saved,
            savedEntity: () => saved,
          ),
        );
      },
    );
  }

  void clearSaved() {
    if (state.savedEntity == null) return;
    emit(state.copyWith(savedEntity: () => null));
  }

  String _messageOf(Failure failure) => switch (failure) {
    NetworkFailure(:final message) => message,
    TimeoutFailure(:final message) => message,
    UnauthorizedFailure(:final message) => message,
    ForbiddenFailure(:final message) => message,
    ValidationFailure(:final message) => message,
    NotFoundFailure(:final message) => message,
    ConflictFailure(:final message) => message,
    ServerFailure(:final message) => message,
    CacheFailure(:final message) => message,
    UnknownFailure(:final message) => message,
  };
}
