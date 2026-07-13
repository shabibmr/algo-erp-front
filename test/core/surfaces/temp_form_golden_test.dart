import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/manifest/entity_manifest.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/core/theme/app_theme.dart';
import 'package:algo_erp_front/l10n/gen/app_localizations.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

class _Item {
  const _Item({
    this.id = 0,
    this.code = '',
    this.name = '',
    this.active = true,
  });
  final int id;
  final String code;
  final String name;
  final bool active;
  _Item copyWith({String? code, String? name, bool? active}) => _Item(
    id: id,
    code: code ?? this.code,
    name: name ?? this.name,
    active: active ?? this.active,
  );
}

class _MockRepo extends Mock implements Repository<_Item, int> {}

class _AllowAll implements PermissionService {
  const _AllowAll();
  @override
  bool can(String module, PermissionAction action) => true;
}

final _manifest = EntityManifest<_Item>(
  id: 'item',
  label: 'Item',
  rbacModule: 'Inventory',
  resourcePath: '/inventory/item',
  eyebrow: 'Inventory · Masters',
  listColumns: [
    FieldSpec<_Item>(
      key: 'name',
      label: 'Name',
      type: FieldType.text,
      cellValue: (i) => i.name,
    ),
  ],
  formFields: [
    FormFieldSpec<_Item>(
      key: 'code',
      label: 'Item code',
      type: FieldType.text,
      required: true,
      half: true,
      section: 'Identity',
      getValue: (i) => i.code,
      setValue: (i, v) => i.copyWith(code: v as String?),
    ),
    FormFieldSpec<_Item>(
      key: 'name',
      label: 'Item name',
      type: FieldType.text,
      required: true,
      half: true,
      section: 'Identity',
      getValue: (i) => i.name,
      setValue: (i, v) => i.copyWith(name: v as String?),
    ),
    FormFieldSpec<_Item>(
      key: 'reorder',
      label: 'Reorder level',
      type: FieldType.decimal,
      section: 'Stock',
      helperText: 'Raise a purchase request below this quantity.',
      getValue: (i) => Decimal.zero,
      setValue: (i, v) => i,
    ),
    FormFieldSpec<_Item>(
      key: 'active',
      label: 'Active',
      type: FieldType.bool,
      section: 'Stock',
      getValue: (i) => i.active,
      setValue: (i, v) => i.copyWith(active: v as bool?),
    ),
  ],
  emptyEntity: _Item.new,
);

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = true;
    registerFallbackValue(const _Item());
    getIt.registerSingleton<PermissionService>(const _AllowAll());
  });
  tearDownAll(getIt.reset);

  testWidgets('index card form golden', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1280, 800);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          backgroundColor: AppTheme.light.scaffoldBackgroundColor,
          body: RepositoryProvider<Repository<_Item, int>>(
            create: (_) => _MockRepo(),
            child: AdaptiveLayout(
              child: MasterFormSurface<_Item, int>(
                manifest: _manifest,
                mode: FormMode.create,
                idOf: (i) => i.id,
                onCancel: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('index_card_form.png'),
    );
  });
}
