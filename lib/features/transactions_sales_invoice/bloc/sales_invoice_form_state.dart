import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:algo_erp_front/features/inventory_godown/domain/godown.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/domain/sales_invoice.dart';
import 'package:equatable/equatable.dart';

enum FormSubmissionStatus {
  initial,
  loading,
  ready,
  submitting,
  success,
  failure,
}

final class SalesInvoiceFormState extends Equatable {
  const SalesInvoiceFormState({
    required this.status,
    required this.draft,
    this.entityId,
    this.isEdit = false,
    this.customer,
    this.godown,
    this.salesperson,
    this.project,
    this.sourceType = '',
    this.source,
    this.errorMessage,
    this.postedInvoiceId,
    this.postedVoucherNo,
    this.postedVerb,
    this.fieldErrors = const {},
    this.isDirty = false,
  });

  final FormSubmissionStatus status;
  final SalesInvoiceDraft draft;
  final int? entityId;
  final bool isEdit;
  final Ledger? customer;
  final Godown? godown;
  final EmployeeLite? salesperson;
  final ProjectLite? project;
  final String sourceType;
  final SourceVoucherLite? source;
  final String? errorMessage;
  final int? postedInvoiceId;
  final String? postedVoucherNo;
  final String? postedVerb;
  final Map<String, String> fieldErrors;

  /// `true` once the user has changed any field or line on this form — drives
  /// the discard-changes guard. Reset on (re)load and on a successful save so
  /// leaving a freshly-loaded or just-saved document never prompts.
  final bool isDirty;

  bool get isSubmitting => status == FormSubmissionStatus.submitting;
  bool get isLoading => status == FormSubmissionStatus.loading;
  bool get isFailure => status == FormSubmissionStatus.failure;

  /// Nullable fields take a closure rather than a bare value: `?? this.field`
  /// can never null one out, which is what previously made a deselected
  /// customer impossible to clear from the picker.
  SalesInvoiceFormState copyWith({
    FormSubmissionStatus? status,
    SalesInvoiceDraft? draft,
    int? entityId,
    bool? isEdit,
    Ledger? Function()? customer,
    Godown? Function()? godown,
    EmployeeLite? Function()? salesperson,
    ProjectLite? Function()? project,
    String? sourceType,
    SourceVoucherLite? Function()? source,
    String? Function()? errorMessage,
    int? Function()? postedInvoiceId,
    String? Function()? postedVoucherNo,
    String? Function()? postedVerb,
    Map<String, String>? fieldErrors,
    bool? isDirty,
  }) {
    return SalesInvoiceFormState(
      status: status ?? this.status,
      draft: draft ?? this.draft,
      entityId: entityId ?? this.entityId,
      isEdit: isEdit ?? this.isEdit,
      customer: customer != null ? customer() : this.customer,
      godown: godown != null ? godown() : this.godown,
      salesperson: salesperson != null ? salesperson() : this.salesperson,
      project: project != null ? project() : this.project,
      sourceType: sourceType ?? this.sourceType,
      source: source != null ? source() : this.source,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      postedInvoiceId: postedInvoiceId != null
          ? postedInvoiceId()
          : this.postedInvoiceId,
      postedVoucherNo: postedVoucherNo != null
          ? postedVoucherNo()
          : this.postedVoucherNo,
      postedVerb: postedVerb != null ? postedVerb() : this.postedVerb,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      isDirty: isDirty ?? this.isDirty,
    );
  }

  @override
  List<Object?> get props => [
    status,
    draft,
    entityId,
    isEdit,
    customer,
    godown,
    salesperson,
    project,
    sourceType,
    source,
    errorMessage,
    postedInvoiceId,
    postedVoucherNo,
    postedVerb,
    fieldErrors,
    isDirty,
  ];
}
