import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/inventory_category/domain/category.dart';
import 'package:equatable/equatable.dart';

enum CategoryListStatus { initial, loading, success, failure }

final class CategoryListState extends Equatable {
  const CategoryListState({
    this.status = CategoryListStatus.initial,
    this.items = const [],
    this.search = '',
    this.failure,
    this.actionMessage,
  });

  final CategoryListStatus status;
  final List<Category> items;
  final String search;
  final Failure? failure;
  final String? actionMessage;

  bool get isLoading => status == CategoryListStatus.loading;
  bool get isSuccess => status == CategoryListStatus.success;
  bool get isFailure => status == CategoryListStatus.failure;

  PageQuery get query =>
      PageQuery(search: search.trim().isEmpty ? null : search.trim());

  CategoryListState copyWith({
    CategoryListStatus? status,
    List<Category>? items,
    String? search,
    Failure? Function()? failure,
    String? Function()? actionMessage,
  }) {
    return CategoryListState(
      status: status ?? this.status,
      items: items ?? this.items,
      search: search ?? this.search,
      failure: failure != null ? failure() : this.failure,
      actionMessage: actionMessage != null
          ? actionMessage()
          : this.actionMessage,
    );
  }

  @override
  List<Object?> get props => [status, items, search, failure, actionMessage];
}
