import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

const _unset = Object();

/// Draft line for posting a sales invoice.
class SalesInvoiceLine extends Equatable {
  SalesInvoiceLine({
    this.itemId,
    this.itemLabel,
    this.skuId,
    this.batchId,
    Decimal? quantity,
    Decimal? price,
    Decimal? discountPercent,
    Decimal? taxRate,
  }) : quantity = quantity ?? Decimal.one,
       price = price ?? Decimal.zero,
       discountPercent = discountPercent ?? Decimal.zero,
       taxRate = taxRate ?? Decimal.zero;

  final int? itemId;

  /// Display-only label from the item picker.
  final String? itemLabel;
  final int? skuId;
  final int? batchId;
  final Decimal quantity;
  final Decimal price;
  final Decimal discountPercent;
  final Decimal taxRate;

  bool get isComplete =>
      itemId != null && quantity > Decimal.zero && price >= Decimal.zero;

  SalesInvoiceLine copyWith({
    Object? itemId = _unset,
    Object? itemLabel = _unset,
    Object? skuId = _unset,
    Object? batchId = _unset,
    Decimal? quantity,
    Decimal? price,
    Decimal? discountPercent,
    Decimal? taxRate,
  }) => SalesInvoiceLine(
    itemId: identical(itemId, _unset) ? this.itemId : itemId as int?,
    itemLabel: identical(itemLabel, _unset)
        ? this.itemLabel
        : itemLabel as String?,
    skuId: identical(skuId, _unset) ? this.skuId : skuId as int?,
    batchId: identical(batchId, _unset) ? this.batchId : batchId as int?,
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
    quantity,
    price,
    discountPercent,
    taxRate,
  ];
}

/// Create/post payload for sales invoice (online posting endpoint).
class SalesInvoiceDraft extends Equatable {
  SalesInvoiceDraft({
    this.voucherPrefix = 'SI',
    DateTime? voucherDate,
    this.financialYear = '',
    this.customerLedgerId,
    this.customerLabel,
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

    /// `Draft` or `Posted` — matches `salesInvoicePostSchema.status`.
    this.saveStatus = 'Posted',
    List<SalesInvoiceLine>? lines,
  }) : voucherDate = voucherDate ?? DateTime.now(),
       lines = lines ?? [SalesInvoiceLine()];

  final String voucherPrefix;
  final DateTime voucherDate;
  final String financialYear;
  final int? customerLedgerId;
  final String? customerLabel;
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
  final String saveStatus;
  final List<SalesInvoiceLine> lines;

  SalesInvoiceDraft copyWith({
    String? voucherPrefix,
    DateTime? voucherDate,
    String? financialYear,
    Object? customerLedgerId = _unset,
    Object? customerLabel = _unset,
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
    String? saveStatus,
    List<SalesInvoiceLine>? lines,
  }) => SalesInvoiceDraft(
    voucherPrefix: voucherPrefix ?? this.voucherPrefix,
    voucherDate: voucherDate ?? this.voucherDate,
    financialYear: financialYear ?? this.financialYear,
    customerLedgerId: identical(customerLedgerId, _unset)
        ? this.customerLedgerId
        : customerLedgerId as int?,
    customerLabel: identical(customerLabel, _unset)
        ? this.customerLabel
        : customerLabel as String?,
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
    saveStatus: saveStatus ?? this.saveStatus,
    lines: lines ?? this.lines,
  );

  @override
  List<Object?> get props => [
    voucherPrefix,
    voucherDate,
    financialYear,
    customerLedgerId,
    godownId,
    salespersonEmployeeId,
    voucherProjectId,
    billingName,
    narration,
    creditDays,
    sourceVoucherId,
    sourceVoucherType,
    saveStatus,
    lines,
  ];
}

/// Lightweight employee row for salesperson FK.
class EmployeeLite extends Equatable {
  const EmployeeLite({required this.id, required this.name, this.code});

  final int id;
  final String name;
  final String? code;

  String get label => (code == null || code!.isEmpty) ? name : '$code — $name';

  @override
  List<Object?> get props => [id, name, code];
}

/// Lightweight project row for project FK.
class ProjectLite extends Equatable {
  const ProjectLite({required this.id, required this.name, this.code});

  final int id;
  final String name;
  final String? code;

  String get label => (code == null || code!.isEmpty) ? name : '$code — $name';

  @override
  List<Object?> get props => [id, name, code];
}

/// Source voucher for Quotation / Sales Order conversion.
class SourceVoucherLite extends Equatable {
  const SourceVoucherLite({
    required this.id,
    required this.type,
    required this.displayNo,
    this.billingName,
    this.customerLedgerId,
    this.godownId,
    this.lines = const [],
  });

  final int id;
  final String type; // Quotation | SalesOrder
  final String displayNo;
  final String? billingName;
  final int? customerLedgerId;
  final int? godownId;
  final List<SalesInvoiceLine> lines;

  @override
  List<Object?> get props => [
    id,
    type,
    displayNo,
    billingName,
    customerLedgerId,
    godownId,
    lines,
  ];
}

/// List-row projection from GET `/transactions/sales-invoices`.
class SalesInvoiceListItem extends Equatable {
  const SalesInvoiceListItem({
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

/// Result of a successful POST.
class SalesInvoicePostResult extends Equatable {
  const SalesInvoicePostResult({
    required this.id,
    required this.voucherNo,
    required this.total,
    required this.subtotal,
    required this.discount,
    required this.vat,
  });

  final int id;
  final String voucherNo;
  final Decimal total;
  final Decimal subtotal;
  final Decimal discount;
  final Decimal vat;

  @override
  List<Object?> get props => [id, voucherNo, total, subtotal, discount, vat];
}

/// Detail from GET `/transactions/sales-invoices/:id`.
class SalesInvoiceDetail extends Equatable {
  const SalesInvoiceDetail({
    required this.id,
    required this.status,
    required this.lines,
    this.voucherPrefix = '',
    this.voucherNo = '',
    this.voucherDate,
    this.billingName,
    this.customerLedgerId,
    this.customerLabel,
    this.godownId,
    this.godownLabel,
    this.total,
    this.grossTotal,
    this.discount,
    this.vat,
    this.rejectionReason,
    this.narration,
    this.salespersonEmployeeId,
    this.salespersonLabel,
    this.voucherProjectId,
    this.projectLabel,
  });

  final int id;
  final String status;
  final String voucherPrefix;
  final String voucherNo;
  final DateTime? voucherDate;
  final String? billingName;
  final int? customerLedgerId;
  final String? customerLabel;
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
  final List<SalesInvoiceDetailLine> lines;

  String get displayNo {
    if (voucherNo.isEmpty) return '#$id';
    final p = voucherPrefix;
    if (p.isEmpty) return voucherNo;
    if (voucherNo.startsWith(p)) return voucherNo;
    return '$p$voucherNo';
  }

  bool get canApprove => status == 'Draft' || status == 'Approved';
  bool get canReject => status == 'Draft' || status == 'Approved';
  bool get canCancel => status == 'Posted' || status == 'Approved';
  bool get canEditDraft => status == 'Draft';

  /// Prefer Approve (now books GL on backend when → Posted).
  bool get canPostAndBook => false;
  bool get isTerminal => status == 'Cancelled' || status == 'Rejected';

  SalesInvoiceDetail copyWith({
    String? status,
    Object? customerLabel = _unset,
    Object? godownLabel = _unset,
    Object? salespersonLabel = _unset,
    Object? projectLabel = _unset,
    List<SalesInvoiceDetailLine>? lines,
  }) => SalesInvoiceDetail(
    id: id,
    status: status ?? this.status,
    voucherPrefix: voucherPrefix,
    voucherNo: voucherNo,
    voucherDate: voucherDate,
    billingName: billingName,
    customerLedgerId: customerLedgerId,
    customerLabel: identical(customerLabel, _unset)
        ? this.customerLabel
        : customerLabel as String?,
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
    customerLedgerId,
    customerLabel,
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

class SalesInvoiceDetailLine extends Equatable {
  const SalesInvoiceDetailLine({
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

  /// Resolved from InventoryItem (detail API only returns item_id).
  final String? itemLabel;
  final Decimal? quantity;
  final Decimal? price;
  final Decimal? discountPercent;
  final Decimal? discountAmount;
  final Decimal? subtotal;
  final Decimal? taxRate;
  final Decimal? taxAmount;

  SalesInvoiceDetailLine copyWith({Object? itemLabel = _unset}) =>
      SalesInvoiceDetailLine(
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

/// Result of approve / reject / cancel lifecycle calls.
class VoucherLifecycleResult extends Equatable {
  const VoucherLifecycleResult({
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
