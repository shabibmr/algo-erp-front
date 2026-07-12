import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/bloc/detail_bloc.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/manifest/entity_manifest.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/core/theme/app_theme.dart';
import 'package:algo_erp_front/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

/// A throwaway entity — same discipline as `master_list_surface_test.dart`.
class _Widget {
  const _Widget({required this.id, required this.name});
  final int id;
  final String name;
  _Widget copyWith({String? name}) => _Widget(id: id, name: name ?? this.name);
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
  formFields: [
    FormFieldSpec<_Widget>(
      key: 'name',
      wireKey: 'Widget_Name',
      label: 'Name',
      type: FieldType.text,
      required: true,
      getValue: (w) => w.name,
      setValue: (w, v) => w.copyWith(name: v as String?),
    ),
  ],
  emptyEntity: () => const _Widget(id: 0, name: ''),
  hardDelete: true,
);

/// Production shape for ItemProperty: create/list/delete, no PUT.
final _noUpdateManifest = EntityManifest<_Widget>(
  id: 'widget-no-update',
  label: 'Widget',
  rbacModule: 'Inventory',
  resourcePath: '/widgets',
  listColumns: _manifest.listColumns,
  formFields: _manifest.formFields,
  emptyEntity: () => const _Widget(id: 0, name: ''),
  supportsUpdate: false,
  // supportsDelete defaults true — matches ItemProperty.
);

/// Production shape for FinancialYear: full create/update, no DELETE.
final _noDeleteManifest = EntityManifest<_Widget>(
  id: 'widget-no-delete',
  label: 'Widget',
  rbacModule: 'Inventory',
  resourcePath: '/widgets',
  listColumns: _manifest.listColumns,
  formFields: _manifest.formFields,
  emptyEntity: () => const _Widget(id: 0, name: ''),
  supportsDelete: false,
);

final _createOnlyManifest = EntityManifest<_Widget>(
  id: 'widget-create-only',
  label: 'Widget',
  rbacModule: 'Inventory',
  resourcePath: '/widgets',
  listColumns: _manifest.listColumns,
  formFields: _manifest.formFields,
  emptyEntity: () => const _Widget(id: 0, name: ''),
  supportsUpdate: false,
  supportsDelete: false,
);

const _readOnlyBanner = 'Widget records are read-only.';

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
    registerFallbackValue(const _Widget(id: 0, name: ''));
    getIt.registerSingleton<PermissionService>(
      const _AllowAllPermissionService(),
    );
  });

  tearDownAll(getIt.reset);

  setUp(() => repo = _MockRepo());

  Widget wrap(Widget child, {DetailBloc<_Widget, int>? detailBloc}) {
    return MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: RepositoryProvider<Repository<_Widget, int>>(
          create: (_) => repo,
          child: detailBloc == null
              ? child
              : BlocProvider<DetailBloc<_Widget, int>>(
                  create: (_) => detailBloc,
                  child: child,
                ),
        ),
      ),
    );
  }

  testWidgets('create mode submits the entered value', (tester) async {
    _Widget? saved;
    when(() => repo.create(any())).thenAnswer(
      (invocation) async =>
          Right(invocation.positionalArguments.first as _Widget),
    );

    await tester.pumpWidget(
      wrap(
        MasterFormSurface<_Widget, int>(
          manifest: _manifest,
          mode: FormMode.create,
          idOf: (w) => w.id,
          onSaved: (w) => saved = w,
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'Alpha');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    final captured =
        verify(() => repo.create(captureAny())).captured.single as _Widget;
    expect(captured.name, 'Alpha');
    expect(saved?.name, 'Alpha');
  });

  testWidgets('server validation error renders under the matching field', (
    tester,
  ) async {
    when(() => repo.create(any())).thenAnswer(
      (_) async => const Left(
        Failure.validation('Invalid', [
          ValidationFieldError(field: 'body.Widget_Name', message: 'Taken'),
        ]),
      ),
    );

    await tester.pumpWidget(
      wrap(
        MasterFormSurface<_Widget, int>(
          manifest: _manifest,
          mode: FormMode.create,
          idOf: (w) => w.id,
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'Alpha');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text('Taken'), findsOneWidget);
  });

  testWidgets('edit mode seeds the form from DetailBloc', (tester) async {
    when(
      () => repo.getById(any()),
    ).thenAnswer((_) async => const Right(_Widget(id: 1, name: 'Existing')));

    await tester.pumpWidget(
      wrap(
        MasterFormSurface<_Widget, int>(
          manifest: _manifest,
          mode: FormMode.edit,
          idOf: (w) => w.id,
        ),
        detailBloc: DetailBloc<_Widget, int>(repository: repo, id: 1)
          ..add(const DetailLoadRequested()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Existing'), findsOneWidget);
  });

  testWidgets('edit mode delete confirms then calls onDeleted', (tester) async {
    when(
      () => repo.getById(any()),
    ).thenAnswer((_) async => const Right(_Widget(id: 1, name: 'Existing')));
    when(() => repo.delete(any())).thenAnswer((_) async => const Right(unit));

    var deleted = false;
    await tester.pumpWidget(
      wrap(
        MasterFormSurface<_Widget, int>(
          manifest: _manifest,
          mode: FormMode.edit,
          idOf: (w) => w.id,
          onDeleted: () => deleted = true,
        ),
        detailBloc: DetailBloc<_Widget, int>(repository: repo, id: 1)
          ..add(const DetailLoadRequested()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    // Not pumpAndSettle: after DetailDeleted, MasterFormSurface renders
    // ViewLoading's indeterminate CircularProgressIndicator, which animates
    // forever — a real caller navigates away via onDeleted before that
    // matters, but this test has no router to do that.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    verify(() => repo.delete(1)).called(1);
    expect(deleted, isTrue);
  });

  testWidgets(
    'supportsUpdate: false, supportsDelete: true — read-only edit, Delete kept',
    (tester) async {
      // ItemProperty shape: backend has DELETE, no PUT.
      when(
        () => repo.getById(any()),
      ).thenAnswer((_) async => const Right(_Widget(id: 1, name: 'Existing')));

      await tester.pumpWidget(
        wrap(
          MasterFormSurface<_Widget, int>(
            manifest: _noUpdateManifest,
            mode: FormMode.edit,
            idOf: (w) => w.id,
          ),
          detailBloc: DetailBloc<_Widget, int>(repository: repo, id: 1)
            ..add(const DetailLoadRequested()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(_readOnlyBanner), findsOneWidget);
      expect(find.text('Save'), findsNothing);
      expect(find.text('Delete'), findsOneWidget);
      final field = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(field.enabled, isFalse);
    },
  );

  testWidgets(
    'supportsUpdate: true, supportsDelete: false — Save kept, Delete hidden',
    (tester) async {
      // FinancialYear shape: backend has PUT, no DELETE.
      when(
        () => repo.getById(any()),
      ).thenAnswer((_) async => const Right(_Widget(id: 1, name: 'Existing')));

      await tester.pumpWidget(
        wrap(
          MasterFormSurface<_Widget, int>(
            manifest: _noDeleteManifest,
            mode: FormMode.edit,
            idOf: (w) => w.id,
          ),
          detailBloc: DetailBloc<_Widget, int>(repository: repo, id: 1)
            ..add(const DetailLoadRequested()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(_readOnlyBanner), findsNothing);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Delete'), findsNothing);
      final field = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(field.enabled, isTrue);
    },
  );

  testWidgets(
    'supportsUpdate: false, supportsDelete: false — no Save/Delete, banner',
    (tester) async {
      when(
        () => repo.getById(any()),
      ).thenAnswer((_) async => const Right(_Widget(id: 1, name: 'Existing')));

      await tester.pumpWidget(
        wrap(
          MasterFormSurface<_Widget, int>(
            manifest: _createOnlyManifest,
            mode: FormMode.edit,
            idOf: (w) => w.id,
          ),
          detailBloc: DetailBloc<_Widget, int>(repository: repo, id: 1)
            ..add(const DetailLoadRequested()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(_readOnlyBanner), findsOneWidget);
      expect(find.text('Save'), findsNothing);
      expect(find.text('Delete'), findsNothing);
      final field = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(field.enabled, isFalse);
    },
  );

  testWidgets('supportsUpdate: false still allows create mode submit', (
    tester,
  ) async {
    // Capability flags must not affect create — only edit mode.
    _Widget? saved;
    when(() => repo.create(any())).thenAnswer(
      (invocation) async =>
          Right(invocation.positionalArguments.first as _Widget),
    );

    await tester.pumpWidget(
      wrap(
        MasterFormSurface<_Widget, int>(
          manifest: _noUpdateManifest,
          mode: FormMode.create,
          idOf: (w) => w.id,
          onSaved: (w) => saved = w,
        ),
      ),
    );

    expect(find.text(_readOnlyBanner), findsNothing);
    expect(find.text('Create'), findsOneWidget);
    expect(find.text('Save'), findsNothing);

    await tester.enterText(find.byType(TextFormField), 'Alpha');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    final captured =
        verify(() => repo.create(captureAny())).captured.single as _Widget;
    expect(captured.name, 'Alpha');
    expect(saved?.name, 'Alpha');
  });
}
