import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/inventory_item_property/domain/item_property.dart';
import 'package:equatable/equatable.dart';

enum ItemPropertyListStatus { initial, loading, success, failure }

final class ItemPropertyListState extends Equatable {
  const ItemPropertyListState({
    this.status = ItemPropertyListStatus.initial,
    this.items = const [],
    this.search = '',
    this.actionMessage,
    this.failure,
  });

  final ItemPropertyListStatus status;
  final List<ItemProperty> items;
  final String search;
  final String? actionMessage;
  final Failure? failure;

  bool get isLoading => status == ItemPropertyListStatus.loading;
  bool get isSuccess => status == ItemPropertyListStatus.success;
  bool get isFailure => status == ItemPropertyListStatus.failure;

  PageQuery get query =>
      PageQuery(search: search.trim().isEmpty ? null : search.trim());

  ItemPropertyListState copyWith({
    ItemPropertyListStatus? status,
    List<ItemProperty>? items,
    String? search,
    String? Function()? actionMessage,
    Failure? Function()? failure,
  }) {
    return ItemPropertyListState(
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
