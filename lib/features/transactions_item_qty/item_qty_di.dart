import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/vouchers/item_qty/item_qty_kind.dart';
import 'package:algo_erp_front/core/vouchers/item_qty/item_qty_repository.dart';

ItemQtyRepository createItemQtyRepository(
  DioClient client,
  ItemQtyVoucherKind kind,
) {
  return ItemQtyRepository(client, kind);
}
