import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/network/paginated.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/bloc/sales_invoice_list_bloc.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/bloc/sales_invoice_list_event.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/bloc/sales_invoice_list_state.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/data/sales_invoice_repository.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/domain/sales_invoice.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockSalesInvoiceRepository extends Mock
    implements SalesInvoiceRepository {}

SalesInvoiceListItem _item(int id) => SalesInvoiceListItem(
  id: id,
  voucherPrefix: 'SI',
  voucherNo: '$id',
  voucherDate: null,
);

/// 3 pages of 2 rows each.
Paginated<SalesInvoiceListItem> _page(int page) => Paginated(
  items: [_item(page * 10), _item(page * 10 + 1)],
  meta: PaginationMeta(total: 6, page: page, limit: 2, totalPages: 3),
);

void main() {
  late _MockSalesInvoiceRepository repository;

  setUpAll(() => registerFallbackValue(const PageQuery()));

  setUp(() {
    repository = _MockSalesInvoiceRepository();
    when(() => repository.list(any())).thenAnswer((invocation) async {
      final query = invocation.positionalArguments.first as PageQuery;
      return Right(_page(query.page));
    });
  });

  SalesInvoiceListBloc build() => SalesInvoiceListBloc(repository: repository);

  blocTest<SalesInvoiceListBloc, SalesInvoiceListState>(
    'load-more appends the next page instead of replacing it',
    build: build,
    act: (bloc) => bloc
      ..add(const SalesInvoiceListFetchRequested())
      ..add(const SalesInvoiceListLoadMoreRequested()),
    wait: const Duration(milliseconds: 50),
    verify: (bloc) {
      expect(bloc.state.items.map((i) => i.id), [10, 11, 20, 21]);
      expect(bloc.state.page, 2);
      expect(bloc.state.hasMore, isTrue);
      expect(bloc.state.total, 6);
    },
  );

  blocTest<SalesInvoiceListBloc, SalesInvoiceListState>(
    'stops asking once the last page is in',
    build: build,
    act: (bloc) async {
      bloc.add(const SalesInvoiceListFetchRequested());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bloc.add(const SalesInvoiceListLoadMoreRequested());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bloc.add(const SalesInvoiceListLoadMoreRequested());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      // Page 3 of 3 is now in — this one must be ignored.
      bloc.add(const SalesInvoiceListLoadMoreRequested());
    },
    wait: const Duration(milliseconds: 60),
    verify: (bloc) {
      expect(bloc.state.items, hasLength(6));
      expect(bloc.state.hasMore, isFalse);
      // 1 initial fetch + 2 successful load-mores; the 4th event is dropped.
      verify(() => repository.list(any())).called(3);
    },
  );

  blocTest<SalesInvoiceListBloc, SalesInvoiceListState>(
    'a burst of scroll events does not append while one page is in flight',
    setUp: () {
      // The request has to actually take time, or the events never overlap and
      // there is nothing for `droppable` to drop — each would just be a normal
      // sequential load-more. This is what a real flick down the list does.
      when(() => repository.list(any())).thenAnswer((invocation) async {
        final query = invocation.positionalArguments.first as PageQuery;
        await Future<void>.delayed(const Duration(milliseconds: 60));
        return Right(_page(query.page));
      });
    },
    build: build,
    act: (bloc) async {
      bloc.add(const SalesInvoiceListFetchRequested());
      await Future<void>.delayed(const Duration(milliseconds: 100));
      bloc
        ..add(const SalesInvoiceListLoadMoreRequested())
        ..add(const SalesInvoiceListLoadMoreRequested())
        ..add(const SalesInvoiceListLoadMoreRequested());
    },
    wait: const Duration(milliseconds: 300),
    verify: (bloc) {
      expect(bloc.state.items.map((i) => i.id), [10, 11, 20, 21]);
      expect(bloc.state.page, 2);
      // The first fetch plus exactly one load-more; the other two are dropped.
      verify(() => repository.list(any())).called(2);
    },
  );

  blocTest<SalesInvoiceListBloc, SalesInvoiceListState>(
    'applying a filter resets to page 1 rather than appending',
    build: build,
    act: (bloc) async {
      bloc.add(const SalesInvoiceListFetchRequested());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bloc.add(const SalesInvoiceListLoadMoreRequested());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bloc.add(const SalesInvoiceListFiltersApplied());
    },
    wait: const Duration(milliseconds: 60),
    verify: (bloc) {
      expect(bloc.state.page, 1);
      expect(bloc.state.items.map((i) => i.id), [10, 11]);
    },
  );

  blocTest<SalesInvoiceListBloc, SalesInvoiceListState>(
    'a failed append keeps the rows already on screen',
    setUp: () {
      when(() => repository.list(any())).thenAnswer((invocation) async {
        final query = invocation.positionalArguments.first as PageQuery;
        if (query.page == 1) return Right(_page(1));
        return const Left(Failure.network('No connection'));
      });
    },
    build: build,
    act: (bloc) async {
      bloc.add(const SalesInvoiceListFetchRequested());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bloc.add(const SalesInvoiceListLoadMoreRequested());
    },
    wait: const Duration(milliseconds: 60),
    verify: (bloc) {
      expect(bloc.state.isSuccess, isTrue, reason: 'list must survive');
      expect(bloc.state.items, hasLength(2));
      expect(bloc.state.isLoadingMore, isFalse);
      expect(bloc.state.failure, isNotNull);
      // Page counter did not advance, so a retry re-asks for page 2.
      expect(bloc.state.page, 1);
    },
  );
}
