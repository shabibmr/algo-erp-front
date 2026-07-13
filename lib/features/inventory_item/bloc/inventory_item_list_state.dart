import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/inventory_item/domain/inventory_item.dart';
import 'package:equatable/equatable.dart';

enum InventoryItemListStatus { initial, loading, success, failure }

final class InventoryItemListState extends Equatable {
  const InventoryItemListState({
    this.status = InventoryItemListStatus.initial,
    this.items = const [],
    this.search = '',
    this.actionMessage,
    this.failure,
  });

  final InventoryItemListStatus status;
  final List<InventoryItem> items;
  final String search;
  final String? actionMessage;
  final Failure? failure;

  bool get isLoading => status == InventoryItemListStatus.loading;
  bool get isSuccess => status == InventoryItemListStatus.success;
  bool get isFailure => status == InventoryItemListStatus.failure;

  PageQuery get query =>
      PageQuery(search: search.trim().isEmpty ? null : search.trim());

  InventoryItemListState copyWith({
    InventoryItemListStatus? status,
    List<InventoryItem>? items,
    String? search,
    String? Function()? actionMessage,
    Failure? Function()? failure,
  }) {
    return InventoryItemListState(
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
