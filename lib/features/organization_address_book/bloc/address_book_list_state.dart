import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/organization_address_book/domain/address_book.dart';
import 'package:equatable/equatable.dart';

enum AddressBookListStatus { initial, loading, success, failure }

final class AddressBookListState extends Equatable {
  const AddressBookListState({
    this.status = AddressBookListStatus.initial,
    this.items = const [],
    this.search = '',
    this.actionMessage,
    this.failure,
  });

  final AddressBookListStatus status;
  final List<AddressBook> items;
  final String search;
  final String? actionMessage;
  final Failure? failure;

  bool get isLoading => status == AddressBookListStatus.loading;
  bool get isSuccess => status == AddressBookListStatus.success;
  bool get isFailure => status == AddressBookListStatus.failure;

  PageQuery get query => PageQuery(search: search.isEmpty ? null : search);

  AddressBookListState copyWith({
    AddressBookListStatus? status,
    List<AddressBook>? items,
    String? search,
    String? Function()? actionMessage,
    Failure? Function()? failure,
  }) {
    return AddressBookListState(
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
