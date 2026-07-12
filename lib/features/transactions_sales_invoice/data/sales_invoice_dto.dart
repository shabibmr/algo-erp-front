import 'package:algo_erp_front/core/domain/line_engine/line_engine.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/domain/sales_invoice.dart';
import 'package:decimal/decimal.dart';

/// Wire helpers for sales invoice list, detail, post, and lifecycle.
abstract final class SalesInvoiceDto {
  static Decimal? _decimal(dynamic v) {
    if (v == null) return null;
    return Decimal.tryParse(v.toString());
  }

  static SalesInvoiceListItem listItemFromJson(Map<String, dynamic> json) {
    final main = json['sales_invoice_main'];
    Map<String, dynamic>? mainMap;
    if (main is Map<String, dynamic>) mainMap = main;

    final dateRaw = json['voucher_date'];
    DateTime? date;
    if (dateRaw is String && dateRaw.isNotEmpty) {
      date = DateTime.tryParse(dateRaw);
    }

    return SalesInvoiceListItem(
      id: json['id'] as int,
      voucherPrefix: json['voucher_prefix'] as String? ?? '',
      voucherNo: json['voucher_no'] as String? ?? '',
      voucherDate: date,
      status: mainMap?['VoucherStatus'] as String?,
      total: _decimal(mainMap?['Total'] ?? mainMap?['Gross_Total']),
      billingName: mainMap?['Billing_Name'] as String?,
    );
  }

  /// GET detail: main row + nested `voucher_headers` + `details`.
  static SalesInvoiceDetail detailFromJson(Map<String, dynamic> json) {
    final headers = json['voucher_headers'];
    Map<String, dynamic>? h;
    if (headers is Map<String, dynamic>) h = headers;

    DateTime? date;
    final dateRaw = h?['voucher_date'] ?? json['Date_Created'];
    if (dateRaw is String && dateRaw.isNotEmpty) {
      date = DateTime.tryParse(dateRaw);
    }

    final rawDetails = json['details'];
    final lines = <SalesInvoiceDetailLine>[];
    if (rawDetails is List) {
      for (final row in rawDetails) {
        if (row is! Map<String, dynamic>) continue;
        lines.add(
          SalesInvoiceDetailLine(
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

    return SalesInvoiceDetail(
      id: json['id'] as int,
      status: json['VoucherStatus'] as String? ?? 'Draft',
      voucherPrefix: h?['voucher_prefix'] as String? ?? '',
      voucherNo:
          (h?['voucher_no'] as String?) ??
          (json['Voucher_No_Display'] as String? ?? ''),
      voucherDate: date,
      billingName: json['Billing_Name'] as String?,
      customerLedgerId: json['voucher_ledger_id'] as int?,
      godownId: json['godown_id'] as int?,
      total: _decimal(json['Total']),
      grossTotal: _decimal(json['Gross_Total']),
      discount: _decimal(json['Discount_in_Amount']),
      vat: _decimal(json['Vat_Amount']),
      rejectionReason: json['Quotation_Dropped_Reason'] as String?,
      narration: json['Narration'] as String?,
      salespersonEmployeeId: json['salesperson_employee_id'] as int?,
      voucherProjectId: json['voucher_project_id'] as int?,
      lines: lines,
    );
  }

  static Map<String, dynamic> draftToPostJson(SalesInvoiceDraft draft) {
    String dateOnly(DateTime d) {
      final y = d.year.toString().padLeft(4, '0');
      final m = d.month.toString().padLeft(2, '0');
      final day = d.day.toString().padLeft(2, '0');
      return '$y-$m-$day';
    }

    return {
      'voucher_prefix': draft.voucherPrefix,
      'voucher_date': dateOnly(draft.voucherDate),
      'financial_year': draft.financialYear,
      'customer_ledger_id': draft.customerLedgerId,
      'godown_id': draft.godownId,
      if (draft.salespersonEmployeeId != null)
        'salesperson_employee_id': draft.salespersonEmployeeId,
      if (draft.voucherProjectId != null)
        'voucher_project_id': draft.voucherProjectId,
      if (draft.billingName != null && draft.billingName!.isNotEmpty)
        'billing_name': draft.billingName,
      if (draft.narration != null && draft.narration!.isNotEmpty)
        'narration': draft.narration,
      'credit_days': draft.creditDays,
      'status': draft.saveStatus,
      if (draft.sourceVoucherId != null)
        'source_voucher_id': draft.sourceVoucherId,
      if (draft.sourceVoucherType != null)
        'source_voucher_type': draft.sourceVoucherType,
      'lines': [
        for (final line in draft.lines.where((l) => l.isComplete))
          {
            'item_id': line.itemId,
            if (line.skuId != null) 'sku_id': line.skuId,
            if (line.batchId != null) 'batch_id': line.batchId,
            'quantity': double.tryParse(line.quantity.toString()) ?? 0,
            'price': double.tryParse(line.price.toString()) ?? 0,
            'discount_percent':
                double.tryParse(line.discountPercent.toString()) ?? 0,
            'tax_rate': double.tryParse(line.taxRate.toString()) ?? 0,
          },
      ],
    };
  }

  static SalesInvoicePostResult postResultFromJson(Map<String, dynamic> json) {
    Decimal d(dynamic v) =>
        Decimal.tryParse(v?.toString() ?? '0') ?? Decimal.zero;
    return SalesInvoicePostResult(
      id: json['id'] as int,
      voucherNo: json['voucherNo'] as String? ?? '',
      total: d(json['total']),
      subtotal: d(json['subtotal']),
      discount: d(json['discount']),
      vat: d(json['vat']),
    );
  }

  static VoucherLifecycleResult lifecycleFromJson(Map<String, dynamic> json) {
    return VoucherLifecycleResult(
      id: json['id'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      message: json['message'] as String?,
      reason: json['reason'] as String?,
      booked: json['booked'] as bool?,
    );
  }

  /// Body for `PUT /transactions/SalesInvoice/:id` (Draft only).
  static Map<String, dynamic> draftToEditJson(SalesInvoiceDraft draft) {
    final lines = <Map<String, dynamic>>[];
    var discountSum = Decimal.zero;
    var taxSum = Decimal.zero;
    var subtotalSum = Decimal.zero;

    for (final line in draft.lines.where((l) => l.isComplete)) {
      final computed = LineEngine.computeLine(
        LineInput(
          quantity: line.quantity,
          price: line.price,
          discountPercent: line.discountPercent,
          taxRate: line.taxRate,
        ),
      );
      subtotalSum += computed.subtotal;
      discountSum += computed.discountAmount;
      taxSum += computed.taxAmount;
      lines.add({
        'item_id': line.itemId,
        if (line.skuId != null) 'voucher_sku_id': line.skuId,
        'Quantity': double.tryParse(line.quantity.toString()) ?? 0,
        'Price': double.tryParse(line.price.toString()) ?? 0,
        'Discount_Percent':
            double.tryParse(line.discountPercent.toString()) ?? 0,
        'Discount_Amount':
            double.tryParse(computed.discountAmount.toString()) ?? 0,
        'Subtotal': double.tryParse(computed.subtotal.toString()) ?? 0,
        'Tax_Rate': double.tryParse(line.taxRate.toString()) ?? 0,
        'Tax_Amount': double.tryParse(computed.taxAmount.toString()) ?? 0,
      });
    }

    final gross = LineEngine.roundMoney(subtotalSum - discountSum + taxSum);

    return {
      'header': {
        'godown_id': draft.godownId,
        'voucher_ledger_id': draft.customerLedgerId,
        if (draft.salespersonEmployeeId != null)
          'salesperson_employee_id': draft.salespersonEmployeeId,
        if (draft.voucherProjectId != null)
          'voucher_project_id': draft.voucherProjectId,
        if (draft.billingName != null) 'Billing_Name': draft.billingName,
        if (draft.narration != null) 'Narration': draft.narration,
        'Total': double.tryParse(gross.toString()) ?? 0,
        'Gross_Total': double.tryParse(gross.toString()) ?? 0,
        'Discount_in_Amount': double.tryParse(discountSum.toString()) ?? 0,
        'Vat_Amount': double.tryParse(taxSum.toString()) ?? 0,
      },
      'lines': lines,
    };
  }

  static EmployeeLite employeeFromJson(Map<String, dynamic> json) =>
      EmployeeLite(
        id: json['id'] as int,
        name: json['Name'] as String? ?? '',
        code: json['employee_code'] as String?,
      );

  static ProjectLite projectFromJson(Map<String, dynamic> json) => ProjectLite(
    id: json['id'] as int,
    name:
        json['Project_Name'] as String? ??
        json['project_name'] as String? ??
        '',
    code: json['project_code'] as String? ?? json['PROJECT_ID'] as String?,
  );

  /// Parse Quotation or Sales Order detail into a conversion source.
  static SourceVoucherLite sourceFromJson(
    Map<String, dynamic> json, {
    required String type,
  }) {
    final headers = json['voucher_headers'];
    Map<String, dynamic>? h;
    if (headers is Map<String, dynamic>) h = headers;
    final prefix = h?['voucher_prefix'] as String? ?? '';
    final no = h?['voucher_no'] as String? ?? '';
    final display = (prefix + no).isEmpty ? '#${json['id']}' : '$prefix$no';

    final rawDetails = json['details'];
    final lines = <SalesInvoiceLine>[];
    if (rawDetails is List) {
      for (final row in rawDetails) {
        if (row is! Map<String, dynamic>) continue;
        lines.add(
          SalesInvoiceLine(
            itemId: row['item_id'] as int?,
            skuId: row['voucher_sku_id'] as int? ?? row['sku_id'] as int?,
            quantity:
                _decimal(row['Quantity'] ?? row['quantity']) ?? Decimal.one,
            price: _decimal(row['Price'] ?? row['price']) ?? Decimal.zero,
            discountPercent:
                _decimal(row['Discount_Percent'] ?? row['discount_percent']) ??
                Decimal.zero,
            taxRate:
                _decimal(row['Tax_Rate'] ?? row['tax_rate']) ?? Decimal.zero,
          ),
        );
      }
    }

    return SourceVoucherLite(
      id: json['id'] as int,
      type: type,
      displayNo: display,
      billingName: json['Billing_Name'] as String?,
      customerLedgerId:
          json['voucher_ledger_id'] as int? ??
          json['customer_ledger_id'] as int?,
      godownId: json['godown_id'] as int?,
      lines: lines.isEmpty ? [SalesInvoiceLine()] : lines,
    );
  }

  /// Map a detail document into a create/edit draft for the form.
  static SalesInvoiceDraft detailToDraft(
    SalesInvoiceDetail detail, {
    String saveStatus = 'Draft',
  }) {
    return SalesInvoiceDraft(
      voucherPrefix: detail.voucherPrefix.isEmpty ? 'SI' : detail.voucherPrefix,
      voucherDate: detail.voucherDate ?? DateTime.now(),
      financialYear: (detail.voucherDate?.year ?? DateTime.now().year)
          .toString(),
      customerLedgerId: detail.customerLedgerId,
      customerLabel: detail.customerLabel ?? detail.billingName,
      godownId: detail.godownId,
      godownLabel: detail.godownLabel,
      salespersonEmployeeId: detail.salespersonEmployeeId,
      salespersonLabel: detail.salespersonLabel,
      voucherProjectId: detail.voucherProjectId,
      projectLabel: detail.projectLabel,
      billingName: detail.billingName,
      narration: detail.narration,
      saveStatus: saveStatus,
      lines: [
        for (final line in detail.lines)
          SalesInvoiceLine(
            itemId: line.itemId,
            itemLabel: line.itemLabel,
            quantity: line.quantity ?? Decimal.one,
            price: line.price ?? Decimal.zero,
            discountPercent: line.discountPercent ?? Decimal.zero,
            taxRate: line.taxRate ?? Decimal.zero,
          ),
        if (detail.lines.isEmpty) SalesInvoiceLine(),
      ],
    );
  }
}
