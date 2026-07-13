import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/organization_user/domain/user_credentials.dart';
import 'package:equatable/equatable.dart';

enum UserCredentialsListStatus { initial, loading, success, failure }

final class UserCredentialsListState extends Equatable {
  const UserCredentialsListState({
    this.status = UserCredentialsListStatus.initial,
    this.items = const [],
    this.search = '',
    this.actionMessage,
    this.failure,
  });

  final UserCredentialsListStatus status;
  final List<UserCredentials> items;
  final String search;
  final String? actionMessage;
  final Failure? failure;

  bool get isLoading => status == UserCredentialsListStatus.loading;
  bool get isSuccess => status == UserCredentialsListStatus.success;
  bool get isFailure => status == UserCredentialsListStatus.failure;

  PageQuery get query => PageQuery(search: search.isEmpty ? null : search);

  UserCredentialsListState copyWith({
    UserCredentialsListStatus? status,
    List<UserCredentials>? items,
    String? search,
    String? Function()? actionMessage,
    Failure? Function()? failure,
  }) {
    return UserCredentialsListState(
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
