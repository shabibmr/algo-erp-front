import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/widgets/states/error_state.dart';
import 'package:algo_erp_front/core/widgets/states/loading_state.dart';
import 'package:algo_erp_front/features/organization_user_role/data/role_permissions_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Editable RBAC matrix for one role (full replace on save).
class RolePermissionsPage extends StatefulWidget {
  const RolePermissionsPage({required this.roleId, this.roleName, super.key});

  final int roleId;
  final String? roleName;

  @override
  State<RolePermissionsPage> createState() => _RolePermissionsPageState();
}

class _RolePermissionsPageState extends State<RolePermissionsPage> {
  late final _repo = RolePermissionsRepository(getIt<DioClient>());
  Future<List<ModulePermissions>>? _future;
  Map<String, ModulePermissions> _rows = {};
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = _load();
      _error = null;
    });
  }

  Future<List<ModulePermissions>> _load() async {
    final result = await _repo.list(widget.roleId);
    return result.fold((f) => throw Exception(f.toString()), (list) {
      final map = <String, ModulePermissions>{
        for (final m in kPermissionMatrixModules)
          m: ModulePermissions(module: m),
      };
      for (final row in list) {
        if (row.module.isEmpty) continue;
        map[row.module] = row;
      }
      _rows = map;
      return map.values.toList(growable: false);
    });
  }

  void _toggle(String module, PermissionAction action, bool value) {
    final cur = _rows[module] ?? ModulePermissions(module: module);
    setState(() {
      _rows[module] = ModulePermissions(
        module: module,
        create: action == PermissionAction.create ? value : cur.create,
        read: action == PermissionAction.read ? value : cur.read,
        update: action == PermissionAction.update ? value : cur.update,
        delete: action == PermissionAction.delete ? value : cur.delete,
        share: action == PermissionAction.share ? value : cur.share,
      );
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    // Send only rows that have any permission granted (full replace).
    final payload = _rows.values
        .where((p) => p.create || p.read || p.update || p.delete || p.share)
        .toList(growable: false);
    final result = await _repo.save(widget.roleId, payload);
    if (!mounted) return;
    result.fold(
      (f) {
        setState(() {
          _saving = false;
          _error = switch (f) {
            NetworkFailure(:final message) => message,
            ValidationFailure(:final message) => message,
            ForbiddenFailure(:final message) => message,
            ServerFailure(:final message) => message,
            _ => f.toString(),
          };
        });
      },
      (_) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Permissions saved')));
        _reload();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final title = widget.roleName == null
        ? 'Permissions'
        : 'Permissions · ${widget.roleName}';
    return AdaptiveLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: () =>
                    context.go('/organization/roles/${widget.roleId}'),
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save matrix'),
              ),
            ],
          ),
          SizedBox(height: tokens.spacing.sm),
          Text(
            'Saving replaces the role’s full permission matrix. '
            'Modules with no checks are removed.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (_error != null) ...[
            SizedBox(height: tokens.spacing.sm),
            Text(
              _error!,
              style: TextStyle(color: tokens.semanticColors.danger),
            ),
          ],
          SizedBox(height: tokens.spacing.md),
          Expanded(
            child: FutureBuilder<List<ModulePermissions>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const LoadingState();
                }
                if (snap.hasError) {
                  final err = snap.error;
                  return ErrorState(
                    failure: err is Failure
                        ? err
                        : Failure.unknown(err.toString()),
                    onRetry: _reload,
                  );
                }
                const modules = kPermissionMatrixModules;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 720,
                    child: ListView.separated(
                      itemCount: modules.length + 1,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          return ListTile(
                            title: Text(
                              'Module',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            trailing: const SizedBox(
                              width: 280,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Text('C'),
                                  Text('R'),
                                  Text('U'),
                                  Text('D'),
                                  Text('S'),
                                ],
                              ),
                            ),
                          );
                        }
                        final module = modules[i - 1];
                        final row =
                            _rows[module] ?? ModulePermissions(module: module);
                        Widget box({
                          required bool value,
                          required PermissionAction action,
                        }) => Checkbox(
                          value: value,
                          onChanged: _saving
                              ? null
                              : (v) => _toggle(module, action, v ?? false),
                        );
                        return ListTile(
                          title: Text(module),
                          trailing: SizedBox(
                            width: 280,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                box(
                                  value: row.create,
                                  action: PermissionAction.create,
                                ),
                                box(
                                  value: row.read,
                                  action: PermissionAction.read,
                                ),
                                box(
                                  value: row.update,
                                  action: PermissionAction.update,
                                ),
                                box(
                                  value: row.delete,
                                  action: PermissionAction.delete,
                                ),
                                box(
                                  value: row.share,
                                  action: PermissionAction.share,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
