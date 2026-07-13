import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/vouchers/item_qty/item_qty_kind.dart';
import 'package:algo_erp_front/core/vouchers/item_qty/item_qty_models.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:equatable/equatable.dart';

enum ItemQtyListStatus { initial, loading, success, failure }

final class ItemQtyListState extends Equatable {
  const ItemQtyListState({
    required this.kind,
    this.status = ItemQtyListStatus.initial,
    this.items = const [],
    this.failure,
    this.startDate,
    this.endDate,
    this.selectedStatus,
    this.prefix = '',
    this.party,
    this.search = '',
    this.filtersExpanded = false,
  });

  final ItemQtyVoucherKind kind;
  final ItemQtyListStatus status;
  final List<ItemQtyListItem> items;
  final Failure? failure;

  final DateTime? startDate;
  final DateTime? endDate;
  final String? selectedStatus;
  final String prefix;
  final Ledger? party;
  final String search;
  final bool filtersExpanded;

  bool get isLoading => status == ItemQtyListStatus.loading;
  bool get isSuccess => status == ItemQtyListStatus.success;
  bool get isFailure => status == ItemQtyListStatus.failure;

  String? _formatYmd(DateTime? d) {
    if (d == null) return null;
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  PageQuery get query => PageQuery(
    search: search.isEmpty ? null : search,
    filters: {
      if (_formatYmd(startDate) != null) 'start_date': _formatYmd(startDate),
      if (_formatYmd(endDate) != null) 'end_date': _formatYmd(endDate),
      if (selectedStatus != null) 'status': selectedStatus,
      if (prefix.trim().isNotEmpty) 'prefix': prefix.trim(),
      if (party != null) 'ledger_id': party!.id,
    },
  );

  ItemQtyListState copyWith({
    ItemQtyVoucherKind? kind,
    ItemQtyListStatus? status,
    List<ItemQtyListItem>? items,
    Failure? failure,
    DateTime? Function()? startDate,
    DateTime? Function()? endDate,
    String? Function()? selectedStatus,
    String? prefix,
    Ledger? Function()? party,
    String? search,
    bool? filtersExpanded,
  }) {
    return ItemQtyListState(
      kind: kind ?? this.kind,
      status: status ?? this.status,
      items: items ?? this.items,
      failure: failure ?? this.failure,
      startDate: startDate != null ? startDate() : this.startDate,
      endDate: endDate != null ? endDate() : this.endDate,
      selectedStatus: selectedStatus != null
          ? selectedStatus()
          : this.selectedStatus,
      prefix: prefix ?? this.prefix,
      party: party != null ? party() : this.party,
      search: search ?? this.search,
      filtersExpanded: filtersExpanded ?? this.filtersExpanded,
    );
  }

  @override
  List<Object?> get props => [
    kind,
    status,
    items,
    failure,
    startDate,
    endDate,
    selectedStatus,
    prefix,
    party,
    search,
    filtersExpanded,
  ];
}
