import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/vouchers/item_qty/item_qty_models.dart';
import 'package:algo_erp_front/core/widgets/chips/status_chip.dart';
import 'package:equatable/equatable.dart';

enum ItemQtyDetailStatus { initial, loading, success, failure }

final class ItemQtyDetailState extends Equatable {
  const ItemQtyDetailState({
    this.status = ItemQtyDetailStatus.initial,
    this.detail,
    this.isBusy = false,
    this.actionMessage,
    this.failure,
  });

  final ItemQtyDetailStatus status;
  final ItemQtyDetail? detail;
  final bool isBusy;
  final String? actionMessage;
  final Failure? failure;

  bool get isLoading => status == ItemQtyDetailStatus.loading;
  bool get isSuccess => status == ItemQtyDetailStatus.success;
  bool get isFailure => status == ItemQtyDetailStatus.failure;

  EntityStatus get entityStatus {
    if (detail == null) return EntityStatus.draft;
    return switch (detail!.status) {
      'Draft' => EntityStatus.draft,
      'Approved' => EntityStatus.approved,
      'Posted' => EntityStatus.posted,
      'Cancelled' => EntityStatus.cancelled,
      'Rejected' => EntityStatus.rejected,
      _ => EntityStatus.draft,
    };
  }

  ItemQtyDetailState copyWith({
    ItemQtyDetailStatus? status,
    ItemQtyDetail? detail,
    bool? isBusy,
    String? Function()? actionMessage,
    Failure? Function()? failure,
  }) {
    return ItemQtyDetailState(
      status: status ?? this.status,
      detail: detail ?? this.detail,
      isBusy: isBusy ?? this.isBusy,
      actionMessage: actionMessage != null
          ? actionMessage()
          : this.actionMessage,
      failure: failure != null ? failure() : this.failure,
    );
  }

  @override
  List<Object?> get props => [status, detail, isBusy, actionMessage, failure];
}
