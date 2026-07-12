import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/manifest/entity_manifest.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/inventory_group/domain/inventory_group.dart';
import 'package:algo_erp_front/features/inventory_group/inventory_group_di.dart';

/// Self-repo for parent selfFk (same pattern as cross-module FKs).
final _inventoryGroupRepository = createInventoryGroupRepository(
  getIt<DioClient>(),
);

/// Inventory group tree nodes. First consumer of [FieldType.selfFk].
final inventoryGroupManifest = EntityManifest<InventoryGroup>(
  id: 'inventory-group',
  label: 'Item group',
  rbacModule: 'Inventory',
  resourcePath: inventoryGroupResourcePath,
  listColumns: [
    FieldSpec<InventoryGroup>(
      key: 'code',
      label: 'Code',
      type: FieldType.text,
      cellValue: (g) => g.code ?? '—',
    ),
    FieldSpec<InventoryGroup>(
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
    FieldSpec<InventoryGroup>(
      key: 'fullPath',
      label: 'Path',
      type: FieldType.text,
      cellValue: (g) => g.fullPath ?? '—',
    ),
    FieldSpec<InventoryGroup>(
      key: 'groupType',
      label: 'Type',
      type: FieldType.text,
      cellValue: (g) => g.groupType ?? '—',
    ),
  ],
  searchFields: const ['Group_Name', 'group_code', 'Group_Type'],
  formFields: [
    FormFieldSpec<InventoryGroup>(
      key: 'groupId',
      wireKey: 'Group_ID',
      label: 'Group ID',
      type: FieldType.text,
      required: true,
      helperText: 'Legacy unique key (also used by older clients)',
      getValue: (g) => g.groupId,
      setValue: (g, v) => g.copyWith(groupId: v as String? ?? ''),
    ),
    FormFieldSpec<InventoryGroup>(
      key: 'code',
      wireKey: 'group_code',
      label: 'Code',
      type: FieldType.text,
      getValue: (g) => g.code,
      setValue: (g, v) => g.copyWith(code: v as String?),
    ),
    FormFieldSpec<InventoryGroup>(
      key: 'name',
      wireKey: 'Group_Name',
      label: 'Name',
      type: FieldType.text,
      required: true,
      getValue: (g) => g.name,
      setValue: (g, v) => g.copyWith(name: v as String?),
    ),
    FormFieldSpec<InventoryGroup>(
      key: 'nameArabic',
      wireKey: 'GroupNameArabic',
      label: 'Name (Arabic)',
      type: FieldType.text,
      getValue: (g) => g.nameArabic,
      setValue: (g, v) => g.copyWith(nameArabic: v as String?),
    ),
    FormFieldSpec<InventoryGroup>(
      key: 'groupType',
      wireKey: 'Group_Type',
      label: 'Type',
      type: FieldType.text,
      getValue: (g) => g.groupType,
      setValue: (g, v) => g.copyWith(groupType: v as String?),
    ),
    FormFieldSpec<InventoryGroup>(
      key: 'parentGroupId',
      wireKey: 'parent_group_id',
      label: 'Parent group',
      type: FieldType.selfFk,
      helperText: 'Optional hierarchy parent (cannot select self)',
      getValue: (g) => g.parentGroupId,
      setValue: (g, v) => g.copyWith(
        parentGroupId: v == null ? null : (v as InventoryGroup).id,
      ),
      fkSearch: (query) async {
        final result = await _inventoryGroupRepository.list(
          PageQuery(search: query),
        );
        return result.fold((_) => const [], (page) => page.items);
      },
      fkDisplayOf: (item) {
        final g = item as InventoryGroup;
        final path = g.fullPath;
        if (path != null && path.isNotEmpty) return path;
        final code = g.code;
        return (code == null || code.isEmpty) ? g.name : '$code — ${g.name}';
      },
      fkResolveById: (id) async {
        final result = await _inventoryGroupRepository.getById(id as int);
        return result.fold((_) => null, (g) => g);
      },
    ),
  ],
  emptyEntity: () => const InventoryGroup(id: 0, groupId: '', name: ''),
  hardDelete: true,
);
