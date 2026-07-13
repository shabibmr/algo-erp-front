import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:algo_erp_front/features/accounts_ledger/ledger_manifest.dart';
import 'package:equatable/equatable.dart';

enum LedgerFormStatus {
  initial,
  loading,
  ready,
  submitting,
  success,
  deleted,
  failure,
}

final class LedgerFormState extends Equatable {
  const LedgerFormState({
    this.status = LedgerFormStatus.initial,
    this.entityId,
    this.isEdit = false,
    this.entity,
    this.fieldErrors = const {},
    this.errorMessage,
    this.failure,
  });

  final LedgerFormStatus status;
  final int? entityId;
  final bool isEdit;
  final Ledger? entity;
  final Map<String, String> fieldErrors;
  final String? errorMessage;
  final Failure? failure;

  Ledger get currentEntity => entity ?? ledgerManifest.emptyEntity!();

  bool get isLoading => status == LedgerFormStatus.loading;
  bool get isSubmitting => status == LedgerFormStatus.submitting;
  bool get isSuccess => status == LedgerFormStatus.success;
  bool get isDeleted => status == LedgerFormStatus.deleted;

  LedgerFormState copyWith({
    LedgerFormStatus? status,
    int? entityId,
    bool? isEdit,
    Ledger? entity,
    Map<String, String>? fieldErrors,
    String? Function()? errorMessage,
    Failure? Function()? failure,
  }) {
    return LedgerFormState(
      status: status ?? this.status,
      entityId: entityId ?? this.entityId,
      isEdit: isEdit ?? this.isEdit,
      entity: entity ?? this.entity,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      failure: failure != null ? failure() : this.failure,
    );
  }

  @override
  List<Object?> get props => [
    status,
    entityId,
    isEdit,
    entity,
    fieldErrors,
    errorMessage,
    failure,
  ];
}
