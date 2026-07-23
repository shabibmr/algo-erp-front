import 'package:algo_erp_front/core/vouchers/voucher_blueprint.dart';
import 'package:flutter/foundation.dart';

/// Party field name on the POST body.
enum ItemQtyPartyField {
  customer('customer_ledger_id'),
  supplier('supplier_ledger_id'),

  /// Credit/Debit notes use a plain `ledger_id`.
  ledger('ledger_id');

  const ItemQtyPartyField(this.wireKey);
  final String wireKey;
}

/// Configuration for one item-qty trading voucher type.
///
/// Drives list/detail nest keys, post body shape, and UI labels without
/// forking DocumentSurface per type.
@immutable
class ItemQtyVoucherKind {
  const ItemQtyVoucherKind({
    required this.blueprint,
    required this.lifecycleType,
    required this.mainNestKey,
    required this.partyField,
    required this.partyLabel,
    required this.requiresGodown,
    this.supportsCreditDays = false,
    this.supportsSource = false,
    this.supportsSourceType = false,
    this.supportsSalesperson = false,
    this.supportsProject = false,
    this.supportsPostStatus = false,
    this.supportsDraftEdit = false,
    this.sourceLifecycleType,
    this.sourceListPath,
    this.sourceDetailPathPattern,
    this.sourceMainNestKey,
    this.postIdKey = 'headerId',
    this.createLabel = 'Create',
  });

  final VoucherBlueprint blueprint;

  /// Backend lifecycle segment, e.g. `Quotation`, `SalesOrder`.
  final String lifecycleType;

  /// Nested main on list rows, e.g. `quotation_main`.
  final String mainNestKey;

  final ItemQtyPartyField partyField;
  final String partyLabel;
  final bool requiresGodown;
  final bool supportsCreditDays;

  /// When true, form can convert from [sourceLifecycleType].
  final bool supportsSource;

  /// When true, post body includes `source_voucher_type` (SI multi-source).
  final bool supportsSourceType;

  final bool supportsSalesperson;
  final bool supportsProject;

  /// When true, post body includes `status` (`Draft` | `Posted`).
  final bool supportsPostStatus;

  /// When true, UI may PUT draft header/lines via lifecycle edit.
  final bool supportsDraftEdit;

  final String? sourceLifecycleType;
  final String? sourceListPath;
  final String? sourceDetailPathPattern;
  final String? sourceMainNestKey;

  /// Phase-4 posts return `headerId`; PI/SI return `id`.
  final String postIdKey;

  final String createLabel;

  String get listRoute => blueprint.listPath;
  String detailRoute(Object id) => blueprint.detailPath(id);
  String get newRoute => '${blueprint.listPath}/new';

  String? sourceDetailPath(Object id) {
    final p = sourceDetailPathPattern;
    if (p == null) return null;
    return p.replaceAll(':id', id.toString());
  }
}

/// Trading voucher seeds — SI gold + pre-sales + purchase chain.
abstract final class ItemQtyKinds {
  static const salesInvoice = ItemQtyVoucherKind(
    blueprint: VoucherBlueprints.salesInvoice,
    lifecycleType: 'SalesInvoice',
    mainNestKey: 'sales_invoice_main',
    partyField: ItemQtyPartyField.customer,
    partyLabel: 'Customer',
    requiresGodown: true,
    supportsCreditDays: true,
    supportsSource: true,
    supportsSourceType: true,
    supportsSalesperson: true,
    supportsProject: true,
    supportsPostStatus: true,
    supportsDraftEdit: true,
    // Default conversion source; UI may also load Quotation.
    sourceLifecycleType: 'SalesOrder',
    sourceListPath: '/transactions/sales-orders',
    sourceDetailPathPattern: '/transactions/sales-orders/:id',
    sourceMainNestKey: 'sales_order_main',
    postIdKey: 'id',
    createLabel: 'Post sales invoice',
  );

  static const quotation = ItemQtyVoucherKind(
    blueprint: VoucherBlueprints.quotation,
    lifecycleType: 'Quotation',
    mainNestKey: 'quotation_main',
    partyField: ItemQtyPartyField.customer,
    partyLabel: 'Customer',
    requiresGodown: false,
    createLabel: 'Create quotation',
  );

  static const salesOrder = ItemQtyVoucherKind(
    blueprint: VoucherBlueprints.salesOrder,
    lifecycleType: 'SalesOrder',
    mainNestKey: 'sales_order_main',
    partyField: ItemQtyPartyField.customer,
    partyLabel: 'Customer',
    requiresGodown: true,
    // Convert-from UI ready; backend SO post may ignore source_voucher_id
    // until phase4 schema is extended — still useful for line copy UX if wired.
    createLabel: 'Create sales order',
  );

  static const deliveryNote = ItemQtyVoucherKind(
    blueprint: VoucherBlueprints.deliveryNote,
    lifecycleType: 'DeliveryNote',
    mainNestKey: 'delivery_note_main',
    partyField: ItemQtyPartyField.customer,
    partyLabel: 'Customer',
    requiresGodown: true,
    supportsSource: true,
    sourceLifecycleType: 'SalesOrder',
    sourceListPath: '/transactions/sales-orders',
    sourceDetailPathPattern: '/transactions/sales-orders/:id',
    sourceMainNestKey: 'sales_order_main',
    createLabel: 'Post delivery note',
  );

  static const purchaseOrder = ItemQtyVoucherKind(
    blueprint: VoucherBlueprints.purchaseOrder,
    lifecycleType: 'PurchaseOrder',
    mainNestKey: 'purchase_order_main',
    partyField: ItemQtyPartyField.supplier,
    partyLabel: 'Supplier',
    requiresGodown: true,
    createLabel: 'Create purchase order',
  );

  static const receiptNote = ItemQtyVoucherKind(
    blueprint: VoucherBlueprints.receiptNote,
    lifecycleType: 'ReceiptNote',
    mainNestKey: 'receipt_note_main',
    partyField: ItemQtyPartyField.supplier,
    partyLabel: 'Supplier',
    requiresGodown: true,
    supportsSource: true,
    sourceLifecycleType: 'PurchaseOrder',
    sourceListPath: '/transactions/purchase-orders',
    sourceDetailPathPattern: '/transactions/purchase-orders/:id',
    sourceMainNestKey: 'purchase_order_main',
    createLabel: 'Post receipt note',
  );

  static const purchaseInvoice = ItemQtyVoucherKind(
    blueprint: VoucherBlueprints.purchaseInvoice,
    lifecycleType: 'PurchaseInvoice',
    mainNestKey: 'purchase_invoice_main',
    partyField: ItemQtyPartyField.supplier,
    partyLabel: 'Supplier',
    requiresGodown: true,
    supportsCreditDays: true,
    postIdKey: 'id',
    createLabel: 'Post purchase invoice',
  );

  static const creditNote = ItemQtyVoucherKind(
    blueprint: VoucherBlueprints.creditNote,
    lifecycleType: 'CreditNote',
    mainNestKey: 'credit_note_main',
    partyField: ItemQtyPartyField.ledger,
    partyLabel: 'Customer ledger',
    requiresGodown: true,
    postIdKey: 'id',
    createLabel: 'Post credit note',
  );

  static const debitNote = ItemQtyVoucherKind(
    blueprint: VoucherBlueprints.debitNote,
    lifecycleType: 'DebitNote',
    mainNestKey: 'debit_note_main',
    partyField: ItemQtyPartyField.ledger,
    partyLabel: 'Supplier ledger',
    requiresGodown: true,
    postIdKey: 'id',
    createLabel: 'Post debit note',
  );

  static const all = <ItemQtyVoucherKind>[
    salesInvoice,
    quotation,
    salesOrder,
    deliveryNote,
    purchaseOrder,
    receiptNote,
    purchaseInvoice,
    creditNote,
    debitNote,
  ];
}
