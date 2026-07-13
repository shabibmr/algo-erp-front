// Private fields fed by public named params cannot use initializing formals.
// ignore_for_file: prefer_initializing_formals

import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/safe_call.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:algo_erp_front/features/inventory_godown/domain/godown.dart';
import 'package:algo_erp_front/features/inventory_item/domain/inventory_item.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/bloc/sales_invoice_detail_event.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/bloc/sales_invoice_detail_state.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/data/sales_invoice_dto.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/data/sales_invoice_repository.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/domain/sales_invoice.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SalesInvoiceDetailBloc
    extends Bloc<SalesInvoiceDetailEvent, SalesInvoiceDetailState> {
  SalesInvoiceDetailBloc({
    required SalesInvoiceRepository repository,
    required Repository<InventoryItem, int> itemRepository,
    required Repository<Ledger, int> ledgerRepository,
    required Repository<Godown, int> godownRepository,
  }) : _repository = repository,
       _itemRepo = itemRepository,
       _ledgerRepo = ledgerRepository,
       _godownRepo = godownRepository,
       super(const SalesInvoiceDetailState()) {
    on<SalesInvoiceDetailFetchRequested>(
      _onFetchRequested,
      transformer: restartable(),
    );
    on<SalesInvoiceDetailRefreshed>(_onRefreshed, transformer: droppable());
    // Lifecycle transitions are irreversible server-side: a second tap while
    // one is in flight must be dropped, not queued behind it.
    on<SalesInvoiceDetailApproved>(_onApproved, transformer: droppable());
    on<SalesInvoiceDetailRejected>(_onRejected, transformer: droppable());
    on<SalesInvoiceDetailCancelled>(_onCancelled, transformer: droppable());
    on<SalesInvoiceDetailPostAndBooked>(
      _onPostAndBooked,
      transformer: droppable(),
    );
  }

  final SalesInvoiceRepository _repository;
  final Repository<InventoryItem, int> _itemRepo;
  final Repository<Ledger, int> _ledgerRepo;
  final Repository<Godown, int> _godownRepo;

  /// The id currently on screen — lets Retry re-fetch without the page having
  /// to hand the id back in (the old retry reached for `context.widget` and
  /// crashed on the cast).
  int? _currentId;

  Future<void> _onFetchRequested(
    SalesInvoiceDetailFetchRequested event,
    Emitter<SalesInvoiceDetailState> emit,
  ) async {
    _currentId = event.id;
    await _fetch(event.id, emit);
  }

  Future<void> _onRefreshed(
    SalesInvoiceDetailRefreshed event,
    Emitter<SalesInvoiceDetailState> emit,
  ) async {
    final id = _currentId;
    if (id != null) await _fetch(id, emit);
  }

  Future<void> _fetch(int id, Emitter<SalesInvoiceDetailState> emit) async {
    emit(
      state.copyWith(
        status: SalesInvoiceDetailStatus.loading,
        actionMessage: () => null,
        postedInvoiceId: () => null,
        failure: () => null,
      ),
    );

    final result = await _repository.getById(
      id,
      resolveItemLabel: (itemId) async {
        final r = await _itemRepo.getById(itemId);
        return r.fold(
          (_) => null,
          (item) =>
              item.code.isEmpty ? item.name : '${item.code} — ${item.name}',
        );
      },
      resolveCustomerLabel: (ledgerId) async {
        final r = await _ledgerRepo.getById(ledgerId);
        return r.fold((_) => null, (ledger) {
          final code = ledger.code;
          return (code == null || code.isEmpty)
              ? ledger.name
              : '$code — ${ledger.name}';
        });
      },
      resolveGodownLabel: (godownId) async {
        final r = await _godownRepo.getById(godownId);
        return r.fold((_) => null, (godown) => godown.name);
      },
      resolveSalespersonLabel: (employeeId) async {
        final r = await _repository.getEmployee(employeeId);
        return r.fold((_) => null, (employee) => employee?.label);
      },
      resolveProjectLabel: (projectId) async {
        final r = await _repository.getProject(projectId);
        return r.fold((_) => null, (project) => project?.label);
      },
    );

    await result.fold(
      (failure) async => emit(
        state.copyWith(
          status: SalesInvoiceDetailStatus.failure,
          failure: () => failure,
        ),
      ),
      (detail) async {
        final series = await _repository.seriesRequiresApproval(
          voucherType: 'SalesInvoice',
          prefix: detail.voucherPrefix.isEmpty ? 'SI' : detail.voucherPrefix,
        );

        emit(
          state.copyWith(
            status: SalesInvoiceDetailStatus.success,
            detail: detail,
            seriesRequiresApproval: () => series.fold((_) => null, (f) => f),
          ),
        );
      },
    );
  }

  Future<void> _onApproved(
    SalesInvoiceDetailApproved event,
    Emitter<SalesInvoiceDetailState> emit,
  ) => _runLifecycle(emit, _repository.approve, fallbackMessage: 'Approved');

  Future<void> _onRejected(
    SalesInvoiceDetailRejected event,
    Emitter<SalesInvoiceDetailState> emit,
  ) => _runLifecycle(
    emit,
    (id) => _repository.reject(id, event.reason),
    fallbackMessage: 'Rejected',
  );

  Future<void> _onCancelled(
    SalesInvoiceDetailCancelled event,
    Emitter<SalesInvoiceDetailState> emit,
  ) => _runLifecycle(emit, _repository.cancel, fallbackMessage: 'Cancelled');

  /// Approve / reject / cancel differ only in the call they make and the verb
  /// they report — the busy flag, failure handling and re-fetch are identical.
  Future<void> _runLifecycle(
    Emitter<SalesInvoiceDetailState> emit,
    Future<Result<VoucherLifecycleResult>> Function(int id) action, {
    required String fallbackMessage,
  }) async {
    final detail = state.detail;
    if (detail == null) return;

    emit(state.copyWith(isBusy: true, actionMessage: () => null));

    final result = await action(detail.id);
    await result.fold(
      (failure) async => emit(
        state.copyWith(isBusy: false, actionMessage: () => failure.message),
      ),
      (ok) async {
        emit(
          state.copyWith(
            isBusy: false,
            actionMessage: () =>
                ok.message ?? '$fallbackMessage → ${ok.status}',
          ),
        );
        await _fetch(detail.id, emit);
      },
    );
  }

  Future<void> _onPostAndBooked(
    SalesInvoiceDetailPostAndBooked event,
    Emitter<SalesInvoiceDetailState> emit,
  ) async {
    final detail = state.detail;
    if (detail == null) return;

    emit(state.copyWith(isBusy: true, actionMessage: () => null));

    final result = await _repository.post(
      SalesInvoiceDto.detailToDraft(detail, saveStatus: 'Posted'),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(isBusy: false, actionMessage: () => failure.message),
      ),
      (posted) => emit(
        state.copyWith(
          isBusy: false,
          actionMessage: () =>
              'Booked ${posted.voucherNo} · original #${detail.id} unchanged',
          postedInvoiceId: () => posted.id,
        ),
      ),
    );
  }
}
