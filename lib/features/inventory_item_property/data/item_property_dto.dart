import 'package:equatable/equatable.dart';

/// Wire shape of `/inventory/property`, matching the backend
/// `sales_inventory_item_properties` table.
class ItemPropertyDto extends Equatable {
  const ItemPropertyDto({
    required this.id,
    required this.propertyId,
    required this.itemId,
    this.defaultValue,
  });

  factory ItemPropertyDto.fromJson(Map<String, dynamic> json) =>
      ItemPropertyDto(
        id: json['id'] as int,
        propertyId: json['Property_ID'] as String,
        itemId: json['Item_ID'] as String,
        defaultValue: json['Default_Value'] as String?,
      );

  final int id;
  final String propertyId;
  final String itemId;
  final String? defaultValue;

  /// `id` is server-generated and never sent on write.
  Map<String, dynamic> toJson() => {
    'Property_ID': propertyId,
    'Item_ID': itemId,
    'Default_Value': defaultValue,
  };

  @override
  List<Object?> get props => [id, propertyId, itemId, defaultValue];
}
