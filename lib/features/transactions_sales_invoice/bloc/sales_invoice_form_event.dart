import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:algo_erp_front/features/inventory_godown/domain/godown.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/domain/sales_invoice.dart';
import 'package:equatable/equatable.dart';

sealed class SalesInvoiceFormEvent extends Equatable {
  const SalesInvoiceFormEvent();

  @override
  List<Object?> get props => [];
}

final class FormInitialized extends SalesInvoiceFormEvent {
  const FormInitialized({this.entityId});
  final int? entityId;

  @override
  List<Object?> get props => [entityId];
}

final class CustomerSelected extends SalesInvoiceFormEvent {
  const CustomerSelected(this.customer);
  final Ledger? customer;

  @override
  List<Object?> get props => [customer];
}

final class GodownSelected extends SalesInvoiceFormEvent {
  const GodownSelected(this.godown);
  final Godown? godown;

  @override
  List<Object?> get props => [godown];
}

final class SalespersonSelected extends SalesInvoiceFormEvent {
  const SalespersonSelected(this.salesperson);
  final EmployeeLite? salesperson;

  @override
  List<Object?> get props => [salesperson];
}

final class ProjectSelected extends SalesInvoiceFormEvent {
  const ProjectSelected(this.project);
  final ProjectLite? project;

  @override
  List<Object?> get props => [project];
}

final class VoucherDateChanged extends SalesInvoiceFormEvent {
  const VoucherDateChanged(this.date);
  final DateTime date;

  @override
  List<Object?> get props => [date];
}

final class BillingNameChanged extends SalesInvoiceFormEvent {
  const BillingNameChanged(this.name);
  final String? name;

  @override
  List<Object?> get props => [name];
}

final class CreditDaysChanged extends SalesInvoiceFormEvent {
  const CreditDaysChanged(this.days);
  final int? days;

  @override
  List<Object?> get props => [days];
}

final class NarrationChanged extends SalesInvoiceFormEvent {
  const NarrationChanged(this.narration);
  final String? narration;

  @override
  List<Object?> get props => [narration];
}

final class SourceTypeChanged extends SalesInvoiceFormEvent {
  const SourceTypeChanged(this.sourceType);
  final String sourceType;

  @override
  List<Object?> get props => [sourceType];
}

final class SourceVoucherSelected extends SalesInvoiceFormEvent {
  const SourceVoucherSelected(this.source);
  final SourceVoucherLite? source;

  @override
  List<Object?> get props => [source];
}

final class FormRowsChanged extends SalesInvoiceFormEvent {
  const FormRowsChanged(this.rows);
  final List<SalesInvoiceLine> rows;

  @override
  List<Object?> get props => [rows];
}

final class LineItemUpdated extends SalesInvoiceFormEvent {
  const LineItemUpdated({required this.index, required this.line});
  final int index;
  final SalesInvoiceLine line;

  @override
  List<Object?> get props => [index, line];
}

final class FormSubmitted extends SalesInvoiceFormEvent {
  const FormSubmitted({required this.saveStatus});
  final String saveStatus; // 'Posted' or 'Draft'

  @override
  List<Object?> get props => [saveStatus];
}
