import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/manifest/entity_manifest.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/organization_address_book/address_book_di.dart';
import 'package:algo_erp_front/features/organization_address_book/domain/address_book.dart';
import 'package:algo_erp_front/features/organization_branch/branch_di.dart';
import 'package:algo_erp_front/features/organization_branch/domain/branch.dart';
import 'package:algo_erp_front/features/organization_user/domain/user_credentials.dart';
import 'package:algo_erp_front/features/organization_user_role/domain/user_role.dart';
import 'package:algo_erp_front/features/organization_user_role/user_role_di.dart';

final _contactRepo = createAddressBookRepository(getIt<DioClient>());
final _roleRepo = createUserRoleRepository(getIt<DioClient>());
final _branchRepo = createBranchRepository(getIt<DioClient>());

/// UserCredentials — password is write-only; multi-FK contact/role/branch.
final userCredentialsManifest = EntityManifest<UserCredentials>(
  id: 'user-credentials',
  label: 'User',
  rbacModule: 'UserCredentials',
  resourcePath: '/organization/users',
  formLayout: FormLayout.columns,
  listColumns: [
    FieldSpec<UserCredentials>(
      key: 'username',
      label: 'Username',
      type: FieldType.text,
      required: true,
      cellValue: (u) => u.username,
    ),
    FieldSpec<UserCredentials>(
      key: 'roleId',
      label: 'Role id',
      type: FieldType.int,
      cellValue: (u) => '${u.roleId}',
    ),
    FieldSpec<UserCredentials>(
      key: 'isActive',
      label: 'Active',
      type: FieldType.bool,
      cellValue: (u) => u.isActive ? 'Yes' : 'No',
    ),
  ],
  searchFields: const ['username'],
  formFields: [
    FormFieldSpec<UserCredentials>(
      key: 'username',
      wireKey: 'username',
      label: 'Username',
      type: FieldType.text,
      required: true,
      helperText: 'Min 3 characters; not changeable after create',
      getValue: (u) => u.username,
      setValue: (u, v) => u.copyWith(username: v as String? ?? ''),
      section: 'Account',
    ),
    FormFieldSpec<UserCredentials>(
      key: 'password',
      wireKey: 'password',
      label: 'Password',
      type: FieldType.text,
      helperText: 'Required on create; leave blank on edit to keep current',
      getValue: (u) => u.password,
      setValue: (u, v) => u.copyWith(password: v as String?),
      section: 'Account',
    ),
    FormFieldSpec<UserCredentials>(
      key: 'contactId',
      wireKey: 'contact_id',
      label: 'Contact',
      type: FieldType.fk,
      required: true,
      getValue: (u) => u.contactId == 0 ? null : u.contactId,
      setValue: (u, v) {
        final contact = v as AddressBook?;
        return u.copyWith(contactId: contact?.id ?? 0);
      },
      fkSearch: (q) async {
        final r = await _contactRepo.list(PageQuery(search: q));
        return r.fold((_) => const [], (p) => p.items);
      },
      fkDisplayOf: (item) => (item as AddressBook).name,
      fkResolveById: (id) async {
        final r = await _contactRepo.getById(id as int);
        return r.fold((_) => null, (c) => c);
      },
      section: 'Links',
    ),
    FormFieldSpec<UserCredentials>(
      key: 'roleId',
      wireKey: 'role_id',
      label: 'Role',
      type: FieldType.fk,
      required: true,
      getValue: (u) => u.roleId == 0 ? null : u.roleId,
      setValue: (u, v) {
        final role = v as UserRole?;
        return u.copyWith(roleId: role?.id ?? 0);
      },
      fkSearch: (q) async {
        final r = await _roleRepo.list(PageQuery(search: q));
        return r.fold((_) => const [], (p) => p.items);
      },
      fkDisplayOf: (item) => (item as UserRole).name,
      fkResolveById: (id) async {
        final r = await _roleRepo.getById(id as int);
        return r.fold((_) => null, (role) => role);
      },
      section: 'Links',
    ),
    FormFieldSpec<UserCredentials>(
      key: 'branchId',
      wireKey: 'branch_id',
      label: 'Branch',
      type: FieldType.fk,
      getValue: (u) => u.branchId,
      setValue: (u, v) {
        final branch = v as Branch?;
        return u.copyWith(branchId: branch?.id);
      },
      fkSearch: (q) async {
        final r = await _branchRepo.list(PageQuery(search: q));
        return r.fold((_) => const [], (p) => p.items);
      },
      fkDisplayOf: (item) => (item as Branch).name,
      fkResolveById: (id) async {
        final r = await _branchRepo.getById(id as int);
        return r.fold((_) => null, (b) => b);
      },
      section: 'Links',
    ),
    FormFieldSpec<UserCredentials>(
      key: 'isActive',
      wireKey: 'is_active',
      label: 'Active',
      type: FieldType.bool,
      getValue: (u) => u.isActive,
      setValue: (u, v) => u.copyWith(isActive: v as bool? ?? true),
      section: 'Status',
    ),
  ],
  emptyEntity: () =>
      const UserCredentials(id: 0, username: '', contactId: 0, roleId: 0),
  // DELETE deactivates (soft) — hardDelete defaults to false.
);
