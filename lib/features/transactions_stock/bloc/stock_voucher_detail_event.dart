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
