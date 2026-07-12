import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

const _unset = Object();

/// Item batch master — soft-deleted via `is_active`. Unique on
/// `(item_id, batch_number)` per backend schema.
class ItemBatch extends Equatable {
  const ItemBatch({
    required this.id,
    required this.itemId,
    required this.batchNumber,
    required this.costPrice,
    required this.sellingPrice,
    this.manufacturingDate,
    this.expirationDate,
    this.isActive = true,
  });

  final int id;
  final int itemId;
  final String batchNumber;
  final DateTime? manufacturingDate;
  final DateTime? expirationDate;
  final Decimal costPrice;
  final Decimal sellingPrice;
  final bool isActive;

  ItemBatch copyWith({
    int? id,
    int? itemId,
    String? batchNumber,
    Object? manufacturingDate = _unset,
    Object? expirationDate = _unset,
    Decimal? costPrice,
    Decimal? sellingPrice,
    bool? isActive,
  }) =>
      ItemBatch(
        id: id ?? this.id,
        itemId: itemId ?? this.itemId,
        batchNumber: batchNumber ?? this.batchNumber,
        manufacturingDate: identical(manufacturingDate, _unset)
            ? this.manufacturingDate
            : manufacturingDate as DateTime?,
        expirationDate: identical(expirationDate, _unset)
            ? this.expirationDate
            : expirationDate as DateTime?,
        costPrice: costPrice ?? this.costPrice,
        sellingPrice: sellingPrice ?? this.sellingPrice,
        isActive: isActive ?? this.isActive,
      );

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
