import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:equatable/equatable.dart';

sealed class LedgerFormEvent extends Equatable {
  const LedgerFormEvent();

  @override
  List<Object?> get props => [];
}

final class LedgerFormInitialized extends LedgerFormEvent {
  const LedgerFormInitialized({this.entityId});
  final int? entityId;

  @override
  List<Object?> get props => [entityId];
}

final class LedgerFormEntityUpdated extends LedgerFormEvent {
  const LedgerFormEntityUpdated(this.entity);
  final Ledger entity;

  @override
  List<Object?> get props => [entity];
}

final class LedgerFormSubmitted extends LedgerFormEvent {
  const LedgerFormSubmitted();
}

final class LedgerFormDeleted extends LedgerFormEvent {
  const LedgerFormDeleted();
}
