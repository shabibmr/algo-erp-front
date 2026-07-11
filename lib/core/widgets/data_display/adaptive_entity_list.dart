import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:flutter/material.dart';

/// One column of an [AdaptiveEntityList]'s desktop/tablet table rendering.
/// [cellBuilder] gets the row item and returns the cell widget; [label] is
/// the column header text.
@immutable
class EntityColumn<T> {
  const EntityColumn({
    required this.label,
    required this.cellBuilder,
    this.numeric = false,
  });

  final String label;
  final Widget Function(BuildContext context, T item) cellBuilder;
  final bool numeric;
}

/// Renders a list of entities as a `DataTable` on tablet/desktop
/// (`context.isTablet || context.isDesktop`) and as a scrolling column of
/// cards on mobile — the one adaptive list shape every master list screen
/// should reuse instead of hand-rolling its own breakpoint switch.
///
/// ```dart
/// AdaptiveEntityList<Brand>(
///   items: brands,
///   columns: [
///     EntityColumn(label: 'Name', cellBuilder: (_, b) => Text(b.name)),
///     EntityColumn(label: 'Active', cellBuilder: (_, b) => StatusChip(...)),
///   ],
///   cardBuilder: (context, b) => ListTile(title: Text(b.name)),
///   onTap: (b) => context.go('/inventory/brand/${b.id}'),
/// )
/// ```
class AdaptiveEntityList<T> extends StatelessWidget {
  const AdaptiveEntityList({
    required this.items,
    required this.columns,
    required this.cardBuilder,
    super.key,
    this.onTap,
    this.keyOf,
  });

  final List<T> items;

  /// Column definitions used only in the table (tablet/desktop) rendering.
  final List<EntityColumn<T>> columns;

  /// Card content used only in the mobile rendering.
  final Widget Function(BuildContext context, T item) cardBuilder;
  final ValueChanged<T>? onTap;

  /// Optional stable key extractor (e.g. `(e) => e.id`) for `ValueKey`s so
  /// list animations/rebuilds don't misidentify rows.
  final Object? Function(T item)? keyOf;

  @override
  Widget build(BuildContext context) {
    final useTable = context.isTablet || context.isDesktop;
    return useTable ? _buildTable(context) : _buildCards(context);
  }

  Widget _buildTable(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          for (final column in columns)
            DataColumn(label: Text(column.label), numeric: column.numeric),
        ],
        rows: [
          for (final item in items)
            DataRow(
              key: keyOf == null ? null : ValueKey(keyOf!(item)),
              onSelectChanged:
                  onTap == null ? null : (_) => onTap!(item),
              cells: [
                for (final column in columns)
                  DataCell(column.cellBuilder(context, item)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCards(BuildContext context) {
    final tokens = context.tokens;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, _) => SizedBox(height: tokens.spacing.sm),
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          key: keyOf == null ? null : ValueKey(keyOf!(item)),
          margin: EdgeInsets.zero,
          child: InkWell(
            borderRadius: BorderRadius.circular(tokens.radii.md),
            onTap: onTap == null ? null : () => onTap!(item),
            child: Padding(
              padding: EdgeInsets.all(tokens.spacing.md),
              child: cardBuilder(context, item),
            ),
          ),
        );
      },
    );
  }
}
