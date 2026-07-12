import 'package:algo_erp_front/core/vouchers/voucher_blueprint.dart';
import 'package:flutter/foundation.dart';

/// Configuration for Payment / Receipt (cash-bank + ledger amount lines).
@immutable
class LedgerAmountVoucherKind {
  const LedgerAmountVoucherKind({
    required this.blueprint,
    required this.lifecycleType,
    required this.mainNestKey,
    required this.createLabel,
  });

  final VoucherBlueprint blueprint;
  final String lifecycleType;
  final String mainNestKey;
  final String createLabel;

  String get listRoute => blueprint.listPath;
  String detailRoute(Object id) => blueprint.detailPath(id);
  String get newRoute => '${blueprint.listPath}/new';
}

abstract final class LedgerAmountKinds {
  static const payment = LedgerAmountVoucherKind(
    blueprint: VoucherBlueprints.payment,
    lifecycleType: 'PaymentVoucher',
    mainNestKey: 'payment_voucher_main',
    createLabel: 'Post payment',
  );

  static const receipt = LedgerAmountVoucherKind(
    blueprint: VoucherBlueprints.receipt,
    lifecycleType: 'ReceiptVoucher',
    mainNestKey: 'receipt_voucher_main',
    createLabel: 'Post receipt',
  );

  static const all = <LedgerAmountVoucherKind>[payment, receipt];
}
