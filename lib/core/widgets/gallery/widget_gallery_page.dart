import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/theme/app_theme.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/widgets/async_state_view.dart';
import 'package:algo_erp_front/core/widgets/chips/status_chip.dart';
import 'package:algo_erp_front/core/widgets/data_display/adaptive_entity_list.dart';
import 'package:algo_erp_front/core/widgets/data_display/line_item_grid.dart';
import 'package:algo_erp_front/core/widgets/dialogs/confirm_dialog.dart';
import 'package:algo_erp_front/core/widgets/fields/app_currency_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_date_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_decimal_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_dropdown_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_number_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_switch_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_text_field.dart';
import 'package:algo_erp_front/core/widgets/filters/filter_bar.dart';
import 'package:algo_erp_front/core/widgets/lookup/fk_lookup_field.dart';
import 'package:algo_erp_front/core/widgets/view_state.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

/// A demo "brand" row used purely to showcase [AdaptiveEntityList] and
/// [FkLookupField] without depending on any real feature entity.
@immutable
class _DemoBrand {
  const _DemoBrand(this.id, this.name, {required this.active});

  final int id;
  final String name;
  final bool active;
}

/// A demo voucher line used to showcase [LineItemGrid].
class _DemoLine {
  _DemoLine({required this.item, required this.qty});

  String item;
  Decimal qty;
}

const _demoBrands = [
  _DemoBrand(1, 'Acme Foods', active: true),
  _DemoBrand(2, 'Northwind Traders', active: true),
  _DemoBrand(3, 'Contoso Retail', active: false),
];

/// Self-contained showcase of every widget in `core/widgets/`, rendered
/// across light/dark theme and LTR/RTL direction via the toolbar toggles —
/// no bloc, no DI, no navigation dependency, so it can be dropped behind a
/// dev-only route (`/widget-gallery`) without wiring anything else up.
class WidgetGalleryPage extends StatefulWidget {
  const WidgetGalleryPage({super.key});

  @override
  State<WidgetGalleryPage> createState() => _WidgetGalleryPageState();
}

class _WidgetGalleryPageState extends State<WidgetGalleryPage> {
  Brightness _brightness = Brightness.light;
  TextDirection _direction = TextDirection.ltr;

  @override
  Widget build(BuildContext context) {
    final theme =
        _brightness == Brightness.light ? AppTheme.light : AppTheme.dark;
    return Theme(
      data: theme,
      child: Directionality(
        textDirection: _direction,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Widget gallery'),
            actions: [
              IconButton(
                tooltip: 'Toggle direction',
                icon: const Icon(Icons.format_textdirection_r_to_l),
                onPressed: () => setState(() {
                  _direction = _direction == TextDirection.ltr
                      ? TextDirection.rtl
                      : TextDirection.ltr;
                }),
              ),
              IconButton(
                tooltip: 'Toggle theme mode',
                icon: const Icon(Icons.brightness_6),
                onPressed: () => setState(() {
                  _brightness = _brightness == Brightness.light
                      ? Brightness.dark
                      : Brightness.light;
                }),
              ),
            ],
          ),
          body: const _GalleryBody(),
        ),
      ),
    );
  }
}

class _GalleryBody extends StatefulWidget {
  const _GalleryBody();

  @override
  State<_GalleryBody> createState() => _GalleryBodyState();
}

class _GalleryBodyState extends State<_GalleryBody> {
  ViewState<String> _asyncDemoState = const ViewData(
    'Loaded content goes here',
  );
  DateTime? _date;
  bool _switchValue = true;
  String? _dropdownValue = 'Retail';
  _DemoBrand? _pickedBrand;
  List<_DemoLine> _lines = [
    _DemoLine(item: 'Widget A', qty: Decimal.fromInt(2)),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return ListView(
      padding: EdgeInsets.all(tokens.spacing.lg),
      children: [
        const _Section('AsyncStateView'),
        SegmentedButton<ViewState<String>>(
          segments: const [
            ButtonSegment(value: ViewLoading<String>(), label: Text('Loading')),
            ButtonSegment(value: ViewEmpty<String>(), label: Text('Empty')),
            ButtonSegment(
              value: ViewData('Loaded content goes here'),
              label: Text('Data'),
            ),
          ],
          selected: {_asyncDemoState},
          onSelectionChanged: (s) => setState(() => _asyncDemoState = s.first),
        ),
        SizedBox(height: tokens.spacing.sm),
        SizedBox(
          height: 160,
          child: AsyncStateView<String>(
            state: _asyncDemoState,
            onRetry: () {},
            builder: (context, data) => Center(child: Text(data)),
          ),
        ),
        SizedBox(height: tokens.spacing.sm),
        SizedBox(
          height: 160,
          child: AsyncStateView<String>(
            state: const ViewError<String>(
              Failure.network('No internet connection'),
            ),
            onRetry: () {},
            builder: (context, data) => Text(data),
          ),
        ),
        SizedBox(height: tokens.spacing.lg),

        const _Section('Status chips'),
        Wrap(
          spacing: tokens.spacing.sm,
          runSpacing: tokens.spacing.sm,
          children: const [
            StatusChip(status: EntityStatus.draft, label: 'Draft'),
            StatusChip(status: EntityStatus.approved, label: 'Approved'),
            StatusChip(status: EntityStatus.posted, label: 'Posted'),
            StatusChip(status: EntityStatus.cancelled, label: 'Cancelled'),
            StatusChip(status: EntityStatus.rejected, label: 'Rejected'),
            StatusChip(status: EntityStatus.pendingSync, label: 'Pending sync'),
          ],
        ),
        SizedBox(height: tokens.spacing.lg),

        const _Section('Confirm dialog'),
        Wrap(
          spacing: tokens.spacing.sm,
          children: [
            OutlinedButton(
              onPressed: () async {
                final ok = await showConfirmDialog(
                  context,
                  title: 'Discard changes?',
                  message: 'Unsaved edits will be lost.',
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Confirmed: $ok')),
                  );
                }
              },
              child: const Text('Show confirm dialog'),
            ),
            OutlinedButton(
              onPressed: () async {
                final ok = await showConfirmDialog(
                  context,
                  title: 'Delete brand?',
                  message: 'This cannot be undone.',
                  confirmLabel: 'Delete',
                  destructive: true,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Confirmed: $ok')),
                  );
                }
              },
              child: const Text('Show destructive confirm dialog'),
            ),
          ],
        ),
        SizedBox(height: tokens.spacing.lg),

        const _Section('Form fields'),
        const AppTextField(label: 'Brand name'),
        SizedBox(height: tokens.spacing.sm),
        const AppNumberField(label: 'Reorder level', initialValue: 10),
        SizedBox(height: tokens.spacing.sm),
        AppDecimalField(label: 'Quantity', initialValue: Decimal.fromInt(5)),
        SizedBox(height: tokens.spacing.sm),
        AppCurrencyField(
          label: 'Unit price',
          initialValue: Decimal.parse('19.99'),
        ),
        SizedBox(height: tokens.spacing.sm),
        AppDateField(
          label: 'Voucher date',
          value: _date,
          onChanged: (d) => setState(() => _date = d),
        ),
        SizedBox(height: tokens.spacing.sm),
        AppSwitchField(
          label: 'Active',
          value: _switchValue,
          onChanged: (v) => setState(() => _switchValue = v),
        ),
        SizedBox(height: tokens.spacing.sm),
        AppDropdownField<String>(
          label: 'Category',
          value: _dropdownValue,
          items: const ['Retail', 'Wholesale', 'Manufacturing'],
          labelOf: (v) => v,
          onChanged: (v) => setState(() => _dropdownValue = v),
        ),
        SizedBox(height: tokens.spacing.lg),

        const _Section('FK lookup field'),
        FkLookupField<_DemoBrand>(
          label: 'Brand',
          value: _pickedBrand,
          displayOf: (b) => b.name,
          loader: (query) async {
            await Future<void>.delayed(const Duration(milliseconds: 200));
            final q = query.toLowerCase();
            return _demoBrands
                .where((b) => b.name.toLowerCase().contains(q))
                .toList();
          },
          onSelected: (b) => setState(() => _pickedBrand = b),
        ),
        SizedBox(height: tokens.spacing.lg),

        const _Section('Filter bar'),
        FilterBar(
          searchHint: 'Search brands...',
          onSearchChanged: (_) {},
          filters: const [
            FilterChipData(key: 'active', label: 'Active', selected: true),
            FilterChipData(key: 'inactive', label: 'Inactive'),
          ],
          onFilterToggled: (_) {},
          trailing: [FilledButton(onPressed: () {}, child: const Text('New'))],
        ),
        SizedBox(height: tokens.spacing.lg),

        const _Section(
          'Adaptive entity list (resize window to see cards ↔ table)',
        ),
        AdaptiveEntityList<_DemoBrand>(
          items: _demoBrands,
          keyOf: (b) => b.id,
          columns: [
            EntityColumn(label: 'Name', cellBuilder: (_, b) => Text(b.name)),
            EntityColumn(
              label: 'Status',
              cellBuilder: (_, b) => StatusChip(
                status: b.active ? EntityStatus.posted : EntityStatus.cancelled,
                label: b.active ? 'Active' : 'Inactive',
              ),
            ),
          ],
          cardBuilder: (_, b) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(b.name),
            trailing: StatusChip(
              status: b.active ? EntityStatus.posted : EntityStatus.cancelled,
              label: b.active ? 'Active' : 'Inactive',
            ),
          ),
        ),
        SizedBox(height: tokens.spacing.lg),

        const _Section('Line item grid'),
        LineItemGrid<_DemoLine>(
          rows: _lines,
          newRow: () => _DemoLine(item: '', qty: Decimal.zero),
          columns: [
            LineItemColumn(
              flex: 2,
              label: 'Item',
              cellBuilder: (context, row, i) => AppTextField(
                label: 'Item',
                initialValue: row.item,
                onChanged: (v) => row.item = v,
              ),
            ),
            LineItemColumn(
              label: 'Qty',
              cellBuilder: (context, row, i) => AppDecimalField(
                label: 'Qty',
                initialValue: row.qty,
                onChanged: (v) => row.qty = v ?? Decimal.zero,
              ),
            ),
          ],
          onChanged: (updated) => setState(() => _lines = updated),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
