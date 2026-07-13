import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/vouchers/ledger_amount/ledger_amount_models.dart';
import 'package:algo_erp_front/core/widgets/chips/status_chip.dart';
import 'package:equatable/equatable.dart';

enum LedgerAmountDetailStatus { initial, loading, success, failure }

final class LedgerAmountDetailState extends Equatable {
  const LedgerAmountDetailState({
    this.status = LedgerAmountDetailStatus.initial,
    this.detail,
    this.isBusy = false,
    this.actionMessage,
    this.failure,
  });

  final LedgerAmountDetailStatus status;
  final LedgerAmountDetail? detail;
  final bool isBusy;
  final String? actionMessage;
  final Failure? failure;

  bool get isLoading => status == LedgerAmountDetailStatus.loading;
  bool get isSuccess => status == LedgerAmountDetailStatus.success;
  bool get isFailure => status == LedgerAmountDetailStatus.failure;

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

  LedgerAmountDetailState copyWith({
    LedgerAmountDetailStatus? status,
    LedgerAmountDetail? detail,
    bool? isBusy,
    String? Function()? actionMessage,
    Failure? Function()? failure,
  }) {
    return LedgerAmountDetailState(
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
