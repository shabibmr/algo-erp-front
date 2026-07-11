import 'package:algo_erp_front/core/manifest/entity_manifest.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/features/organization_user_role/domain/user_role.dart';

/// UserRole's manifest. Unlike Inventory/Employee — which gate every route
/// behind one coarse module string — Organization's routes `authorize()` per
/// entity, so `rbacModule` is `'UserRole'`, not `'Organization'`
/// (`organization.routes.ts`).
final userRoleManifest = EntityManifest<UserRole>(
  id: 'user-role',
  label: 'User role',
  rbacModule: 'UserRole',
  resourcePath: '/organization/roles',
  listColumns: [
    FieldSpec<UserRole>(
      key: 'name',
      label: 'Role',
      type: FieldType.text,
      required: true,
      cellValue: (r) => r.name,
    ),
    FieldSpec<UserRole>(
      key: 'description',
      label: 'Description',
      type: FieldType.text,
      cellValue: (r) => r.description ?? '—',
    ),
  ],
  searchFields: const ['name', 'description'],
  formFields: [
    FormFieldSpec<UserRole>(
      key: 'name',
      wireKey: 'role_name',
      label: 'Role',
      type: FieldType.text,
      required: true,
      getValue: (r) => r.name,
      setValue: (r, v) => r.copyWith(name: v as String?),
    ),
    FormFieldSpec<UserRole>(
      key: 'description',
      wireKey: 'description',
      label: 'Description',
      type: FieldType.text,
      getValue: (r) => r.description,
      setValue: (r, v) => r.copyWith(description: v),
    ),
  ],
  emptyEntity: () => const UserRole(id: 0, name: ''),
  hardDelete: true,
);
