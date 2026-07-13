import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/manifest/entity_manifest.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/organization_currency/currency_di.dart';
import 'package:algo_erp_front/features/organization_currency/domain/currency.dart';
import 'package:algo_erp_front/features/organization_currency_rate/domain/currency_rate.dart';
import 'package:decimal/decimal.dart';

final _currencyRepository = createCurrencyRepository(getIt<DioClient>());

final _isoDatePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

/// FX rates. Append-only: create + view; no PUT/DELETE on the backend.
final currencyRateManifest = EntityManifest<CurrencyRate>(
  id: 'currency-rate',
  label: 'Currency rate',
  rbacModule: 'CurrencyRate',
  resourcePath: '/organization/rates/history',
  listColumns: [
    FieldSpec<CurrencyRate>(
      key: 'rateDate',
      label: 'Date',
      type: FieldType.text,
      required: true,
      cellValue: (r) => r.rateDate,
    ),
    FieldSpec<CurrencyRate>(
      key: 'currencyId',
      label: 'Currency',
      type: FieldType.int,
      required: true,
      cellValue: (r) => r.currencyId.toString(),
    ),
    FieldSpec<CurrencyRate>(
      key: 'buyRate',
      label: 'Buy',
      type: FieldType.decimal,
      cellValue: (r) => r.buyRate.toString(),
    ),
    FieldSpec<CurrencyRate>(
      key: 'sellRate',
      label: 'Sell',
      type: FieldType.decimal,
      cellValue: (r) => r.sellRate.toString(),
    ),
    FieldSpec<CurrencyRate>(
      key: 'midRate',
      label: 'Mid',
      type: FieldType.decimal,
      cellValue: (r) => r.midRate?.toString() ?? '—',
    ),
  ],
  formFields: [
    FormFieldSpec<CurrencyRate>(
      key: 'currencyId',
      wireKey: 'currency_id',
      label: 'Currency',
      type: FieldType.fk,
      required: true,
      getValue: (r) => r.currencyId == 0 ? null : r.currencyId,
      setValue: (r, v) =>
          r.copyWith(currencyId: v == null ? 0 : (v as Currency).id),
      fkSearch: (query) async {
        final result = await _currencyRepository.list(PageQuery(search: query));
        return result.fold((_) => const [], (page) => page.items);
      },
      fkDisplayOf: (item) {
        final c = item as Currency;
        return '${c.isoCode} — ${c.name}';
      },
      fkResolveById: (id) async {
        final result = await _currencyRepository.getById(id as int);
        return result.fold((_) => null, (c) => c);
      },
    ),
    FormFieldSpec<CurrencyRate>(
      key: 'rateDate',
      wireKey: 'rate_date',
      label: 'Rate date',
      type: FieldType.text,
      required: true,
      hintText: 'YYYY-MM-DD',
      getValue: (r) => r.rateDate,
      setValue: (r, v) => r.copyWith(rateDate: v as String? ?? ''),
      validator: (v) {
        final text = v as String?;
        if (text == null || text.isEmpty) return null;
        return _isoDatePattern.hasMatch(text) ? null : 'Must be YYYY-MM-DD';
      },
    ),
    FormFieldSpec<CurrencyRate>(
      key: 'buyRate',
      wireKey: 'buy_rate',
      label: 'Buy rate',
      type: FieldType.decimal,
      required: true,
      getValue: (r) => r.buyRate,
      setValue: (r, v) => r.copyWith(buyRate: v as Decimal? ?? Decimal.zero),
    ),
    FormFieldSpec<CurrencyRate>(
      key: 'sellRate',
      wireKey: 'sell_rate',
      label: 'Sell rate',
      type: FieldType.decimal,
      required: true,
      getValue: (r) => r.sellRate,
      setValue: (r, v) => r.copyWith(sellRate: v as Decimal? ?? Decimal.zero),
    ),
    FormFieldSpec<CurrencyRate>(
      key: 'midRate',
      wireKey: 'mid_rate',
      label: 'Mid rate',
      type: FieldType.decimal,
      getValue: (r) => r.midRate,
      setValue: (r, v) => r.copyWith(midRate: v as Decimal?),
    ),
    FormFieldSpec<CurrencyRate>(
      key: 'financialYearId',
      wireKey: 'financial_year_id',
      label: 'Financial year id',
      type: FieldType.int,
      helperText: 'Optional FY id',
      getValue: (r) => r.financialYearId,
      setValue: (r, v) => r.copyWith(financialYearId: v as int?),
    ),
  ],
  emptyEntity: () => CurrencyRate(
    id: 0,
    currencyId: 0,
    rateDate: '',
    buyRate: Decimal.zero,
    sellRate: Decimal.zero,
  ),
  supportsUpdate: false,
  supportsDelete: false,
  hardDelete: true,
  emptyMessage: 'Post the first daily FX rate for multi-currency work.',
);
