import 'package:algo_erp_front/core/error/failure.dart';
import 'package:equatable/equatable.dart';

enum UomFormStatus { initial, loading, ready, submitting, success, failure }

final class UomFormState extends Equatable {
  const UomFormState({
    this.status = UomFormStatus.initial,
    this.entityId,
    this.isEdit = false,
    this.name = '',
    this.code = '',
    this.symbol = '',
    this.decimalPlaces = 0,
    this.errorMessage,
    this.failure,
  });

  final UomFormStatus status;
  final int? entityId;
  final bool isEdit;
  final String name;
  final String code;
  final String symbol;
  final int decimalPlaces;
  final String? errorMessage;
  final Failure? failure;

  bool get isLoading => status == UomFormStatus.loading;
  bool get isSubmitting => status == UomFormStatus.submitting;
  bool get isSuccess => status == UomFormStatus.success;

  UomFormState copyWith({
    UomFormStatus? status,
    int? entityId,
    bool? isEdit,
    String? name,
    String? code,
    String? symbol,
    int? decimalPlaces,
    String? Function()? errorMessage,
    Failure? Function()? failure,
  }) {
    return UomFormState(
      status: status ?? this.status,
      entityId: entityId ?? this.entityId,
      isEdit: isEdit ?? this.isEdit,
      name: name ?? this.name,
      code: code ?? this.code,
      symbol: symbol ?? this.symbol,
      decimalPlaces: decimalPlaces ?? this.decimalPlaces,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      failure: failure != null ? failure() : this.failure,
    );
  }

  @override
  List<Object?> get props => [
    status,
    entityId,
    isEdit,
    name,
    code,
    symbol,
    decimalPlaces,
    errorMessage,
    failure,
  ];
}
