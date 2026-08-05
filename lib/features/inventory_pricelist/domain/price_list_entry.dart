import 'package:equatable/equatable.dart';

const _unset = Object();

/// Per-item rate row on a price list (`pricelist_entries`). Hard-deleted.
///
/// `itemId` is the inventory item **code** (string soft-FK), matching
/// effective-price lookup semantics on the backend.
class PriceListEntry extends Equatable {
  const PriceListEntry({
    required this.id,
    required this.itemId,
    required this.price,
    required this.priceListId,
    this.percent,
    this.uomId,
    this.entryType = 0,
  });

  final int id;
  final String itemId;
  final double price;
  final int priceListId;
  final double? percent;
  final String? uomId;

  /// `0` Custom, `1` Standard, `2` MRP (`MRP2_STD1_CUS0`).
  final int entryType;

  PriceListEntry copyWith({
    int? id,
    String? itemId,
    double? price,
    int? priceListId,
    Object? percent = _unset,
    Object? uomId = _unset,
    int? entryType,
  }) => PriceListEntry(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    price: price ?? this.price,
    priceListId: priceListId ?? this.priceListId,
    percent: identical(percent, _unset) ? this.percent : percent as double?,
    uomId: identical(uomId, _unset) ? this.uomId : uomId as String?,
    entryType: entryType ?? this.entryType,
  );

  @override
  List<Object?> get props => [
    id,
    itemId,
    price,
    priceListId,
    percent,
    uomId,
    entryType,
  ];
}
