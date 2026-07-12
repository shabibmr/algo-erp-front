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
import 'package:algo_erp_front/core/widgets/layout/page_header.dart';
import 'package:algo_erp_front/core/widgets/layout/work_sheet.dart';
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
/// **No separate `MasterDetailSurface`**: edit mode with fields disabled
/// via `supportsUpdate: false` (and/or RBAC) serves as the read-only view.
/// Form page chrome should title that case "View …" rather than "Edit …".
/// Revisit only if that reads badly in practice — see `docs/manifest-spec.md`.
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
    this.onCancel,
  });

  final EntityManifest<E> manifest;
  final FormMode mode;
  final ID Function(E entity) idOf;
  final ValueChanged<E>? onSaved;
  final VoidCallback? onDeleted;

  /// Leaves the form without saving. Feature pages wire this to "back to the
  /// list"; leave it null and Cancel is disabled.
  final VoidCallback? onCancel;

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

  static bool _isFkType(FieldType type) =>
      type == FieldType.fk || type == FieldType.selfFk;

  void _seedFromLoaded(E entity) {
    if (_seeded) return;
    _seeded = true;
    _draft = entity;
    for (final field in widget.manifest.formFields) {
      if (!_isFkType(field.type)) continue;
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
      if (_isFkType(field.type)) _fkDisplayCache[field.key] = value;
      _fieldErrors = Map.of(_fieldErrors)..remove(field.errorKey);
    });
  }

  /// For [FieldType.selfFk], drop the draft row from parent candidates so the
  /// user cannot pick self. Full cycle checks remain server-side.
  Future<List<Object>> _fkLoader(FormFieldSpec<E> field, String query) async {
    final items = await field.fkSearch!(query);
    if (field.type != FieldType.selfFk || _draft == null) return items;
    final selfId = widget.idOf(_draft as E);
    return items
        .where((item) {
          // Self-ref pickers return the same entity type as the form draft.
          return widget.idOf(item as E) != selfId;
        })
        .toList(growable: false);
  }

  Future<void> _submit(Repository<E, ID> repo) async {
    // Defense in depth: capability flags are primarily a UI concern, but
    // still refuse update when the manifest says the backend has no PUT.
    if (widget.mode == FormMode.edit && !widget.manifest.supportsUpdate) {
      return;
    }
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
    result.fold((failure) {
      setState(() {
        _submitting = false;
        _fieldErrors = fieldErrorsFrom(failure);
        _generalError = failure is ValidationFailure
            ? null
            : _messageOf(failure);
      });
      // FormField only re-runs its validator on Form.validate() — a
      // rebuild alone (even with a changed validator closure) doesn't
      // repaint the new server errorText, so force one after the errors
      // above have landed in the widget tree.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _formKey.currentState?.validate();
      });
    }, (saved) => widget.onSaved?.call(saved));
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
    if (!widget.manifest.supportsDelete) return;
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

  /// The page title. Read-only edit is a *view*, and should say so.
  String get _title => switch (widget.mode) {
    FormMode.create => 'New ${widget.manifest.label.toLowerCase()}',
    FormMode.edit when !widget.manifest.supportsUpdate =>
      'View ${widget.manifest.label.toLowerCase()}',
    FormMode.edit => 'Edit ${widget.manifest.label.toLowerCase()}',
  };

  /// The save button keeps the name of what it does, through the whole flow.
  String get _saveLabel {
    if (_submitting) return 'Saving…';
    return widget.mode == FormMode.create ? 'Create' : 'Save';
  }

  /// Groups the manifest's fields into index cards, preserving manifest order
  /// both within a card and across cards. Fields with no section share a
  /// single unnamed card, which is what every manifest gets until it starts
  /// naming sections.
  Map<String?, List<FormFieldSpec<E>>> get _sections {
    final sections = <String?, List<FormFieldSpec<E>>>{};
    for (final field in widget.manifest.formFields) {
      sections.putIfAbsent(field.section, () => []).add(field);
    }
    return sections;
  }

  Widget _banner(
    BuildContext context, {
    required String message,
    required Color color,
    required IconData icon,
  }) {
    final tokens = context.tokens;
    return Container(
      margin: EdgeInsets.only(bottom: tokens.spacing.md),
      padding: EdgeInsets.all(tokens.spacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(tokens.radii.lg),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          SizedBox(width: tokens.spacing.sm),
          Expanded(
            child: Text(message, style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }

  /// Lays a section's fields out in one or two columns.
  ///
  /// - Mobile: one column.
  /// - Tablet/desktop: two columns by default so the form uses the full
  ///   work area (not a narrow 720px strip). Explicit `half: true` on both
  ///   still pairs; a bool alone at the end of a row stays full width when
  ///   it is the only remaining field.
  List<Widget> _fieldsOf(
    BuildContext context,
    List<FormFieldSpec<E>> fields, {
    required bool enabled,
  }) {
    final tokens = context.tokens;
    final pairUp = !context.isMobile;
    final rows = <Widget>[];

    for (var i = 0; i < fields.length; i++) {
      final field = fields[i];
      final next = i + 1 < fields.length ? fields[i + 1] : null;
      final pairs = pairUp && next != null && _shouldPair(field, next);

      rows.add(
        Padding(
          padding: EdgeInsets.only(top: rows.isEmpty ? 0 : tokens.spacing.md),
          child: pairs
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _field(context, field, enabled: enabled)),
                    SizedBox(width: tokens.spacing.md),
                    Expanded(
                      child: _field(context, next, enabled: enabled),
                    ),
                  ],
                )
              : _field(context, field, enabled: enabled),
        ),
      );
      if (pairs) i++;
    }
    return rows;
  }

  /// Whether [a] and [b] share a row on wide layouts.
  ///
  /// Prefer explicit `half: true` pairs; otherwise auto-pair consecutive
  /// compact fields so full-width forms don't leave empty horizontal space.
  bool _shouldPair(FormFieldSpec<E> a, FormFieldSpec<E> b) {
    if (a.half && b.half) return true;
    // One field opted into half and the other didn't — don't force a pair.
    if (a.half || b.half) return false;
    return _isCompactField(a) && _isCompactField(b);
  }

  bool _isCompactField(FormFieldSpec<E> field) {
    // Switches with long labels read better full width when alone; still
    // pair when both sides are switches or compact inputs.
    return switch (field.type) {
      FieldType.text ||
      FieldType.int ||
      FieldType.decimal ||
      FieldType.dateTime ||
      FieldType.fk ||
      FieldType.selfFk ||
      FieldType.bool => true,
    };
  }

  Widget _field(
    BuildContext context,
    FormFieldSpec<E> field, {
    required bool enabled,
  }) {
    return FieldRenderer.build<E>(
      field: field,
      value: _isFkType(field.type)
          ? _fkDisplayCache[field.key]
          : field.getValue(_draft as E),
      onChanged: (value) => _setField(field, value),
      enabled: enabled,
      errorText: _fieldErrors[field.errorKey],
      fkLoaderOverride: _isFkType(field.type)
          ? (q) => _fkLoader(field, q)
          : null,
    );
  }

  Widget _buildForm(BuildContext context, Repository<E, ID> repo) {
    final tokens = context.tokens;
    final manifest = widget.manifest;
    final action = widget.mode == FormMode.create
        ? PermissionAction.create
        : PermissionAction.update;
    final isReadOnlyEdit =
        widget.mode == FormMode.edit && !manifest.supportsUpdate;
    final canDelete = widget.mode == FormMode.edit && manifest.supportsDelete;
    final sections = _sections;

    Widget formBody;

    if (manifest.formLayout == FormLayout.tabs && sections.length > 1) {
      formBody = DefaultTabController(
        length: sections.length,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isReadOnlyEdit)
              _banner(
                context,
                message: '${manifest.label} records are read-only.',
                color: tokens.brand.inkMuted,
                icon: Icons.lock_outline,
              ),
            if (_generalError != null)
              _banner(
                context,
                message: _generalError!,
                color: tokens.semanticColors.danger,
                icon: Icons.error_outline,
              ),
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                for (final sectionName in sections.keys)
                  Tab(text: sectionName ?? 'General'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  for (final entry in sections.entries)
                    SingleChildScrollView(
                      padding: EdgeInsets.only(top: tokens.spacing.md),
                      child: WorkSheet(
                        fill: false,
                        title: entry.key,
                        padding: EdgeInsets.all(tokens.spacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: _fieldsOf(
                            context,
                            entry.value,
                            enabled: !_submitting && !isReadOnlyEdit,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (manifest.formLayout == FormLayout.columns &&
        sections.length > 1 &&
        !context.isMobile) {
      final col1 = <Widget>[];
      final col2 = <Widget>[];
      for (final (index, entry) in sections.entries.indexed) {
        final sectionWidget = Padding(
          padding: EdgeInsets.only(
            bottom: tokens.spacing.md,
          ),
          child: WorkSheet(
            fill: false,
            title: entry.key,
            padding: EdgeInsets.all(tokens.spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: _fieldsOf(
                context,
                entry.value,
                enabled: !_submitting && !isReadOnlyEdit,
              ),
            ),
          ),
        );
        if (index.isEven) {
          col1.add(sectionWidget);
        } else {
          col2.add(sectionWidget);
        }
      }
      formBody = SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isReadOnlyEdit)
              _banner(
                context,
                message: '${manifest.label} records are read-only.',
                color: tokens.brand.inkMuted,
                icon: Icons.lock_outline,
              ),
            if (_generalError != null)
              _banner(
                context,
                message: _generalError!,
                color: tokens.semanticColors.danger,
                icon: Icons.error_outline,
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: col1,
                  ),
                ),
                SizedBox(width: tokens.spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: col2,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      formBody = SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isReadOnlyEdit)
              _banner(
                context,
                message: '${manifest.label} records are read-only.',
                color: tokens.brand.inkMuted,
                icon: Icons.lock_outline,
              ),
            if (_generalError != null)
              _banner(
                context,
                message: _generalError!,
                color: tokens.semanticColors.danger,
                icon: Icons.error_outline,
              ),
            for (final (index, entry) in sections.entries.indexed) ...[
              if (index > 0) SizedBox(height: tokens.spacing.md),
              WorkSheet(
                fill: false,
                title: entry.key,
                padding: EdgeInsets.all(tokens.spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: _fieldsOf(
                    context,
                    entry.value,
                    enabled: !_submitting && !isReadOnlyEdit,
                  ),
                ),
              ),
            ],
            SizedBox(height: tokens.spacing.lg),
          ],
        ),
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: formBody),
          _Footer(
            children: [
              if (canDelete)
                PermissionGate(
                  module: manifest.rbacModule,
                  action: PermissionAction.delete,
                  child: TextButton.icon(
                    onPressed: _submitting ? null : () => _delete(context),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: tokens.semanticColors.danger,
                    ),
                  ),
                ),
              const Spacer(),
              OutlinedButton(
                onPressed: _submitting ? null : widget.onCancel,
                child: const Text('Cancel'),
              ),
              if (!isReadOnlyEdit) ...[
                SizedBox(width: tokens.spacing.sm),
                PermissionGate(
                  module: manifest.rbacModule,
                  action: action,
                  child: FilledButton(
                    onPressed: _submitting ? null : () => _submit(repo),
                    child: Text(_saveLabel),
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
    final tokens = context.tokens;
    final repo = RepositoryProvider.of<Repository<E, ID>>(context);

    // The header sits outside the load state: which record you opened is known
    // before it arrives, so the page shouldn't be a nameless spinner.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(eyebrow: widget.manifest.eyebrowText, title: _title),
        SizedBox(height: tokens.spacing.lg),
        Expanded(child: _body(context, repo)),
      ],
    );
  }

  Widget _body(BuildContext context, Repository<E, ID> repo) {
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
            onRetry: () => context.read<DetailBloc<E, ID>>().add(
              const DetailLoadRequested(),
            ),
            builder: (context, _) => _buildForm(context, repo),
          );
        },
      ),
    );
  }
}

/// The form's action bar, pinned below the scrolling cards so Save is reachable
/// without scrolling to the bottom of a long form.
class _Footer extends StatelessWidget {
  const _Footer({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: EdgeInsets.only(top: tokens.spacing.md),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: tokens.brand.mist)),
      ),
      child: Row(children: children),
    );
  }
}
