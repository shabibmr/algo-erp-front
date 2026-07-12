import 'package:algo_erp_front/features/transactions_sales_invoice/presentation/sales_invoice_html_open_stub.dart'
    if (dart.library.html) 'package:algo_erp_front/features/transactions_sales_invoice/presentation/sales_invoice_html_open_web.dart'
    as impl;

/// Opens authenticated invoice HTML for browser print (web blob URL).
/// No-op on non-web platforms.
void openSalesInvoiceHtml(String htmlContent) =>
    impl.openSalesInvoiceHtml(htmlContent);
