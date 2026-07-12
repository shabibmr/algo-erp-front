import 'package:algo_erp_front/features/transactions_sales_invoice/data/sales_invoice_dto.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/domain/sales_invoice.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('listItemFromJson reads nested sales_invoice_main', () {
    final item = SalesInvoiceDto.listItemFromJson({
      'id': 9,
      'voucher_prefix': 'SI',
      'voucher_no': '00012',
      'voucher_date': '2025-06-01',
      'sales_invoice_main': {
        'VoucherStatus': 'Posted',
        'Total': 123.5,
        'Billing_Name': 'Acme',
      },
    });
    expect(item.id, 9);
    expect(item.voucherPrefix, 'SI');
    expect(item.voucherNo, '00012');
    expect(item.status, 'Posted');
    expect(item.total, Decimal.parse('123.5'));
    expect(item.billingName, 'Acme');
  });

  test('draftToPostJson omits incomplete lines and formats date', () {
    final draft = SalesInvoiceDraft(
      voucherPrefix: 'SI',
      voucherDate: DateTime(2025, 4, 1),
      financialYear: '2025',
      customerLedgerId: 3,
      godownId: 1,
      creditDays: 15,
      saveStatus: 'Draft',
      lines: [
        SalesInvoiceLine(
          itemId: 10,
          quantity: Decimal.parse('2'),
          price: Decimal.parse('50'),
          discountPercent: Decimal.parse('10'),
          taxRate: Decimal.parse('5'),
        ),
        SalesInvoiceLine(), // incomplete — skipped
      ],
    );
    final json = SalesInvoiceDto.draftToPostJson(draft);
    expect(json['voucher_date'], '2025-04-01');
    expect(json['customer_ledger_id'], 3);
    expect(json['godown_id'], 1);
    expect(json['status'], 'Draft');
    expect(json['lines'], hasLength(1));
    expect(json['lines'][0]['item_id'], 10);
    expect(json['lines'][0]['quantity'], 2);
    expect(json['lines'][0]['discount_percent'], 10);
  });

  test('detailFromJson reads main + headers + details', () {
    final detail = SalesInvoiceDto.detailFromJson({
      'id': 42,
      'VoucherStatus': 'Posted',
      'Billing_Name': 'Acme LLC',
      'voucher_ledger_id': 7,
      'godown_id': 2,
      'Total': 100,
      'Gross_Total': 105,
      'Discount_in_Amount': 0,
      'Vat_Amount': 5,
      'Voucher_No_Display': 'SI/00042',
      'voucher_headers': {
        'voucher_prefix': 'SI',
        'voucher_no': '00042',
        'voucher_date': '2025-06-15',
      },
      'details': [
        {
          'id': 1,
          'item_id': 9,
          'Quantity': 2,
          'Price': 50,
          'Discount_Percent': 0,
          'Discount_Amount': 0,
          'Subtotal': 100,
          'Tax_Rate': 5,
          'Tax_Amount': 5,
        },
      ],
    });
    expect(detail.id, 42);
    expect(detail.status, 'Posted');
    expect(detail.canCancel, isTrue);
    expect(detail.canApprove, isFalse);
    expect(detail.voucherPrefix, 'SI');
    expect(detail.lines, hasLength(1));
    expect(detail.lines.first.itemId, 9);
    expect(detail.vat, Decimal.parse('5'));
  });

  test('draftToEditJson builds header and computed lines', () {
    final draft = SalesInvoiceDraft(
      customerLedgerId: 3,
      godownId: 1,
      billingName: 'Acme',
      lines: [
        SalesInvoiceLine(
          itemId: 10,
          quantity: Decimal.parse('2'),
          price: Decimal.parse('50'),
          discountPercent: Decimal.parse('10'),
          taxRate: Decimal.parse('5'),
        ),
      ],
    );
    final json = SalesInvoiceDto.draftToEditJson(draft);
    expect(json['header']['voucher_ledger_id'], 3);
    expect(json['header']['godown_id'], 1);
    expect(json['lines'], hasLength(1));
    expect(json['lines'][0]['item_id'], 10);
    expect(json['lines'][0]['Quantity'], 2);
    // subtotal 100, disc 10, tax on 90 @5% = 4.5
    expect(json['lines'][0]['Discount_Amount'], 10);
    expect(json['lines'][0]['Tax_Amount'], 4.5);
  });

  test('lifecycleFromJson maps status message and booked', () {
    final r = SalesInvoiceDto.lifecycleFromJson({
      'id': 1,
      'status': 'Posted',
      'message': 'Voucher posted and booked (Posted)',
      'booked': true,
    });
    expect(r.status, 'Posted');
    expect(r.message, contains('booked'));
    expect(r.booked, isTrue);
  });

  test('postResultFromJson maps response keys', () {
    final r = SalesInvoiceDto.postResultFromJson({
      'id': 1,
      'voucherNo': 'SI/00001',
      'total': 100,
      'subtotal': 95,
      'discount': 0,
      'vat': 5,
    });
    expect(r.voucherNo, 'SI/00001');
    expect(r.total, Decimal.parse('100'));
    expect(r.vat, Decimal.parse('5'));
  });

  test('draftToPostJson includes salesperson, project, source, batch', () {
    final draft = SalesInvoiceDraft(
      voucherPrefix: 'SI',
      voucherDate: DateTime(2025, 4, 1),
      financialYear: '2025',
      customerLedgerId: 3,
      godownId: 1,
      salespersonEmployeeId: 8,
      voucherProjectId: 4,
      sourceVoucherId: 99,
      sourceVoucherType: 'SalesOrder',
      saveStatus: 'Draft',
      lines: [
        SalesInvoiceLine(
          itemId: 10,
          skuId: 2,
          batchId: 5,
          quantity: Decimal.parse('1'),
          price: Decimal.parse('10'),
        ),
      ],
    );
    final json = SalesInvoiceDto.draftToPostJson(draft);
    expect(json['salesperson_employee_id'], 8);
    expect(json['voucher_project_id'], 4);
    expect(json['source_voucher_id'], 99);
    expect(json['source_voucher_type'], 'SalesOrder');
    expect(json['lines'][0]['batch_id'], 5);
    expect(json['lines'][0]['sku_id'], 2);
  });

  test('sourceFromJson maps quotation/SO lines', () {
    final src = SalesInvoiceDto.sourceFromJson({
      'id': 12,
      'Billing_Name': 'Acme',
      'voucher_ledger_id': 3,
      'godown_id': 1,
      'voucher_headers': {'voucher_prefix': 'SO', 'voucher_no': '0001'},
      'details': [
        {
          'item_id': 9,
          'voucher_sku_id': 2,
          'Quantity': 3,
          'Price': 20,
          'Discount_Percent': 0,
          'Tax_Rate': 5,
        },
      ],
    }, type: 'SalesOrder');
    expect(src.id, 12);
    expect(src.type, 'SalesOrder');
    expect(src.displayNo, 'SO0001');
    expect(src.customerLedgerId, 3);
    expect(src.lines, hasLength(1));
    expect(src.lines.first.itemId, 9);
    expect(src.lines.first.quantity, Decimal.parse('3'));
  });

  test('detailFromJson reads salesperson and project ids', () {
    final detail = SalesInvoiceDto.detailFromJson({
      'id': 1,
      'VoucherStatus': 'Draft',
      'salesperson_employee_id': 8,
      'voucher_project_id': 4,
      'voucher_headers': {'voucher_prefix': 'SI', 'voucher_no': '1'},
      'details': const [],
    });
    expect(detail.salespersonEmployeeId, 8);
    expect(detail.voucherProjectId, 4);
    expect(detail.canApprove, isTrue);
  });
}
