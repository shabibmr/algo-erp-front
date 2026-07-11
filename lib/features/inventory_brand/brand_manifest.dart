import 'package:algo_erp_front/core/manifest/entity_manifest.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/features/inventory_brand/domain/brand.dart';

/// Brand's manifest — the EMR vertical slice's proving ground.
///
/// `rbacModule` is `'Inventory'`, **not** `'Brand'`: the backend's
/// `authorize()` middleware gates all of `/inventory/**` on the coarse
/// `'Inventory'` string (`inventory.routes.ts`), so that is what
/// `PermissionService.can()` must be asked for once BE-001 lands.
final brandManifest = EntityManifest<Brand>(
  id: 'brand',
  label: 'Brand',
  rbacModule: 'Inventory',
  resourcePath: '/inventory/brand',
  listColumns: [
    FieldSpec<Brand>(
      key: 'name',
      label: 'Name',
      type: FieldType.text,
      required: true,
      cellValue: (brand) => brand.name,
    ),
    FieldSpec<Brand>(
      key: 'description',
      label: 'Description',
      type: FieldType.text,
      cellValue: (brand) => brand.description ?? '—',
    ),
  ],
  searchFields: const ['name'],
  formFields: [
    FormFieldSpec<Brand>(
      key: 'name',
      wireKey: 'Brand_Name',
      label: 'Name',
      type: FieldType.text,
      required: true,
      getValue: (brand) => brand.name,
      setValue: (brand, v) => brand.copyWith(name: v as String?),
    ),
    FormFieldSpec<Brand>(
      key: 'description',
      wireKey: 'Brand_Description',
      label: 'Description',
      type: FieldType.text,
      getValue: (brand) => brand.description,
      setValue: (brand, v) => brand.copyWith(description: v),
    ),
  ],
  emptyEntity: () => const Brand(id: 0, name: ''),
  hardDelete: true,
);
