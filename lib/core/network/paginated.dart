import 'package:equatable/equatable.dart';

/// Matches the backend's list payload shape exactly:
/// `{ items: T[], meta: { total, page, limit, totalPages } }`.
class Paginated<T> {
  const Paginated({required this.items, required this.meta});

  factory Paginated.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return Paginated<T>(
      items: rawItems.map(fromJsonT).toList(growable: false),
      meta: PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );
  }

  final List<T> items;
  final PaginationMeta meta;
}

class PaginationMeta extends Equatable {
  const PaginationMeta({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
      totalPages: json['totalPages'] as int? ?? 0,
    );
  }

  final int total;
  final int page;
  final int limit;
  final int totalPages;

  bool get hasMore => page < totalPages;

  @override
  List<Object?> get props => [total, page, limit, totalPages];
}
