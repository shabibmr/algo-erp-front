import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/network/paginated.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

/// A throwaway entity — proves `CrudBloc` needs no knowledge of any real model.
class _Item {
  const _Item(this.id, this.name);
  final int id;
  final String name;
}

class _MockRepo extends Mock implements Repository<_Item, int> {}

Paginated<_Item> _page(
  List<_Item> items, {
  required int total,
  int page = 1,
  int limit = 20,
  int? totalPages,
}) {
  return Paginated<_Item>(
    items: items,
    meta: PaginationMeta(
      total: total,
      page: page,
      limit: limit,
      totalPages: totalPages ?? (total / limit).ceil(),
    ),
  );
}

void main() {
  late _MockRepo repo;

  const a = _Item(1, 'Apple');
  const b = _Item(2, 'Banana');
  const c = _Item(3, 'Cherry');

  setUpAll(() {
    registerFallbackValue(const PageQuery());
    registerFallbackValue(const _Item(0, ''));
  });

  setUp(() => repo = _MockRepo());

  CrudBloc<_Item, int, void> build({
    Duration debounce = const Duration(milliseconds: 20),
  }) =>
      CrudBloc<_Item, int, void>(
        repository: repo,
        idOf: (e) => e.id,
        searchDebounce: debounce,
      );

  group('load', () {
    blocTest<CrudBloc<_Item, int, void>, CrudState<_Item>>(
      'emits [loading, loaded] on success',
      setUp: () => when(() => repo.list(any())).thenAnswer(
        (_) async => Right(_page([a, b], total: 2)),
      ),
      build: build,
      act: (bloc) => bloc.add(const CrudLoadRequested()),
      expect: () => [
        isA<CrudLoading<_Item>>(),
        isA<CrudLoaded<_Item>>()
            .having((s) => s.items, 'items', [a, b])
            .having((s) => s.hasMore, 'hasMore', false),
      ],
    );

    blocTest<CrudBloc<_Item, int, void>, CrudState<_Item>>(
      'emits [loading, error] when the repository fails',
      setUp: () => when(() => repo.list(any())).thenAnswer(
        (_) async => const Left(Failure.network('offline')),
      ),
      build: build,
      act: (bloc) => bloc.add(const CrudLoadRequested()),
      expect: () => [
        isA<CrudLoading<_Item>>(),
        isA<CrudError<_Item>>().having(
          (s) => s.failure,
          'failure',
          const Failure.network('offline'),
        ),
      ],
    );
  });

  blocTest<CrudBloc<_Item, int, void>, CrudState<_Item>>(
    'loadMore appends the next page and requests page 2',
    setUp: () => when(() => repo.list(any())).thenAnswer(
      (_) async => Right(_page([b], total: 2, page: 2, limit: 1)),
    ),
    build: build,
    seed: () => const CrudLoaded<_Item>(
      items: [a],
      meta: PaginationMeta(total: 2, page: 1, limit: 1, totalPages: 2),
    ),
    act: (bloc) => bloc.add(const CrudLoadMoreRequested()),
    expect: () => [
      isA<CrudLoaded<_Item>>().having((s) => s.isLoadingMore, 'more', true),
      isA<CrudLoaded<_Item>>().having((s) => s.items, 'items', [a, b]),
    ],
    verify: (_) {
      final query = verify(() => repo.list(captureAny())).captured.last
          as PageQuery;
      expect(query.page, 2);
    },
  );

  blocTest<CrudBloc<_Item, int, void>, CrudState<_Item>>(
    'search debounces then loads with the search term',
    setUp: () => when(() => repo.list(any())).thenAnswer(
      (_) async => Right(_page([a], total: 1)),
    ),
    build: build,
    act: (bloc) => bloc.add(const CrudSearchChanged('app')),
    wait: const Duration(milliseconds: 60),
    expect: () => [
      isA<CrudLoading<_Item>>(),
      isA<CrudLoaded<_Item>>().having((s) => s.items, 'items', [a]),
    ],
    verify: (_) {
      final query =
          verify(() => repo.list(captureAny())).captured.last as PageQuery;
      expect(query.search, 'app');
    },
  );

  blocTest<CrudBloc<_Item, int, void>, CrudState<_Item>>(
    'create prepends the new item without reloading',
    setUp: () =>
        when(() => repo.create(any())).thenAnswer((_) async => const Right(c)),
    build: build,
    seed: () => const CrudLoaded<_Item>(
      items: [a],
      meta: PaginationMeta(total: 1, page: 1, limit: 20, totalPages: 1),
    ),
    act: (bloc) => bloc.add(const CrudItemCreated(c)),
    expect: () => [
      isA<CrudLoaded<_Item>>()
          .having((s) => s.items, 'items', [c, a])
          .having((s) => s.meta.total, 'total', 2),
    ],
    verify: (_) => verifyNever(() => repo.list(any())),
  );

  blocTest<CrudBloc<_Item, int, void>, CrudState<_Item>>(
    'update replaces the item in place',
    setUp: () => when(() => repo.update(any(), any()))
        .thenAnswer((_) async => const Right(_Item(1, 'Apricot'))),
    build: build,
    seed: () => const CrudLoaded<_Item>(
      items: [a, b],
      meta: PaginationMeta(total: 2, page: 1, limit: 20, totalPages: 1),
    ),
    act: (bloc) => bloc.add(const CrudItemUpdated(_Item(1, 'Apricot'))),
    expect: () => [
      isA<CrudLoaded<_Item>>().having(
        (s) => s.items.map((e) => e.name).toList(),
        'names',
        ['Apricot', 'Banana'],
      ),
    ],
  );

  blocTest<CrudBloc<_Item, int, void>, CrudState<_Item>>(
    'delete optimistically removes the item on success',
    setUp: () => when(() => repo.delete(any()))
        .thenAnswer((_) async => const Right(unit)),
    build: build,
    seed: () => const CrudLoaded<_Item>(
      items: [a, b],
      meta: PaginationMeta(total: 2, page: 1, limit: 20, totalPages: 1),
    ),
    act: (bloc) => bloc.add(const CrudItemDeleted(a)),
    expect: () => [
      isA<CrudLoaded<_Item>>().having((s) => s.items, 'items', [b]),
    ],
  );

  test('delete failure reports on mutationFailures and restores the list',
      () async {
    when(() => repo.list(any()))
        .thenAnswer((_) async => Right(_page([a, b], total: 2)));
    when(() => repo.delete(any()))
        .thenAnswer((_) async => const Left(Failure.server('boom')));

    final bloc = build();
    final failures = <Failure>[];
    final sub = bloc.mutationFailures.listen(failures.add);

    // Drive the bloc into a loaded state through a real load.
    bloc.add(const CrudLoadRequested());
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(bloc.state, isA<CrudLoaded<_Item>>());

    // Optimistic remove → delete fails → refresh restores server truth.
    bloc.add(const CrudItemDeleted(a));
    await Future<void>.delayed(const Duration(milliseconds: 60));

    expect(failures, [const Failure.server('boom')]);
    final state = bloc.state;
    expect(state, isA<CrudLoaded<_Item>>());
    expect((state as CrudLoaded<_Item>).items, [a, b]);

    await sub.cancel();
    await bloc.close();
  });
}
