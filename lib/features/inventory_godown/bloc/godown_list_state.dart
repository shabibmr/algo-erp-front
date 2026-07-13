import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/inventory_godown/domain/godown.dart';
import 'package:equatable/equatable.dart';

enum GodownListStatus { initial, loading, success, failure }

final class GodownListState extends Equatable {
  const GodownListState({
    this.status = GodownListStatus.initial,
    this.items = const [],
    this.search = '',
    this.actionMessage,
    this.failure,
  });

  final GodownListStatus status;
  final List<Godown> items;
  final String search;
  final String? actionMessage;
  final Failure? failure;

  bool get isLoading => status == GodownListStatus.loading;
  bool get isSuccess => status == GodownListStatus.success;
  bool get isFailure => status == GodownListStatus.failure;

  PageQuery get query => PageQuery(search: search.isEmpty ? null : search);

  GodownListState copyWith({
    GodownListStatus? status,
    List<Godown>? items,
    String? search,
    String? Function()? actionMessage,
    Failure? Function()? failure,
  }) {
    return GodownListState(
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
