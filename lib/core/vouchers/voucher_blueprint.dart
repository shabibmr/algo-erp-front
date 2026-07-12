import 'package:flutter/foundation.dart';

/// Who appears as the primary party on the document header.
enum VoucherPartyKind {
  /// Customer receivable (Sales Invoice, Credit Note, …).
  customer,

  /// Supplier payable (Purchase Invoice, Debit Note, …).
  supplier,

  /// No party (Journal, Contra).
  none,

  /// Cash/bank + counterparty lines (Payment / Receipt).
  cashBank,
}

/// Shape of each detail line.
enum VoucherLineShape {
  /// item + qty + price + discount% + tax% (SI / PI / notes).
  itemQty,

  /// ledger + amount (Payment / Receipt).
  ledgerAmount,

  /// ledger + debit + credit (Journal).
  debitCredit,

  /// ledger + amount + DR/CR (Contra).
  contraAmount,
}

/// Lifecycle actions the UI may expose (gated by status + RBAC).
enum VoucherLifecycleAction { saveDraft, post, approve, reject, cancel, edit }

/// Declares one voucher type for DocumentSurface and feature packages.
///
/// One blueprint per type (Sales Invoice, Payment, …) — not a freezed
/// runtime registry yet; features hold a `const` instance.
@immutable
class VoucherBlueprint {
  const VoucherBlueprint({
    required this.id,
    required this.label,
    required this.rbacModule,
    required this.party,
    required this.lineShape,
    required this.postPath,
    required this.listPath,
    required this.detailPathPattern,
    this.affectsGl = true,
    this.affectsStock = false,
    this.needsGodown = false,
    this.needsBatch = false,
    this.lifecycle = const {VoucherLifecycleAction.post},
    this.defaultPrefix,
  });

  /// Stable id, e.g. `sales-invoice`.
  final String id;
  final String label;

  /// Backend `authorize` module, e.g. `SalesInvoice`.
  final String rbacModule;

  final VoucherPartyKind party;
  final VoucherLineShape lineShape;

  /// POST path for create/post, e.g. `/transactions/sales-invoice`.
  final String postPath;

  /// GET list path, e.g. `/transactions/sales-invoices`.
  final String listPath;

  /// Detail path with `:id`, e.g. `/transactions/sales-invoices/:id`.
  final String detailPathPattern;

  final bool affectsGl;
  final bool affectsStock;
  final bool needsGodown;
  final bool needsBatch;

  /// Actions this type supports in principle (UI still filters by status).
  final Set<VoucherLifecycleAction> lifecycle;

  /// Suggested voucher series prefix, e.g. `SI`.
  final String? defaultPrefix;

  String detailPath(Object id) =>
      detailPathPattern.replaceAll(':id', id.toString());
}

/// Seed blueprints — SI gold + Sprint D trading family.
abstract final class VoucherBlueprints {
  static const salesInvoice = VoucherBlueprint(
    id: 'sales-invoice',
    label: 'Sales invoice',
    rbacModule: 'SalesInvoice',
    party: VoucherPartyKind.customer,
    lineShape: VoucherLineShape.itemQty,
    postPath: '/transactions/sales-invoice',
    listPath: '/transactions/sales-invoices',
    detailPathPattern: '/transactions/sales-invoices/:id',
    affectsStock: true,
    needsGodown: true,
    lifecycle: {
      VoucherLifecycleAction.saveDraft,
      VoucherLifecycleAction.post,
      VoucherLifecycleAction.cancel,
      VoucherLifecycleAction.approve,
      VoucherLifecycleAction.reject,
      VoucherLifecycleAction.edit,
    },
    defaultPrefix: 'SI',
  );

  static const quotation = VoucherBlueprint(
    id: 'quotation',
    label: 'Quotation',
    rbacModule: 'Quotation',
    party: VoucherPartyKind.customer,
    lineShape: VoucherLineShape.itemQty,
    postPath: '/transactions/quotation',
    listPath: '/transactions/quotations',
    detailPathPattern: '/transactions/quotations/:id',
    affectsGl: false,
    lifecycle: {VoucherLifecycleAction.post, VoucherLifecycleAction.cancel},
    defaultPrefix: 'QT',
  );

  static const salesOrder = VoucherBlueprint(
    id: 'sales-order',
    label: 'Sales order',
    rbacModule: 'SalesOrder',
    party: VoucherPartyKind.customer,
    lineShape: VoucherLineShape.itemQty,
    postPath: '/transactions/sales-order',
    listPath: '/transactions/sales-orders',
    detailPathPattern: '/transactions/sales-orders/:id',
    affectsGl: false,
    needsGodown: true,
    lifecycle: {VoucherLifecycleAction.post, VoucherLifecycleAction.cancel},
    defaultPrefix: 'SO',
  );

  static const deliveryNote = VoucherBlueprint(
    id: 'delivery-note',
    label: 'Delivery note',
    rbacModule: 'DeliveryNote',
    party: VoucherPartyKind.customer,
    lineShape: VoucherLineShape.itemQty,
    postPath: '/transactions/delivery-note',
    listPath: '/transactions/delivery-notes',
    detailPathPattern: '/transactions/delivery-notes/:id',
    affectsStock: true,
    needsGodown: true,
    lifecycle: {VoucherLifecycleAction.post, VoucherLifecycleAction.cancel},
    defaultPrefix: 'DN',
  );

  static const purchaseOrder = VoucherBlueprint(
    id: 'purchase-order',
    label: 'Purchase order',
    rbacModule: 'PurchaseOrder',
    party: VoucherPartyKind.supplier,
    lineShape: VoucherLineShape.itemQty,
    postPath: '/transactions/purchase-order',
    listPath: '/transactions/purchase-orders',
    detailPathPattern: '/transactions/purchase-orders/:id',
    affectsGl: false,
    needsGodown: true,
    lifecycle: {VoucherLifecycleAction.post, VoucherLifecycleAction.cancel},
    defaultPrefix: 'PO',
  );

  static const receiptNote = VoucherBlueprint(
    id: 'receipt-note',
    label: 'Receipt note',
    rbacModule: 'ReceiptNote',
    party: VoucherPartyKind.supplier,
    lineShape: VoucherLineShape.itemQty,
    postPath: '/transactions/receipt-note',
    listPath: '/transactions/receipt-notes',
    detailPathPattern: '/transactions/receipt-notes/:id',
    affectsStock: true,
    needsGodown: true,
    lifecycle: {VoucherLifecycleAction.post, VoucherLifecycleAction.cancel},
    defaultPrefix: 'RN',
  );

  static const purchaseInvoice = VoucherBlueprint(
    id: 'purchase-invoice',
    label: 'Purchase invoice',
    rbacModule: 'PurchaseInvoice',
    party: VoucherPartyKind.supplier,
    lineShape: VoucherLineShape.itemQty,
    postPath: '/transactions/purchase-invoice',
    listPath: '/transactions/purchase-invoices',
    detailPathPattern: '/transactions/purchase-invoices/:id',
    affectsStock: true,
    needsGodown: true,
    lifecycle: {
      VoucherLifecycleAction.post,
      VoucherLifecycleAction.cancel,
      VoucherLifecycleAction.approve,
      VoucherLifecycleAction.reject,
    },
    defaultPrefix: 'PI',
  );

  static const payment = VoucherBlueprint(
    id: 'payment',
    label: 'Payment',
    rbacModule: 'PaymentVoucher',
    party: VoucherPartyKind.cashBank,
    lineShape: VoucherLineShape.ledgerAmount,
    postPath: '/transactions/payment',
    listPath: '/transactions/payments',
    detailPathPattern: '/transactions/payments/:id',
    lifecycle: {VoucherLifecycleAction.post, VoucherLifecycleAction.cancel},
    defaultPrefix: 'PV',
  );

  static const receipt = VoucherBlueprint(
    id: 'receipt',
    label: 'Receipt',
    rbacModule: 'ReceiptVoucher',
    party: VoucherPartyKind.cashBank,
    lineShape: VoucherLineShape.ledgerAmount,
    postPath: '/transactions/receipt',
    listPath: '/transactions/receipts',
    detailPathPattern: '/transactions/receipts/:id',
    lifecycle: {VoucherLifecycleAction.post, VoucherLifecycleAction.cancel},
    defaultPrefix: 'RV',
  );

  static const creditNote = VoucherBlueprint(
    id: 'credit-note',
    label: 'Credit note',
    rbacModule: 'CreditNote',
    party: VoucherPartyKind.customer,
    lineShape: VoucherLineShape.itemQty,
    postPath: '/transactions/credit-note',
    listPath: '/transactions/credit-notes',
    detailPathPattern: '/transactions/credit-notes/:id',
    affectsStock: true,
    needsGodown: true,
    lifecycle: {VoucherLifecycleAction.post, VoucherLifecycleAction.cancel},
    defaultPrefix: 'CN',
  );

  static const debitNote = VoucherBlueprint(
    id: 'debit-note',
    label: 'Debit note',
    rbacModule: 'DebitNote',
    party: VoucherPartyKind.supplier,
    lineShape: VoucherLineShape.itemQty,
    postPath: '/transactions/debit-note',
    listPath: '/transactions/debit-notes',
    detailPathPattern: '/transactions/debit-notes/:id',
    affectsStock: true,
    needsGodown: true,
    lifecycle: {VoucherLifecycleAction.post, VoucherLifecycleAction.cancel},
    defaultPrefix: 'DBN',
  );

  static const journal = VoucherBlueprint(
    id: 'journal',
    label: 'Journal',
    rbacModule: 'JournalVoucher',
    party: VoucherPartyKind.none,
    lineShape: VoucherLineShape.debitCredit,
    postPath: '/transactions/journal',
    listPath: '/transactions/journals',
    detailPathPattern: '/transactions/journals/:id',
    lifecycle: {VoucherLifecycleAction.post, VoucherLifecycleAction.cancel},
    defaultPrefix: 'JV',
  );

  static const contra = VoucherBlueprint(
    id: 'contra',
    label: 'Contra',
    rbacModule: 'ContraVoucher',
    party: VoucherPartyKind.none,
    lineShape: VoucherLineShape.contraAmount,
    postPath: '/transactions/contra',
    listPath: '/transactions/contra',
    detailPathPattern: '/transactions/contra/:id',
    lifecycle: {VoucherLifecycleAction.post, VoucherLifecycleAction.cancel},
    defaultPrefix: 'CV',
  );

  static const godownTransfer = VoucherBlueprint(
    id: 'godown-transfer',
    label: 'Godown transfer',
    rbacModule: 'GodownTransfer',
    party: VoucherPartyKind.none,
    lineShape: VoucherLineShape.itemQty,
    postPath: '/transactions/godown-transfer',
    listPath: '/transactions/godown-transfers',
    detailPathPattern: '/transactions/godown-transfers/:id',
    affectsGl: false,
    affectsStock: true,
    needsGodown: true,
    lifecycle: {VoucherLifecycleAction.post, VoucherLifecycleAction.cancel},
    defaultPrefix: 'GT',
  );

  static const materialIn = VoucherBlueprint(
    id: 'material-in',
    label: 'Material in',
    rbacModule: 'MaterialIn',
    party: VoucherPartyKind.none,
    lineShape: VoucherLineShape.itemQty,
    postPath: '/transactions/material-in',
    listPath: '/transactions/material-in',
    detailPathPattern: '/transactions/material-in/:id',
    affectsGl: false,
    affectsStock: true,
    needsGodown: true,
    lifecycle: {VoucherLifecycleAction.post, VoucherLifecycleAction.cancel},
    defaultPrefix: 'MI',
  );

  static const requirement = VoucherBlueprint(
    id: 'requirement',
    label: 'Requirement',
    rbacModule: 'Requirement',
    party: VoucherPartyKind.none,
    lineShape: VoucherLineShape.itemQty,
    postPath: '/transactions/requirement',
    listPath: '/transactions/requirements',
    detailPathPattern: '/transactions/requirements/:id',
    affectsGl: false,
    lifecycle: {VoucherLifecycleAction.post, VoucherLifecycleAction.cancel},
    defaultPrefix: 'RQ',
  );

  static const stockRequest = VoucherBlueprint(
    id: 'stock-request',
    label: 'Stock request',
    rbacModule: 'StockRequest',
    party: VoucherPartyKind.none,
    lineShape: VoucherLineShape.itemQty,
    postPath: '/transactions/stock-request',
    listPath: '/transactions/stock-requests',
    detailPathPattern: '/transactions/stock-requests/:id',
    affectsGl: false,
    affectsStock: true,
    needsGodown: true,
    lifecycle: {VoucherLifecycleAction.post, VoucherLifecycleAction.cancel},
    defaultPrefix: 'SR',
  );
}
