import 'package:equatable/equatable.dart';

sealed class SalesInvoiceDetailEvent extends Equatable {
  const SalesInvoiceDetailEvent();

  @override
  List<Object?> get props => [];
}

final class SalesInvoiceDetailFetchRequested extends SalesInvoiceDetailEvent {
  const SalesInvoiceDetailFetchRequested(this.id);
  final int id;

  @override
  List<Object?> get props => [id];
}

final class SalesInvoiceDetailRefreshed extends SalesInvoiceDetailEvent {
  const SalesInvoiceDetailRefreshed();
}

final class SalesInvoiceDetailApproved extends SalesInvoiceDetailEvent {
  const SalesInvoiceDetailApproved();
}

final class SalesInvoiceDetailRejected extends SalesInvoiceDetailEvent {
  const SalesInvoiceDetailRejected(this.reason);
  final String reason;

  @override
  List<Object?> get props => [reason];
}

final class SalesInvoiceDetailCancelled extends SalesInvoiceDetailEvent {
  const SalesInvoiceDetailCancelled();
}

final class SalesInvoiceDetailPostAndBooked extends SalesInvoiceDetailEvent {
  const SalesInvoiceDetailPostAndBooked();
}
