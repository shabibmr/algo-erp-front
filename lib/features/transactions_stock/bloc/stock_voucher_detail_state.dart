import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/vouchers/stock/stock_voucher_models.dart';
import 'package:algo_erp_front/core/widgets/chips/status_chip.dart';
import 'package:equatable/equatable.dart';

enum StockVoucherDetailStatus { initial, loading, success, failure }

final class StockVoucherDetailState extends Equatable {
  const StockVoucherDetailState({
    this.status = StockVoucherDetailStatus.initial,
    this.detail,
    this.isBusy = false,
    this.actionMessage,
    this.failure,
  });

  final StockVoucherDetailStatus status;
  final StockVoucherDetail? detail;
  final bool isBusy;
  final String? actionMessage;
  final Failure? failure;

  bool get isLoading => status == StockVoucherDetailStatus.loading;
  bool get isSuccess => status == StockVoucherDetailStatus.success;
  bool get isFailure => status == StockVoucherDetailStatus.failure;

  EntityStatus get entityStatus {
    if (detail == null) return EntityStatus.posted;
    return switch (detail!.status) {
      'Draft' => EntityStatus.draft,
      'Approved' => EntityStatus.approved,
      'Posted' => EntityStatus.posted,
      'Cancelled' => EntityStatus.cancelled,
      'Rejected' => EntityStatus.rejected,
      _ => EntityStatus.posted,
    };
  }

  StockVoucherDetailState copyWith({
    StockVoucherDetailStatus? status,
    StockVoucherDetail? detail,
    bool? isBusy,
    String? Function()? actionMessage,
    Failure? Function()? failure,
  }) {
    return StockVoucherDetailState(
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
