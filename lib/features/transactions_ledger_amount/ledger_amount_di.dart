import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/vouchers/ledger_amount/ledger_amount_kind.dart';
import 'package:algo_erp_front/core/vouchers/ledger_amount/ledger_amount_repository.dart';

LedgerAmountRepository createLedgerAmountRepository(
  DioClient client,
  LedgerAmountVoucherKind kind,
) {
  return LedgerAmountRepository(client, kind);
}
