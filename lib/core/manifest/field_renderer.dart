import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/core/widgets/fields/app_date_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_decimal_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_number_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_switch_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_text_field.dart';
import 'package:algo_erp_front/core/widgets/fields/field_label.dart';
import 'package:algo_erp_front/core/widgets/lookup/fk_lookup_field.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/widgets.dart';

/// Maps a [FormFieldSpec] to the widget that edits it — the single switch
/// over [FieldType] that lets `MasterFormSurface` stay entity-agnostic.
///
/// `value` carries the field's current draft value; for [FieldType.fk] /
/// [FieldType.selfFk] it is the *resolved display object* (not the raw id)
/// so the picker can render a label — `MasterFormSurface` is responsible for
/// id↔object translation at its boundary, since only it holds the
/// FK-resolution cache.
abstract final class FieldRenderer {
  static Widget build<E>({
    required FormFieldSpec<E> field,
    required Object? value,
    required ValueChanged<Object?> onChanged,
    required bool enabled,
    String? errorText,

    /// Optional override for [FieldType.fk]/[FieldType.selfFk] loaders
    /// (used by the form surface to exclude the draft row on selfFk).
    Future<List<Object>> Function(String query)? fkLoaderOverride,
  }) {
    final isEnabled = enabled && !field.readOnly;
    String? validate(Object? v) {
      if (errorText != null) return errorText;
      final isEmpty = v == null || (v is String && v.isEmpty);
      if (field.required && isEmpty) return '${field.label} is required';
      return field.validator?.call(v);
    }

    // Required fields carry a brass asterisk — an instruction, not an error.
    final label = FieldLabel(text: field.label, isRequired: field.required);

    switch (field.type) {
      case FieldType.text:
        return AppTextField(
          label: field.label,
          labelWidget: label,
          value: value as String?,
          helperText: field.helperText,
          hintText: field.hintText,
          enabled: isEnabled,
          validator: validate,
          onChanged: onChanged,
        );
      case FieldType.int:
        return AppNumberField(
          label: field.label,
          labelWidget: label,
          value: value as int?,
          helperText: field.helperText,
          hintText: field.hintText,
          enabled: isEnabled,
          validator: validate,
          onChanged: onChanged,
        );
      case FieldType.decimal:
        return AppDecimalField(
          label: field.label,
          labelWidget: label,
          value: value as Decimal?,
          helperText: field.helperText,
          hintText: field.hintText,
          enabled: isEnabled,
          validator: validate,
          onChanged: onChanged,
        );
      case FieldType.bool:
        return AppSwitchField(
          label: field.label,
          labelWidget: label,
          value: (value as bool?) ?? false,
          helperText: field.helperText,
          enabled: isEnabled,
          onChanged: onChanged,
        );
      case FieldType.dateTime:
        return AppDateField(
          label: field.label,
          labelWidget: label,
          value: value as DateTime?,
          helperText: field.helperText,
          enabled: isEnabled,
          validator: validate,
          onChanged: onChanged,
        );
      case FieldType.fk:
      case FieldType.selfFk:
        return FkLookupField<Object>(
          label: field.label,
          labelWidget: label,
          value: value,
          displayOf: field.fkDisplayOf!,
          loader: fkLoaderOverride ?? field.fkSearch!,
          helperText: field.helperText,
          enabled: isEnabled,
          onSelected: onChanged,
          validator: validate,
        );
    }
  }
}
