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
enum VoucherLifecycleAction {
  saveDraft,
  post,
  approve,
  reject,
  cancel,
  edit,
}

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
    this.lifecycle = const {
      VoucherLifecycleAction.post,
    },
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

/// Seed blueprints — expand in Sprint D.
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
}
