import 'package:algo_erp_front/core/manifest/entity_manifest.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/features/organization_config/domain/config_setting.dart';

/// Config settings — list + edit value only
/// (`supportsDelete: false`, no create).
final configSettingManifest = EntityManifest<ConfigSetting>(
  id: 'config-setting',
  label: 'Config setting',
  rbacModule: 'ConfigSetting',
  resourcePath: '/organization/config',
  listColumns: [
    FieldSpec<ConfigSetting>(
      key: 'key',
      label: 'Key',
      type: FieldType.text,
      required: true,
      cellValue: (s) => s.key,
    ),
    FieldSpec<ConfigSetting>(
      key: 'value',
      label: 'Value',
      type: FieldType.text,
      cellValue: (s) => s.value,
    ),
    FieldSpec<ConfigSetting>(
      key: 'dataType',
      label: 'Type',
      type: FieldType.text,
      cellValue: (s) => s.dataType ?? '—',
    ),
    FieldSpec<ConfigSetting>(
      key: 'displayText',
      label: 'Label',
      type: FieldType.text,
      cellValue: (s) => s.displayText ?? '—',
    ),
  ],
  searchFields: const ['gm_key', 'display_text'],
  formFields: [
    FormFieldSpec<ConfigSetting>(
      key: 'key',
      wireKey: 'gm_key',
      label: 'Key',
      type: FieldType.text,
      required: true,
      readOnly: true,
      getValue: (s) => s.key,
      setValue: (s, v) => s.copyWith(key: v as String? ?? s.key),
    ),
    FormFieldSpec<ConfigSetting>(
      key: 'displayText',
      wireKey: 'display_text',
      label: 'Label',
      type: FieldType.text,
      readOnly: true,
      getValue: (s) => s.displayText,
      setValue: (s, v) => s.copyWith(displayText: v as String?),
    ),
    FormFieldSpec<ConfigSetting>(
      key: 'dataType',
      wireKey: 'Data_Type',
      label: 'Data type',
      type: FieldType.text,
      readOnly: true,
      getValue: (s) => s.dataType,
      setValue: (s, v) => s.copyWith(dataType: v as String?),
    ),
    FormFieldSpec<ConfigSetting>(
      key: 'value',
      wireKey: 'value',
      label: 'Value',
      type: FieldType.text,
      required: true,
      helperText: 'Stored as string; type is metadata only',
      getValue: (s) => s.value,
      setValue: (s, v) => s.copyWith(value: v as String? ?? ''),
    ),
  ],
  emptyEntity: () => const ConfigSetting(id: 0, key: '', value: ''),
  supportsDelete: false,
  emptyMessage: 'No config rows seed — seed on the server first.',
);
