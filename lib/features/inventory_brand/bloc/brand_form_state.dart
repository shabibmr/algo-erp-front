import 'package:algo_erp_front/core/error/failure.dart';
import 'package:equatable/equatable.dart';

enum BrandFormStatus { initial, loading, ready, submitting, success, failure }

final class BrandFormState extends Equatable {
  const BrandFormState({
    this.status = BrandFormStatus.initial,
    this.entityId,
    this.isEdit = false,
    this.name = '',
    this.description = '',
    this.errorMessage,
    this.failure,
  });

  final BrandFormStatus status;
  final int? entityId;
  final bool isEdit;
  final String name;
  final String description;
  final String? errorMessage;
  final Failure? failure;

  bool get isLoading => status == BrandFormStatus.loading;
  bool get isSubmitting => status == BrandFormStatus.submitting;
  bool get isSuccess => status == BrandFormStatus.success;

  BrandFormState copyWith({
    BrandFormStatus? status,
    int? entityId,
    bool? isEdit,
    String? name,
    String? description,
    String? Function()? errorMessage,
    Failure? Function()? failure,
  }) {
    return BrandFormState(
      status: status ?? this.status,
      entityId: entityId ?? this.entityId,
      isEdit: isEdit ?? this.isEdit,
      name: name ?? this.name,
      description: description ?? this.description,
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
    description,
    errorMessage,
    failure,
  ];
}
