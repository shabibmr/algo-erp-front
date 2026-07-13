import 'package:algo_erp_front/core/error/failure.dart';
import 'package:equatable/equatable.dart';

enum CategoryFormStatus {
  initial,
  loading,
  ready,
  submitting,
  success,
  failure,
}

final class CategoryFormState extends Equatable {
  const CategoryFormState({
    this.status = CategoryFormStatus.initial,
    this.entityId,
    this.isEdit = false,
    this.name = '',
    this.code = '',
    this.description = '',
    this.errorMessage,
    this.failure,
  });

  final CategoryFormStatus status;
  final int? entityId;
  final bool isEdit;
  final String name;
  final String code;
  final String description;
  final String? errorMessage;
  final Failure? failure;

  bool get isLoading => status == CategoryFormStatus.loading;
  bool get isSubmitting => status == CategoryFormStatus.submitting;
  bool get isSuccess => status == CategoryFormStatus.success;

  CategoryFormState copyWith({
    CategoryFormStatus? status,
    int? entityId,
    bool? isEdit,
    String? name,
    String? code,
    String? description,
    String? Function()? errorMessage,
    Failure? Function()? failure,
  }) {
    return CategoryFormState(
      status: status ?? this.status,
      entityId: entityId ?? this.entityId,
      isEdit: isEdit ?? this.isEdit,
      name: name ?? this.name,
      code: code ?? this.code,
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
    code,
    description,
    errorMessage,
    failure,
  ];
}
