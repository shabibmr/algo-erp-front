import 'package:algo_erp_front/core/error/failure.dart';
import 'package:equatable/equatable.dart';

enum GodownFormStatus { initial, loading, ready, submitting, success, failure }

final class GodownFormState extends Equatable {
  const GodownFormState({
    this.status = GodownFormStatus.initial,
    this.entityId,
    this.isEdit = false,
    this.name = '',
    this.code = '',
    this.location = '',
    this.narration = '',
    this.isProfitCentre = false,
    this.isDefault = false,
    this.isProduction = false,
    this.errorMessage,
    this.failure,
  });

  final GodownFormStatus status;
  final int? entityId;
  final bool isEdit;
  final String name;
  final String code;
  final String location;
  final String narration;
  final bool isProfitCentre;
  final bool isDefault;
  final bool isProduction;
  final String? errorMessage;
  final Failure? failure;

  bool get isLoading => status == GodownFormStatus.loading;
  bool get isSubmitting => status == GodownFormStatus.submitting;
  bool get isSuccess => status == GodownFormStatus.success;

  GodownFormState copyWith({
    GodownFormStatus? status,
    int? entityId,
    bool? isEdit,
    String? name,
    String? code,
    String? location,
    String? narration,
    bool? isProfitCentre,
    bool? isDefault,
    bool? isProduction,
    String? Function()? errorMessage,
    Failure? Function()? failure,
  }) {
    return GodownFormState(
      status: status ?? this.status,
      entityId: entityId ?? this.entityId,
      isEdit: isEdit ?? this.isEdit,
      name: name ?? this.name,
      code: code ?? this.code,
      location: location ?? this.location,
      narration: narration ?? this.narration,
      isProfitCentre: isProfitCentre ?? this.isProfitCentre,
      isDefault: isDefault ?? this.isDefault,
      isProduction: isProduction ?? this.isProduction,
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
    location,
    narration,
    isProfitCentre,
    isDefault,
    isProduction,
    errorMessage,
    failure,
  ];
}
