import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

const _unset = Object();

/// Shared item + qty + price line for trading vouchers (Q/SO/DN/PO/RN/PI).
class ItemQtyLine extends Equatable {
  ItemQtyLine({
    this.itemId,
    this.itemLabel,
    this.skuId,
    this.batchId,
    this.sourceLineId,
    Decimal? quantity,
    Decimal? price,
    Decimal? discountPercent,
    Decimal? taxRate,
  }) : quantity = quantity ?? Decimal.one,
       price = price ?? Decimal.zero,
       discountPercent = discountPercent ?? Decimal.zero,
       taxRate = taxRate ?? Decimal.zero;

  final int? itemId;
  final String? itemLabel;
  final int? skuId;
  final int? batchId;
  final int? sourceLineId;
  final Decimal quantity;
  final Decimal price;
  final Decimal discountPercent;
  final Decimal taxRate;

  bool get isComplete =>
      itemId != null && quantity > Decimal.zero && price >= Decimal.zero;

  ItemQtyLine copyWith({
    Object? itemId = _unset,
    Object? itemLabel = _unset,
    Object? skuId = _unset,
    Object? batchId = _unset,
    Object? sourceLineId = _unset,
    Decimal? quantity,
    Decimal? price,
    Decimal? discountPercent,
    Decimal? taxRate,
  }) => ItemQtyLine(
    itemId: identical(itemId, _unset) ? this.itemId : itemId as int?,
    itemLabel: identical(itemLabel, _unset)
        ? this.itemLabel
        : itemLabel as String?,
    skuId: identical(skuId, _unset) ? this.skuId : skuId as int?,
    batchId: identical(batchId, _unset) ? this.batchId : batchId as int?,
    sourceLineId: identical(sourceLineId, _unset)
        ? this.sourceLineId
        : sourceLineId as int?,
    quantity: quantity ?? this.quantity,
    price: price ?? this.price,
    discountPercent: discountPercent ?? this.discountPercent,
    taxRate: taxRate ?? this.taxRate,
  );

  @override
  List<Object?> get props => [
    itemId,
    itemLabel,
    skuId,
    batchId,
    sourceLineId,
    quantity,
    price,
    discountPercent,
    taxRate,
  ];
}

/// Create/post payload for an item-qty trading voucher.
class ItemQtyDraft extends Equatable {
  ItemQtyDraft({
    this.voucherPrefix = '',
    DateTime? voucherDate,
    this.financialYear = '',
    this.partyLedgerId,
    this.partyLabel,
    this.godownId,
    this.godownLabel,
    this.billingName,
    this.narration,
    this.creditDays = 30,
    this.sourceVoucherId,
    this.sourceVoucherLabel,
    List<ItemQtyLine>? lines,
  }) : voucherDate = voucherDate ?? DateTime.now(),
       lines = lines ?? [ItemQtyLine()];

  final String voucherPrefix;
  final DateTime voucherDate;
  final String financialYear;
  final int? partyLedgerId;
  final String? partyLabel;
  final int? godownId;
  final String? godownLabel;
  final String? billingName;
  final String? narration;
  final int creditDays;
  final int? sourceVoucherId;
  final String? sourceVoucherLabel;
  final List<ItemQtyLine> lines;

  ItemQtyDraft copyWith({
    String? voucherPrefix,
    DateTime? voucherDate,
    String? financialYear,
    Object? partyLedgerId = _unset,
    Object? partyLabel = _unset,
    Object? godownId = _unset,
    Object? godownLabel = _unset,
    Object? billingName = _unset,
    Object? narration = _unset,
    int? creditDays,
    Object? sourceVoucherId = _unset,
    Object? sourceVoucherLabel = _unset,
    List<ItemQtyLine>? lines,
  }) => ItemQtyDraft(
    voucherPrefix: voucherPrefix ?? this.voucherPrefix,
    voucherDate: voucherDate ?? this.voucherDate,
    financialYear: financialYear ?? this.financialYear,
    partyLedgerId: identical(partyLedgerId, _unset)
        ? this.partyLedgerId
        : partyLedgerId as int?,
    partyLabel: identical(partyLabel, _unset)
        ? this.partyLabel
        : partyLabel as String?,
    godownId: identical(godownId, _unset) ? this.godownId : godownId as int?,
    godownLabel: identical(godownLabel, _unset)
        ? this.godownLabel
        : godownLabel as String?,
    billingName: identical(billingName, _unset)
        ? this.billingName
        : billingName as String?,
    narration: identical(narration, _unset)
        ? this.narration
        : narration as String?,
    creditDays: creditDays ?? this.creditDays,
    sourceVoucherId: identical(sourceVoucherId, _unset)
        ? this.sourceVoucherId
        : sourceVoucherId as int?,
    sourceVoucherLabel: identical(sourceVoucherLabel, _unset)
        ? this.sourceVoucherLabel
        : sourceVoucherLabel as String?,
    lines: lines ?? this.lines,
  );

  @override
  List<Object?> get props => [
    voucherPrefix,
    voucherDate,
    financialYear,
    partyLedgerId,
    godownId,
    billingName,
    narration,
    creditDays,
    sourceVoucherId,
    lines,
  ];
}

class ItemQtyListItem extends Equatable {
  const ItemQtyListItem({
    required this.id,
    required this.voucherPrefix,
    required this.voucherNo,
    required this.voucherDate,
    this.status,
    this.total,
    this.billingName,
  });

  final int id;
  final String voucherPrefix;
  final String voucherNo;
  final DateTime? voucherDate;
  final String? status;
  final Decimal? total;
  final String? billingName;

  String get displayNo =>
      voucherNo.isEmpty ? '$voucherPrefix/?' : '$voucherPrefix$voucherNo';

  @override
  List<Object?> get props => [
    id,
    voucherPrefix,
    voucherNo,
    voucherDate,
    status,
    total,
    billingName,
  ];
}

class ItemQtyPostResult extends Equatable {
  const ItemQtyPostResult({
    required this.id,
    required this.voucherNo,
    required this.total,
  });

  final int id;
  final String voucherNo;
  final Decimal total;

  @override
  List<Object?> get props => [id, voucherNo, total];
}

class ItemQtyDetailLine extends Equatable {
  const ItemQtyDetailLine({
    required this.id,
    this.itemId,
    this.itemLabel,
    this.quantity,
    this.price,
    this.discountPercent,
    this.discountAmount,
    this.subtotal,
    this.taxRate,
    this.taxAmount,
  });

  final int id;
  final int? itemId;
  final String? itemLabel;
  final Decimal? quantity;
  final Decimal? price;
  final Decimal? discountPercent;
  final Decimal? discountAmount;
  final Decimal? subtotal;
  final Decimal? taxRate;
  final Decimal? taxAmount;

  ItemQtyDetailLine copyWith({Object? itemLabel = _unset}) => ItemQtyDetailLine(
    id: id,
    itemId: itemId,
    itemLabel: identical(itemLabel, _unset)
        ? this.itemLabel
        : itemLabel as String?,
    quantity: quantity,
    price: price,
    discountPercent: discountPercent,
    discountAmount: discountAmount,
    subtotal: subtotal,
    taxRate: taxRate,
    taxAmount: taxAmount,
  );

  @override
  List<Object?> get props => [
    id,
    itemId,
    itemLabel,
    quantity,
    price,
    discountPercent,
    discountAmount,
    subtotal,
    taxRate,
    taxAmount,
  ];
}

class ItemQtyDetail extends Equatable {
  const ItemQtyDetail({
    required this.id,
    required this.status,
    required this.lines,
    this.voucherPrefix = '',
    this.voucherNo = '',
    this.voucherDate,
    this.billingName,
    this.partyLedgerId,
    this.partyLabel,
    this.godownId,
    this.godownLabel,
    this.total,
    this.grossTotal,
    this.discount,
    this.vat,
    this.narration,
  });

  final int id;
  final String status;
  final String voucherPrefix;
  final String voucherNo;
  final DateTime? voucherDate;
  final String? billingName;
  final int? partyLedgerId;
  final String? partyLabel;
  final int? godownId;
  final String? godownLabel;
  final Decimal? total;
  final Decimal? grossTotal;
  final Decimal? discount;
  final Decimal? vat;
  final String? narration;
  final List<ItemQtyDetailLine> lines;

  String get displayNo {
    if (voucherNo.isEmpty) return '#$id';
    final p = voucherPrefix;
    if (p.isEmpty) return voucherNo;
    if (voucherNo.startsWith(p)) return voucherNo;
    return '$p$voucherNo';
  }

  bool get canCancel =>
      status == 'Posted' || status == 'Approved' || status == 'Draft';

  ItemQtyDetail copyWith({
    String? status,
    Object? partyLabel = _unset,
    Object? godownLabel = _unset,
    List<ItemQtyDetailLine>? lines,
  }) => ItemQtyDetail(
    id: id,
    status: status ?? this.status,
    voucherPrefix: voucherPrefix,
    voucherNo: voucherNo,
    voucherDate: voucherDate,
    billingName: billingName,
    partyLedgerId: partyLedgerId,
    partyLabel: identical(partyLabel, _unset)
        ? this.partyLabel
        : partyLabel as String?,
    godownId: godownId,
    godownLabel: identical(godownLabel, _unset)
        ? this.godownLabel
        : godownLabel as String?,
    total: total,
    grossTotal: grossTotal,
    discount: discount,
    vat: vat,
    narration: narration,
    lines: lines ?? this.lines,
  );

  @override
  List<Object?> get props => [
    id,
    status,
    voucherPrefix,
    voucherNo,
    voucherDate,
    billingName,
    partyLedgerId,
    partyLabel,
    godownId,
    godownLabel,
    total,
    grossTotal,
    discount,
    vat,
    narration,
    lines,
  ];
}

/// Lightweight source voucher for conversion (SO → DN, PO → RN).
class ItemQtySourceLite extends Equatable {
  const ItemQtySourceLite({
    required this.id,
    required this.type,
    required this.displayNo,
    this.billingName,
    this.partyLedgerId,
    this.godownId,
    this.lines = const [],
  });

  final int id;
  final String type;
  final String displayNo;
  final String? billingName;
  final int? partyLedgerId;
  final int? godownId;
  final List<ItemQtyLine> lines;

  @override
  List<Object?> get props => [
    id,
    type,
    displayNo,
    billingName,
    partyLedgerId,
    godownId,
    lines,
  ];
}

class ItemQtyLifecycleResult extends Equatable {
  const ItemQtyLifecycleResult({
    required this.id,
    required this.status,
    this.message,
  });

  final int id;
  final String status;
  final String? message;

  @override
  List<Object?> get props => [id, status, message];
}
