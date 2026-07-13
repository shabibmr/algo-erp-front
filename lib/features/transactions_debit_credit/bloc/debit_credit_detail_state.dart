import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/vouchers/debit_credit/debit_credit_models.dart';
import 'package:algo_erp_front/core/widgets/chips/status_chip.dart';
import 'package:equatable/equatable.dart';

enum DebitCreditDetailStatus { initial, loading, success, failure }

final class DebitCreditDetailState extends Equatable {
  const DebitCreditDetailState({
    this.status = DebitCreditDetailStatus.initial,
    this.detail,
    this.isBusy = false,
    this.actionMessage,
    this.failure,
  });

  final DebitCreditDetailStatus status;
  final DebitCreditDetail? detail;
  final bool isBusy;
  final String? actionMessage;
  final Failure? failure;

  bool get isLoading => status == DebitCreditDetailStatus.loading;
  bool get isSuccess => status == DebitCreditDetailStatus.success;
  bool get isFailure => status == DebitCreditDetailStatus.failure;

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

  DebitCreditDetailState copyWith({
    DebitCreditDetailStatus? status,
    DebitCreditDetail? detail,
    bool? isBusy,
    String? Function()? actionMessage,
    Failure? Function()? failure,
  }) {
    return DebitCreditDetailState(
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
