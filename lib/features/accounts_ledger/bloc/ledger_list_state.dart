import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:equatable/equatable.dart';

enum LedgerListStatus { initial, loading, success, failure }

final class LedgerListState extends Equatable {
  const LedgerListState({
    this.status = LedgerListStatus.initial,
    this.items = const [],
    this.search = '',
    this.actionMessage,
    this.failure,
  });

  final LedgerListStatus status;
  final List<Ledger> items;
  final String search;
  final String? actionMessage;
  final Failure? failure;

  bool get isLoading => status == LedgerListStatus.loading;
  bool get isSuccess => status == LedgerListStatus.success;
  bool get isFailure => status == LedgerListStatus.failure;

  PageQuery get query => PageQuery(search: search.isEmpty ? null : search);

  LedgerListState copyWith({
    LedgerListStatus? status,
    List<Ledger>? items,
    String? search,
    String? Function()? actionMessage,
    Failure? Function()? failure,
  }) {
    return LedgerListState(
      status: status ?? this.status,
      items: items ?? this.items,
      search: search ?? this.search,
      actionMessage: actionMessage != null
          ? actionMessage()
          : this.actionMessage,
      failure: failure != null ? failure() : this.failure,
    );
  }

  @override
  List<Object?> get props => [status, items, search, actionMessage, failure];
}
