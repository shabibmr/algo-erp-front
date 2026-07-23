import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

const _unset = Object();

class StockVoucherLine extends Equatable {
  StockVoucherLine({
    this.itemId,
    this.itemLabel,
    this.skuId,
    Decimal? quantity,
    Decimal? price,
    Decimal? adjValue,
    Decimal? crQty,
    Decimal? drQty,
    Decimal? requestQty,
    this.narration,
  }) : quantity = quantity ?? Decimal.one,
       price = price ?? Decimal.zero,
       adjValue = adjValue ?? Decimal.zero,
       crQty = crQty ?? Decimal.zero,
       drQty = drQty ?? Decimal.zero,
       requestQty = requestQty ?? Decimal.one;

  final int? itemId;
  final String? itemLabel;
  final int? skuId;
  final Decimal quantity;
  final Decimal price;
  final Decimal adjValue;
  final Decimal crQty;
  final Decimal drQty;
  final Decimal requestQty;
  final String? narration;

  bool isCompleteQtyPrice() =>
      itemId != null && quantity > Decimal.zero && price >= Decimal.zero;

  bool isCompleteCrDr() =>
      itemId != null && (crQty > Decimal.zero || drQty > Decimal.zero);

  bool isCompleteRequest() => itemId != null && requestQty > Decimal.zero;

  StockVoucherLine copyWith({
    Object? itemId = _unset,
    Object? itemLabel = _unset,
    Object? skuId = _unset,
    Decimal? quantity,
    Decimal? price,
    Decimal? adjValue,
    Decimal? crQty,
    Decimal? drQty,
    Decimal? requestQty,
    Object? narration = _unset,
  }) => StockVoucherLine(
    itemId: identical(itemId, _unset) ? this.itemId : itemId as int?,
    itemLabel: identical(itemLabel, _unset)
        ? this.itemLabel
        : itemLabel as String?,
    skuId: identical(skuId, _unset) ? this.skuId : skuId as int?,
    quantity: quantity ?? this.quantity,
    price: price ?? this.price,
    adjValue: adjValue ?? this.adjValue,
    crQty: crQty ?? this.crQty,
    drQty: drQty ?? this.drQty,
    requestQty: requestQty ?? this.requestQty,
    narration: identical(narration, _unset)
        ? this.narration
        : narration as String?,
  );

  @override
  List<Object?> get props => [
    itemId,
    itemLabel,
    skuId,
    quantity,
    price,
    adjValue,
    crQty,
    drQty,
    requestQty,
    narration,
  ];
}

class StockVoucherDraft extends Equatable {
  StockVoucherDraft({
    this.voucherPrefix = '',
    DateTime? voucherDate,
    this.financialYear = '',
    this.fromGodownId,
    this.fromGodownLabel,
    this.toGodownId,
    this.toGodownLabel,
    this.godownId,
    this.godownLabel,
    this.narration,
    this.requirementVoucherNo,
    List<StockVoucherLine>? lines,
  }) : voucherDate = voucherDate ?? DateTime.now(),
       lines = lines ?? [StockVoucherLine()];

  final String voucherPrefix;
  final DateTime voucherDate;
  final String financialYear;
  final int? fromGodownId;
  final String? fromGodownLabel;
  final int? toGodownId;
  final String? toGodownLabel;
  final int? godownId;
  final String? godownLabel;
  final String? narration;
  final String? requirementVoucherNo;
  final List<StockVoucherLine> lines;

  StockVoucherDraft copyWith({
    String? voucherPrefix,
    DateTime? voucherDate,
    String? financialYear,
    Object? fromGodownId = _unset,
    Object? fromGodownLabel = _unset,
    Object? toGodownId = _unset,
    Object? toGodownLabel = _unset,
    Object? godownId = _unset,
    Object? godownLabel = _unset,
    Object? narration = _unset,
    Object? requirementVoucherNo = _unset,
    List<StockVoucherLine>? lines,
  }) => StockVoucherDraft(
    voucherPrefix: voucherPrefix ?? this.voucherPrefix,
    voucherDate: voucherDate ?? this.voucherDate,
    financialYear: financialYear ?? this.financialYear,
    fromGodownId: identical(fromGodownId, _unset)
        ? this.fromGodownId
        : fromGodownId as int?,
    fromGodownLabel: identical(fromGodownLabel, _unset)
        ? this.fromGodownLabel
        : fromGodownLabel as String?,
    toGodownId: identical(toGodownId, _unset)
        ? this.toGodownId
        : toGodownId as int?,
    toGodownLabel: identical(toGodownLabel, _unset)
        ? this.toGodownLabel
        : toGodownLabel as String?,
    godownId: identical(godownId, _unset) ? this.godownId : godownId as int?,
    godownLabel: identical(godownLabel, _unset)
        ? this.godownLabel
        : godownLabel as String?,
    narration: identical(narration, _unset)
        ? this.narration
        : narration as String?,
    requirementVoucherNo: identical(requirementVoucherNo, _unset)
        ? this.requirementVoucherNo
        : requirementVoucherNo as String?,
    lines: lines ?? this.lines,
  );

  @override
  List<Object?> get props => [
    voucherPrefix,
    voucherDate,
    financialYear,
    fromGodownId,
    toGodownId,
    godownId,
    narration,
    requirementVoucherNo,
    lines,
  ];
}

class StockVoucherListItem extends Equatable {
  const StockVoucherListItem({
    required this.id,
    required this.voucherPrefix,
    required this.voucherNo,
    required this.voucherDate,
    this.status,
    this.total,
    this.billingName,
    this.narration,
  });

  final int id;
  final String voucherPrefix;
  final String voucherNo;
  final DateTime? voucherDate;
  final String? status;
  final Decimal? total;
  final String? billingName;
  final String? narration;

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
    narration,
  ];
}

class StockVoucherPostResult extends Equatable {
  const StockVoucherPostResult({
    required this.id,
    required this.voucherNo,
    this.total,
  });

  final int id;
  final String voucherNo;
  final Decimal? total;

  @override
  List<Object?> get props => [id, voucherNo, total];
}

class StockVoucherDetailLine extends Equatable {
  const StockVoucherDetailLine({
    required this.id,
    this.itemId,
    this.itemLabel,
    this.quantity,
    this.price,
    this.subtotal,
    this.crQty,
    this.drQty,
    this.requestQty,
    this.issueQty,
    this.narration,
  });

  final int id;
  final int? itemId;
  final String? itemLabel;
  final Decimal? quantity;
  final Decimal? price;
  final Decimal? subtotal;
  final Decimal? crQty;
  final Decimal? drQty;
  final Decimal? requestQty;
  final Decimal? issueQty;
  final String? narration;

  StockVoucherDetailLine copyWith({
    Object? itemLabel = _unset,
    Decimal? issueQty,
  }) => StockVoucherDetailLine(
    id: id,
    itemId: itemId,
    itemLabel: identical(itemLabel, _unset)
        ? this.itemLabel
        : itemLabel as String?,
    quantity: quantity,
    price: price,
    subtotal: subtotal,
    crQty: crQty,
    drQty: drQty,
    requestQty: requestQty,
    issueQty: issueQty ?? this.issueQty,
    narration: narration,
  );

  @override
  List<Object?> get props => [
    id,
    itemId,
    itemLabel,
    quantity,
    price,
    subtotal,
    crQty,
    drQty,
    requestQty,
    issueQty,
    narration,
  ];
}

class StockVoucherDetail extends Equatable {
  const StockVoucherDetail({
    required this.id,
    required this.status,
    required this.lines,
    this.voucherPrefix = '',
    this.voucherNo = '',
    this.voucherDate,
    this.fromGodownId,
    this.fromGodownLabel,
    this.toGodownId,
    this.toGodownLabel,
    this.godownId,
    this.godownLabel,
    this.total,
    this.billingName,
    this.narration,
    this.requirementVoucherNo,
  });

  final int id;
  final String status;
  final String voucherPrefix;
  final String voucherNo;
  final DateTime? voucherDate;
  final int? fromGodownId;
  final String? fromGodownLabel;
  final int? toGodownId;
  final String? toGodownLabel;
  final int? godownId;
  final String? godownLabel;
  final Decimal? total;
  final String? billingName;
  final String? narration;
  final String? requirementVoucherNo;
  final List<StockVoucherDetailLine> lines;

  String get displayNo {
    if (voucherNo.isEmpty) return '#$id';
    final p = voucherPrefix;
    if (p.isEmpty) return voucherNo;
    if (voucherNo.startsWith(p)) return voucherNo;
    return '$p$voucherNo';
  }

  bool get canCancel => status == 'Posted' || status == 'Approved';

  bool get canApprove => status == 'Draft' || status == 'Approved';

  bool get canReject => status == 'Draft' || status == 'Approved';

  /// Stock request fulfill is available while still open (Draft).
  bool get canFulfill => status == 'Draft' || status == 'Approved';

  StockVoucherDetail copyWith({
    String? status,
    Object? fromGodownLabel = _unset,
    Object? toGodownLabel = _unset,
    Object? godownLabel = _unset,
    List<StockVoucherDetailLine>? lines,
  }) => StockVoucherDetail(
    id: id,
    status: status ?? this.status,
    voucherPrefix: voucherPrefix,
    voucherNo: voucherNo,
    voucherDate: voucherDate,
    fromGodownId: fromGodownId,
    fromGodownLabel: identical(fromGodownLabel, _unset)
        ? this.fromGodownLabel
        : fromGodownLabel as String?,
    toGodownId: toGodownId,
    toGodownLabel: identical(toGodownLabel, _unset)
        ? this.toGodownLabel
        : toGodownLabel as String?,
    godownId: godownId,
    godownLabel: identical(godownLabel, _unset)
        ? this.godownLabel
        : godownLabel as String?,
    total: total,
    billingName: billingName,
    narration: narration,
    requirementVoucherNo: requirementVoucherNo,
    lines: lines ?? this.lines,
  );

  @override
  List<Object?> get props => [
    id,
    status,
    voucherPrefix,
    voucherNo,
    voucherDate,
    fromGodownId,
    fromGodownLabel,
    toGodownId,
    toGodownLabel,
    godownId,
    godownLabel,
    total,
    billingName,
    narration,
    requirementVoucherNo,
    lines,
  ];
}

class StockVoucherLifecycleResult extends Equatable {
  const StockVoucherLifecycleResult({
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
