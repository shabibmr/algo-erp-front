import 'package:equatable/equatable.dart';

const _unset = Object();

/// The PriceList master entity — hard-deleted (no `is_active` column on the
/// backend `price_lists` table). The table's own PK column is literally
/// named `Price_List_ID` (not `id`) — a DTO-only concern, see
/// `PriceListDto.fromJson`; this entity still exposes a clean `id`.
class PriceList extends Equatable {
  const PriceList({
    required this.id,
    required this.name,
    this.startDate,
    this.endDate,
    this.isDefault = false,
    this.showInPos = true,
    this.isOnline = false,
  });

  final int id;
  final String name;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isDefault;
  final bool showInPos;
  final bool isOnline;

  PriceList copyWith({
    int? id,
    String? name,
    Object? startDate = _unset,
    Object? endDate = _unset,
    bool? isDefault,
    bool? showInPos,
    bool? isOnline,
  }) => PriceList(
    id: id ?? this.id,
    name: name ?? this.name,
    startDate: identical(startDate, _unset)
        ? this.startDate
        : startDate as DateTime?,
    endDate: identical(endDate, _unset) ? this.endDate : endDate as DateTime?,
    isDefault: isDefault ?? this.isDefault,
    showInPos: showInPos ?? this.showInPos,
    isOnline: isOnline ?? this.isOnline,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    startDate,
    endDate,
    isDefault,
    showInPos,
    isOnline,
  ];
}
