import 'package:equatable/equatable.dart';

/// Wire shape of `/inventory/batch`, matching `item_batches` + `itemBatchSchema`.
class ItemBatchDto extends Equatable {
  const ItemBatchDto({
    required this.id,
    required this.itemId,
    required this.batchNumber,
    required this.costPrice,
    required this.sellingPrice,
    this.manufacturingDate,
    this.expirationDate,
    this.isActive = true,
  });

  factory ItemBatchDto.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic raw) {
      if (raw == null) return null;
      if (raw is DateTime) return raw;
      if (raw is String && raw.isNotEmpty) {
        return DateTime.tryParse(raw);
      }
      return null;
    }

    String asWireNumber(dynamic v, [String fallback = '0']) {
      if (v == null) return fallback;
      return v.toString();
    }

    return ItemBatchDto(
      id: json['id'] as int,
      itemId: json['item_id'] as int,
      batchNumber: json['batch_number'] as String? ?? '',
      manufacturingDate: parseDate(json['manufacturing_date']),
      expirationDate: parseDate(json['expiration_date']),
      costPrice: asWireNumber(json['cost_price']),
      sellingPrice: asWireNumber(json['selling_price']),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  final int id;
  final int itemId;
  final String batchNumber;
  final DateTime? manufacturingDate;
  final DateTime? expirationDate;

  /// Decimal wire as string until the mapper.
  final String costPrice;
  final String sellingPrice;
  final bool isActive;

  static String? _dateOnly(DateTime? d) {
    if (d == null) return null;
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Map<String, dynamic> toJson() => {
        'item_id': itemId,
        'batch_number': batchNumber,
        'manufacturing_date': _dateOnly(manufacturingDate),
        'expiration_date': _dateOnly(expirationDate),
        'cost_price': double.tryParse(costPrice) ?? 0,
        'selling_price': double.tryParse(sellingPrice) ?? 0,
        'is_active': isActive,
      };

  @override
  List<Object?> get props => [
        id,
        itemId,
        batchNumber,
        manufacturingDate,
        expirationDate,
        costPrice,
        sellingPrice,
        isActive,
      ];
}
