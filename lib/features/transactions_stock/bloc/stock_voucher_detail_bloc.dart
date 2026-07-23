import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/error/safe_call.dart';
import 'package:algo_erp_front/core/vouchers/stock/stock_voucher_models.dart';
import 'package:algo_erp_front/core/vouchers/stock/stock_voucher_repository.dart';
import 'package:algo_erp_front/features/inventory_godown/domain/godown.dart';
import 'package:algo_erp_front/features/inventory_item/domain/inventory_item.dart';
import 'package:algo_erp_front/features/transactions_stock/bloc/stock_voucher_detail_event.dart';
import 'package:algo_erp_front/features/transactions_stock/bloc/stock_voucher_detail_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StockVoucherDetailBloc
    extends Bloc<StockVoucherDetailEvent, StockVoucherDetailState> {
  StockVoucherDetailBloc({
    required StockVoucherRepository repository,
    required Repository<InventoryItem, int> itemRepository,
    required Repository<Godown, int> godownRepository,
  }) : _repository = repository,
       _itemRepo = itemRepository,
       _godownRepo = godownRepository,
       super(const StockVoucherDetailState()) {
    on<StockVoucherDetailFetchRequested>(_onFetchRequested);
    on<StockVoucherDetailRefreshed>(_onRefreshed);
    on<StockVoucherDetailCancelled>(_onCancelled);
    on<StockVoucherDetailApproved>(_onApproved);
    on<StockVoucherDetailRejected>(_onRejected);
    on<StockVoucherDetailFulfilled>(_onFulfilled);
  }

  final StockVoucherRepository _repository;
  final Repository<InventoryItem, int> _itemRepo;
  final Repository<Godown, int> _godownRepo;

  Future<void> _onFetchRequested(
    StockVoucherDetailFetchRequested event,
    Emitter<StockVoucherDetailState> emit,
  ) async {
    emit(
      state.copyWith(
        status: StockVoucherDetailStatus.loading,
        actionMessage: () => null,
      ),
    );

    final result = await _repository.getById(
      event.id,
      resolveItemLabel: (itemId) async {
        final r = await _itemRepo.getById(itemId);
        return r.fold(
          (_) => null,
          (item) =>
              item.code.isEmpty ? item.name : '${item.code} — ${item.name}',
        );
      },
      resolveGodownLabel: (godownId) async {
        final r = await _godownRepo.getById(godownId);
        return r.fold((_) => null, (g) => g.name);
      },
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: StockVoucherDetailStatus.failure,
          failure: () => failure,
        ),
      ),
      (detail) => emit(
        state.copyWith(
          status: StockVoucherDetailStatus.success,
          detail: detail,
        ),
      ),
    );
  }

  Future<void> _onRefreshed(
    StockVoucherDetailRefreshed event,
    Emitter<StockVoucherDetailState> emit,
  ) async {
    if (state.detail != null) {
      add(StockVoucherDetailFetchRequested(state.detail!.id));
    }
  }

  Future<void> _onCancelled(
    StockVoucherDetailCancelled event,
    Emitter<StockVoucherDetailState> emit,
  ) => _run(emit, _repository.cancel, 'Cancelled');

  Future<void> _onApproved(
    StockVoucherDetailApproved event,
    Emitter<StockVoucherDetailState> emit,
  ) => _run(emit, _repository.approve, 'Approved');

  Future<void> _onRejected(
    StockVoucherDetailRejected event,
    Emitter<StockVoucherDetailState> emit,
  ) async {
    if (state.detail == null) return;
    emit(state.copyWith(isBusy: true, actionMessage: () => null));
    final result = await _repository.reject(state.detail!.id, event.reason);
    result.fold(
      (failure) => emit(
        state.copyWith(isBusy: false, actionMessage: () => _messageOf(failure)),
      ),
      (r) {
        emit(
          state.copyWith(
            isBusy: false,
            actionMessage: () => r.message ?? 'Rejected',
          ),
        );
        add(StockVoucherDetailFetchRequested(state.detail!.id));
      },
    );
  }

  Future<void> _onFulfilled(
    StockVoucherDetailFulfilled event,
    Emitter<StockVoucherDetailState> emit,
  ) async {
    if (state.detail == null) return;
    emit(state.copyWith(isBusy: true, actionMessage: () => null));
    final result = await _repository.fulfill(
      state.detail!.id,
      event.issueQuantities,
    );
    result.fold(
      (failure) => emit(
        state.copyWith(isBusy: false, actionMessage: () => _messageOf(failure)),
      ),
      (_) {
        emit(state.copyWith(isBusy: false, actionMessage: () => 'Fulfilled'));
        add(StockVoucherDetailFetchRequested(state.detail!.id));
      },
    );
  }

  Future<void> _run(
    Emitter<StockVoucherDetailState> emit,
    Future<Result<StockVoucherLifecycleResult>> Function(int id) call,
    String fallback,
  ) async {
    if (state.detail == null) return;
    emit(state.copyWith(isBusy: true, actionMessage: () => null));
    final result = await call(state.detail!.id);
    result.fold(
      (failure) => emit(
        state.copyWith(isBusy: false, actionMessage: () => _messageOf(failure)),
      ),
      (r) {
        emit(
          state.copyWith(
            isBusy: false,
            actionMessage: () => r.message ?? fallback,
          ),
        );
        add(StockVoucherDetailFetchRequested(state.detail!.id));
      },
    );
  }

  String _messageOf(Failure f) => switch (f) {
    NetworkFailure(:final message) => message,
    TimeoutFailure(:final message) => message,
    UnauthorizedFailure(:final message) => message,
    ForbiddenFailure(:final message) => message,
    ValidationFailure(:final message) => message,
    NotFoundFailure(:final message) => message,
    ConflictFailure(:final message) => message,
    ServerFailure(:final message) => message,
    CacheFailure(:final message) => message,
    UnknownFailure(:final message) => message,
  };
}
