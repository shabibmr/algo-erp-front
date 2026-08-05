import 'package:algo_erp_front/core/domain/line_engine/line_engine.dart';
import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

const _unset = Object();

/// Shared item + qty + price line for trading vouchers (SI/Q/SO/DN/PO/RN/PI/…).
class ItemQtyLine extends Equatable {
  ItemQtyLine({
    this.itemId,
    this.itemLabel,
    this.itemCode,
    this.skuId,
    this.batchId,
    this.sourceLineId,
    this.priceLevel,
    Decimal? quantity,
    Decimal? price,
    Decimal? discountPercent,
    Decimal? taxRate,
    int? uid,
  }) : quantity = quantity ?? Decimal.one,
       price = price ?? Decimal.zero,
       discountPercent = discountPercent ?? Decimal.zero,
       taxRate = taxRate ?? Decimal.zero,
       uid = uid ?? _nextUid++;

  static int _nextUid = 0;

  /// Client-side row identity, stable across [copyWith], so the line grid can
  /// key rows by the line rather than by position. Deliberately absent from
  /// [props] (identity, not value) and never sent to the server.
  final int uid;

  final int? itemId;

  /// Display-only label from the item picker.
  final String? itemLabel;

  /// Inventory `Item_Code` — needed for price-list effective-price lookup.
  final String? itemCode;
  final int? skuId;
  final int? batchId;
  final int? sourceLineId;

  /// Detail `PriceLevel` audit (price list name or id).
  final String? priceLevel;
  final Decimal quantity;
  final Decimal price;
  final Decimal discountPercent;
  final Decimal taxRate;

  bool get isComplete =>
      itemId != null && quantity > Decimal.zero && price >= Decimal.zero;

  /// Input for [LineEngine] — single path for form totals and edit payloads.
  LineInput toLineInput() => LineInput(
    quantity: quantity,
    price: price,
    discountPercent: discountPercent,
    taxRate: taxRate,
  );

  ItemQtyLine copyWith({
    Object? itemId = _unset,
    Object? itemLabel = _unset,
    Object? itemCode = _unset,
    Object? skuId = _unset,
    Object? batchId = _unset,
    Object? sourceLineId = _unset,
    Object? priceLevel = _unset,
    Decimal? quantity,
    Decimal? price,
    Decimal? discountPercent,
    Decimal? taxRate,
  }) => ItemQtyLine(
    itemId: identical(itemId, _unset) ? this.itemId : itemId as int?,
    itemLabel: identical(itemLabel, _unset)
        ? this.itemLabel
        : itemLabel as String?,
    itemCode: identical(itemCode, _unset)
        ? this.itemCode
        : itemCode as String?,
    skuId: identical(skuId, _unset) ? this.skuId : skuId as int?,
    batchId: identical(batchId, _unset) ? this.batchId : batchId as int?,
    sourceLineId: identical(sourceLineId, _unset)
        ? this.sourceLineId
        : sourceLineId as int?,
    priceLevel: identical(priceLevel, _unset)
        ? this.priceLevel
        : priceLevel as String?,
    quantity: quantity ?? this.quantity,
    price: price ?? this.price,
    discountPercent: discountPercent ?? this.discountPercent,
    taxRate: taxRate ?? this.taxRate,
    uid: uid,
  );

  @override
  List<Object?> get props => [
    itemId,
    itemLabel,
    itemCode,
    skuId,
    batchId,
    sourceLineId,
    priceLevel,
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
    this.salespersonEmployeeId,
    this.salespersonLabel,
    this.voucherProjectId,
    this.projectLabel,
    this.billingName,
    this.narration,
    this.creditDays = 30,
    this.sourceVoucherId,
    this.sourceVoucherType,
    this.sourceVoucherLabel,
    this.priceListId,
    this.priceListLabel,
    this.saveStatus = 'Posted',
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
  final int? salespersonEmployeeId;
  final String? salespersonLabel;
  final int? voucherProjectId;
  final String? projectLabel;
  final String? billingName;
  final String? narration;
  final int creditDays;
  final int? sourceVoucherId;
  final String? sourceVoucherType;
  final String? sourceVoucherLabel;

  /// Optional header price list for rate lookup (SI / SO).
  final int? priceListId;
  final String? priceListLabel;

  /// `Draft` or `Posted` — used by SI post body (`status`).
  final String saveStatus;
  final List<ItemQtyLine> lines;

  /// Domain-level readiness for create/post (not edit).
  bool get isReadyToPost =>
      partyLedgerId != null &&
      godownId != null &&
      financialYear.trim().isNotEmpty &&
      lines.any((l) => l.isComplete);

  /// Ready for draft-only edit (party + godown + ≥1 line; FY may be absent).
  bool get isReadyToSaveDraft =>
      partyLedgerId != null &&
      godownId != null &&
      lines.any((l) => l.isComplete);

  ItemQtyDraft copyWith({
    String? voucherPrefix,
    DateTime? voucherDate,
    String? financialYear,
    Object? partyLedgerId = _unset,
    Object? partyLabel = _unset,
    Object? godownId = _unset,
    Object? godownLabel = _unset,
    Object? salespersonEmployeeId = _unset,
    Object? salespersonLabel = _unset,
    Object? voucherProjectId = _unset,
    Object? projectLabel = _unset,
    Object? billingName = _unset,
    Object? narration = _unset,
    int? creditDays,
    Object? sourceVoucherId = _unset,
    Object? sourceVoucherType = _unset,
    Object? sourceVoucherLabel = _unset,
    Object? priceListId = _unset,
    Object? priceListLabel = _unset,
    String? saveStatus,
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
    salespersonEmployeeId: identical(salespersonEmployeeId, _unset)
        ? this.salespersonEmployeeId
        : salespersonEmployeeId as int?,
    salespersonLabel: identical(salespersonLabel, _unset)
        ? this.salespersonLabel
        : salespersonLabel as String?,
    voucherProjectId: identical(voucherProjectId, _unset)
        ? this.voucherProjectId
        : voucherProjectId as int?,
    projectLabel: identical(projectLabel, _unset)
        ? this.projectLabel
        : projectLabel as String?,
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
    sourceVoucherType: identical(sourceVoucherType, _unset)
        ? this.sourceVoucherType
        : sourceVoucherType as String?,
    sourceVoucherLabel: identical(sourceVoucherLabel, _unset)
        ? this.sourceVoucherLabel
        : sourceVoucherLabel as String?,
    priceListId: identical(priceListId, _unset)
        ? this.priceListId
        : priceListId as int?,
    priceListLabel: identical(priceListLabel, _unset)
        ? this.priceListLabel
        : priceListLabel as String?,
    saveStatus: saveStatus ?? this.saveStatus,
    lines: lines ?? this.lines,
  );

  @override
  List<Object?> get props => [
    voucherPrefix,
    voucherDate,
    financialYear,
    partyLedgerId,
    partyLabel,
    godownId,
    godownLabel,
    salespersonEmployeeId,
    salespersonLabel,
    voucherProjectId,
    projectLabel,
    billingName,
    narration,
    creditDays,
    sourceVoucherId,
    sourceVoucherType,
    sourceVoucherLabel,
    priceListId,
    priceListLabel,
    saveStatus,
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
    this.subtotal,
    this.discount,
    this.vat,
  });

  final int id;
  final String voucherNo;
  final Decimal total;
  final Decimal? subtotal;
  final Decimal? discount;
  final Decimal? vat;

  @override
  List<Object?> get props => [id, voucherNo, total, subtotal, discount, vat];
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

  /// Map a persisted detail line into a draft line for create/edit forms.
  ItemQtyLine toDraftLine() => ItemQtyLine(
    itemId: itemId,
    itemLabel: itemLabel,
    quantity: quantity ?? Decimal.one,
    price: price ?? Decimal.zero,
    discountPercent: discountPercent ?? Decimal.zero,
    taxRate: taxRate ?? Decimal.zero,
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
    this.salespersonEmployeeId,
    this.salespersonLabel,
    this.voucherProjectId,
    this.projectLabel,
    this.total,
    this.grossTotal,
    this.discount,
    this.vat,
    this.rejectionReason,
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
  final int? salespersonEmployeeId;
  final String? salespersonLabel;
  final int? voucherProjectId;
  final String? projectLabel;
  final Decimal? total;
  final Decimal? grossTotal;
  final Decimal? discount;
  final Decimal? vat;
  final String? rejectionReason;
  final String? narration;
  final List<ItemQtyDetailLine> lines;

  String get displayNo {
    if (voucherNo.isEmpty) return '#$id';
    final p = voucherPrefix;
    if (p.isEmpty) return voucherNo;
    if (voucherNo.startsWith(p)) return voucherNo;
    return '$p$voucherNo';
  }

  /// Backend cancel allows Posted or Approved only.
  bool get canCancel => status == 'Posted' || status == 'Approved';

  /// Approve advances Draft → Approved/Posted (series-dependent).
  bool get canApprove => status == 'Draft' || status == 'Approved';

  bool get canReject => status == 'Draft' || status == 'Approved';

  bool get canEditDraft => status == 'Draft';

  /// Prefer Approve (SI books GL on backend when → Posted).
  bool get canPostAndBook => false;

  bool get isTerminal => status == 'Cancelled' || status == 'Rejected';

  ItemQtyDetail copyWith({
    String? status,
    Object? partyLabel = _unset,
    Object? godownLabel = _unset,
    Object? salespersonLabel = _unset,
    Object? projectLabel = _unset,
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
    salespersonEmployeeId: salespersonEmployeeId,
    salespersonLabel: identical(salespersonLabel, _unset)
        ? this.salespersonLabel
        : salespersonLabel as String?,
    voucherProjectId: voucherProjectId,
    projectLabel: identical(projectLabel, _unset)
        ? this.projectLabel
        : projectLabel as String?,
    total: total,
    grossTotal: grossTotal,
    discount: discount,
    vat: vat,
    rejectionReason: rejectionReason,
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
    salespersonEmployeeId,
    salespersonLabel,
    voucherProjectId,
    projectLabel,
    total,
    grossTotal,
    discount,
    vat,
    rejectionReason,
    narration,
    lines,
  ];
}

/// Lightweight source voucher for conversion (Q/SO → SI, SO → DN, PO → RN).
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
    this.reason,
    this.booked,
  });

  final int id;
  final String status;
  final String? message;
  final String? reason;

  /// True when approve also booked GL/stock (Sales Invoice → Posted).
  final bool? booked;

  @override
  List<Object?> get props => [id, status, message, reason, booked];
}
