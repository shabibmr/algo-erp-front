import 'package:algo_erp_front/core/vouchers/voucher_blueprint.dart';
import 'package:flutter/foundation.dart';

/// How line amounts are edited and posted.
enum DebitCreditLineMode {
  /// Journal: `debit_amount` + `credit_amount` columns.
  dualAmount,

  /// Contra: `amount` + `type` (`DR`/`CR`).
  amountWithSide,
}

@immutable
class DebitCreditVoucherKind {
  const DebitCreditVoucherKind({
    required this.blueprint,
    required this.lifecycleType,
    required this.mainNestKey,
    required this.lineMode,
    required this.createLabel,
    this.minLines = 2,
  });

  final VoucherBlueprint blueprint;
  final String lifecycleType;
  final String mainNestKey;
  final DebitCreditLineMode lineMode;
  final String createLabel;
  final int minLines;

  String get listRoute => blueprint.listPath;
  String detailRoute(Object id) => blueprint.detailPath(id);
  String get newRoute => '${blueprint.listPath}/new';
}

abstract final class DebitCreditKinds {
  static const journal = DebitCreditVoucherKind(
    blueprint: VoucherBlueprints.journal,
    lifecycleType: 'JournalVoucher',
    mainNestKey: 'journal_voucher_main',
    lineMode: DebitCreditLineMode.dualAmount,
    createLabel: 'Post journal',
  );

  static const contra = DebitCreditVoucherKind(
    blueprint: VoucherBlueprints.contra,
    lifecycleType: 'ContraVoucher',
    mainNestKey: 'contra_voucher_main',
    lineMode: DebitCreditLineMode.amountWithSide,
    createLabel: 'Post contra',
  );

  static const all = <DebitCreditVoucherKind>[journal, contra];
}
