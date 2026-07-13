import 'package:algo_erp_front/core/error/failure.dart';
import 'package:equatable/equatable.dart';

enum ItemPropertyFormStatus {
  initial,
  loading,
  ready,
  submitting,
  success,
  failure,
}

final class ItemPropertyFormState extends Equatable {
  const ItemPropertyFormState({
    this.status = ItemPropertyFormStatus.initial,
    this.entityId,
    this.isEdit = false,
    this.itemId = '',
    this.defaultValue = '',
    this.errorMessage,
    this.failure,
  });

  final ItemPropertyFormStatus status;
  final int? entityId;
  final bool isEdit;
  final String itemId;
  final String defaultValue;
  final String? errorMessage;
  final Failure? failure;

  bool get isLoading => status == ItemPropertyFormStatus.loading;
  bool get isSubmitting => status == ItemPropertyFormStatus.submitting;
  bool get isSuccess => status == ItemPropertyFormStatus.success;

  ItemPropertyFormState copyWith({
    ItemPropertyFormStatus? status,
    int? entityId,
    bool? isEdit,
    String? itemId,
    String? defaultValue,
    String? Function()? errorMessage,
    Failure? Function()? failure,
  }) {
    return ItemPropertyFormState(
      status: status ?? this.status,
      entityId: entityId ?? this.entityId,
      isEdit: isEdit ?? this.isEdit,
      itemId: itemId ?? this.itemId,
      defaultValue: defaultValue ?? this.defaultValue,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      failure: failure != null ? failure() : this.failure,
    );
  }

  @override
  List<Object?> get props => [
    status,
    entityId,
    isEdit,
    itemId,
    defaultValue,
    errorMessage,
    failure,
  ];
}
