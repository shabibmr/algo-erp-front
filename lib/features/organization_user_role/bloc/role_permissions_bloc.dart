import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/organization_user_role/bloc/role_permissions_event.dart';
import 'package:algo_erp_front/features/organization_user_role/bloc/role_permissions_state.dart';
import 'package:algo_erp_front/features/organization_user_role/data/role_permissions_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RolePermissionsBloc
    extends Bloc<RolePermissionsEvent, RolePermissionsState> {
  RolePermissionsBloc({required RolePermissionsRepository repository})
    : _repository = repository,
      super(const RolePermissionsState()) {
    on<RolePermissionsFetchRequested>(_onFetchRequested);
    on<RolePermissionToggled>(_onPermissionToggled);
    on<RolePermissionsSaved>(_onSaved);
  }

  final RolePermissionsRepository _repository;

  Future<void> _onFetchRequested(
    RolePermissionsFetchRequested event,
    Emitter<RolePermissionsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: RolePermissionsStatus.loading,
        roleId: event.roleId,
        errorMessage: () => null,
        saveSuccess: false,
      ),
    );

    final result = await _repository.list(event.roleId);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: RolePermissionsStatus.failure,
          failure: () => failure,
        ),
      ),
      (list) {
        final map = <String, ModulePermissions>{
          for (final m in kPermissionMatrixModules)
            m: ModulePermissions(module: m),
        };
        for (final row in list) {
          if (row.module.isNotEmpty) {
            map[row.module] = row;
          }
        }
        emit(state.copyWith(status: RolePermissionsStatus.success, rows: map));
      },
    );
  }

  void _onPermissionToggled(
    RolePermissionToggled event,
    Emitter<RolePermissionsState> emit,
  ) {
    final currentMap = Map<String, ModulePermissions>.of(state.rows);
    final cur =
        currentMap[event.module] ?? ModulePermissions(module: event.module);

    currentMap[event.module] = ModulePermissions(
      module: event.module,
      create: event.action == PermissionAction.create
          ? event.value
          : cur.create,
      read: event.action == PermissionAction.read ? event.value : cur.read,
      update: event.action == PermissionAction.update
          ? event.value
          : cur.update,
      delete: event.action == PermissionAction.delete
          ? event.value
          : cur.delete,
      share: event.action == PermissionAction.share ? event.value : cur.share,
    );

    emit(state.copyWith(rows: currentMap));
  }

  Future<void> _onSaved(
    RolePermissionsSaved event,
    Emitter<RolePermissionsState> emit,
  ) async {
    if (state.roleId == null) return;

    emit(
      state.copyWith(
        isSaving: true,
        errorMessage: () => null,
        saveSuccess: false,
      ),
    );

    final payload = state.rows.values
        .where((p) => p.create || p.read || p.update || p.delete || p.share)
        .toList(growable: false);

    final result = await _repository.save(state.roleId!, payload);

    result.fold(
      (failure) => emit(
        state.copyWith(
          isSaving: false,
          errorMessage: () => _messageOf(failure),
        ),
      ),
      (_) {
        emit(state.copyWith(isSaving: false, saveSuccess: true));
        add(RolePermissionsFetchRequested(state.roleId!));
      },
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
