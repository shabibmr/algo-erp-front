import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/inventory_group/domain/inventory_group.dart';
import 'package:equatable/equatable.dart';

enum InventoryGroupListStatus { initial, loading, success, failure }

final class InventoryGroupListState extends Equatable {
  const InventoryGroupListState({
    this.status = InventoryGroupListStatus.initial,
    this.items = const [],
    this.search = '',
    this.actionMessage,
    this.failure,
  });

  final InventoryGroupListStatus status;
  final List<InventoryGroup> items;
  final String search;
  final String? actionMessage;
  final Failure? failure;

  bool get isLoading => status == InventoryGroupListStatus.loading;
  bool get isSuccess => status == InventoryGroupListStatus.success;
  bool get isFailure => status == InventoryGroupListStatus.failure;

  PageQuery get query =>
      PageQuery(search: search.trim().isEmpty ? null : search.trim());

  InventoryGroupListState copyWith({
    InventoryGroupListStatus? status,
    List<InventoryGroup>? items,
    String? search,
    String? Function()? actionMessage,
    Failure? Function()? failure,
  }) {
    return InventoryGroupListState(
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
