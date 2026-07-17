import 'package:equatable/equatable.dart';

/// Whether a [MasterFormSurface] is creating a new entity or editing one.
enum FormMode { create, edit }

/// Immutable UI state for [MasterFormCubit] / [MasterFormSurface].
final class MasterFormState<E> extends Equatable {
  const MasterFormState({
    this.draft,
    this.seeded = false,
    this.submitting = false,
    this.generalError,
    this.fieldErrors = const {},
    this.fkDisplayCache = const {},
    this.savedEntity,
    this.serverErrorsVersion = 0,
  });

  final E? draft;
  final bool seeded;
  final bool submitting;
  final String? generalError;
  final Map<String, String> fieldErrors;
  final Map<String, Object?> fkDisplayCache;

  /// Set after a successful create/update so the surface can fire [onSaved].
  final E? savedEntity;

  /// Bumped when server field errors land so the form re-validates once.
  final int serverErrorsVersion;

  MasterFormState<E> copyWith({
    E? Function()? draft,
    bool? seeded,
    bool? submitting,
    String? Function()? generalError,
    Map<String, String>? fieldErrors,
    Map<String, Object?>? fkDisplayCache,
    E? Function()? savedEntity,
    int? serverErrorsVersion,
  }) {
    return MasterFormState<E>(
      draft: draft != null ? draft() : this.draft,
      seeded: seeded ?? this.seeded,
      submitting: submitting ?? this.submitting,
      generalError: generalError != null ? generalError() : this.generalError,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      fkDisplayCache: fkDisplayCache ?? this.fkDisplayCache,
      savedEntity: savedEntity != null ? savedEntity() : this.savedEntity,
      serverErrorsVersion: serverErrorsVersion ?? this.serverErrorsVersion,
    );
  }

  @override
  List<Object?> get props => [
    draft,
    seeded,
    submitting,
    generalError,
    fieldErrors,
    fkDisplayCache,
    savedEntity,
    serverErrorsVersion,
  ];
}
