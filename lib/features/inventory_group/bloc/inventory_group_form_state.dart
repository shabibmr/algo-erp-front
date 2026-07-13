import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/inventory_group/domain/inventory_group.dart';
import 'package:equatable/equatable.dart';

enum InventoryGroupFormStatus {
  initial,
  loading,
  ready,
  submitting,
  success,
  failure,
}

final class InventoryGroupFormState extends Equatable {
  const InventoryGroupFormState({
    this.status = InventoryGroupFormStatus.initial,
    this.entityId,
    this.isEdit = false,
    this.name = '',
    this.code = '',
    this.nameArabic = '',
    this.groupType = '',
    this.parentGroupId,
    this.availableGroups = const [],
    this.errorMessage,
    this.failure,
  });

  final InventoryGroupFormStatus status;
  final int? entityId;
  final bool isEdit;
  final String name;
  final String code;
  final String nameArabic;
  final String groupType;
  final int? parentGroupId;
  final List<InventoryGroup> availableGroups;
  final String? errorMessage;
  final Failure? failure;

  bool get isLoading => status == InventoryGroupFormStatus.loading;
  bool get isSubmitting => status == InventoryGroupFormStatus.submitting;
  bool get isSuccess => status == InventoryGroupFormStatus.success;

  InventoryGroupFormState copyWith({
    InventoryGroupFormStatus? status,
    int? entityId,
    bool? isEdit,
    String? name,
    String? code,
    String? nameArabic,
    String? groupType,
    int? Function()? parentGroupId,
    List<InventoryGroup>? availableGroups,
    String? Function()? errorMessage,
    Failure? Function()? failure,
  }) {
    return InventoryGroupFormState(
      status: status ?? this.status,
      entityId: entityId ?? this.entityId,
      isEdit: isEdit ?? this.isEdit,
      name: name ?? this.name,
      code: code ?? this.code,
      nameArabic: nameArabic ?? this.nameArabic,
      groupType: groupType ?? this.groupType,
      parentGroupId: parentGroupId != null
          ? parentGroupId()
          : this.parentGroupId,
      availableGroups: availableGroups ?? this.availableGroups,
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
    nameArabic,
    groupType,
    parentGroupId,
    availableGroups,
    errorMessage,
    failure,
  ];
}
