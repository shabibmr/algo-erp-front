import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/auth/permission_gate.dart';
import 'package:algo_erp_front/core/bloc/detail_bloc.dart';
import 'package:algo_erp_front/core/bloc/master_form_cubit.dart';
import 'package:algo_erp_front/core/bloc/master_form_state.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/manifest/entity_manifest.dart';
import 'package:algo_erp_front/core/manifest/field_renderer.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/utils/extensions/view_state_x.dart';
import 'package:algo_erp_front/core/widgets/async_state_view.dart';
import 'package:algo_erp_front/core/widgets/dialogs/confirm_dialog.dart';
import 'package:algo_erp_front/core/widgets/layout/field_widths.dart';
import 'package:algo_erp_front/core/widgets/layout/form_field_layout.dart';
import 'package:algo_erp_front/core/widgets/layout/page_header.dart';
import 'package:algo_erp_front/core/widgets/layout/work_canvas.dart';
import 'package:algo_erp_front/core/widgets/layout/work_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'package:algo_erp_front/core/bloc/master_form_state.dart' show FormMode;

/// Renders a manifest's create/edit form: fields from
/// `manifest.formFields` via [FieldRenderer], server validation errors
/// mapped back to fields by FormMixin inside [MasterFormCubit], and
/// (edit mode) a delete action.
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
/// no-bloc-construction convention. Draft/submit state lives in a local
/// [MasterFormCubit] created by this widget.
class MasterFormSurface<E, ID> extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          MasterFormCubit<E, ID>(manifest: manifest, mode: mode, idOf: idOf),
      child: _MasterFormView<E, ID>(
        manifest: manifest,
        mode: mode,
        idOf: idOf,
        onSaved: onSaved,
        onDeleted: onDeleted,
        onCancel: onCancel,
      ),
    );
  }
}

class _MasterFormView<E, ID> extends StatefulWidget {
  const _MasterFormView({
    required this.manifest,
    required this.mode,
    required this.idOf,
    this.onSaved,
    this.onDeleted,
    this.onCancel,
  });

  final EntityManifest<E> manifest;
  final FormMode mode;
  final ID Function(E entity) idOf;
  final ValueChanged<E>? onSaved;
  final VoidCallback? onDeleted;
  final VoidCallback? onCancel;

  @override
  State<_MasterFormView<E, ID>> createState() => _MasterFormViewState<E, ID>();
}

class _MasterFormViewState<E, ID> extends State<_MasterFormView<E, ID>> {
  final _formKey = GlobalKey<FormState>();

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
  String _saveLabel(bool submitting) {
    if (submitting) return 'Saving…';
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

  List<Widget> _fieldsOf(
    BuildContext context,
    MasterFormCubit<E, ID> cubit,
    MasterFormState<E> state,
    List<FormFieldSpec<E>> fields, {
    required bool enabled,
  }) {
    final items = <FormFieldLayoutItem>[
      for (final field in fields)
        FormFieldLayoutItem(
          type: field.type,
          half: field.half,
          child: _field(context, cubit, state, field, enabled: enabled),
        ),
    ];
    return FormFieldLayout.buildRows(context, items);
  }

  Widget _field(
    BuildContext context,
    MasterFormCubit<E, ID> cubit,
    MasterFormState<E> state,
    FormFieldSpec<E> field, {
    required bool enabled,
  }) {
    final draft = state.draft as E;
    return FieldRenderer.build<E>(
      field: field,
      value: MasterFormCubit.isFkType(field.type)
          ? state.fkDisplayCache[field.key]
          : field.getValue(draft),
      onChanged: (value) => cubit.setField(field, value),
      enabled: enabled,
      errorText: state.fieldErrors[field.errorKey],
      fkLoaderOverride: MasterFormCubit.isFkType(field.type)
          ? (q) => cubit.fkLoader(field, q)
          : null,
    );
  }

  EdgeInsets _sheetPadding(BuildContext context) {
    final s = context.tokens.spacing;
    return EdgeInsets.symmetric(horizontal: s.md, vertical: s.sm);
  }

  Widget _buildForm(
    BuildContext context,
    Repository<E, ID> repo,
    MasterFormCubit<E, ID> cubit,
    MasterFormState<E> state,
  ) {
    final tokens = context.tokens;
    final manifest = widget.manifest;
    final action = widget.mode == FormMode.create
        ? PermissionAction.create
        : PermissionAction.update;
    final isReadOnlyEdit =
        widget.mode == FormMode.edit && !manifest.supportsUpdate;
    final canDelete = widget.mode == FormMode.edit && manifest.supportsDelete;
    final sections = _sections;
    final submitting = state.submitting;
    final generalError = state.generalError;

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
            if (generalError != null)
              _banner(
                context,
                message: generalError,
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
                        padding: _sheetPadding(context),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: _fieldsOf(
                            context,
                            cubit,
                            state,
                            entry.value,
                            enabled: !submitting && !isReadOnlyEdit,
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
          padding: EdgeInsets.only(bottom: tokens.spacing.md),
          child: WorkSheet(
            fill: false,
            title: entry.key,
            padding: _sheetPadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: _fieldsOf(
                context,
                cubit,
                state,
                entry.value,
                enabled: !submitting && !isReadOnlyEdit,
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
            if (generalError != null)
              _banner(
                context,
                message: generalError,
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
            if (generalError != null)
              _banner(
                context,
                message: generalError,
                color: tokens.semanticColors.danger,
                icon: Icons.error_outline,
              ),
            for (final (index, entry) in sections.entries.indexed) ...[
              if (index > 0) SizedBox(height: tokens.spacing.md),
              WorkSheet(
                fill: false,
                title: entry.key,
                padding: _sheetPadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: _fieldsOf(
                    context,
                    cubit,
                    state,
                    entry.value,
                    enabled: !submitting && !isReadOnlyEdit,
                  ),
                ),
              ),
            ],
            SizedBox(height: tokens.spacing.md),
          ],
        ),
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: FieldWidths.formContent,
                ),
                child: formBody,
              ),
            ),
          ),
          _Footer(
            children: [
              if (canDelete)
                PermissionGate(
                  module: manifest.rbacModule,
                  action: PermissionAction.delete,
                  child: TextButton.icon(
                    onPressed: submitting ? null : () => _delete(context),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: tokens.semanticColors.danger,
                    ),
                  ),
                ),
              const Spacer(),
              OutlinedButton(
                onPressed: submitting ? null : widget.onCancel,
                child: const Text('Cancel'),
              ),
              if (!isReadOnlyEdit) ...[
                SizedBox(width: tokens.spacing.sm),
                PermissionGate(
                  module: manifest.rbacModule,
                  action: action,
                  child: FilledButton(
                    onPressed: submitting
                        ? null
                        : () => cubit.submit(
                            repository: repo,
                            formIsValid: () =>
                                _formKey.currentState?.validate() ?? false,
                          ),
                    child: Text(_saveLabel(submitting)),
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

    return BlocListener<MasterFormCubit<E, ID>, MasterFormState<E>>(
      listenWhen: (previous, current) =>
          previous.savedEntity != current.savedEntity &&
              current.savedEntity != null ||
          previous.serverErrorsVersion != current.serverErrorsVersion,
      listener: (context, state) {
        final saved = state.savedEntity;
        if (saved != null) {
          widget.onSaved?.call(saved);
          context.read<MasterFormCubit<E, ID>>().clearSaved();
          return;
        }
        // FormField only re-runs its validator on Form.validate() — a
        // rebuild alone doesn't repaint new server errorText.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _formKey.currentState?.validate();
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(eyebrow: widget.manifest.eyebrowText, title: _title),
          SizedBox(height: tokens.spacing.lg),
          // Desk Lamp: the card stack gets a soft lagoon focus rim — personal
          // attention on this record. Lists deliberately stay unlit.
          Expanded(child: WorkCanvas(child: _body(context, repo))),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, Repository<E, ID> repo) {
    if (widget.mode == FormMode.create) {
      return BlocBuilder<MasterFormCubit<E, ID>, MasterFormState<E>>(
        builder: (context, state) {
          final cubit = context.read<MasterFormCubit<E, ID>>();
          return _buildForm(context, repo, cubit, state);
        },
      );
    }

    return MultiBlocListener(
      listeners: [
        BlocListener<DetailBloc<E, ID>, DetailState<E>>(
          listener: (context, state) {
            if (state is DetailDeleted<E>) widget.onDeleted?.call();
          },
        ),
      ],
      child: BlocBuilder<DetailBloc<E, ID>, DetailState<E>>(
        builder: (context, detailState) {
          return AsyncStateView<E>(
            state: detailState.toViewState(),
            onRetry: () => context.read<DetailBloc<E, ID>>().add(
              const DetailLoadRequested(),
            ),
            builder: (context, entity) {
              return BlocBuilder<MasterFormCubit<E, ID>, MasterFormState<E>>(
                builder: (context, formState) {
                  final cubit = context.read<MasterFormCubit<E, ID>>();
                  // Seed the draft from the loaded entity here rather than
                  // via a BlocListener on DetailBloc: a listener only fires on
                  // transitions after it subscribes, so if the detail load
                  // reaches Loaded before this subtree mounts, the transition
                  // is missed and the form never seeds. The builder always sees
                  // the current loaded entity. Seeding is idempotent (guarded
                  // by `seeded`); the post-frame defers the emit out of build.
                  if (!formState.seeded) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (context.mounted) cubit.seedFromEntity(entity);
                    });
                    return const SizedBox.shrink();
                  }
                  if (formState.draft == null) {
                    return const SizedBox.shrink();
                  }
                  return _buildForm(context, repo, cubit, formState);
                },
              );
            },
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
