import 'package:algo_erp_front/core/vouchers/voucher_blueprint.dart';
import 'package:flutter/foundation.dart';

/// Header godown shape for stock vouchers.
enum StockHeaderMode {
  /// Godown transfer / stock request.
  fromToGodown,

  /// Optional single godown (material in).
  optionalGodown,

  /// No godown (requirement).
  none,
}

/// Line wire/UI shape.
enum StockLineMode {
  /// item + qty + price (+ optional adj_value).
  itemQtyPrice,

  /// item + crQty + drQty + Price.
  itemCrDr,

  /// inventory_item_id + request_qty.
  itemRequestQty,
}

@immutable
class StockVoucherKind {
  const StockVoucherKind({
    required this.blueprint,
    required this.lifecycleType,
    required this.mainNestKey,
    required this.headerMode,
    required this.lineMode,
    required this.createLabel,
    this.supportsAdjValue = false,
    this.supportsRequirementRef = false,
    this.postIdKey = 'headerId',
  });

  final VoucherBlueprint blueprint;
  final String lifecycleType;
  final String mainNestKey;
  final StockHeaderMode headerMode;
  final StockLineMode lineMode;
  final String createLabel;
  final bool supportsAdjValue;
  final bool supportsRequirementRef;
  final String postIdKey;

  String get listRoute => blueprint.listPath;
  String detailRoute(Object id) => blueprint.detailPath(id);
  String get newRoute => '${blueprint.listPath}/new';
}

abstract final class StockVoucherKinds {
  static const godownTransfer = StockVoucherKind(
    blueprint: VoucherBlueprints.godownTransfer,
    lifecycleType: 'GodownTransfer',
    // Backend table typo is intentional: godown_tranfer_main
    mainNestKey: 'godown_tranfer_main',
    headerMode: StockHeaderMode.fromToGodown,
    lineMode: StockLineMode.itemQtyPrice,
    createLabel: 'Post transfer',
    supportsAdjValue: true,
  );

  static const materialIn = StockVoucherKind(
    blueprint: VoucherBlueprints.materialIn,
    lifecycleType: 'MaterialIn',
    mainNestKey: 'material_in_main',
    headerMode: StockHeaderMode.optionalGodown,
    lineMode: StockLineMode.itemCrDr,
    createLabel: 'Post material in',
  );

  static const requirement = StockVoucherKind(
    blueprint: VoucherBlueprints.requirement,
    lifecycleType: 'Requirement',
    mainNestKey: 'requirement_main',
    headerMode: StockHeaderMode.none,
    lineMode: StockLineMode.itemQtyPrice,
    createLabel: 'Create requirement',
  );

  static const stockRequest = StockVoucherKind(
    blueprint: VoucherBlueprints.stockRequest,
    lifecycleType: 'StockRequest',
    mainNestKey: 'stock_request_main',
    headerMode: StockHeaderMode.fromToGodown,
    lineMode: StockLineMode.itemRequestQty,
    createLabel: 'Create stock request',
    supportsRequirementRef: true,
  );

  static const all = <StockVoucherKind>[
    godownTransfer,
    materialIn,
    requirement,
    stockRequest,
  ];
}
