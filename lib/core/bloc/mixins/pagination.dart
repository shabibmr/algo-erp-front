import 'package:algo_erp_front/core/network/paginated.dart';

/// Small helpers for evolving [PaginationMeta] as a `CrudBloc` mutates its list
/// in place — inserting or removing an item without a full server reload.
extension PaginationMetaX on PaginationMeta {
  PaginationMeta copyWith({
    int? total,
    int? page,
    int? limit,
    int? totalPages,
  }) {
    return PaginationMeta(
      total: total ?? this.total,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      totalPages: totalPages ?? this.totalPages,
    );
  }

  /// After an optimistic insert: bump the total and recompute page count.
  PaginationMeta withOneMore() => _withTotal(total + 1);

  /// After an optimistic delete: drop the total (never below zero).
  PaginationMeta withOneFewer() => _withTotal(total > 0 ? total - 1 : 0);

  PaginationMeta _withTotal(int newTotal) {
    final effectiveLimit = limit <= 0 ? 1 : limit;
    return copyWith(
      total: newTotal,
      totalPages: (newTotal / effectiveLimit).ceil(),
    );
  }
}
