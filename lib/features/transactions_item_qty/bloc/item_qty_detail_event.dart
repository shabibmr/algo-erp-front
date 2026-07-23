import 'package:equatable/equatable.dart';

sealed class ItemQtyDetailEvent extends Equatable {
  const ItemQtyDetailEvent();

  @override
  List<Object?> get props => [];
}

final class ItemQtyDetailFetchRequested extends ItemQtyDetailEvent {
  const ItemQtyDetailFetchRequested(this.id);
  final int id;

  @override
  List<Object?> get props => [id];
}

final class ItemQtyDetailRefreshed extends ItemQtyDetailEvent {
  const ItemQtyDetailRefreshed();
}

final class ItemQtyDetailCancelled extends ItemQtyDetailEvent {
  const ItemQtyDetailCancelled();
}

final class ItemQtyDetailApproved extends ItemQtyDetailEvent {
  const ItemQtyDetailApproved();
}

final class ItemQtyDetailRejected extends ItemQtyDetailEvent {
  const ItemQtyDetailRejected(this.reason);
  final String reason;

  @override
  List<Object?> get props => [reason];
}
