import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

const _unset = Object();

enum AttributeType {
  predetermined('PREDETERMINED', 'Pre-determined'),
  editable('EDITABLE', 'Editable'),
  group('GROUP', 'Group');

  const AttributeType(this.wireValue, this.label);
  final String wireValue;
  final String label;

  static AttributeType fromWire(String? value) {
    return switch (value?.toUpperCase()) {
      'EDITABLE' => AttributeType.editable,
      'GROUP' => AttributeType.group,
      _ => AttributeType.predetermined,
    };
  }
}

class ProductAttributeOption extends Equatable {
  const ProductAttributeOption({
    required this.id,
    required this.attributeId,
    required this.value,
    this.valueCode,
    this.displayOrder = 0,
    this.isActive = true,
  });

  final int id;
  final int attributeId;
  final String value;
  final String? valueCode;
  final int displayOrder;
  final bool isActive;

  ProductAttributeOption copyWith({
    int? id,
    int? attributeId,
    String? value,
    Object? valueCode = _unset,
    int? displayOrder,
    bool? isActive,
  }) => ProductAttributeOption(
    id: id ?? this.id,
    attributeId: attributeId ?? this.attributeId,
    value: value ?? this.value,
    valueCode: identical(valueCode, _unset)
        ? this.valueCode
        : valueCode as String?,
    displayOrder: displayOrder ?? this.displayOrder,
    isActive: isActive ?? this.isActive,
  );

  @override
  List<Object?> get props => [
    id,
    attributeId,
    value,
    valueCode,
    displayOrder,
    isActive,
  ];
}

class ProductAttribute extends Equatable {
  const ProductAttribute({
    required this.id,
    required this.name,
    this.code,
    this.type = AttributeType.predetermined,
    this.dataType = 'TEXT',
    this.parentId,
    this.parentName,
    this.unit,
    this.isActive = true,
    this.options = const [],
    this.subAttributes = const [],
  });

  final int id;
  final String name;
  final String? code;
  final AttributeType type;
  final String dataType;
  final int? parentId;
  final String? parentName;
  final String? unit;
  final bool isActive;
  final List<ProductAttributeOption> options;
  final List<ProductAttribute> subAttributes;

  bool get isGroup => type == AttributeType.group;
  bool get isPredetermined => type == AttributeType.predetermined;
  bool get isEditable => type == AttributeType.editable;

  ProductAttribute copyWith({
    int? id,
    String? name,
    Object? code = _unset,
    AttributeType? type,
    String? dataType,
    Object? parentId = _unset,
    Object? parentName = _unset,
    Object? unit = _unset,
    bool? isActive,
    List<ProductAttributeOption>? options,
    List<ProductAttribute>? subAttributes,
  }) => ProductAttribute(
    id: id ?? this.id,
    name: name ?? this.name,
    code: identical(code, _unset) ? this.code : code as String?,
    type: type ?? this.type,
    dataType: dataType ?? this.dataType,
    parentId: identical(parentId, _unset) ? this.parentId : parentId as int?,
    parentName: identical(parentName, _unset)
        ? this.parentName
        : parentName as String?,
    unit: identical(unit, _unset) ? this.unit : unit as String?,
    isActive: isActive ?? this.isActive,
    options: options ?? this.options,
    subAttributes: subAttributes ?? this.subAttributes,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    code,
    type,
    dataType,
    parentId,
    parentName,
    unit,
    isActive,
    options,
    subAttributes,
  ];
}

/// An attribute assigned to an item, with the item-specific flags.
class ItemAttributeAssignment extends Equatable {
  const ItemAttributeAssignment({
    required this.attributeId,
    required this.attribute,
    this.isRequired = false,
    this.displayOrder = 0,
  });

  final int attributeId;
  final ProductAttribute attribute;
  final bool isRequired;
  final int displayOrder;

  @override
  List<Object?> get props => [attributeId, attribute, isRequired, displayOrder];
}

/// A variant SKU row as listed on the item.
class ItemSku extends Equatable {
  const ItemSku({
    required this.id,
    required this.skuCode,
    required this.skuName,
    required this.attributeSummary,
    this.rate,
  });

  final int id;
  final String skuCode;
  final String skuName;
  final String attributeSummary;
  final Decimal? rate;

  @override
  List<Object?> get props => [id, skuCode, skuName, attributeSummary, rate];
}

/// Outcome of resolving a variant: the SKU and whether it was just created.
class ResolvedVariant extends Equatable {
  const ResolvedVariant({required this.sku, required this.isNew});

  final ItemSku sku;
  final bool isNew;

  @override
  List<Object?> get props => [sku, isNew];
}

/// One attribute value chosen for a variant.
class VariantAttributeInput extends Equatable {
  const VariantAttributeInput({
    required this.attributeId,
    required this.value,
    this.valueId,
  });

  final int attributeId;
  final String value;
  final int? valueId;

  @override
  List<Object?> get props => [attributeId, value, valueId];
}
