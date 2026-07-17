import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/export/export_cubit.dart';
import 'package:algo_erp_front/core/network/paginated.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements Repository<String, Object?> {}

Paginated<String> _page({
  required List<String> items,
  required int total,
  required int page,
  required int totalPages,
}) => Paginated(
  items: items,
  meta: PaginationMeta(
    total: total,
    page: page,
    limit: kExportPageSize,
    totalPages: totalPages,
  ),
);

void main() {
  late _MockRepository repository;

  setUp(() {
    repository = _MockRepository();
    registerFallbackValue(const PageQuery());
  });

  group('ExportCubit', () {
    blocTest<ExportCubit<String>, ExportState<String>>(
      'walks every page, not just the first — the whole point of the cubit',
      setUp: () {
        // The screen shows page 1; an export that stopped there would silently
        // write a partial file. This is the regression the cubit exists for.
        when(() => repository.list(any())).thenAnswer((invocation) async {
          final query = invocation.positionalArguments.first as PageQuery;
          return switch (query.page) {
            1 => Right(
              _page(items: ['a', 'b'], total: 5, page: 1, totalPages: 3),
            ),
            2 => Right(
              _page(items: ['c', 'd'], total: 5, page: 2, totalPages: 3),
            ),
            _ => Right(_page(items: ['e'], total: 5, page: 3, totalPages: 3)),
          };
        });
      },
      build: () => ExportCubit<String>(source: repository.list),
      act: (cubit) =>
          cubit.run(query: const PageQuery(), format: ExportFormat.excel),
      expect: () => [
        isA<ExportRunning<String>>(),
        isA<ExportReady<String>>()
            .having((s) => s.items, 'items', ['a', 'b', 'c', 'd', 'e'])
            .having((s) => s.total, 'total', 5)
            .having((s) => s.isTruncated, 'isTruncated', isFalse),
      ],
      verify: (_) => verify(() => repository.list(any())).called(3),
    );

    blocTest<ExportCubit<String>, ExportState<String>>(
      'exports at the page size, not the screen page size',
      setUp: () => when(() => repository.list(any())).thenAnswer(
        (_) async =>
            Right(_page(items: ['a'], total: 1, page: 1, totalPages: 1)),
      ),
      build: () => ExportCubit<String>(source: repository.list),
      act: (cubit) => cubit.run(
        // A list showing 25 at a time must not export in 25-row round trips.
        query: const PageQuery(limit: 25),
        format: ExportFormat.excel,
      ),
      verify: (_) => verify(
        () => repository.list(
          any(that: isA<PageQuery>().having((q) => q.limit, 'limit', 200)),
        ),
      ).called(1),
    );

    blocTest<ExportCubit<String>, ExportState<String>>(
      'carries the search and filters through to every page',
      setUp: () => when(() => repository.list(any())).thenAnswer(
        (_) async =>
            Right(_page(items: ['a'], total: 1, page: 1, totalPages: 1)),
      ),
      build: () => ExportCubit<String>(source: repository.list),
      act: (cubit) => cubit.run(
        query: const PageQuery(search: 'cash', filters: {'isActive': true}),
        format: ExportFormat.excel,
      ),
      verify: (_) => verify(
        () => repository.list(
          any(
            that: isA<PageQuery>()
                .having((q) => q.search, 'search', 'cash')
                .having((q) => q.filters, 'filters', {'isActive': true}),
          ),
        ),
      ).called(1),
    );

    blocTest<ExportCubit<String>, ExportState<String>>(
      'stops on an empty page rather than spinning forever',
      setUp: () {
        // A server whose totalPages disagrees with what it actually returns
        // would otherwise loop until the row cap.
        when(() => repository.list(any())).thenAnswer((invocation) async {
          final query = invocation.positionalArguments.first as PageQuery;
          if (query.page == 1) {
            return Right(
              _page(items: ['a'], total: 99, page: 1, totalPages: 9),
            );
          }
          return Right(_page(items: [], total: 99, page: 2, totalPages: 9));
        });
      },
      build: () => ExportCubit<String>(source: repository.list),
      act: (cubit) =>
          cubit.run(query: const PageQuery(), format: ExportFormat.excel),
      expect: () => [
        isA<ExportRunning<String>>(),
        isA<ExportReady<String>>().having((s) => s.items, 'items', ['a']),
      ],
      verify: (_) => verify(() => repository.list(any())).called(2),
    );

    blocTest<ExportCubit<String>, ExportState<String>>(
      'caps the walk and reports the file as truncated',
      setUp: () => when(() => repository.list(any())).thenAnswer(
        (_) async => Right(
          _page(
            items: List.filled(200, 'x'),
            total: 10000,
            page: 1,
            totalPages: 50,
          ),
        ),
      ),
      // Default page size (200) against a 500-row cap: the walk overshoots the
      // cap mid-page, so the trim has to happen on the accumulated rows.
      build: () => ExportCubit<String>(source: repository.list, rowCap: 500),
      act: (cubit) =>
          cubit.run(query: const PageQuery(), format: ExportFormat.excel),
      expect: () => [
        isA<ExportRunning<String>>(),
        isA<ExportReady<String>>()
            .having((s) => s.items.length, 'items', 500)
            // The true size of the result set, not what we managed to pull —
            // the user has to be told what they are missing.
            .having((s) => s.total, 'total', 10000)
            .having((s) => s.isTruncated, 'isTruncated', isTrue),
      ],
    );

    blocTest<ExportCubit<String>, ExportState<String>>(
      'a failure mid-walk surfaces instead of writing a half file',
      setUp: () {
        when(() => repository.list(any())).thenAnswer((invocation) async {
          final query = invocation.positionalArguments.first as PageQuery;
          if (query.page == 1) {
            return Right(_page(items: ['a'], total: 4, page: 1, totalPages: 2));
          }
          return const Left(Failure.network('boom'));
        });
      },
      build: () => ExportCubit<String>(source: repository.list),
      act: (cubit) =>
          cubit.run(query: const PageQuery(), format: ExportFormat.excel),
      expect: () => [isA<ExportRunning<String>>(), isA<ExportFailed<String>>()],
    );

    blocTest<ExportCubit<String>, ExportState<String>>(
      'a second run while one is walking is ignored',
      setUp: () => when(() => repository.list(any())).thenAnswer((_) async {
        return Right(_page(items: ['a'], total: 1, page: 1, totalPages: 1));
      }),
      build: () => ExportCubit<String>(source: repository.list),
      act: (cubit) {
        // Two taps must not double the traffic and race to hand the view two
        // files.
        cubit
          ..run(query: const PageQuery(), format: ExportFormat.excel)
          ..run(query: const PageQuery(), format: ExportFormat.csv);
      },
      expect: () => [
        isA<ExportRunning<String>>(),
        isA<ExportReady<String>>().having(
          (s) => s.format,
          'format',
          ExportFormat.excel,
        ),
      ],
      verify: (_) => verify(() => repository.list(any())).called(1),
    );

    blocTest<ExportCubit<String>, ExportState<String>>(
      'the chosen format reaches the view',
      setUp: () => when(() => repository.list(any())).thenAnswer(
        (_) async =>
            Right(_page(items: ['a'], total: 1, page: 1, totalPages: 1)),
      ),
      build: () => ExportCubit<String>(source: repository.list),
      act: (cubit) =>
          cubit.run(query: const PageQuery(), format: ExportFormat.csv),
      expect: () => [
        isA<ExportRunning<String>>(),
        isA<ExportReady<String>>().having(
          (s) => s.format,
          'format',
          ExportFormat.csv,
        ),
      ],
    );

    blocTest<ExportCubit<String>, ExportState<String>>(
      'handled() clears the payload so a rebuild cannot re-write the file',
      setUp: () => when(() => repository.list(any())).thenAnswer(
        (_) async =>
            Right(_page(items: ['a'], total: 1, page: 1, totalPages: 1)),
      ),
      build: () => ExportCubit<String>(source: repository.list),
      act: (cubit) async {
        await cubit.run(query: const PageQuery(), format: ExportFormat.excel);
        cubit.handled();
      },
      expect: () => [
        isA<ExportRunning<String>>(),
        isA<ExportReady<String>>(),
        isA<ExportIdle<String>>(),
      ],
    );
  });
}
