import 'package:algo_erp_front/features/inventory_group/domain/inventory_group.dart';
import 'package:equatable/equatable.dart';

sealed class InventoryGroupFormEvent extends Equatable {
  const InventoryGroupFormEvent();

  @override
  List<Object?> get props => [];
}

final class InventoryGroupFormInitialized extends InventoryGroupFormEvent {
  const InventoryGroupFormInitialized({this.entityId});

  final int? entityId;

  @override
  List<Object?> get props => [entityId];
}

final class InventoryGroupFormNameChanged extends InventoryGroupFormEvent {
  const InventoryGroupFormNameChanged(this.name);

  final String name;

  @override
  List<Object?> get props => [name];
}

final class InventoryGroupFormCodeChanged extends InventoryGroupFormEvent {
  const InventoryGroupFormCodeChanged(this.code);

  final String code;

  @override
  List<Object?> get props => [code];
}

final class InventoryGroupFormNameArabicChanged
    extends InventoryGroupFormEvent {
  const InventoryGroupFormNameArabicChanged(this.nameArabic);

  final String nameArabic;

  @override
  List<Object?> get props => [nameArabic];
}

final class InventoryGroupFormGroupTypeChanged extends InventoryGroupFormEvent {
  const InventoryGroupFormGroupTypeChanged(this.groupType);

  final String groupType;

  @override
  List<Object?> get props => [groupType];
}

final class InventoryGroupFormParentGroupIdChanged
    extends InventoryGroupFormEvent {
  const InventoryGroupFormParentGroupIdChanged(this.parentGroupId);

  final int? parentGroupId;

  @override
  List<Object?> get props => [parentGroupId];
}

final class InventoryGroupFormSubmitted extends InventoryGroupFormEvent {
  const InventoryGroupFormSubmitted();
}
