import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/manifest/entity_manifest.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/network/paginated.dart';
import 'package:algo_erp_front/core/surfaces/master_list_surface.dart';
import 'package:algo_erp_front/core/theme/app_theme.dart';
import 'package:algo_erp_front/core/widgets/filters/filter_bar.dart';
import 'package:algo_erp_front/core/widgets/layout/page_header.dart';
import 'package:algo_erp_front/core/widgets/shortcuts/create_new_shortcuts.dart';
import 'package:algo_erp_front/core/widgets/states/ledger_skeleton.dart';
import 'package:algo_erp_front/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

/// A throwaway entity — proves `MasterListSurface` needs no knowledge of any
/// real model, same discipline as `crud_bloc_test.dart`.
class _Widget {
  const _Widget(this.id, this.name);
  final int id;
  final String name;
}

class _MockRepo extends Mock implements Repository<_Widget, int> {}

final _manifest = EntityManifest<_Widget>(
  id: 'widget',
  label: 'Widget',
  rbacModule: 'Inventory',
  resourcePath: '/widgets',
  listColumns: [
    FieldSpec<_Widget>(
      key: 'name',
      label: 'Name',
      type: FieldType.text,
      cellValue: (w) => w.name,
    ),
  ],
);

Paginated<_Widget> _page(
  List<_Widget> items, {
  required int total,
  int page = 1,
  int limit = 20,
}) {
  return Paginated<_Widget>(
    items: items,
    meta: PaginationMeta(
      total: total,
      page: page,
      limit: limit,
      totalPages: (total / limit).ceil(),
    ),
  );
}

/// These tests exercise the surface, not RBAC — so permit everything and let
/// `permission_service_test.dart` cover the real matrix.
class _AllowAllPermissionService implements PermissionService {
  const _AllowAllPermissionService();

  @override
  bool can(String module, PermissionAction action) => true;
}

void main() {
  late _MockRepo repo;

  setUpAll(() {
    registerFallbackValue(const PageQuery());
    getIt.registerSingleton<PermissionService>(
      const _AllowAllPermissionService(),
    );
  });

  tearDownAll(getIt.reset);

  setUp(() => repo = _MockRepo());

  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BlocProvider<CrudBloc<_Widget, int, void>>(
          create: (_) =>
              CrudBloc<_Widget, int, void>(repository: repo, idOf: (w) => w.id)
                ..add(const CrudLoadRequested()),
          child: child,
        ),
      ),
    );
  }

  testWidgets('renders loading then the list once data arrives', (
    tester,
  ) async {
    when(() => repo.list(any())).thenAnswer(
      (_) async => Right(_page([const _Widget(1, 'Alpha')], total: 1)),
    );

    await tester.pumpWidget(
      wrap(MasterListSurface<_Widget>(manifest: _manifest, idOf: (w) => w.id)),
    );
    // The ledger holds its own shape while loading rather than collapsing to a
    // spinner in an empty sheet.
    expect(find.byType(LedgerSkeleton), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(LedgerSkeleton), findsNothing);
    expect(find.text('Alpha'), findsOneWidget);
  });

  testWidgets('the create action sits on the header, not in the toolbar', (
    tester,
  ) async {
    when(() => repo.list(any())).thenAnswer(
      (_) async => Right(_page([const _Widget(1, 'Alpha')], total: 1)),
    );

    await tester.pumpWidget(
      wrap(
        MasterListSurface<_Widget>(
          manifest: _manifest,
          idOf: (w) => w.id,
          onCreate: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Page action lives on the PageHeader; the sheet's FilterBar only carries
    // controls that act on the sheet's contents.
    expect(
      find.descendant(
        of: find.byType(PageHeader),
        matching: find.widgetWithText(FilledButton, 'New widget'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(FilterBar),
        matching: find.byType(FilledButton),
      ),
      findsNothing,
    );
    expect(find.text('1 record'), findsOneWidget);
  });

  testWidgets('an empty list invites the first record', (tester) async {
    when(
      () => repo.list(any()),
    ).thenAnswer((_) async => Right(_page([], total: 0)));

    await tester.pumpWidget(
      wrap(
        MasterListSurface<_Widget>(
          manifest: _manifest,
          idOf: (w) => w.id,
          onCreate: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No widget yet.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'New widget'), findsNWidgets(2));
  });

  testWidgets('renders the error state with retry on failure', (tester) async {
    when(
      () => repo.list(any()),
    ).thenAnswer((_) async => const Left(Failure.network('offline')));

    await tester.pumpWidget(
      wrap(MasterListSurface<_Widget>(manifest: _manifest, idOf: (w) => w.id)),
    );
    await tester.pumpAndSettle();

    expect(find.text('offline'), findsOneWidget);
  });

  testWidgets('typing in the search field dispatches CrudSearchChanged', (
    tester,
  ) async {
    when(() => repo.list(any())).thenAnswer(
      (_) async => Right(_page([const _Widget(1, 'Alpha')], total: 1)),
    );

    await tester.pumpWidget(
      wrap(MasterListSurface<_Widget>(manifest: _manifest, idOf: (w) => w.id)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'alp');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    final query =
        verify(() => repo.list(captureAny())).captured.last as PageQuery;
    expect(query.search, 'alp');
  });

  testWidgets('Ctrl+N invokes onCreate', (tester) async {
    when(() => repo.list(any())).thenAnswer(
      (_) async => Right(_page([const _Widget(1, 'Alpha')], total: 1)),
    );

    var createCount = 0;
    await tester.pumpWidget(
      wrap(
        MasterListSurface<_Widget>(
          manifest: _manifest,
          idOf: (w) => w.id,
          onCreate: () => createCount++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // CreateNewShortcuts autofocuses so Ctrl+N works without a click.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(createCount, 1);
    expect(find.byType(CreateNewShortcuts), findsOneWidget);
  });
}
