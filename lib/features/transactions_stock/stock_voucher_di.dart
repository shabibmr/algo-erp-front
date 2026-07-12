import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/vouchers/stock/stock_voucher_kind.dart';
import 'package:algo_erp_front/core/vouchers/stock/stock_voucher_repository.dart';

StockVoucherRepository createStockVoucherRepository(
  DioClient client,
  StockVoucherKind kind,
) {
  return StockVoucherRepository(client, kind);
}
