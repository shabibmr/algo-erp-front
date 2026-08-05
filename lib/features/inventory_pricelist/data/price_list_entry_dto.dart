import 'package:equatable/equatable.dart';

/// Wire shape of `/inventory/pricelist-entry` (`pricelist_entries`).
class PriceListEntryDto extends Equatable {
  const PriceListEntryDto({
    required this.id,
    required this.itemId,
    required this.price,
    required this.priceListId,
    this.percent,
    this.uomId,
    this.entryType = 0,
  });

  factory PriceListEntryDto.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['_id'];
    return PriceListEntryDto(
      id: rawId is int ? rawId : int.parse('$rawId'),
      itemId: json['Item_Id'] as String,
      price: (json['Price'] as num).toDouble(),
      priceListId: json['Price_List_ID'] as int,
      percent: (json['percent'] as num?)?.toDouble(),
      uomId: json['UOM_Id'] as String?,
      entryType: (json['MRP2_STD1_CUS0'] as num?)?.toInt() ?? 0,
    );
  }

  final int id;
  final String itemId;
  final double price;
  final int priceListId;
  final double? percent;
  final String? uomId;
  final int entryType;

  Map<String, dynamic> toJson() => {
    'Item_Id': itemId,
    'Price': price,
    'Price_List_ID': priceListId,
    'percent': percent,
    'UOM_Id': uomId,
    'MRP2_STD1_CUS0': entryType,
  };

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
