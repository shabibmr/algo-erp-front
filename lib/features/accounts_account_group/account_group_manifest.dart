import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/manifest/entity_manifest.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/accounts_account_group/account_group_di.dart';
import 'package:algo_erp_front/features/accounts_account_group/domain/account_group.dart';

final _accountGroupRepository =
    createAccountGroupRepository(getIt<DioClient>());

/// Account-group master with optional parent (`FieldType.selfFk`).
/// `rbacModule` is the coarse `'Accounts'` string.
final accountGroupManifest = EntityManifest<AccountGroup>(
  id: 'account_group',
  label: 'Account group',
  rbacModule: 'Accounts',
  resourcePath: accountGroupResourcePath,
  listColumns: [
    FieldSpec<AccountGroup>(
      key: 'code',
      label: 'Code',
      type: FieldType.text,
      cellValue: (g) => g.code ?? '—',
    ),
    FieldSpec<AccountGroup>(
      key: 'name',
      label: 'Name',
      type: FieldType.text,
      required: true,
      cellValue: (g) {
        final depth = g.depth ?? 0;
        final indent = depth > 0 ? '${'  ' * depth}↳ ' : '';
        return '$indent${g.name}';
      },
    ),
    FieldSpec<AccountGroup>(
      key: 'fullPath',
      label: 'Path',
      type: FieldType.text,
      cellValue: (g) => g.fullPath ?? '—',
    ),
    FieldSpec<AccountGroup>(
      key: 'isSystemDefined',
      label: 'System',
      type: FieldType.bool,
      cellValue: (g) => g.isSystemDefined ? 'Yes' : 'No',
    ),
  ],
  searchFields: const ['Group_Name', 'group_code'],
  formFields: [
    FormFieldSpec<AccountGroup>(
      key: 'code',
      wireKey: 'group_code',
      label: 'Code',
      type: FieldType.text,
      getValue: (g) => g.code,
      setValue: (g, v) => g.copyWith(code: v as String?),
    ),
    FormFieldSpec<AccountGroup>(
      key: 'name',
      wireKey: 'Group_Name',
      label: 'Name',
      type: FieldType.text,
      required: true,
      getValue: (g) => g.name,
      setValue: (g, v) => g.copyWith(name: v as String?),
    ),
    FormFieldSpec<AccountGroup>(
      key: 'parentGroupId',
      wireKey: 'parent_group_id',
      label: 'Parent group',
      type: FieldType.selfFk,
      helperText: 'Optional hierarchy parent (cannot select self)',
      getValue: (g) => g.parentGroupId,
      setValue: (g, v) => g.copyWith(
        parentGroupId: v == null ? null : (v as AccountGroup).id,
      ),
      fkSearch: (query) async {
        final result =
            await _accountGroupRepository.list(PageQuery(search: query));
        return result.fold((_) => const [], (page) => page.items);
      },
      fkDisplayOf: (item) {
        final g = item as AccountGroup;
        final path = g.fullPath;
        if (path != null && path.isNotEmpty) return path;
        final code = g.code;
        return (code == null || code.isEmpty) ? g.name : '$code — ${g.name}';
      },
      fkResolveById: (id) async {
        final result = await _accountGroupRepository.getById(id as int);
        return result.fold((_) => null, (g) => g);
      },
    ),
    FormFieldSpec<AccountGroup>(
      key: 'isSystemDefined',
      wireKey: 'is_system_defined',
      label: 'System defined',
      type: FieldType.bool,
      getValue: (g) => g.isSystemDefined,
      setValue: (g, v) => g.copyWith(isSystemDefined: v as bool?),
    ),
  ],
  emptyEntity: () => const AccountGroup(id: 0, name: ''),
  hardDelete: true,
);
