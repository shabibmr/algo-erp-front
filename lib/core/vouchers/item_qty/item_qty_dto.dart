import 'package:algo_erp_front/core/vouchers/item_qty/item_qty_kind.dart';
import 'package:algo_erp_front/core/vouchers/item_qty/item_qty_models.dart';
import 'package:decimal/decimal.dart';

/// Wire helpers for item-qty trading vouchers
/// (parameterized by [ItemQtyVoucherKind]).
abstract final class ItemQtyDto {
  static Decimal? _decimal(dynamic v) {
    if (v == null) return null;
    return Decimal.tryParse(v.toString());
  }

  static String _dateOnly(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static ItemQtyListItem listItemFromJson(
    Map<String, dynamic> json, {
    required String mainNestKey,
  }) {
    final main = json[mainNestKey];
    Map<String, dynamic>? mainMap;
    if (main is Map<String, dynamic>) mainMap = main;

    final dateRaw = json['voucher_date'];
    DateTime? date;
    if (dateRaw is String && dateRaw.isNotEmpty) {
      date = DateTime.tryParse(dateRaw);
    }

    return ItemQtyListItem(
      id: json['id'] as int,
      voucherPrefix: json['voucher_prefix'] as String? ?? '',
      voucherNo: json['voucher_no'] as String? ?? '',
      voucherDate: date,
      status: mainMap?['VoucherStatus'] as String?,
      total: _decimal(mainMap?['Total'] ?? mainMap?['Gross_Total']),
      billingName: mainMap?['Billing_Name'] as String?,
    );
  }

  static ItemQtyDetail detailFromJson(Map<String, dynamic> json) {
    final headers = json['voucher_headers'];
    Map<String, dynamic>? h;
    if (headers is Map<String, dynamic>) h = headers;

    DateTime? date;
    final dateRaw = h?['voucher_date'] ?? json['Date_Created'];
    if (dateRaw is String && dateRaw.isNotEmpty) {
      date = DateTime.tryParse(dateRaw);
    }

    final rawDetails = json['details'];
    final lines = <ItemQtyDetailLine>[];
    if (rawDetails is List) {
      for (final row in rawDetails) {
        if (row is! Map<String, dynamic>) continue;
        lines.add(
          ItemQtyDetailLine(
            id: row['id'] as int? ?? 0,
            itemId: row['item_id'] as int?,
            quantity: _decimal(row['Quantity']),
            price: _decimal(row['Price']),
            discountPercent: _decimal(row['Discount_Percent']),
            discountAmount: _decimal(row['Discount_Amount']),
            subtotal: _decimal(row['Subtotal']),
            taxRate: _decimal(row['Tax_Rate']),
            taxAmount: _decimal(row['Tax_Amount']),
          ),
        );
      }
    }

    return ItemQtyDetail(
      id: json['id'] as int,
      status: json['VoucherStatus'] as String? ?? 'Draft',
      voucherPrefix: h?['voucher_prefix'] as String? ?? '',
      voucherNo:
          (h?['voucher_no'] as String?) ??
          (json['Voucher_No_Display'] as String? ?? ''),
      voucherDate: date,
      billingName: json['Billing_Name'] as String?,
      partyLedgerId: json['voucher_ledger_id'] as int?,
      godownId: json['godown_id'] as int?,
      total: _decimal(json['Total']),
      grossTotal: _decimal(json['Gross_Total']),
      discount: _decimal(json['Discount_in_Amount']),
      vat: _decimal(json['Vat_Amount']),
      narration: json['Narration'] as String?,
      lines: lines,
    );
  }

  static Map<String, dynamic> draftToPostJson(
    ItemQtyDraft draft, {
    required ItemQtyVoucherKind kind,
  }) {
    final map = <String, dynamic>{
      'voucher_prefix': draft.voucherPrefix,
      'voucher_date': _dateOnly(draft.voucherDate),
      'financial_year': draft.financialYear,
      kind.partyField.wireKey: draft.partyLedgerId,
      if (kind.requiresGodown) 'godown_id': draft.godownId,
      if (draft.billingName != null && draft.billingName!.isNotEmpty)
        'billing_name': draft.billingName,
      if (draft.narration != null && draft.narration!.isNotEmpty)
        'narration': draft.narration,
      if (kind.supportsCreditDays) 'credit_days': draft.creditDays,
      if (kind.supportsSource && draft.sourceVoucherId != null)
        'source_voucher_id': draft.sourceVoucherId,
      'lines': [
        for (final line in draft.lines.where((l) => l.isComplete))
          {
            'item_id': line.itemId,
            if (line.skuId != null) 'sku_id': line.skuId,
            if (line.batchId != null) 'batch_id': line.batchId,
            if (line.sourceLineId != null) 'source_line_id': line.sourceLineId,
            'quantity': double.tryParse(line.quantity.toString()) ?? 0,
            'price': double.tryParse(line.price.toString()) ?? 0,
            'discount_percent':
                double.tryParse(line.discountPercent.toString()) ?? 0,
            'tax_rate': double.tryParse(line.taxRate.toString()) ?? 0,
          },
      ],
    };
    return map;
  }

  static ItemQtyPostResult postResultFromJson(
    Map<String, dynamic> json, {
    required String idKey,
  }) {
    final id =
        json[idKey] as int? ?? json['id'] as int? ?? json['headerId'] as int?;
    if (id == null) {
      throw const FormatException('Expected post result id');
    }
    return ItemQtyPostResult(
      id: id,
      voucherNo: json['voucherNo'] as String? ?? '',
      total: _decimal(json['total']) ?? Decimal.zero,
    );
  }

  static ItemQtyLifecycleResult lifecycleFromJson(Map<String, dynamic> json) {
    return ItemQtyLifecycleResult(
      id: json['id'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      message: json['message'] as String?,
    );
  }

  static ItemQtySourceLite sourceFromJson(
    Map<String, dynamic> json, {
    required String type,
    required String mainNestKey,
  }) {
    final headers = json['voucher_headers'];
    Map<String, dynamic>? h;
    if (headers is Map<String, dynamic>) h = headers;

    final p = h?['voucher_prefix'] as String? ?? '';
    final n =
        (h?['voucher_no'] as String?) ??
        (json['Voucher_No_Display'] as String? ?? '');
    final displayNo = (p + n).isEmpty ? '#${json['id']}' : '$p$n';

    final lines = <ItemQtyLine>[];
    final rawDetails = json['details'];
    if (rawDetails is List) {
      for (final row in rawDetails) {
        if (row is! Map<String, dynamic>) continue;
        lines.add(
          ItemQtyLine(
            itemId: row['item_id'] as int?,
            skuId: row['voucher_sku_id'] as int?,
            sourceLineId: row['id'] as int?,
            quantity: _decimal(row['Quantity']) ?? Decimal.one,
            price: _decimal(row['Price']) ?? Decimal.zero,
            discountPercent: _decimal(row['Discount_Percent']) ?? Decimal.zero,
            taxRate: _decimal(row['Tax_Rate']) ?? Decimal.zero,
          ),
        );
      }
    }

    return ItemQtySourceLite(
      id: json['id'] as int,
      type: type,
      displayNo: displayNo,
      billingName: json['Billing_Name'] as String?,
      partyLedgerId: json['voucher_ledger_id'] as int?,
      godownId: json['godown_id'] as int?,
      lines: lines.isEmpty ? [ItemQtyLine()] : lines,
    );
  }
}
