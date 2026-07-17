import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/theme/app_theme.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/widgets/async_state_view.dart';
import 'package:algo_erp_front/core/widgets/charts/ranked_bar_chart.dart';
import 'package:algo_erp_front/core/widgets/charts/share_donut_chart.dart';
import 'package:algo_erp_front/core/widgets/charts/signed_bar_chart.dart';
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
import 'package:algo_erp_front/core/widgets/layout/page_header.dart';
import 'package:algo_erp_front/core/widgets/layout/work_sheet.dart';
import 'package:algo_erp_front/core/widgets/lookup/fk_lookup_field.dart';
import 'package:algo_erp_front/core/widgets/states/ledger_skeleton.dart';
import 'package:algo_erp_front/core/widgets/view_state.dart';
import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

class _GalleryChromeState extends Equatable {
  const _GalleryChromeState({
    this.brightness = Brightness.light,
    this.direction = TextDirection.ltr,
  });

  final Brightness brightness;
  final TextDirection direction;

  _GalleryChromeState copyWith({
    Brightness? brightness,
    TextDirection? direction,
  }) {
    return _GalleryChromeState(
      brightness: brightness ?? this.brightness,
      direction: direction ?? this.direction,
    );
  }

  @override
  List<Object?> get props => [brightness, direction];
}

class _GalleryChromeCubit extends Cubit<_GalleryChromeState> {
  _GalleryChromeCubit() : super(const _GalleryChromeState());

  void toggleDirection() => emit(
    state.copyWith(
      direction: state.direction == TextDirection.ltr
          ? TextDirection.rtl
          : TextDirection.ltr,
    ),
  );

  void toggleBrightness() => emit(
    state.copyWith(
      brightness: state.brightness == Brightness.light
          ? Brightness.dark
          : Brightness.light,
    ),
  );
}

class _GalleryDemoState extends Equatable {
  _GalleryDemoState({
    this.asyncDemoState = const ViewData('Loaded content goes here'),
    this.date,
    this.switchValue = true,
    this.dropdownValue = 'Retail',
    this.pickedBrand,
    List<_DemoLine>? lines,
  }) : lines = lines ?? [_DemoLine(item: 'Widget A', qty: Decimal.fromInt(2))];

  final ViewState<String> asyncDemoState;
  final DateTime? date;
  final bool switchValue;
  final String? dropdownValue;
  final _DemoBrand? pickedBrand;
  final List<_DemoLine> lines;

  _GalleryDemoState copyWith({
    ViewState<String>? asyncDemoState,
    DateTime? Function()? date,
    bool? switchValue,
    String? Function()? dropdownValue,
    _DemoBrand? Function()? pickedBrand,
    List<_DemoLine>? lines,
  }) {
    return _GalleryDemoState(
      asyncDemoState: asyncDemoState ?? this.asyncDemoState,
      date: date != null ? date() : this.date,
      switchValue: switchValue ?? this.switchValue,
      dropdownValue: dropdownValue != null
          ? dropdownValue()
          : this.dropdownValue,
      pickedBrand: pickedBrand != null ? pickedBrand() : this.pickedBrand,
      lines: lines ?? this.lines,
    );
  }

  @override
  List<Object?> get props => [
    asyncDemoState,
    date,
    switchValue,
    dropdownValue,
    pickedBrand,
    lines,
  ];
}

class _GalleryDemoCubit extends Cubit<_GalleryDemoState> {
  _GalleryDemoCubit() : super(_GalleryDemoState());

  void setAsync(ViewState<String> s) => emit(state.copyWith(asyncDemoState: s));
  void setDate(DateTime? d) => emit(state.copyWith(date: () => d));
  void setSwitch(bool v) => emit(state.copyWith(switchValue: v));
  void setDropdown(String? v) => emit(state.copyWith(dropdownValue: () => v));
  void setBrand(_DemoBrand? b) => emit(state.copyWith(pickedBrand: () => b));
  void setLines(List<_DemoLine> lines) => emit(state.copyWith(lines: lines));
}

/// Self-contained showcase of every widget in `core/widgets/`, rendered
/// across light/dark theme and LTR/RTL direction via the toolbar toggles —
/// no DI, no navigation dependency, so it can be dropped behind a
/// dev-only route (`/widget-gallery`) without wiring anything else up.
class WidgetGalleryPage extends StatelessWidget {
  const WidgetGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => _GalleryChromeCubit()),
        BlocProvider(create: (_) => _GalleryDemoCubit()),
      ],
      child: BlocBuilder<_GalleryChromeCubit, _GalleryChromeState>(
        builder: (context, chrome) {
          final theme = chrome.brightness == Brightness.light
              ? AppTheme.light
              : AppTheme.dark;
          return Theme(
            data: theme,
            child: Directionality(
              textDirection: chrome.direction,
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('Widget gallery'),
                  actions: [
                    IconButton(
                      tooltip: 'Toggle direction',
                      icon: const Icon(Icons.format_textdirection_r_to_l),
                      onPressed: context
                          .read<_GalleryChromeCubit>()
                          .toggleDirection,
                    ),
                    IconButton(
                      tooltip: 'Toggle theme mode',
                      icon: const Icon(Icons.brightness_6),
                      onPressed: context
                          .read<_GalleryChromeCubit>()
                          .toggleBrightness,
                    ),
                  ],
                ),
                body: const _GalleryBody(),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GalleryBody extends StatelessWidget {
  const _GalleryBody();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return BlocBuilder<_GalleryDemoCubit, _GalleryDemoState>(
      builder: (context, demo) {
        final cubit = context.read<_GalleryDemoCubit>();
        return ListView(
          padding: EdgeInsets.all(tokens.spacing.lg),
          children: [
            const _Section('AsyncStateView'),
            SegmentedButton<ViewState<String>>(
              segments: const [
                ButtonSegment(
                  value: ViewLoading<String>(),
                  label: Text('Loading'),
                ),
                ButtonSegment(value: ViewEmpty<String>(), label: Text('Empty')),
                ButtonSegment(
                  value: ViewData('Loaded content goes here'),
                  label: Text('Data'),
                ),
              ],
              selected: {demo.asyncDemoState},
              onSelectionChanged: (s) => cubit.setAsync(s.first),
            ),
            SizedBox(height: tokens.spacing.sm),
            SizedBox(
              height: 160,
              child: AsyncStateView<String>(
                state: demo.asyncDemoState,
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
                StatusChip(
                  status: EntityStatus.pendingSync,
                  label: 'Pending sync',
                ),
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
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Confirmed: $ok')));
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
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Confirmed: $ok')));
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
            const AppNumberField(label: 'Reorder level', value: 10),
            SizedBox(height: tokens.spacing.sm),
            AppDecimalField(label: 'Quantity', value: Decimal.fromInt(5)),
            SizedBox(height: tokens.spacing.sm),
            AppCurrencyField(
              label: 'Unit price',
              value: Decimal.parse('19.99'),
            ),
            SizedBox(height: tokens.spacing.sm),
            AppDateField(
              label: 'Voucher date',
              value: demo.date,
              onChanged: cubit.setDate,
            ),
            SizedBox(height: tokens.spacing.sm),
            AppSwitchField(
              label: 'Active',
              value: demo.switchValue,
              onChanged: cubit.setSwitch,
            ),
            SizedBox(height: tokens.spacing.sm),
            AppDropdownField<String>(
              label: 'Category',
              value: demo.dropdownValue,
              items: const ['Retail', 'Wholesale', 'Manufacturing'],
              labelOf: (v) => v,
              onChanged: cubit.setDropdown,
            ),
            SizedBox(height: tokens.spacing.lg),

            const _Section('FK lookup field'),
            FkLookupField<_DemoBrand>(
              label: 'Brand',
              value: demo.pickedBrand,
              displayOf: (b) => b.name,
              loader: (query) async {
                await Future<void>.delayed(const Duration(milliseconds: 200));
                final q = query.toLowerCase();
                return _demoBrands
                    .where((b) => b.name.toLowerCase().contains(q))
                    .toList();
              },
              onSelected: cubit.setBrand,
            ),
            SizedBox(height: tokens.spacing.lg),

            const _Section('Page header'),
            PageHeader(
              eyebrow: 'Inventory',
              title: 'Brands',
              subtitle: '128 records',
              actions: [
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('New brand'),
                ),
              ],
            ),
            SizedBox(height: tokens.spacing.lg),

            const _Section('Work sheet + filter bar (the sheet toolbar)'),
            WorkSheet(
              fill: false,
              toolbar: FilterBar(
                searchHint: 'Search brands',
                onSearchChanged: (_) {},
                filters: const [
                  FilterChipData(
                    key: 'active',
                    label: 'Active',
                    selected: true,
                  ),
                  FilterChipData(key: 'inactive', label: 'Inactive'),
                ],
                onFilterToggled: (_) {},
                trailing: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.download_outlined),
                    tooltip: 'Export to CSV',
                  ),
                ],
              ),
              // In a real list screen the sheet fills the page and the ledger takes
              // its height from that. Here the sheet is content-sized, so the
              // ledger needs a height of its own to scroll within.
              child: SizedBox(
                height: 240,
                child: AdaptiveEntityList<_DemoBrand>(
                  items: _demoBrands,
                  keyOf: (b) => b.id,
                  onTap: (_) {},
                  columns: [
                    EntityColumn(
                      label: 'Code',
                      mono: true,
                      primary: true,
                      cellBuilder: (_, b) => Text('BRD-00${b.id}'),
                    ),
                    EntityColumn(
                      label: 'Name',
                      flex: 3,
                      cellBuilder: (_, b) => Text(b.name),
                    ),
                    EntityColumn(
                      label: 'Status',
                      cellBuilder: (_, b) => StatusChip(
                        status: b.active
                            ? EntityStatus.posted
                            : EntityStatus.cancelled,
                        label: b.active ? 'Active' : 'Inactive',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: tokens.spacing.lg),

            const _Section("Ledger skeleton (the list's first paint)"),
            const WorkSheet(fill: false, child: LedgerSkeleton(rows: 6)),
            SizedBox(height: tokens.spacing.lg),

            const _Section('Line item grid'),
            LineItemGrid<_DemoLine>(
              rows: demo.lines,
              newRow: () => _DemoLine(item: '', qty: Decimal.zero),
              columns: [
                LineItemColumn(
                  flex: 2,
                  label: 'Item',
                  cellBuilder: (context, row, i) => AppTextField(
                    label: 'Item',
                    value: row.item,
                    onChanged: (v) => row.item = v,
                  ),
                ),
                LineItemColumn(
                  label: 'Qty',
                  cellBuilder: (context, row, i) => AppDecimalField(
                    label: 'Qty',
                    value: row.qty,
                    onChanged: (v) => row.qty = v ?? Decimal.zero,
                  ),
                ),
              ],
              onChanged: cubit.setLines,
            ),
            SizedBox(height: tokens.spacing.lg),

            const _Section('Charts'),
            SignedBarChart(
              title: 'Sales vs purchase invoices',
              seriesLabels: const ['Sales', 'Purchase'],
              seriesColors: [tokens.brand.lagoon, tokens.brand.brass],
              groups: const [
                BarSeriesGroup(label: 'Apr', values: [4, 2]),
                BarSeriesGroup(label: 'May', values: [6, 3]),
                BarSeriesGroup(label: 'Jun', values: [5, 4]),
              ],
            ),
            SizedBox(height: tokens.spacing.sm),
            ShareDonutChart(
              title: 'Cash vs bank position',
              slices: [
                DonutSlice(
                  label: 'Cash',
                  value: 4200,
                  color: tokens.brand.lagoon,
                ),
                DonutSlice(
                  label: 'Bank',
                  value: 6800,
                  color: tokens.brand.brass,
                ),
              ],
              valueFormatter: (v) => 'AED ${v.toStringAsFixed(0)}',
            ),
            SizedBox(height: tokens.spacing.sm),
            RankedBarChart(
              title: 'Top customers (by invoice count)',
              barColor: tokens.brand.lagoon,
              entries: const [
                RankedBarEntry(label: 'Ledger #12', value: 9),
                RankedBarEntry(label: 'Ledger #4', value: 6),
                RankedBarEntry(label: 'Ledger #31', value: 3),
              ],
            ),
          ],
        );
      },
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
