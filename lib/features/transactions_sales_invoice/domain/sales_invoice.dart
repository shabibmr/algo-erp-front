/// Sales Invoice domain types — aliases over shared item-qty trading models.
///
/// Prefer importing `core/vouchers/item_qty/*` for new code; these typedefs
/// keep the SI feature package readable and limit churn in call sites.
library;

import 'package:algo_erp_front/core/domain/lookups.dart';
import 'package:algo_erp_front/core/vouchers/item_qty/item_qty_models.dart';

export 'package:algo_erp_front/core/domain/lookups.dart' show NamedRef;
export 'package:algo_erp_front/core/vouchers/item_qty/item_qty_models.dart';

typedef SalesInvoiceLine = ItemQtyLine;
typedef SalesInvoiceDraft = ItemQtyDraft;
typedef SalesInvoiceListItem = ItemQtyListItem;
typedef SalesInvoiceDetail = ItemQtyDetail;
typedef SalesInvoiceDetailLine = ItemQtyDetailLine;
typedef SalesInvoicePostResult = ItemQtyPostResult;
typedef SourceVoucherLite = ItemQtySourceLite;
typedef VoucherLifecycleResult = ItemQtyLifecycleResult;

/// Lightweight employee row for salesperson FK.
typedef EmployeeLite = NamedRef;

/// Lightweight project row for project FK.
typedef ProjectLite = NamedRef;
