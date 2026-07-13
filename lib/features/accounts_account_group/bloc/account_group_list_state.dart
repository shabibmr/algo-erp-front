import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/accounts_account_group/domain/account_group.dart';
import 'package:equatable/equatable.dart';

enum AccountGroupListStatus { initial, loading, success, failure }

final class AccountGroupListState extends Equatable {
  const AccountGroupListState({
    this.status = AccountGroupListStatus.initial,
    this.items = const [],
    this.search = '',
    this.actionMessage,
    this.failure,
  });

  final AccountGroupListStatus status;
  final List<AccountGroup> items;
  final String search;
  final String? actionMessage;
  final Failure? failure;

  bool get isLoading => status == AccountGroupListStatus.loading;
  bool get isSuccess => status == AccountGroupListStatus.success;
  bool get isFailure => status == AccountGroupListStatus.failure;

  PageQuery get query => PageQuery(search: search.isEmpty ? null : search);

  AccountGroupListState copyWith({
    AccountGroupListStatus? status,
    List<AccountGroup>? items,
    String? search,
    String? Function()? actionMessage,
    Failure? Function()? failure,
  }) {
    return AccountGroupListState(
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
