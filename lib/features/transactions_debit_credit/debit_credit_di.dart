import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/vouchers/debit_credit/debit_credit_kind.dart';
import 'package:algo_erp_front/core/vouchers/debit_credit/debit_credit_repository.dart';

DebitCreditRepository createDebitCreditRepository(
  DioClient client,
  DebitCreditVoucherKind kind,
) {
  return DebitCreditRepository(client, kind);
}
