import 'package:equatable/equatable.dart';

class ProductAttributeOptionDto extends Equatable {
  const ProductAttributeOptionDto({
    required this.id,
    required this.attributeId,
    required this.attributeValue,
    this.valueCode,
    this.displayOrder = 0,
    this.isActive = true,
  });

  factory ProductAttributeOptionDto.fromJson(Map<String, dynamic> json) =>
      ProductAttributeOptionDto(
        id: json['id'] as int? ?? 0,
        attributeId: json['attribute_id'] as int? ?? 0,
        attributeValue: json['attribute_value'] as String? ?? '',
        valueCode: json['value_code'] as String?,
        displayOrder: json['display_order'] as int? ?? 0,
        isActive: json['is_active'] as bool? ?? true,
      );

  final int id;
  final int attributeId;
  final String attributeValue;
  final String? valueCode;
  final int displayOrder;
  final bool isActive;

  Map<String, dynamic> toJson() => {
    'attribute_value': attributeValue,
    if (valueCode != null) 'value_code': valueCode,
    'display_order': displayOrder,
    'is_active': isActive,
  };

  @override
  List<Object?> get props => [
    id,
    attributeId,
    attributeValue,
    valueCode,
    displayOrder,
    isActive,
  ];
}

class ProductAttributeDto extends Equatable {
  const ProductAttributeDto({
    required this.id,
    required this.attributeName,
    this.attributeCode,
    this.attributeType = 'PREDETERMINED',
    this.dataType = 'TEXT',
    this.parentId,
    this.parentName,
    this.unit,
    this.isActive = true,
    this.values = const [],
    this.subAttributes = const [],
  });

  factory ProductAttributeDto.fromJson(Map<String, dynamic> json) {
    final rawValues = json['values'] as List<dynamic>?;
    final rawSub = json['sub_attributes'] as List<dynamic>?;
    final parentAttr = json['parent_attribute'] as Map<String, dynamic>?;

    return ProductAttributeDto(
      id: json['id'] as int? ?? 0,
      attributeName: json['attribute_name'] as String? ?? '',
      attributeCode: json['attribute_code'] as String?,
      attributeType: json['attribute_type'] as String? ?? 'PREDETERMINED',
      dataType: json['data_type'] as String? ?? 'TEXT',
      parentId: json['parent_id'] as int?,
      parentName: parentAttr?['attribute_name'] as String?,
      unit: json['unit'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      values:
          rawValues
              ?.map(
                (v) => ProductAttributeOptionDto.fromJson(
                  v as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const [],
      subAttributes:
          rawSub
              ?.map(
                (s) =>
                    ProductAttributeDto.fromJson(s as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );
  }

  final int id;
  final String attributeName;
  final String? attributeCode;
  final String attributeType;
  final String dataType;
  final int? parentId;
  final String? parentName;
  final String? unit;
  final bool isActive;
  final List<ProductAttributeOptionDto> values;
  final List<ProductAttributeDto> subAttributes;

  Map<String, dynamic> toJson() => {
    'attribute_name': attributeName,
    if (attributeCode != null && attributeCode!.isNotEmpty)
      'attribute_code': attributeCode,
    'attribute_type': attributeType,
    'data_type': dataType,
    'parent_id': parentId,
    if (unit != null) 'unit': unit,
    'is_active': isActive,
  };

  @override
  List<Object?> get props => [
    id,
    attributeName,
    attributeCode,
    attributeType,
    dataType,
    parentId,
    parentName,
    unit,
    isActive,
    values,
    subAttributes,
  ];
}
