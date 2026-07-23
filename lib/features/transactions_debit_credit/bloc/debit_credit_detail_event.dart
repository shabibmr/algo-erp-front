import 'package:equatable/equatable.dart';

sealed class DebitCreditDetailEvent extends Equatable {
  const DebitCreditDetailEvent();

  @override
  List<Object?> get props => [];
}

final class DebitCreditDetailFetchRequested extends DebitCreditDetailEvent {
  const DebitCreditDetailFetchRequested(this.id);
  final int id;

  @override
  List<Object?> get props => [id];
}

final class DebitCreditDetailRefreshed extends DebitCreditDetailEvent {
  const DebitCreditDetailRefreshed();
}

final class DebitCreditDetailCancelled extends DebitCreditDetailEvent {
  const DebitCreditDetailCancelled();
}

final class DebitCreditDetailApproved extends DebitCreditDetailEvent {
  const DebitCreditDetailApproved();
}

final class DebitCreditDetailRejected extends DebitCreditDetailEvent {
  const DebitCreditDetailRejected(this.reason);
  final String reason;

  @override
  List<Object?> get props => [reason];
}
