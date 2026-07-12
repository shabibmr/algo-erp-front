import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/data/sales_invoice_repository.dart';

SalesInvoiceRepository createSalesInvoiceRepository(DioClient client) {
  return SalesInvoiceRepository(client);
}
