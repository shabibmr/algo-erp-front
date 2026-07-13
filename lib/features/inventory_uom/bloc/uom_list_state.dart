import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/inventory_uom/domain/uom.dart';
import 'package:equatable/equatable.dart';

enum UomListStatus { initial, loading, success, failure }

final class UomListState extends Equatable {
  const UomListState({
    this.status = UomListStatus.initial,
    this.items = const [],
    this.search = '',
    this.actionMessage,
    this.failure,
  });

  final UomListStatus status;
  final List<Uom> items;
  final String search;
  final String? actionMessage;
  final Failure? failure;

  bool get isLoading => status == UomListStatus.loading;
  bool get isSuccess => status == UomListStatus.success;
  bool get isFailure => status == UomListStatus.failure;

  PageQuery get query => PageQuery(search: search.isEmpty ? null : search);

  UomListState copyWith({
    UomListStatus? status,
    List<Uom>? items,
    String? search,
    String? Function()? actionMessage,
    Failure? Function()? failure,
  }) {
    return UomListState(
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
