import 'dart:async';

import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/auth/permission_gate.dart';
import 'package:algo_erp_front/core/bloc/detail_bloc.dart';
import 'package:algo_erp_front/core/bloc/form_mixin.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/manifest/entity_manifest.dart';
import 'package:algo_erp_front/core/manifest/field_renderer.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/utils/extensions/view_state_x.dart';
import 'package:algo_erp_front/core/widgets/async_state_view.dart';
import 'package:algo_erp_front/core/widgets/dialogs/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Whether a [MasterFormSurface] is creating a new entity or editing one.
enum FormMode { create, edit }

/// Renders a manifest's create/edit form: fields from
/// `manifest.formFields` via [FieldRenderer], server validation errors
/// mapped back to fields by [FormMixin], and (edit mode) a delete action.
///
/// **Update-event design**: submits call `Repository<E,ID>.create`/`.update`
/// directly (already the exact `Future<Result<E>>` shape a form submit
/// needs) rather than going through `CrudBloc`'s fire-and-forget list-sync
/// events or adding a duplicate update event to `DetailBloc`. `DetailBloc`
/// keeps its narrower existing job: edit-mode's initial load and delete.
/// The list screen re-fetches naturally when the caller navigates back to it
/// (its `CrudBloc` is reconstructed fresh, per `BrandListPage`'s pattern).
///
/// **No separate `MasterDetailSurface`**: edit mode with every field's
/// `enabled` gated by RBAC serves as the read-only view. Revisit only if
/// that reads badly in practice — see `docs/manifest-spec.md`.
///
/// Expects a `Repository<E, ID>` provided above it (via `RepositoryProvider`)
/// and — in edit mode — a `DetailBloc<E, ID>` provided above it as well.
/// The Surface constructs neither, matching `MasterListSurface`'s
/// no-bloc-construction convention.
class MasterFormSurface<E, ID> extends StatefulWidget {
  const MasterFormSurface({
    required this.manifest,
    required this.mode,
    required this.idOf,
    super.key,
    this.onSaved,
    this.onDeleted,
  });

  final EntityManifest<E> manifest;
  final FormMode mode;
  final ID Function(E entity) idOf;
  final ValueChanged<E>? onSaved;
  final VoidCallback? onDeleted;

  @override
  State<MasterFormSurface<E, ID>> createState() =>
      _MasterFormSurfaceState<E, ID>();
}

class _MasterFormSurfaceState<E, ID> extends State<MasterFormSurface<E, ID>>
    with FormMixin {
  final _formKey = GlobalKey<FormState>();
  E? _draft;
  bool _seeded = false;
  bool _submitting = false;
  String? _generalError;
  Map<String, String> _fieldErrors = const {};
  final Map<String, Object?> _fkDisplayCache = {};

  @override
  void initState() {
    super.initState();
    if (widget.mode == FormMode.create) {
      _draft = widget.manifest.emptyEntity!();
      _seeded = true;
    }
  }

  void _seedFromLoaded(E entity) {
    if (_seeded) return;
    _seeded = true;
    _draft = entity;
    for (final field in widget.manifest.formFields) {
      if (field.type != FieldType.fk) continue;
      final rawId = field.getValue(entity);
      if (rawId == null) continue;
      unawaited(
        field.fkResolveById!(rawId).then((resolved) {
          if (!mounted || resolved == null) return;
          setState(() => _fkDisplayCache[field.key] = resolved);
        }),
      );
    }
  }

  void _setField(FormFieldSpec<E> field, Object? value) {
    setState(() {
      _draft = field.setValue(_draft as E, value);
      if (field.type == FieldType.fk) _fkDisplayCache[field.key] = value;
      _fieldErrors = Map.of(_fieldErrors)..remove(field.errorKey);
    });
  }

  Future<void> _submit(Repository<E, ID> repo) async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;
    setState(() {
      _submitting = true;
      _generalError = null;
    });
    final draft = _draft as E;
    final result = widget.mode == FormMode.create
        ? await repo.create(draft)
        : await repo.update(widget.idOf(draft), draft);
    if (!mounted) return;
    result.fold(
      (failure) {
        setState(() {
          _submitting = false;
          _fieldErrors = fieldErrorsFrom(failure);
          _generalError =
              failure is ValidationFailure ? null : _messageOf(failure);
        });
        // FormField only re-runs its validator on Form.validate() — a
        // rebuild alone (even with a changed validator closure) doesn't
        // repaint the new server errorText, so force one after the errors
        // above have landed in the widget tree.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _formKey.currentState?.validate();
        });
      },
      (saved) => widget.onSaved?.call(saved),
    );
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

  Future<void> _delete(BuildContext context) async {
    final manifest = widget.manifest;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete ${manifest.label}?',
      message: manifest.hardDelete
          ? 'This cannot be undone.'
          : 'This can be restored later.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    context.read<DetailBloc<E, ID>>().add(const DetailDeleteRequested());
  }

  Widget _buildForm(BuildContext context, Repository<E, ID> repo) {
    final tokens = context.tokens;
    final manifest = widget.manifest;
    final action = widget.mode == FormMode.create
        ? PermissionAction.create
        : PermissionAction.update;
    final isReadOnlyEdit =
        widget.mode == FormMode.edit && !manifest.supportsUpdate;
    final canDelete =
        widget.mode == FormMode.edit && manifest.supportsDelete;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isReadOnlyEdit) ...[
            Container(
              padding: EdgeInsets.all(tokens.spacing.sm),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(tokens.radii.sm),
              ),
              child: const Text(
                'This entity cannot be edited — the backend has no update '
                'endpoint for it.',
              ),
            ),
            SizedBox(height: tokens.spacing.md),
          ],
          if (_generalError != null) ...[
            Container(
              padding: EdgeInsets.all(tokens.spacing.sm),
              decoration: BoxDecoration(
                color: tokens.semanticColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(tokens.radii.sm),
              ),
              child: Text(
                _generalError!,
                style: TextStyle(color: tokens.semanticColors.danger),
              ),
            ),
            SizedBox(height: tokens.spacing.md),
          ],
          for (final field in manifest.formFields) ...[
            FieldRenderer.build<E>(
              field: field,
              value: field.type == FieldType.fk
                  ? _fkDisplayCache[field.key]
                  : field.getValue(_draft as E),
              onChanged: (value) => _setField(field, value),
              enabled: !_submitting && !isReadOnlyEdit,
              errorText: _fieldErrors[field.errorKey],
            ),
            SizedBox(height: tokens.spacing.sm),
          ],
          SizedBox(height: tokens.spacing.md),
          Row(
            children: [
              if (!isReadOnlyEdit)
                PermissionGate(
                  module: manifest.rbacModule,
                  action: action,
                  child: FilledButton(
                    onPressed: _submitting ? null : () => _submit(repo),
                    child: Text(_submitting
                        ? 'Saving...'
                        : (widget.mode == FormMode.create
                            ? 'Create'
                            : 'Save')),
                  ),
                ),
              if (canDelete) ...[
                SizedBox(width: tokens.spacing.sm),
                PermissionGate(
                  module: manifest.rbacModule,
                  action: PermissionAction.delete,
                  child: OutlinedButton(
                    onPressed: _submitting ? null : () => _delete(context),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryProvider.of<Repository<E, ID>>(context);

    if (widget.mode == FormMode.create) {
      return _buildForm(context, repo);
    }

    return BlocListener<DetailBloc<E, ID>, DetailState<E>>(
      listener: (context, state) {
        if (state is DetailDeleted<E>) widget.onDeleted?.call();
      },
      child: BlocBuilder<DetailBloc<E, ID>, DetailState<E>>(
        builder: (context, state) {
          if (state is DetailLoaded<E>) _seedFromLoaded(state.entity);
          return AsyncStateView<E>(
            state: state.toViewState(),
            onRetry: () => context
                .read<DetailBloc<E, ID>>()
                .add(const DetailLoadRequested()),
            builder: (context, _) => _buildForm(context, repo),
          );
        },
      ),
    );
  }
}
