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

  group('export', () {
    /// Export asks for 200-row pages, so it sees a different shape of result
    /// than the 2-row screen pages above.
    void stubExportPages({required int total}) {
      when(() => repository.list(any())).thenAnswer((invocation) async {
        final query = invocation.positionalArguments.first as PageQuery;
        // The screen's own first fetch still uses the default limit.
        if (query.limit != 200) return Right(_page(query.page));

        final totalPages = (total / 200).ceil();
        final start = (query.page - 1) * 200;
        final count = (total - start).clamp(0, 200);
        return Right(
          Paginated(
            items: [for (var i = 0; i < count; i++) _item(start + i)],
            meta: PaginationMeta(
              total: total,
              page: query.page,
              limit: 200,
              totalPages: totalPages,
            ),
          ),
        );
      });
    }

    blocTest<SalesInvoiceListBloc, SalesInvoiceListState>(
      'walks every page, not just the ones scrolled into view',
      setUp: () => stubExportPages(total: 450),
      build: build,
      act: (bloc) async {
        bloc.add(const SalesInvoiceListFetchRequested());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(const SalesInvoiceListExportRequested());
      },
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        final export = bloc.state.export;
        expect(export, isNotNull);
        // All 450 rows — the screen itself is still holding only page 1.
        expect(export!.rows, hasLength(450));
        expect(export.isTruncated, isFalse);
        expect(bloc.state.items, hasLength(2));
        expect(bloc.state.isExporting, isFalse);
      },
    );

    blocTest<SalesInvoiceListBloc, SalesInvoiceListState>(
      'caps a runaway export and reports the true total',
      setUp: () => stubExportPages(total: 12000),
      build: build,
      act: (bloc) async {
        bloc.add(const SalesInvoiceListFetchRequested());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(const SalesInvoiceListExportRequested());
      },
      wait: const Duration(milliseconds: 200),
      verify: (bloc) {
        final export = bloc.state.export!;
        expect(export.rows, hasLength(5000));
        // The user must be told the file is short, not left to assume it's all.
        expect(export.isTruncated, isTrue);
        expect(export.total, 12000);
      },
    );

    blocTest<SalesInvoiceListBloc, SalesInvoiceListState>(
      'a failed export surfaces the failure and hands over no file',
      setUp: () {
        when(() => repository.list(any())).thenAnswer((invocation) async {
          final query = invocation.positionalArguments.first as PageQuery;
          if (query.limit != 200) return Right(_page(query.page));
          return const Left(Failure.network('No connection'));
        });
      },
      build: build,
      act: (bloc) async {
        bloc.add(const SalesInvoiceListFetchRequested());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(const SalesInvoiceListExportRequested());
      },
      wait: const Duration(milliseconds: 60),
      verify: (bloc) {
        expect(bloc.state.export, isNull, reason: 'no half-written file');
        expect(bloc.state.isExporting, isFalse);
        expect(bloc.state.failure, isNotNull);
        expect(bloc.state.items, hasLength(2), reason: 'list must survive');
      },
    );

    blocTest<SalesInvoiceListBloc, SalesInvoiceListState>(
      'a double tap on export does not run it twice',
      setUp: () {
        when(() => repository.list(any())).thenAnswer((invocation) async {
          final query = invocation.positionalArguments.first as PageQuery;
          await Future<void>.delayed(const Duration(milliseconds: 60));
          if (query.limit != 200) return Right(_page(query.page));
          return Right(
            Paginated(
              items: [_item(1)],
              meta: const PaginationMeta(
                total: 1,
                page: 1,
                limit: 200,
                totalPages: 1,
              ),
            ),
          );
        });
      },
      build: build,
      act: (bloc) async {
        bloc.add(const SalesInvoiceListFetchRequested());
        await Future<void>.delayed(const Duration(milliseconds: 100));
        bloc
          ..add(const SalesInvoiceListExportRequested())
          ..add(const SalesInvoiceListExportRequested());
      },
      wait: const Duration(milliseconds: 300),
      verify: (bloc) {
        expect(bloc.state.export!.rows, hasLength(1));
        // The screen's first fetch plus one export page; the second tap is
        // dropped rather than queued behind the first.
        verify(() => repository.list(any())).called(2);
      },
    );

    blocTest<SalesInvoiceListBloc, SalesInvoiceListState>(
      'the payload is cleared once the view has written the file',
      setUp: () => stubExportPages(total: 3),
      build: build,
      act: (bloc) async {
        bloc.add(const SalesInvoiceListFetchRequested());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(const SalesInvoiceListExportRequested());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(const SalesInvoiceListExportHandled());
      },
      wait: const Duration(milliseconds: 60),
      // Otherwise the next rebuild would download the same file again.
      verify: (bloc) => expect(bloc.state.export, isNull),
    );
  });

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
