import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/utils/extensions/format_x.dart';
import 'package:decimal/decimal.dart';

/// Export columns for a voucher list.
///
/// The five voucher lists (sales invoice, item-qty, ledger-amount,
/// debit/credit, stock) have no `EntityManifest` — they are driven by
/// `VoucherBlueprints`, not the manifest engine — but their list rows are the
/// same five fields in every case. Rather than five near-identical column lists,
/// this takes the accessors and builds one.
///
/// Note the `exportValue` on the money and date columns. `cellValue` renders
/// `AED 1,234.50` for the screen, and while `EntityExport` can read that back,
/// there is no reason to make it guess when the row is holding the `Decimal`
/// itself. Money and dates go into the spreadsheet from the source value.
List<FieldSpec<T>> voucherExportColumns<T>({
  required String Function(T item) displayNo,
  required DateTime? Function(T item) voucherDate,
  required String? Function(T item) status,
  required Decimal? Function(T item) total,
  String? Function(T item)? party,
  String partyLabel = 'Party',
}) => [
  FieldSpec<T>(
    key: 'displayNo',
    label: 'Number',
    type: FieldType.text,
    primary: true,
    cellValue: displayNo,
  ),
  FieldSpec<T>(
    key: 'voucherDate',
    label: 'Date',
    type: FieldType.dateTime,
    cellValue: (item) => voucherDate(item)?.toDayString() ?? '—',
    exportValue: voucherDate,
  ),
  FieldSpec<T>(
    key: 'status',
    label: 'Status',
    type: FieldType.text,
    cellValue: (item) => status(item) ?? '—',
  ),
  if (party != null)
    FieldSpec<T>(
      key: 'party',
      label: partyLabel,
      type: FieldType.text,
      cellValue: (item) => party(item) ?? '—',
    ),
  FieldSpec<T>(
    key: 'total',
    label: 'Total',
    type: FieldType.decimal,
    cellValue: (item) => total(item)?.toMoney() ?? '—',
    exportValue: total,
  ),
];
