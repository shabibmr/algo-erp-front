import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

sealed class StockVoucherDetailEvent extends Equatable {
  const StockVoucherDetailEvent();

  @override
  List<Object?> get props => [];
}

final class StockVoucherDetailFetchRequested extends StockVoucherDetailEvent {
  const StockVoucherDetailFetchRequested(this.id);
  final int id;

  @override
  List<Object?> get props => [id];
}

final class StockVoucherDetailRefreshed extends StockVoucherDetailEvent {
  const StockVoucherDetailRefreshed();
}

final class StockVoucherDetailCancelled extends StockVoucherDetailEvent {
  const StockVoucherDetailCancelled();
}

final class StockVoucherDetailApproved extends StockVoucherDetailEvent {
  const StockVoucherDetailApproved();
}

final class StockVoucherDetailRejected extends StockVoucherDetailEvent {
  const StockVoucherDetailRejected(this.reason);
  final String reason;

  @override
  List<Object?> get props => [reason];
}

final class StockVoucherDetailFulfilled extends StockVoucherDetailEvent {
  const StockVoucherDetailFulfilled(this.issueQuantities);
  final List<({int lineId, Decimal issueQty})> issueQuantities;

  @override
  List<Object?> get props => [issueQuantities];
}
