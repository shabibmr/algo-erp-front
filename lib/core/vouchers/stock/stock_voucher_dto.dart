import 'package:algo_erp_front/core/vouchers/stock/stock_voucher_kind.dart';
import 'package:algo_erp_front/core/vouchers/stock/stock_voucher_models.dart';
import 'package:decimal/decimal.dart';

/// Wire helpers for stock vouchers (GT / MaterialIn / Requirement / SR).
abstract final class StockVoucherDto {
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

  static StockVoucherListItem listItemFromJson(
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

    return StockVoucherListItem(
      id: json['id'] as int,
      voucherPrefix: json['voucher_prefix'] as String? ?? '',
      voucherNo: json['voucher_no'] as String? ?? '',
      voucherDate: date,
      status: mainMap?['VoucherStatus'] as String?,
      total: _decimal(mainMap?['Total'] ?? mainMap?['Gross_Total']),
      billingName: mainMap?['Billing_Name'] as String?,
      narration: mainMap?['Narration'] as String?,
    );
  }

  static StockVoucherDetail detailFromJson(Map<String, dynamic> json) {
    final headers = json['voucher_headers'];
    Map<String, dynamic>? h;
    if (headers is Map<String, dynamic>) h = headers;

    DateTime? date;
    final dateRaw =
        h?['voucher_date'] ?? json['Date_Created'] ?? json['Time_Stamp'];
    if (dateRaw is String && dateRaw.isNotEmpty) {
      date = DateTime.tryParse(dateRaw);
    }

    final lines = <StockVoucherDetailLine>[];
    final rawDetails = json['details'];
    if (rawDetails is List) {
      for (final row in rawDetails) {
        if (row is! Map<String, dynamic>) continue;
        lines.add(
          StockVoucherDetailLine(
            id: row['id'] as int? ?? 0,
            itemId: row['item_id'] as int? ?? row['inventory_item_id'] as int?,
            quantity: _decimal(row['Quantity'] ?? row['Request_Qty']),
            price: _decimal(row['Price']),
            subtotal: _decimal(row['Subtotal']),
            crQty: _decimal(row['crQty']),
            drQty: _decimal(row['drQty']),
            requestQty: _decimal(row['Request_Qty']),
            issueQty: _decimal(row['Issue_qty'] ?? row['Issue_Qty']),
            narration:
                row['Item_Narration'] as String? ?? row['remarks'] as String?,
          ),
        );
      }
    }

    return StockVoucherDetail(
      id: json['id'] as int,
      status: json['VoucherStatus'] as String? ?? 'Posted',
      voucherPrefix: h?['voucher_prefix'] as String? ?? '',
      voucherNo:
          (h?['voucher_no'] as String?) ??
          (json['Voucher_No_Display'] as String? ?? ''),
      voucherDate: date,
      fromGodownId: json['from_godown_id'] as int?,
      toGodownId: json['to_godown_id'] as int?,
      godownId: json['godown_id'] as int?,
      total: _decimal(json['Total'] ?? json['Gross_Total']),
      billingName: json['Billing_Name'] as String?,
      narration: json['Narration'] as String?,
      requirementVoucherNo: json['Requirement_Voucher_No'] as String?,
      lines: lines,
    );
  }

  static Map<String, dynamic> draftToPostJson(
    StockVoucherDraft draft, {
    required StockVoucherKind kind,
  }) {
    final map = <String, dynamic>{
      'voucher_prefix': draft.voucherPrefix,
      'voucher_date': _dateOnly(draft.voucherDate),
      'financial_year': draft.financialYear,
      if (draft.narration != null && draft.narration!.isNotEmpty)
        'narration': draft.narration,
    };

    switch (kind.headerMode) {
      case StockHeaderMode.fromToGodown:
        map['from_godown_id'] = draft.fromGodownId;
        map['to_godown_id'] = draft.toGodownId;
      case StockHeaderMode.optionalGodown:
        if (draft.godownId != null) map['godown_id'] = draft.godownId;
      case StockHeaderMode.none:
        break;
    }

    if (kind.supportsRequirementRef &&
        draft.requirementVoucherNo != null &&
        draft.requirementVoucherNo!.isNotEmpty) {
      map['requirement_voucher_no'] = draft.requirementVoucherNo;
    }

    final lines = <Map<String, dynamic>>[];
    for (final line in draft.lines) {
      switch (kind.lineMode) {
        case StockLineMode.itemQtyPrice:
          if (!line.isCompleteQtyPrice()) continue;
          lines.add({
            'item_id': line.itemId,
            if (line.skuId != null) 'sku_id': line.skuId,
            'quantity': double.tryParse(line.quantity.toString()) ?? 0,
            'price': double.tryParse(line.price.toString()) ?? 0,
            if (kind.supportsAdjValue)
              'adj_value': double.tryParse(line.adjValue.toString()) ?? 0,
            if (line.narration != null && line.narration!.isNotEmpty)
              'narration': line.narration,
          });
        case StockLineMode.itemCrDr:
          if (!line.isCompleteCrDr()) continue;
          lines.add({
            'item_id': line.itemId,
            if (line.skuId != null) 'sku_id': line.skuId,
            'crQty': double.tryParse(line.crQty.toString()) ?? 0,
            'drQty': double.tryParse(line.drQty.toString()) ?? 0,
            'Price': double.tryParse(line.price.toString()) ?? 0,
            if (line.narration != null && line.narration!.isNotEmpty)
              'Item_Narration': line.narration,
          });
        case StockLineMode.itemRequestQty:
          if (!line.isCompleteRequest()) continue;
          lines.add({
            'inventory_item_id': line.itemId,
            'request_qty': double.tryParse(line.requestQty.toString()) ?? 0,
            if (line.narration != null && line.narration!.isNotEmpty)
              'remarks': line.narration,
          });
      }
    }
    map['lines'] = lines;
    return map;
  }

  static StockVoucherPostResult postResultFromJson(
    Map<String, dynamic> json, {
    required String idKey,
  }) {
    final id =
        json[idKey] as int? ?? json['id'] as int? ?? json['headerId'] as int?;
    if (id == null) {
      throw const FormatException('Expected stock voucher post id');
    }
    return StockVoucherPostResult(
      id: id,
      voucherNo: json['voucherNo'] as String? ?? '',
      total: _decimal(json['total']),
    );
  }

  static StockVoucherLifecycleResult lifecycleFromJson(
    Map<String, dynamic> json,
  ) {
    return StockVoucherLifecycleResult(
      id: json['id'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      message: json['message'] as String?,
    );
  }
}
