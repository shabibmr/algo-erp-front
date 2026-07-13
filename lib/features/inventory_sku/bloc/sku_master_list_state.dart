import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/inventory_sku/domain/sku_master.dart';
import 'package:equatable/equatable.dart';

enum SkuMasterListStatus { initial, loading, success, failure }

final class SkuMasterListState extends Equatable {
  const SkuMasterListState({
    this.status = SkuMasterListStatus.initial,
    this.items = const [],
    this.search = '',
    this.actionMessage,
    this.failure,
  });

  final SkuMasterListStatus status;
  final List<SkuMaster> items;
  final String search;
  final String? actionMessage;
  final Failure? failure;

  bool get isLoading => status == SkuMasterListStatus.loading;
  bool get isSuccess => status == SkuMasterListStatus.success;
  bool get isFailure => status == SkuMasterListStatus.failure;

  PageQuery get query =>
      PageQuery(search: search.trim().isEmpty ? null : search.trim());

  SkuMasterListState copyWith({
    SkuMasterListStatus? status,
    List<SkuMaster>? items,
    String? search,
    String? Function()? actionMessage,
    Failure? Function()? failure,
  }) {
    return SkuMasterListState(
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
