// Private fields fed by public named params cannot use initializing formals.
// ignore_for_file: prefer_initializing_formals

import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/vouchers/voucher_blueprint.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:algo_erp_front/features/inventory_godown/domain/godown.dart';
import 'package:algo_erp_front/features/inventory_item/domain/inventory_item.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/bloc/sales_invoice_form_event.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/bloc/sales_invoice_form_state.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/data/sales_invoice_dto.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/data/sales_invoice_repository.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/domain/sales_invoice.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SalesInvoiceFormBloc
    extends Bloc<SalesInvoiceFormEvent, SalesInvoiceFormState> {
  SalesInvoiceFormBloc({
    required SalesInvoiceRepository repository,
    required Repository<Ledger, int> ledgerRepository,
    required Repository<Godown, int> godownRepository,
    required Repository<InventoryItem, int> itemRepository,
  }) : _repository = repository,
       _ledgerRepo = ledgerRepository,
       _godownRepo = godownRepository,
       _itemRepo = itemRepository,
       super(
         SalesInvoiceFormState(
           status: FormSubmissionStatus.initial,
           draft: SalesInvoiceDraft(
             voucherPrefix:
                 VoucherBlueprints.salesInvoice.defaultPrefix ?? 'SI',
             financialYear: DateTime.now().year.toString(),
           ),
         ),
       ) {
    on<FormInitialized>(_onInitialized);
    on<CustomerSelected>(_onCustomerSelected);
    on<GodownSelected>(_onGodownSelected);
    on<SalespersonSelected>(_onSalespersonSelected);
    on<ProjectSelected>(_onProjectSelected);
    on<VoucherDateChanged>(_onVoucherDateChanged);
    on<BillingNameChanged>(_onBillingNameChanged);
    on<CreditDaysChanged>(_onCreditDaysChanged);
    on<NarrationChanged>(_onNarrationChanged);
    on<SourceTypeChanged>(_onSourceTypeChanged);
    on<SourceVoucherSelected>(
      _onSourceVoucherSelected,
      transformer: restartable(),
    );
    // Genuinely droppable: a second tap while a post is in flight is ignored,
    // not queued behind it. `asyncExpand` would have buffered and posted twice.
    on<FormSubmitted>(_onSubmitted, transformer: droppable());
    on<FormRowsChanged>(_onFormRowsChanged);
    on<LineItemUpdated>(_onLineItemUpdated);
  }

  final SalesInvoiceRepository _repository;
  final Repository<Ledger, int> _ledgerRepo;
  final Repository<Godown, int> _godownRepo;
  final Repository<InventoryItem, int> _itemRepo;

  Future<void> _onInitialized(
    FormInitialized event,
    Emitter<SalesInvoiceFormState> emit,
  ) async {
    final entityId = event.entityId;
    if (entityId == null) {
      emit(state.copyWith(status: FormSubmissionStatus.ready, isEdit: false));
      return;
    }

    emit(
      state.copyWith(
        status: FormSubmissionStatus.loading,
        entityId: entityId,
        isEdit: true,
      ),
    );

    final result = await _repository.getById(
      entityId,
      resolveItemLabel: _resolveItemLabel,
    );

    await result.fold(
      (failure) async => emit(
        state.copyWith(
          status: FormSubmissionStatus.failure,
          errorMessage: () => failure.message,
        ),
      ),
      (detail) async {
        if (detail.status != 'Draft') {
          emit(
            state.copyWith(
              status: FormSubmissionStatus.failure,
              errorMessage: () =>
                  'Only Draft invoices can be edited '
                  '(status is ${detail.status}).',
            ),
          );
          return;
        }

        // Resolve the FK display labels *before* emitting, rather than firing
        // `.then(add(...))` chains that outlive this handler — those threw a
        // StateError when the user navigated away mid-flight, and routing them
        // through CustomerSelected clobbered the invoice's own billing name.
        final (customer, godown, salesperson, project) = await (
          _resolveCustomer(detail.customerLedgerId, detail.billingName),
          _resolveGodown(detail.godownId),
          _resolveSalesperson(
            detail.salespersonEmployeeId,
            detail.salespersonLabel,
          ),
          _resolveProject(detail.voucherProjectId, detail.projectLabel),
        ).wait;

        emit(
          state.copyWith(
            status: FormSubmissionStatus.ready,
            draft: SalesInvoiceDto.detailToDraft(detail),
            customer: () => customer,
            godown: () => godown,
            salesperson: () => salesperson,
            project: () => project,
          ),
        );
      },
    );
  }

  /// Each resolver falls back to a placeholder carrying the id, so a lookup
  /// that fails leaves the picker showing *something* rather than blank.
  Future<Ledger?> _resolveCustomer(int? id, String? billingName) async {
    if (id == null) return null;
    final result = await _ledgerRepo.getById(id);
    return result.fold(
      (_) => Ledger(
        id: id,
        name: billingName ?? 'Ledger #$id',
        openingBalance: Decimal.zero,
      ),
      (ledger) => ledger,
    );
  }

  Future<Godown?> _resolveGodown(int? id) async {
    if (id == null) return null;
    final result = await _godownRepo.getById(id);
    return result.fold(
      (_) => Godown(id: id, name: 'Godown #$id'),
      (godown) => godown,
    );
  }

  Future<EmployeeLite?> _resolveSalesperson(int? id, String? label) async {
    if (id == null) return null;
    final result = await _repository.getEmployee(id);
    return result.fold(
      (_) => EmployeeLite(id: id, name: label ?? 'Employee #$id'),
      (employee) =>
          employee ?? EmployeeLite(id: id, name: label ?? 'Employee #$id'),
    );
  }

  Future<ProjectLite?> _resolveProject(int? id, String? label) async {
    if (id == null) return null;
    final result = await _repository.getProject(id);
    return result.fold(
      (_) => ProjectLite(id: id, name: label ?? 'Project #$id'),
      (project) =>
          project ?? ProjectLite(id: id, name: label ?? 'Project #$id'),
    );
  }

  Future<String?> _resolveItemLabel(int itemId) async {
    final result = await _itemRepo.getById(itemId);
    return result.fold(
      (_) => null,
      (item) => item.code.isEmpty ? item.name : '${item.code} — ${item.name}',
    );
  }

  void _onCustomerSelected(
    CustomerSelected event,
    Emitter<SalesInvoiceFormState> emit,
  ) {
    final customer = event.customer;
    emit(
      state.copyWith(
        customer: () => customer,
        errorMessage: () => null,
        draft: state.draft.copyWith(
          customerLedgerId: customer?.id,
          customerLabel: customer?.name,
          billingName: customer?.name,
        ),
      ),
    );
  }

  void _onGodownSelected(
    GodownSelected event,
    Emitter<SalesInvoiceFormState> emit,
  ) {
    final godown = event.godown;
    emit(
      state.copyWith(
        godown: () => godown,
        errorMessage: () => null,
        draft: state.draft.copyWith(
          godownId: godown?.id,
          godownLabel: godown?.name,
        ),
      ),
    );
  }

  void _onSalespersonSelected(
    SalespersonSelected event,
    Emitter<SalesInvoiceFormState> emit,
  ) {
    final salesperson = event.salesperson;
    emit(
      state.copyWith(
        salesperson: () => salesperson,
        errorMessage: () => null,
        draft: state.draft.copyWith(
          salespersonEmployeeId: salesperson?.id,
          salespersonLabel: salesperson?.label,
        ),
      ),
    );
  }

  void _onProjectSelected(
    ProjectSelected event,
    Emitter<SalesInvoiceFormState> emit,
  ) {
    final project = event.project;
    emit(
      state.copyWith(
        project: () => project,
        errorMessage: () => null,
        draft: state.draft.copyWith(
          voucherProjectId: project?.id,
          projectLabel: project?.label,
        ),
      ),
    );
  }

  void _onVoucherDateChanged(
    VoucherDateChanged event,
    Emitter<SalesInvoiceFormState> emit,
  ) {
    emit(
      state.copyWith(
        errorMessage: () => null,
        draft: state.draft.copyWith(voucherDate: event.date),
      ),
    );
  }

  void _onBillingNameChanged(
    BillingNameChanged event,
    Emitter<SalesInvoiceFormState> emit,
  ) {
    final name = event.name;
    emit(
      state.copyWith(
        errorMessage: () => null,
        draft: state.draft.copyWith(
          billingName: (name == null || name.isEmpty) ? null : name,
        ),
      ),
    );
  }

  void _onCreditDaysChanged(
    CreditDaysChanged event,
    Emitter<SalesInvoiceFormState> emit,
  ) {
    emit(
      state.copyWith(
        errorMessage: () => null,
        draft: state.draft.copyWith(creditDays: event.days ?? 30),
      ),
    );
  }

  void _onNarrationChanged(
    NarrationChanged event,
    Emitter<SalesInvoiceFormState> emit,
  ) {
    final narration = event.narration;
    emit(
      state.copyWith(
        errorMessage: () => null,
        draft: state.draft.copyWith(
          narration: (narration == null || narration.isEmpty)
              ? null
              : narration,
        ),
      ),
    );
  }

  void _onSourceTypeChanged(
    SourceTypeChanged event,
    Emitter<SalesInvoiceFormState> emit,
  ) {
    emit(
      state.copyWith(
        sourceType: event.sourceType,
        source: () => null,
        errorMessage: () => null,
        draft: state.draft.copyWith(
          sourceVoucherId: null,
          sourceVoucherType: null,
          sourceVoucherLabel: null,
        ),
      ),
    );
  }

  Future<void> _onSourceVoucherSelected(
    SourceVoucherSelected event,
    Emitter<SalesInvoiceFormState> emit,
  ) async {
    final selected = event.source;
    if (selected == null) {
      emit(
        state.copyWith(
          source: () => null,
          errorMessage: () => null,
          draft: state.draft.copyWith(
            sourceVoucherId: null,
            sourceVoucherType: null,
            sourceVoucherLabel: null,
          ),
        ),
      );
      return;
    }

    final result = await _repository.getSourceVoucher(
      type: selected.type,
      id: selected.id,
    );

    await result.fold(
      (failure) async =>
          emit(state.copyWith(errorMessage: () => failure.message)),
      (source) async {
        final (customer, godown) = await (
          _resolveCustomer(source.customerLedgerId, source.billingName),
          _resolveGodown(source.godownId ?? state.draft.godownId),
        ).wait;

        emit(
          state.copyWith(
            source: () => source,
            customer: () => customer,
            godown: () => godown ?? state.godown,
            errorMessage: () => null,
            draft: state.draft.copyWith(
              sourceVoucherId: source.id,
              sourceVoucherType: source.type,
              sourceVoucherLabel: source.displayNo,
              customerLedgerId: source.customerLedgerId,
              billingName: source.billingName,
              godownId: source.godownId ?? state.draft.godownId,
              lines: source.lines,
            ),
          ),
        );
      },
    );
  }

  void _onFormRowsChanged(
    FormRowsChanged event,
    Emitter<SalesInvoiceFormState> emit,
  ) {
    emit(
      state.copyWith(
        errorMessage: () => null,
        draft: state.draft.copyWith(lines: event.rows),
      ),
    );
  }

  void _onLineItemUpdated(
    LineItemUpdated event,
    Emitter<SalesInvoiceFormState> emit,
  ) {
    if (event.index < 0 || event.index >= state.draft.lines.length) return;
    final lines = List<SalesInvoiceLine>.of(state.draft.lines);
    lines[event.index] = event.line;
    emit(
      state.copyWith(
        errorMessage: () => null,
        draft: state.draft.copyWith(lines: lines),
      ),
    );
  }

  Future<void> _onSubmitted(
    FormSubmitted event,
    Emitter<SalesInvoiceFormState> emit,
  ) async {
    final validationError = _validate();
    if (validationError != null) {
      emit(
        state.copyWith(
          status: FormSubmissionStatus.ready,
          errorMessage: () => validationError,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: FormSubmissionStatus.submitting,
        errorMessage: () => null,
      ),
    );

    final draftToSave = state.draft.copyWith(
      lines: state.draft.lines.where((line) => line.isComplete).toList(),
      saveStatus: event.saveStatus,
    );

    if (state.isEdit) {
      final result = await _repository.updateDraft(
        state.entityId!,
        draftToSave,
      );
      result.fold(
        (failure) => emit(
          state.copyWith(
            status: FormSubmissionStatus.ready,
            errorMessage: () => failure.message,
          ),
        ),
        (_) => emit(
          state.copyWith(
            status: FormSubmissionStatus.success,
            postedInvoiceId: () => state.entityId,
            postedVerb: () => 'Draft updated',
          ),
        ),
      );
      return;
    }

    final result = await _repository.post(draftToSave);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: FormSubmissionStatus.ready,
          errorMessage: () => failure.message,
        ),
      ),
      (posted) => emit(
        state.copyWith(
          status: FormSubmissionStatus.success,
          postedInvoiceId: () => posted.id,
          postedVoucherNo: () => posted.voucherNo,
          postedVerb: () =>
              event.saveStatus == 'Draft' ? 'Saved draft' : 'Posted',
        ),
      ),
    );
  }

  String? _validate() {
    if (state.draft.customerLedgerId == null) return 'Customer is required';
    if (state.draft.godownId == null) return 'Godown is required';
    if (!state.draft.lines.any((line) => line.isComplete)) {
      return 'Add at least one complete line (item, qty, price)';
    }
    if (!state.isEdit && state.draft.financialYear.trim().isEmpty) {
      return 'Financial year is required';
    }
    return null;
  }
}
