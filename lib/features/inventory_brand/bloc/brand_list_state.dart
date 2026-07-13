import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/inventory_brand/domain/brand.dart';
import 'package:equatable/equatable.dart';

enum BrandListStatus { initial, loading, success, failure }

final class BrandListState extends Equatable {
  const BrandListState({
    this.status = BrandListStatus.initial,
    this.items = const [],
    this.search = '',
    this.actionMessage,
    this.failure,
  });

  final BrandListStatus status;
  final List<Brand> items;
  final String search;
  final String? actionMessage;
  final Failure? failure;

  bool get isLoading => status == BrandListStatus.loading;
  bool get isSuccess => status == BrandListStatus.success;
  bool get isFailure => status == BrandListStatus.failure;

  PageQuery get query =>
      PageQuery(search: search.trim().isEmpty ? null : search.trim());

  BrandListState copyWith({
    BrandListStatus? status,
    List<Brand>? items,
    String? search,
    String? Function()? actionMessage,
    Failure? Function()? failure,
  }) {
    return BrandListState(
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
