import 'package:algo_erp_front/core/vouchers/item_qty/item_qty_dto.dart';
import 'package:algo_erp_front/core/vouchers/item_qty/item_qty_kind.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/domain/sales_invoice.dart';

/// Wire helpers for sales invoice — thin façade over [ItemQtyDto].
abstract final class SalesInvoiceDto {
  static const _kind = ItemQtyKinds.salesInvoice;

  static SalesInvoiceListItem listItemFromJson(Map<String, dynamic> json) =>
      ItemQtyDto.listItemFromJson(json, mainNestKey: _kind.mainNestKey);

  static SalesInvoiceDetail detailFromJson(Map<String, dynamic> json) =>
      ItemQtyDto.detailFromJson(json);

  static Map<String, dynamic> draftToPostJson(SalesInvoiceDraft draft) =>
      ItemQtyDto.draftToPostJson(draft, kind: _kind);

  static Map<String, dynamic> draftToEditJson(SalesInvoiceDraft draft) =>
      ItemQtyDto.draftToEditJson(draft);

  static SalesInvoicePostResult postResultFromJson(Map<String, dynamic> json) =>
      ItemQtyDto.postResultFromJson(json, idKey: _kind.postIdKey);

  static VoucherLifecycleResult lifecycleFromJson(Map<String, dynamic> json) =>
      ItemQtyDto.lifecycleFromJson(json);

  static EmployeeLite employeeFromJson(Map<String, dynamic> json) =>
      ItemQtyDto.employeeFromJson(json);

  static ProjectLite projectFromJson(Map<String, dynamic> json) =>
      ItemQtyDto.projectFromJson(json);

  static SourceVoucherLite sourceFromJson(
    Map<String, dynamic> json, {
    required String type,
  }) {
    final nest = type == 'SalesOrder' ? 'sales_order_main' : 'quotation_main';
    return ItemQtyDto.sourceFromJson(json, type: type, mainNestKey: nest);
  }

  static SalesInvoiceDraft detailToDraft(
    SalesInvoiceDetail detail, {
    String saveStatus = 'Draft',
  }) => ItemQtyDto.detailToDraft(
    detail,
    saveStatus: saveStatus,
    defaultPrefix: _kind.blueprint.defaultPrefix ?? 'SI',
  );
}
