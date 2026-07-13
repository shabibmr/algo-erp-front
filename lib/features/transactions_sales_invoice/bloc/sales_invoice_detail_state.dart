import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/widgets/chips/status_chip.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/domain/sales_invoice.dart';
import 'package:equatable/equatable.dart';

enum SalesInvoiceDetailStatus { initial, loading, success, failure }

final class SalesInvoiceDetailState extends Equatable {
  const SalesInvoiceDetailState({
    this.status = SalesInvoiceDetailStatus.initial,
    this.detail,
    this.seriesRequiresApproval,
    this.isBusy = false,
    this.actionMessage,
    this.failure,
    this.postedInvoiceId,
  });

  final SalesInvoiceDetailStatus status;
  final SalesInvoiceDetail? detail;
  final bool? seriesRequiresApproval;
  final bool isBusy;
  final String? actionMessage;
  final Failure? failure;
  final int? postedInvoiceId;

  bool get isLoading => status == SalesInvoiceDetailStatus.loading;
  bool get isSuccess => status == SalesInvoiceDetailStatus.success;
  bool get isFailure => status == SalesInvoiceDetailStatus.failure;

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

  SalesInvoiceDetailState copyWith({
    SalesInvoiceDetailStatus? status,
    SalesInvoiceDetail? detail,
    bool? Function()? seriesRequiresApproval,
    bool? isBusy,
    String? Function()? actionMessage,
    Failure? Function()? failure,
    int? Function()? postedInvoiceId,
  }) {
    return SalesInvoiceDetailState(
      status: status ?? this.status,
      detail: detail ?? this.detail,
      seriesRequiresApproval: seriesRequiresApproval != null
          ? seriesRequiresApproval()
          : this.seriesRequiresApproval,
      isBusy: isBusy ?? this.isBusy,
      actionMessage: actionMessage != null
          ? actionMessage()
          : this.actionMessage,
      failure: failure != null ? failure() : this.failure,
      postedInvoiceId: postedInvoiceId != null
          ? postedInvoiceId()
          : this.postedInvoiceId,
    );
  }

  @override
  List<Object?> get props => [
    status,
    detail,
    seriesRequiresApproval,
    isBusy,
    actionMessage,
    failure,
    postedInvoiceId,
  ];
}
