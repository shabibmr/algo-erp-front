import 'package:equatable/equatable.dart';

sealed class LedgerAmountDetailEvent extends Equatable {
  const LedgerAmountDetailEvent();

  @override
  List<Object?> get props => [];
}

final class LedgerAmountDetailFetchRequested extends LedgerAmountDetailEvent {
  const LedgerAmountDetailFetchRequested(this.id);
  final int id;

  @override
  List<Object?> get props => [id];
}

final class LedgerAmountDetailRefreshed extends LedgerAmountDetailEvent {
  const LedgerAmountDetailRefreshed();
}

final class LedgerAmountDetailCancelled extends LedgerAmountDetailEvent {
  const LedgerAmountDetailCancelled();
}
