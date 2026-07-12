import 'package:equatable/equatable.dart';

const _unset = Object();

/// The ItemProperty master entity — hard delete
/// (`sales_inventory_item_properties` has no soft-delete column).
///
/// The backend has no `PUT /inventory/property/:id` route, so this manifest
/// sets `supportsUpdate: false`: `MasterFormSurface` renders edit mode
/// read-only rather than assuming every manifest with `formFields` supports
/// update.
class ItemProperty extends Equatable {
  const ItemProperty({
    required this.id,
    required this.propertyId,
    required this.itemId,
    this.defaultValue,
  });

  final int id;
  final String propertyId;
  final String itemId;
  final String? defaultValue;

  ItemProperty copyWith({
    int? id,
    String? propertyId,
    String? itemId,
    Object? defaultValue = _unset,
  }) => ItemProperty(
    id: id ?? this.id,
    propertyId: propertyId ?? this.propertyId,
    itemId: itemId ?? this.itemId,
    defaultValue: identical(defaultValue, _unset)
        ? this.defaultValue
        : defaultValue as String?,
  );

  @override
  List<Object?> get props => [id, propertyId, itemId, defaultValue];
}
