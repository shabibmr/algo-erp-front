import 'dart:async';

import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/auth/permission_gate.dart';
import 'package:algo_erp_front/core/bloc/detail_bloc.dart';
import 'package:algo_erp_front/core/bloc/form_mixin.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/manifest/field_renderer.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/utils/extensions/view_state_x.dart';
import 'package:algo_erp_front/core/widgets/async_state_view.dart';
import 'package:algo_erp_front/core/widgets/dialogs/confirm_dialog.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:algo_erp_front/features/accounts_ledger/ledger_di.dart';
import 'package:algo_erp_front/features/accounts_ledger/ledger_extension_fields.dart';
import 'package:algo_erp_front/features/accounts_ledger/ledger_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Tabbed ledger form: Core + Bank + Credit + Tax.
///
/// Extensions nest into the same create/update payload (`bankDetails`,
/// `creditSettings`, `taxSettings`) — not separate menu entities.
class LedgerFormPage extends StatelessWidget {
  const LedgerFormPage({required this.mode, super.key, this.entityId});

  final FormMode mode;
  final int? entityId;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<Repository<Ledger, int>>(
      create: (_) => createLedgerRepository(getIt<DioClient>()),
      child: Builder(
        builder: (context) {
          final title = mode == FormMode.create
              ? 'New ${ledgerManifest.label}'
              : ledgerManifest.supportsUpdate
                  ? 'Edit ${ledgerManifest.label}'
                  : 'View ${ledgerManifest.label}';
          return AdaptiveLayout(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 16),
                Expanded(
                  child: mode == FormMode.edit
                      ? BlocProvider<DetailBloc<Ledger, int>>(
                          create: (ctx) => DetailBloc<Ledger, int>(
                            repository:
                                ctx.read<Repository<Ledger, int>>(),
                            id: entityId!,
                          )..add(const DetailLoadRequested()),
                          child: _LedgerTabbedForm(mode: mode),
                        )
                      : _LedgerTabbedForm(mode: mode),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LedgerTabbedForm extends StatefulWidget {
  const _LedgerTabbedForm({required this.mode});

  final FormMode mode;

  @override
  State<_LedgerTabbedForm> createState() => _LedgerTabbedFormState();
}

class _LedgerTabbedFormState extends State<_LedgerTabbedForm>
    with FormMixin, SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _formKey = GlobalKey<FormState>();
  late Ledger _draft;
  bool _seeded = false;
  bool _submitting = false;
  String? _generalError;
  Map<String, String> _fieldErrors = const {};
  final Map<String, Object?> _fkDisplayCache = {};

  List<FormFieldSpec<Ledger>> get _allFields =>
      allLedgerFormFields(ledgerManifest.formFields);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    if (widget.mode == FormMode.create) {
      _draft = ledgerManifest.emptyEntity!();
      _seeded = true;
    } else {
      // Placeholder until DetailBloc seeds the real row.
      _draft = ledgerManifest.emptyEntity!();
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  static bool _isFkType(FieldType type) =>
      type == FieldType.fk || type == FieldType.selfFk;

  void _seedFromLoaded(Ledger entity) {
    if (_seeded) return;
    _seeded = true;
    _draft = entity;
    for (final field in _allFields) {
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

  void _setField(FormFieldSpec<Ledger> field, Object? value) {
    setState(() {
      _draft = field.setValue(_draft, value);
      if (_isFkType(field.type)) _fkDisplayCache[field.key] = value;
      _fieldErrors = Map.of(_fieldErrors)..remove(field.errorKey);
    });
  }

  Future<List<Object>> _fkLoader(
    FormFieldSpec<Ledger> field,
    String query,
  ) async {
    return field.fkSearch!(query);
  }

  Future<void> _submit(Repository<Ledger, int> repo) async {
    if (widget.mode == FormMode.edit && !ledgerManifest.supportsUpdate) {
      return;
    }
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;
    setState(() {
      _submitting = true;
      _generalError = null;
    });
    final draft = _draft;
    final result = widget.mode == FormMode.create
        ? await repo.create(draft)
        : await repo.update(draft.id, draft);
    if (!mounted) return;
    result.fold(
      (failure) {
        setState(() {
          _submitting = false;
          _fieldErrors = fieldErrorsFrom(failure);
          _generalError =
              failure is ValidationFailure ? null : _messageOf(failure);
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _formKey.currentState?.validate();
        });
      },
      (_) => context.go(ledgerManifest.resourcePath),
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
    if (!ledgerManifest.supportsDelete) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete ${ledgerManifest.label}?',
      message: ledgerManifest.hardDelete
          ? 'This cannot be undone.'
          : 'This can be restored later.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    context.read<DetailBloc<Ledger, int>>().add(const DetailDeleteRequested());
  }

  Widget _fieldList(List<FormFieldSpec<Ledger>> fields) {
    final tokens = context.tokens;
    final isReadOnlyEdit =
        widget.mode == FormMode.edit && !ledgerManifest.supportsUpdate;
    return ListView(
      padding: EdgeInsets.only(top: tokens.spacing.sm),
      children: [
        for (final field in fields) ...[
          FieldRenderer.build<Ledger>(
            field: field,
            value: _isFkType(field.type)
                ? _fkDisplayCache[field.key]
                : field.getValue(_draft),
            onChanged: (value) => _setField(field, value),
            enabled: !_submitting && !isReadOnlyEdit,
            errorText: _fieldErrors[field.errorKey],
            fkLoaderOverride:
                _isFkType(field.type) ? (q) => _fkLoader(field, q) : null,
          ),
          SizedBox(height: tokens.spacing.sm),
        ],
      ],
    );
  }

  Widget _buildForm(Repository<Ledger, int> repo) {
    final tokens = context.tokens;
    final action = widget.mode == FormMode.create
        ? PermissionAction.create
        : PermissionAction.update;
    final isReadOnlyEdit =
        widget.mode == FormMode.edit && !ledgerManifest.supportsUpdate;
    final canDelete =
        widget.mode == FormMode.edit && ledgerManifest.supportsDelete;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isReadOnlyEdit) ...[
            Container(
              padding: EdgeInsets.all(tokens.spacing.sm),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(tokens.radii.sm),
              ),
              child: const Text('This entity cannot be edited.'),
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
          TabBar(
            controller: _tabs,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Core'),
              Tab(text: 'Bank'),
              Tab(text: 'Credit'),
              Tab(text: 'Tax'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _fieldList(ledgerManifest.formFields),
                _fieldList(ledgerBankFormFields),
                _fieldList(ledgerCreditFormFields),
                _fieldList(ledgerTaxFormFields),
              ],
            ),
          ),
          SizedBox(height: tokens.spacing.md),
          Row(
            children: [
              if (!isReadOnlyEdit)
                PermissionGate(
                  module: ledgerManifest.rbacModule,
                  action: action,
                  child: FilledButton(
                    onPressed: _submitting ? null : () => _submit(repo),
                    child: Text(
                      _submitting
                          ? 'Saving...'
                          : (widget.mode == FormMode.create
                              ? 'Create'
                              : 'Save'),
                    ),
                  ),
                ),
              if (canDelete) ...[
                if (!isReadOnlyEdit) SizedBox(width: tokens.spacing.sm),
                PermissionGate(
                  module: ledgerManifest.rbacModule,
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
    final repo = RepositoryProvider.of<Repository<Ledger, int>>(context);

    if (widget.mode == FormMode.create) {
      return _buildForm(repo);
    }

    return BlocListener<DetailBloc<Ledger, int>, DetailState<Ledger>>(
      listener: (context, state) {
        if (state is DetailDeleted<Ledger>) {
          context.go(ledgerManifest.resourcePath);
        }
      },
      child: BlocBuilder<DetailBloc<Ledger, int>, DetailState<Ledger>>(
        builder: (context, state) {
          if (state is DetailLoaded<Ledger>) _seedFromLoaded(state.entity);
          return AsyncStateView<Ledger>(
            state: state.toViewState(),
            onRetry: () => context
                .read<DetailBloc<Ledger, int>>()
                .add(const DetailLoadRequested()),
            builder: (context, _) => _buildForm(repo),
          );
        },
      ),
    );
  }
}
