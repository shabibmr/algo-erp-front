import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_bloc_scope.dart';
import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/safe_call.dart';
import 'package:algo_erp_front/core/network/paginated.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

/// The entity under test — a stand-in for any master.
class _Thing {
  const _Thing(this.id, this.name);
  final int id;
  final String name;
}

/// Counts list() calls so a test can prove a refetch actually happened.
class _FakeRepo implements Repository<_Thing, int> {
  int listCalls = 0;
  List<_Thing> rows = const [];

  @override
  Future<Result<Paginated<_Thing>>> list([PageQuery? query]) async {
    listCalls++;
    return Right(
      Paginated<_Thing>(
        items: rows,
        meta: PaginationMeta(
          total: rows.length,
          page: 1,
          limit: 20,
          totalPages: 1,
        ),
      ),
    );
  }

  @override
  Future<Result<_Thing>> create(_Thing entity) async => Right(entity);

  @override
  Future<Result<_Thing>> update(int id, _Thing entity) async => Right(entity);

  @override
  Future<Result<Unit>> delete(int id) async => const Right(unit);

  @override
  Future<Result<_Thing>> getById(int id) async =>
      Right(rows.firstWhere((t) => t.id == id));
}

void main() {
  group('CrudBlocScope', () {
    late _FakeRepo repo;
    var factoryCalls = 0;

    CrudBloc<_Thing, int, void> create() {
      factoryCalls++;
      return CrudBloc<_Thing, int, void>(repository: repo, idOf: (t) => t.id);
    }

    setUp(() {
      repo = _FakeRepo();
      factoryCalls = 0;
    });

    testWidgets('hands sibling subtrees the same bloc instance', (
      tester,
    ) async {
      // The whole point: a master's list and form are sibling routes. If they
      // do not resolve the identical bloc, a form can never tell a list that
      // its rows changed — which is the bug this scope exists to fix.
      CrudBloc<_Thing, int, void>? fromList;
      CrudBloc<_Thing, int, void>? fromForm;

      await tester.pumpWidget(
        MaterialApp(
          home: CrudBlocScope(
            child: Column(
              children: [
                Builder(
                  builder: (context) {
                    fromList = CrudBlocScope.of<_Thing, int, void>(
                      context,
                      'thing',
                      create,
                    );
                    return const SizedBox();
                  },
                ),
                Builder(
                  builder: (context) {
                    fromForm = CrudBlocScope.of<_Thing, int, void>(
                      context,
                      'thing',
                      create,
                    );
                    return const SizedBox();
                  },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(fromList, isNotNull);
      expect(
        identical(fromList, fromForm),
        isTrue,
        reason: 'list and form must share one bloc',
      );
      expect(factoryCalls, 1, reason: 'bloc is built once, then cached');
    });

    testWidgets('loads once on first resolve, and refetches on refresh', (
      tester,
    ) async {
      repo.rows = const [_Thing(1, 'B1')];
      late CrudBloc<_Thing, int, void> bloc;

      await tester.pumpWidget(
        MaterialApp(
          home: CrudBlocScope(
            child: Builder(
              builder: (context) {
                bloc = CrudBlocScope.of<_Thing, int, void>(
                  context,
                  'thing',
                  create,
                );
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The scope fires the initial load itself, so pages no longer do.
      expect(repo.listCalls, 1);
      expect((bloc.state as CrudLoaded<_Thing>).items.length, 1);

      // Simulate a form saving a second row directly through the repository,
      // then notifying the shared bloc the way MasterFormSurface's onSaved
      // does.
      repo.rows = const [_Thing(1, 'B1'), _Thing(2, 'B2')];
      bloc.add(const CrudRefreshRequested());
      await tester.pumpAndSettle();

      expect(repo.listCalls, 2, reason: 'refresh must refetch from the server');
      final items = (bloc.state as CrudLoaded<_Thing>).items;
      expect(items.length, 2, reason: 'the newly created row must appear');
      expect(items.map((t) => t.name), containsAll(<String>['B1', 'B2']));
    });
  });
}
