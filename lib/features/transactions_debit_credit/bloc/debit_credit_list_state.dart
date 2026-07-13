import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/vouchers/debit_credit/debit_credit_kind.dart';
import 'package:algo_erp_front/core/vouchers/debit_credit/debit_credit_models.dart';
import 'package:equatable/equatable.dart';

enum DebitCreditListStatus { initial, loading, success, failure }

final class DebitCreditListState extends Equatable {
  const DebitCreditListState({
    required this.kind,
    this.status = DebitCreditListStatus.initial,
    this.items = const [],
    this.failure,
    this.startDate,
    this.endDate,
    this.selectedStatus,
    this.prefix = '',
    this.search = '',
    this.filtersExpanded = false,
  });

  final DebitCreditVoucherKind kind;
  final DebitCreditListStatus status;
  final List<DebitCreditListItem> items;
  final Failure? failure;

  final DateTime? startDate;
  final DateTime? endDate;
  final String? selectedStatus;
  final String prefix;
  final String search;
  final bool filtersExpanded;

  bool get isLoading => status == DebitCreditListStatus.loading;
  bool get isSuccess => status == DebitCreditListStatus.success;
  bool get isFailure => status == DebitCreditListStatus.failure;

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
    },
  );

  DebitCreditListState copyWith({
    DebitCreditVoucherKind? kind,
    DebitCreditListStatus? status,
    List<DebitCreditListItem>? items,
    Failure? failure,
    DateTime? Function()? startDate,
    DateTime? Function()? endDate,
    String? Function()? selectedStatus,
    String? prefix,
    String? search,
    bool? filtersExpanded,
  }) {
    return DebitCreditListState(
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
    search,
    filtersExpanded,
  ];
}
