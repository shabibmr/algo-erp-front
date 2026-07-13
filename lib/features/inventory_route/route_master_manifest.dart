import 'package:algo_erp_front/core/manifest/entity_manifest.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/features/inventory_route/domain/route_master.dart';

/// RouteMaster's manifest. `rbacModule` is `'Inventory'`.
final routeMasterManifest = EntityManifest<RouteMaster>(
  id: 'route',
  label: 'Route',
  rbacModule: 'Inventory',
  resourcePath: '/inventory/route',
  listColumns: [
    FieldSpec<RouteMaster>(
      key: 'name',
      label: 'Name',
      type: FieldType.text,
      cellValue: (r) => r.name ?? '—',
    ),
    FieldSpec<RouteMaster>(
      key: 'routeCode',
      label: 'Route code',
      type: FieldType.text,
      cellValue: (r) => r.routeCode,
    ),
  ],
  searchFields: const ['routeCode', 'name'],
  formFields: [
    FormFieldSpec<RouteMaster>(
      key: 'name',
      wireKey: 'route_name',
      label: 'Name',
      type: FieldType.text,
      getValue: (r) => r.name,
      setValue: (r, v) => r.copyWith(name: v),
    ),
    FormFieldSpec<RouteMaster>(
      key: 'routeCode',
      wireKey: 'route_id',
      label: 'Route code',
      type: FieldType.text,
      getValue: (r) => r.routeCode,
      setValue: (r, v) => r.copyWith(routeCode: v as String?),
    ),
    FormFieldSpec<RouteMaster>(
      key: 'description',
      wireKey: 'Description',
      label: 'Description',
      type: FieldType.text,
      getValue: (r) => r.description,
      setValue: (r, v) => r.copyWith(description: v),
    ),
  ],
  emptyEntity: () => const RouteMaster(id: 0, routeCode: ''),
  hardDelete: true,
);
